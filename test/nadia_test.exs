defmodule NadiaTest do
  use ExUnit.Case, async: false
#  use ExVCR.Mock, adapter: ExVCR.Adapter.Hackney
  doctest Nadia, only: [get_file_link: 1]
  alias Nadia.Model.User
  require Logger

  setup_all do
    unless Application.get_env(:nadia, :token) do
      Application.put_env(:nadia, :token, {:system, "ENV_TOKEN", "TEST_TOKEN"})
    end

    :ok
  end

  setup do
    bypass = Bypass.open()
    Application.put_env(:nadia, :base_url, "http://localhost:#{bypass.port}/")
    {:ok, bypass: bypass}
  end

  test "get_me", %{bypass: bypass} do
      Bypass.expect(bypass, fn conn ->
        Plug.Conn.resp(conn, 200, Poison.encode!(
        %{ok: true, result: %{id: 777,  username: "TelexiaBot"}}))
        end)

      assert  {:ok, %User{id: 777,  username: "TelexiaBot"}} = Nadia.get_me(Nadia.Config.token())
  end

  test "outage or connection refused", %{bypass: bypass} do
      Bypass.down(bypass)
      assert {:error, %Nadia.Model.Error{reason: :econnrefused}} = Nadia.get_me(Nadia.Config.token())
  end

  test "send_message", %{bypass: bypass} do
    data = %{message_id: 777, text: "Hey There!"}
    Bypass.expect(bypass, fn conn ->
      Plug.Conn.resp(conn, 200, Poison.encode!(%{ok: true, result: data}))
      end)
      {:ok, message} = Nadia.send_message(Nadia.Config.token(),777, "Hey There!")
      assert message.text == "Hey There!"

  end

  test "forward_message", %{bypass: bypass} do
    data = %{forward_date: 123456798, forward_from: %{username: "SomeRandomDude", id: 72551}}
    Bypass.expect(bypass, fn conn ->
      Plug.Conn.resp(conn, 200, Poison.encode!(%{ok: true, result: data}))
    end)

      {:ok, message} = Nadia.forward_message(Nadia.Config.token(),777, 777, 777)
      refute is_nil(message.forward_date)
      refute is_nil(message.forward_from)

  end

  test "send_photo", %{bypass: bypass} do
    file_id = "AgADBQADq6cxG7Vg2gSIF48DtOpj4-edszIABGGN5AM6XKzcLjwAAgI"
    data = %{photo: [%{file_id: file_id}]}
    Bypass.expect(bypass, fn conn ->
      Plug.Conn.resp(conn, 200, Poison.encode!(%{ok: true, result: data}))
    end)

      {:ok, message} = Nadia.send_photo(Nadia.Config.token(),777, file_id)
      assert is_list(message.photo)
      assert Enum.any?(message.photo, &(&1.file_id == file_id))

  end

  test "send_sticker", %{bypass: bypass} do
      {:ok, message} = Nadia.send_sticker(Nadia.Config.token(),777, "BQADBQADBgADmEjsA1aqdSxtzvvVAg")
      refute is_nil(message.sticker)
      assert message.sticker.file_id == "BQADBQADBgADmEjsA1aqdSxtzvvVAg"
  end
