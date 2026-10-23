defmodule LineaUI.TestEndpoint do
  @moduledoc """
  The endpoint `Phoenix.LiveViewTest` needs to mount LiveViews in the package's tests.

      use LineaUI.LiveCase
      {:ok, view, _html} = live_isolated(build_conn(), MyTestLive)
  """

  use Phoenix.Endpoint, otp_app: :linea_ui

  socket "/live", Phoenix.LiveView.Socket

  defmodule ErrorHTML do
    @moduledoc false
    def render(template, _assigns), do: Phoenix.Controller.status_message_from_template(template)
  end
end
