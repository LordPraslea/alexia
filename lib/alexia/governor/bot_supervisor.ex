defmodule Alexia.Supervisor.BotSupervisor do
  @moduledoc  """
    Bot Supervisor
  """
  use Supervisor

  def start_link(bots) do
    Supervisor.start_link(__MODULE__,bots, name: __MODULE__)
  end

  def init(bots) do
    :ets.new(:alexia_bot_info, [:public,:set, :named_table])
    poller_bots = filter_poller_bots(bots)
    webhook_bots =  filter_poller_bots(bots,:reject)

    children = [
        {Registry, [keys: :unique, name: Registry.BotPoller]},
        {Registry, [keys: :unique, name: Registry.BotMatcher]},
        Supervisor.child_spec({Alexia.Supervisor.Matcher, webhook_bots}, type: :supervisor),
        Supervisor.child_spec({Alexia.Supervisor.Poller, poller_bots}, type: :supervisor),
    ]
    Supervisor.init(children, strategy: :one_for_one)
  end

  defp filter_poller_bots(bots, type \\ :filter) do
    apply(Enum, type, [bots, fn (bot) ->
        is_nil(Map.get(bot,:webhook))
     end])
  end

end
