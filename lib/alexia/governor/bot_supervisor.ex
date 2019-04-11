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

    children = [
        {Registry, [keys: :unique, name: Registry.BotPoller]},
        {Registry, [keys: :unique, name: Registry.BotMatcher]},
        Supervisor.child_spec({Alexia.Supervisor.Matcher, []}, type: :supervisor),
        Supervisor.child_spec({Alexia.Supervisor.Poller, poller_bots}, type: :supervisor),
    ]

    Supervisor.init(children, strategy: :one_for_one)
  end

  defp filter_poller_bots(bots) do
    Enum.filter(bots, fn (bot) ->
      webhook = Map.get(bot,:webhook)
      if is_nil(webhook) do
        true
      else
        current_bot_hash = Alexia.Governor.add_bot_info(bot)
        Alexia.set_webhook(bot.token,url: webhook <> current_bot_hash )
        IO.puts "Starting webhook #{webhook <> current_bot_hash }"
        false
      end
     end)
  end



end
