defmodule LineaUI.Test.TabsLive do
  @moduledoc false
  use Phoenix.LiveView
  use LineaUI

  def mount(_params, _session, socket), do: {:ok, assign(socket, tab: "home", picked: nil)}

  def render(assigns) do
    ~H"""
    <.tabs id="t" selected={@tab} on_change="pick">
      <:tab name="home">Home</:tab>
      <:tab name="profile">Profile</:tab>
      <:panel name="home">Home panel</:panel>
      <:panel name="profile">Profile panel</:panel>
    </.tabs>
    <button id="server-pick" phx-click="server_pick">Profile from the server</button>
    <p id="picked">{@picked}</p>
    """
  end

  def handle_event("pick", %{"id" => "t", "value" => value, "tab" => value}, socket),
    do: {:noreply, assign(socket, picked: value)}

  def handle_event("server_pick", _params, socket), do: {:noreply, assign(socket, tab: "profile")}
end
