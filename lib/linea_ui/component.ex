defmodule LineaUI.Component do
  @moduledoc false

  defmacro __using__(_opts) do
    quote do
      use Phoenix.Component

      import LineaUI.Component.Helpers
      import LineaUI.ClassMerge, only: [merge: 1]

      alias Phoenix.LiveView.JS
    end
  end
end
