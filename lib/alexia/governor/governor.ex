defmodule Alexia.Governor do

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


  @doc  """
    Hashes the bot token against an unique random string
    Adds the BOT info to an ets table for later recall
  """
    def add_bot_info(bot) do
      secret_mix = Application.get_env(:alexia,:secret_mix)
      current_bot_hash = :crypto.hash(:sha256,bot.token <> secret_mix)
      |> Base.url_encode64(padding: false)
  #    :ets.insert(:alexia_bot_info,{current_bot_hash,Map.put(bot,:matcher, matcher_pid)})
      current_bot_hash
    end

    #TODO it sems that I only need the matcher pid
    #since the bot token should already be in there!
    def get_bot_info(bot_hash) do
       case :ets.lookup(:alexia_bot_info, bot_hash)   do
         [{_ign, bot,matcher}] ->  {bot,matcher}
         [{_ign, bot}] ->  bot
          [] ->  nil
       end
    end

end
