defmodule Nadia.Governor.Poller do
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
    name =  {:via, Registry, {Registry.BotPoller, bot_name}}
    settings = Map.merge(settings, %{name: name, offset: 0})
    Logger.log :info, "Started poller for BOT: #{bot_name}  "
    GenServer.start_link __MODULE__, settings, name: name
  end

  def init(%{name: name} = settings) do
    {:ok, matcher_pid} = Supervisor.start_child(Nadia.Supervisor.Matcher,
      Supervisor.child_spec({Nadia.Governor.Matcher, settings}, id: settings.bot_name ))
      update(name)
    {:ok, Map.put(settings,:matcher, matcher_pid)}
  end

  def handle_cast(:update, %{offset: offset, token: token} = state) do
    new_offset = Nadia.get_updates(token,[offset: offset])
                 |> process_messages(state)
    #  IO.puts "Offset differences old #{offset} new #{new_offset}"
    {:noreply, Map.put(state,:offset,new_offset + 1), 1000}
  end

  def timeout() do

  end
  # ^ Default Timeout of 1 second. ^
  #TODO if it goes for 5 minute without any message then boost the timeout
  #to 2 seconds and put ti back to 1 second once receiving a message
  # 5 minutes 2 seconds
  # 10 minutes 3 seconds
  # 20 minutes 4 seconds
  # 30 minutes 5 seconds
  # 1 hour+ rand 5 - 10 seconds
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
      Logger.debug "#{bot_settings.bot_name} #{inspect bot_settings.matcher} \n #{inspect message}"
      Nadia.Governor.Matcher.match bot_settings.matcher, message,bot_settings.token
    #  match(message,bot_settings)
    rescue
      err in MatchError ->
        Logger.log :warn, "Errored with #{err} at #{Poison.encode! message}"
    end
  end



end
