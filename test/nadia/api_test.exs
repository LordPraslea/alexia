defmodule Nadia.APITest do
  use ExUnit.Case
  use ExVCR.Mock, adapter: ExVCR.Adapter.Hackney
  doctest Nadia.API
  alias Nadia.API

  setup_all do
    unless Application.get_env(:nadia, :token) do
      Application.put_env(:nadia, :token, "304884665:AAE1ItId1gf9MsM-Smrv9sPc0glmB2HkMAo")
      Application.put_env(:nadia, :bots, [
        %{bot_name: "Nadia", commands_module: YourAppModule.NadiaBot.Commands,
        token:  "304884665:AAE1ItId1gf9MsM-Smrv9sPc0glmB2HkMAo"}])
    end

    :ok
  end
  def get_token() do
      Application.get_env(:nadia, :token)
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
             "https://api.telegram.org/file/bot#{Nadia.Config.token()}/document/file_10"
  end
end
