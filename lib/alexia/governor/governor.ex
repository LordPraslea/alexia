defmodule Alexia.Governor do
  require Logger

  @doc  """
    Given an update (either from getUpdates or webhook) it extracts the chat_id

    It can be from an inline_query, callback_query, message, edited message or channel post.
  """
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
    Hashes the bot token against an unique random string called `:secret_mix`
  """
    def get_bot_hash(bot) do
      secret_mix = Application.get_env(:alexia,:secret_mix)
      :crypto.hash(:sha256,bot.token <> secret_mix)
      |> Base.url_encode64(padding: false)
    end


    @doc  """
      Given the `bot_hash` it returns the bot_matcher_pid or nil if it doesn't exist.

      Args:
      * `bot_hash` - Hashed bot token
      Returns the bot bot_matcher_pid
    """
    def get_bot_info(bot_hash) do
       case :ets.lookup(:alexia_bot_info, bot_hash)   do
         [{_ign, bot,matcher_pid}] ->  {bot,matcher_pid}
         [{_ign, bot_matcher_pid}] ->  bot_matcher_pid
          [] ->  nil
       end
    end

    @doc  """
      Given the `bot` map it takes the token and hashes it. If the webhook is set up then it
      sets the correct webhook URL with the hashed token.

      Args:
      * `bot` - Bot map containing bot_name, token and other settings.
      Returns the bot bot_matcher_pid
    """
    def setup_bot_webhook(bot) do
      webhook = Map.get(bot,:webhook)
      current_bot_hash = Alexia.Governor.get_bot_hash(bot)
      if !is_nil(webhook) do
        #    Alexia.Governor.Matcher.start_matcher(bot)
        Alexia.set_webhook(bot.token,url: webhook <> current_bot_hash )
        Logger.info "Starting webhook #{webhook <> current_bot_hash }"
      end
      current_bot_hash
    end

end
