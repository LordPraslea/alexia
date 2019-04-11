defmodule Alexia.Governor.Matcher do
  @moduledoc """
      Each Bot has a Matcher GenServer which runs independent
      spawned_links for the functions and modules to run the commands
  """
  use GenServer
#  alias MafiaBot.Commands
  require Logger

  # Server

  def start_link(bot) do
    bot_name = Map.get(bot,:bot_name)
    name =  {:via, Registry, {Registry.BotMatcher, bot_name}}
    current_bot_hash = Alexia.Governor.add_bot_info(bot)
    bot = Map.merge(bot, %{name: name, current_bot_hash: current_bot_hash })
    Logger.log :info, "Started matcher for bot #{bot_name}  "
    GenServer.start_link __MODULE__, bot, name: name
  end

  def init(bot) do
    :ets.insert(:alexia_bot_info,{bot.current_bot_hash,self()})
    {:ok, bot}
  end

  #Run command in task
  def handle_cast({message,token}, state) do
    Task.start fn ->
      apply(state.commands_module, :command, [message,token])
    end
    {:noreply, state}
  end
  def handle_cast({message}, state) do
    Task.start fn ->
      apply(state.commands_module, :command, [message,state.token])
    end
    {:noreply, state}
  end

  # Client

  def match(matcher_name,message, token) do
    GenServer.cast(matcher_name, {message,token})
  end

  def match(matcher_name,message) do
    GenServer.cast(matcher_name, {message})
  end

  @doc  """
    Dynamically starting a matcher for a bot under the Matcher Supervisor
  """
  def start_matcher(bot) do
    Supervisor.start_child(Alexia.Supervisor.Matcher,
      Supervisor.child_spec({Alexia.Governor.Matcher, bot}, id: bot.bot_name ))
  end

end
