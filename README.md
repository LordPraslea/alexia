Alexia [![Build Status](https://travis-ci.org/zhyu/alexia.svg?branch=master)](https://travis-ci.org/zhyu/alexia) [![Inline docs](http://inch-ci.org/github/zhyu/alexia.svg)](http://inch-ci.org/github/zhyu/alexia) [![Hex pm](https://img.shields.io/hexpm/v/alexia.svg)](https://hex.pm/packages/alexia) [![Hex.pm](https://img.shields.io/hexpm/dt/alexia.svg)](https://hex.pm/packages/alexia)
=====

Telegram Bot API Wrapper written in Elixir ([document](https://hexdocs.pm/alexia/))

This is a fork of nadia adding extra features, enhancements etc.
*NOTE* Version 0.5.0 implements multi bots and comes with a total makeover.
It's not backward compatible with the previous versions of nadia (0.4.4) unless you remap the functions yourself.

[A detailed HOW TO tutorial is available on my blog](https://andreiclinciu.net/alexia-telegram-bot-library-for-elixir-multi-bot-environments-and-supervisor)

## Installation
Add Alexia to your `mix.exs` dependencies:

```elixir
def deps do
  [{:alexia, "~> 0.5.3"}]
end
```
and run `$ mix deps.get`.

## Configuration

In `config/config.exs`, add your Telegram Bot settings like [this](config/config.exs.example)

```elixir
config :alexia, bots: [
  %{bot_name: "AlexandraBot", commands_module: YourAppModule.AlexandraBot.Commands,
  token:  Base.decode64!("KFEDOSKYG5KUQSZVK5CDKU22INEUUWCZGRLDIRKPJ5BEUQZWK5IA"),
    webhook: "https://yourdomain.example.com/your-telegram-update-link/"},
  %{bot_name: "MegaCoolBot", commands_module: YourAppModule.MegaCoolBot.Commands,
  token: Base.decode64!("KZDU2VBUJZJUQQJSIFLVMT2SGZCVMWKYKFKUOQ2OKNHU4QSXIU2Q")}],
  secret_mix: "MOq8cDjlwEBoLi88TXfGY+HeQllySLgEuObNUr006Ug"

```

You can also add an optional recv_timeout in seconds (defaults to 5s).
```elixir
config :alexia,
  recv_timeout: 10
```

You can also add a proxy support.
```elixir
config :alexia,
  proxy: "http://proxy_url:proxy_port",
  proxy_auth: {"user", "password"},
  ssl: [versions: [:'tlsv1.2']]
```

You can also configure the the base url for the api if you need to for some
reason.

```elixir
config :alexia,
  # Telegram API. Default: https://api.telegram.org/bot
  base_url: "http://my-own-endpoint.com/whatever/",

  # Telegram Graph API. Default: https://api.telegra.ph
  graph_base_url: "http://my-own-endpoint.com/whatever/"
```

Environment variables may be used as well:

```elixir
config :alexia,
  token: {:system, "ENVVAR_WITH_MYAPP_TOKEN", "default_value_if_needed"}
```

And then, in `mix.exs`, list `:alexia` as an application inside `application/0`:

```elixir
def application do
  [applications: [:alexia]]
end
```

Now Mix will guarantee the `:alexia` application is started before your application is started.

## Using the built-in Governor "framework" to handle multiple bots
The Governor framework is just a functionality enhancement which adds
supervisor trees to handle the Registry, bot Pollers and Bot Matchers.
Taking care of the fault tolerance part so you can focus on programming.
This makes it easy to have multiple bots within the same application.

What happens is on Startup the settings are read and then
a Poller is setup under a supervision tree for each bot.
The Poller then handles off to a Matcher which then allows YOU
to specify a specific module in your application to run code.
This can be done on a per bot basis.

### Edit App.Application
Add this to the Supervisor      
```elixir
  {Alexia.Supervisor.BotSupervisor, Application.get_env(:alexia,:bots)},
```

### Creating a YourBotApp.Commands modules for each bot
See the example setup at [this](examples/commands.ex.example) and [this](examples/testing.ex.example)
```elixir
defmodule YourBot.Commands do
    #alias Alexia.Model

  #Handling Messages from chats to their own command
  def command(%{message: %{text: text} } = update, token) do
    text_command(text,update,token)
  end

  #Handy when using the Up arrow! and editing the previous message
    def command(%{edited_message: %{text: text} } = update, token) do
      text_command(text,update,token)
    end
  #Inline queries see documentation
  def command(%{inline_query: %{query: query}} = update,token) do
    inline_query_command(query,update,token)
  end
  #Callback queries, see documentation
  def command(%{callback_query: %{data: data}} = update,token) do
    callback_query_command(data,update,token)
  end

  #Catchall, can be used for debugging/Testing OR
  #Showing your default help/answer for unknown requests
  def command(update, token), do: default_reply(update,token)

  #Example of externalizing
  def inline_query_command("troll" <> _,update,token), do: Testing.inline_query_command("troll",update,token)

  def inline_query_command(_query,update,token) do
    #Default
  end
  def callback_query_command("/choose" <> _,update,token), do: Testing.callback_query_command("/choose",update,token)

  def callback_query_command(_data,update,token) do
      Alexia.answer_callback_query token,update.callback_query.id,      text: "Default callback."
  end

  def text_command("hello",update,token)  do
    Alexia.send_message(token,Alexia.Governor.get_chat_id(update),"Well, hello there! #{update.message.from.first_name}")
  end
  #Externalize to a different module
  def text_command("/yourcommand",update,token),  do: Testing.text_command("/yourcommand",update,token)
  def text_command(_,update,token) , do: default_reply(update,token)

  #The default reply
    def default_reply(update,token) do
      Alexia.send_message(token,Alexia.Governor.get_chat_id(update), "Sorry, that command is NOT yet implemented!")
    end
end
```

Duplicate the above for each bot you need

### get_me

```elixir
iex> Alexia.get_me(token)
{:ok,
 %Alexia.Model.User{first_name: "Alexia", id: 666, last_name: nil,
  username: "alexia_bot"}}
```

### get_updates

```elixir
iex> Alexia.get_updates bot_token, limit: 5
{:ok, []}

iex> {:ok,
 [%Alexia.Model.Update{callback_query: nil, chosen_inline_result: nil,
   edited_message: nil, inline_query: nil,
   message: %Alexia.Model.Message{audio: nil, caption: nil,
    channel_chat_created: nil,
    chat: %Alexia.Model.Chat{first_name: "Alexia", id: 123,
     last_name: "TheBot", title: nil, type: "private", username: "alexia_the_bot"},
    contact: nil, date: 1471208260, delete_chat_photo: nil, document: nil,
    edit_date: nil, entities: nil, forward_date: nil, forward_from: nil,
    forward_from_chat: nil,
    from: %Alexia.Model.User{first_name: "Alexia", id: 123,
     last_name: "TheBot", username: "alexia_the_bot"}, group_chat_created: nil,
    left_chat_member: nil, location: nil, message_id: 543,
    migrate_from_chat_id: nil, migrate_to_chat_id: nil, new_chat_member: nil,
    new_chat_photo: [], new_chat_title: nil, photo: [], pinned_message: nil,
    reply_to_message: nil, sticker: nil, supergroup_chat_created: nil,
    text: "rew", venue: nil, video: nil, voice: nil}, update_id: 98765}]}
```

### send_message

```elixir
iex> case Alexia.send_message(token, telegram_chat_id, "The message text goes here") do
  {:ok, _result} ->
    :ok
  {:error, %Alexia.Model.Error{reason: "Please wait a little"}} ->
    :wait
  end

:ok
```

You can use the built in Governor.get_chat_id(update) on the update received
so it will extract the correct chat_id for you
 Alexia.send_message(token, Governor.get_chat_id(update), "The message text goes here")


### Some Considerations about using the token

Taken into consideration that the previous version only had one call to the config for the bot_token.
This implementation transmits the token as the first argument to each command.
I've taken into consideration using and implementing macro's and such.
Or calling the current genserver to get the token
However needless complexity surfaces each time.

Refer to [Alexia document](https://hexdocs.pm/alexia/) and [Telegram Bot API document](https://core.telegram.org/bots/api) for more details.
