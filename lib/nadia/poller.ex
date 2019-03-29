defmodule Nadia.Poller do
    @moduledoc """
      Creates a continuous poller for each BOT keeping the state intact.
      It's possible to run multiple bots, each in it's own state with it's own poller.
      Under a supervision tree
    """
    use GenServer
    require Logger

  # Server
  #%{token: bot_token, config: config, offset: 0}
  def start_link(settings) do
    bot_name = Map.get(settings,:bot_name)
    name =  {:via, Registry, {Registry.Bots, bot_name}}
    settings = Map.merge(settings, %{name: name, offset: 0})
    Logger.log :info, "Started poller for bot #{bot_name}  "
    GenServer.start_link __MODULE__, settings, name: name
  end

  def init(%{name: name} = settings) do
    update(name)
    {:ok, settings}
  end

  def handle_cast(:update, %{offset: offset, token: token} = state) do
    new_offset = Nadia.get_updates(token,[offset: offset])
                 |> process_messages(state)
    {:noreply, Map.put(state,:offset,new_offset + 1), 1000}
  end

  # ^ Default Timeout of 1 second. ^
  #TODO if it goes for 1 minute without any message then boost the timeout
  #to 5-10 seconds and put ti back to 1 second once receiving a message
  #This way for multiple bots it won't spam the telegram servers for updates
  #unnecessarily
  def handle_info(:timeout, %{name: name} = state) do
    update(name)
    {:noreply, state}
  end

  @doc  """
  There is a known problem in SSL Erlang where you get the following error
  {:ssl_closed, {:sslsocket, {:gen_tcp, #Port<0.27>, :tls_connection, :undefined}, [#PID<0.402.0>, #PID<0.401.0>]}}
  See
  https://github.com/benoitc/hackney/issues/464 & https://bugs.erlang.org/browse/ERL-371

   This goes through to hackney,httpoison up to the poller    The ports and pids don't exist anymore.
   The only sane way to handle this is via another "update".
   Since killing/sending a shutdown will restart it continuously & will pollute the logs every 3 minues
  """
  def handle_info({:ssl_closed, _}, %{name: name} = state) do
    update(name)
    #    {:stop, :ssl_closed, state}
    {:noreply, state}
  end

  # Client

  def update(name) do
    GenServer.cast name, :update
  end

  # Helpers

  defp process_messages({:ok, []},_state), do: -1
  defp process_messages({:ok, results},state) do
    results
    |> Enum.map(fn %{update_id: id} = message ->
      message
      |> process_message(state)

      id
    end)
    |> List.last
  end
  defp process_messages({:error, %Nadia.Model.Error{reason: reason}},_state) do
    Logger.log :error, reason
    -1
  end
  defp process_messages({:error, error},_state) do
    Logger.log :error, error
    -1
  end

  defp process_message(nil,_state), do: IO.puts "nil"
  defp process_message(message,bot_settings) do
    try do
    #  MafiaBot.Matcher.match message
      match(message,bot_settings)
    rescue
      err in MatchError ->
        Logger.log :warn, "Errored with #{err} at #{Poison.encode! message}"
    end
  end

  def match(%{message: %{text: "hi"} } = update,%{token: token} = bot_settings) do
    Nadia.send_message(token,get_chat_id(update),"Well, hello there! #{update.message.from.first_name}")
  end
  def match(update,%{token: token}) do
    Nadia.send_message(token,get_chat_id(update), "Sorry, that command is NOT yet implemented!")
  end
  def get_chat_id(update) do
    case update do
       %{inline_query: inline_query} when not is_nil(inline_query) ->
         inline_query.from.id
       %{callback_query: callback_query} when not is_nil(callback_query) ->
         callback_query.message.chat.id
       %{message: %{chat: %{id: id}}} when not is_nil(id) ->
         id
       %{edited_message: %{chat: %{id: id}}} when not is_nil(id) ->
         id
       %{channel_post: %{chat: %{id: id}}} when not is_nil(id) ->
         id
       _ -> raise "No chat id found!"
     end
    end

end
