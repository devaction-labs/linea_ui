defmodule LineaUI.LiveCase do
  @moduledoc """
  Tests that drive a component inside a real LiveView: clicks, form changes, pushed events.

      defmodule MyLive do
        use Phoenix.LiveView
        use LineaUI

        def mount(_params, _session, socket), do: {:ok, assign(socket, open: false)}
        def render(assigns), do: ~H"<.modal id=\\"m\\" open={@open}>Hi</.modal>"
      end

      {:ok, view, _html} = live_isolated(build_conn(), MyLive)

  Test LiveViews go in the test file itself or in `test/support/live/<component>_live.ex`.
  """

  use ExUnit.CaseTemplate

  using do
    quote do
      import Phoenix.ConnTest
      import Phoenix.LiveViewTest
      import LineaUI.ComponentCase, only: [find: 2, classes: 2]

      @endpoint LineaUI.TestEndpoint
    end
  end

  setup do
    {:ok, conn: Phoenix.ConnTest.build_conn()}
  end
end
