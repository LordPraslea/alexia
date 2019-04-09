defmodule Alexia.APITest do
  use ExUnit.Case
  use ExVCR.Mock, adapter: ExVCR.Adapter.Hackney
  doctest Alexia.API
  alias Alexia.API

  setup_all do
    unless Application.get_env(:alexia, :token) do
      Application.put_env(:alexia, :token, "304884665:AAE1ItId1gf9MsM-Smrv9sPc0glmB2HkMAo")
      Application.put_env(:alexia, :bots, [
        %{bot_name: "Alexia", commands_module: YourAppModule.AlexiaBot.Commands,
        token:  "304884665:AAE1ItId1gf9MsM-Smrv9sPc0glmB2HkMAo"}])
    end

    :ok
  end
  def get_token() do
      Application.get_env(:alexia, :token)
  end
  setup do
    ExVCR.Config.filter_sensitive_data("bot[^/]+/", "bot<TOKEN>/")
    :ok
  end

  test "request_with_map" do
    use_cassette "api_request_with_map", match_requests_on: [:request_body] do
      assert [] == API.request?("getUpdates",get_token(), %{"limit" => 4})
    end
  end

  test "build_file_url" do
    assert API.build_file_url(get_token(), "document/file_10") ==
             "https://api.telegram.org/file/bot#{Alexia.Config.token()}/document/file_10"
  end
end