~S"""


  test "send_contact" do
    use_cassette "send_contact" do
      {:ok, message} = Nadia.send_contact(Nadia.Config.token(),666, 10_123_800_555, "Test")
      refute is_nil(message.contact)
      assert message.contact.phone_number == "10123800555"
      assert message.contact.first_name == "Test"
    end
  end

  test "send_location" do
    use_cassette "send_location" do
      {:ok, message} = Nadia.send_location(Nadia.Config.token(),666, 1, 2)
      refute is_nil(message.location)
      assert_in_delta message.location.latitude, 1, 1.0e-3
      assert_in_delta message.location.longitude, 2, 1.0e-3
    end
  end

  test "send_venue" do
    use_cassette "send_venue" do
      {:ok, message} = Nadia.send_venue(Nadia.Config.token(),666, 1, 2, "Test", "teststreet")
      refute is_nil(message.venue)
      assert_in_delta message.venue.location.latitude, 1, 1.0e-3
      assert_in_delta message.venue.location.longitude, 2, 1.0e-3
      assert message.venue.title == "Test"
      assert message.venue.address == "teststreet"
    end
  end

  test "send_chat_action" do
    use_cassette "send_chat_action" do
      assert Nadia.send_chat_action(Nadia.Config.token(),666, "typing") == :ok
    end
  end

  test "get_user_profile_photos" do
    use_cassette "get_user_profile_photos" do
      {:ok, user_profile_photos} = Nadia.get_user_profile_photos(Nadia.Config.token(),666)
      assert user_profile_photos.total_count == 1
      refute is_nil(user_profile_photos.photos)
    end
  end

  test "get_updates" do
    use_cassette "get_updates" do
      {:ok, updates} = Nadia.get_updates(Nadia.Config.token(),limit: 1)
      assert length(updates) == 1
    end
  end

  test "set webhook" do
    use_cassette "set_webhook" do
      assert Nadia.set_webhook(Nadia.Config.token(),url: "https://telegram.org/") == :ok
    end
  end

  test "get webhook info" do
    use_cassette "get_webhook_info" do
      webhook_info = %Nadia.Model.WebhookInfo{
        allowed_updates: [],
        has_custom_certificate: false,
        last_error_date: nil,
        last_error_message: nil,
        max_connections: nil,
        pending_update_count: 0,
        url: ""
      }

      assert Nadia.get_webhook_info(Nadia.Config.token()) == {:ok, webhook_info}
    end
  end

  test "delete webhook" do
    use_cassette "delete_webhook" do
      assert Nadia.delete_webhook(Nadia.Config.token()) == :ok
    end
  end

  test "get_file" do
    use_cassette "get_file" do
      {:ok, file} = Nadia.get_file(Nadia.Config.token(),"BQADBQADBgADmEjsA1aqdSxtzvvVAg")
      refute is_nil(file.file_path)
      assert file.file_id == "BQADBQADBgADmEjsA1aqdSxtzvvVAg"
    end
  end

  test "get_file_link" do
    file = %Nadia.Model.File{
      file_id: "BQADBQADBgADmEjsA1aqdSxtzvvVAg",
      file_path: "document/file_10",
      file_size: 17680
    }

    {:ok, file_link} = Nadia.get_file_link(Nadia.Config.token(),file)

    assert file_link ==
             "https://api.telegram.org/file/bot#{Nadia.Config.token()}/document/file_10"
  end

  test "get_chat" do
    use_cassette "get_chat" do
      {:ok, chat} = Nadia.get_chat("@group")
      assert chat.username == "group"
    end
  end

  test "get_chat_member" do
    use_cassette "get_chat_member" do
      {:ok, chat_member} = Nadia.get_chat_member("@group", 666)
      assert chat_member.user.username == "nadia_bot"
      assert chat_member.status == "member"
    end
  end

  test "get_chat_administrators" do
    use_cassette "get_chat_administrators" do
      {:ok, [admin | [creator]]} = Nadia.get_chat_administrators(Nadia.Config.token(),"@group")
      assert admin.status == "administrator"
      assert admin.user.username == "nadia_bot"
      assert creator.status == "creator"
      assert creator.user.username == "group_creator"
    end
  end

  test "get_chat_members_count" do
    use_cassette "get_chat_members_count" do
      {:ok, count} = Nadia.get_chat_members_count(Nadia.Config.token(),"@group")
      assert count == 2
    end
  end

  test "leave_chat" do
    use_cassette "leave_chat" do
      assert Nadia.leave_chat(Nadia.Config.token(),"@group") == :ok
    end
  end

  test "answer_inline_query" do
    photo = %Nadia.Model.InlineQueryResult.Photo{
      id: "1",
      photo_url:
        "http://vignette1.wikia.nocookie.net/cardfight/images/5/53/Monokuma.jpg/revision/latest?cb=20130928103410",
      thumb_url:
        "http://vignette1.wikia.nocookie.net/cardfight/images/5/53/Monokuma.jpg/revision/latest?cb=20130928103410"
    }

    use_cassette "answer_inline_query" do
      assert :ok == Nadia.answer_inline_query(Nadia.Config.token(),666, [photo])
    end
  end
"""
end
