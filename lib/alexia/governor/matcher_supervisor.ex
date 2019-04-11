defmodule Alexia.Supervisor.Matcher do
  @moduledoc  """
    Bot Matcher Supervisor
  """
  use Supervisor

  def start_link(bots) do
    Supervisor.start_link(__MODULE__,bots, name: __MODULE__)
  end

  def init(bots) do
  #  children  =    [   ]
    children = Enum.map(bots,fn (bot) ->
        Supervisor.child_spec({Alexia.Governor.Matcher, bot}, id: bot.bot_name )
    end)
    Supervisor.init(children, strategy: :one_for_one)
  end
end
