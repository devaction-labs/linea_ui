defmodule LineaUI.Components.ToastStyleConfigTest do
  # Changes the application env, so it does not run alongside other tests.
  use ExUnit.Case, async: false

  alias LineaUI.Components.Toast

  test "config :toast_style, :card restores the classic card" do
    Application.put_env(:linea_ui, :toast_style, :card)
    on_exit(fn -> Application.delete_env(:linea_ui, :toast_style) end)
    assert Toast.payload("x", kind: :success)["status"] == nil
  end
end
