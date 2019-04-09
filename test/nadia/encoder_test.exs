defmodule Alexia.EncoderTest do
  use ExUnit.Case, async: true

  alias Alexia.Model.{InlineKeyboardButton}

  test "inline keyboard button excludes unknown keys as json" do
    json = Poison.encode!(%InlineKeyboardButton{})

    assert json == "{}"
  end
end
