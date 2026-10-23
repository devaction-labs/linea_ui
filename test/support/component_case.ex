defmodule LineaUI.ComponentCase do
  @moduledoc """
  Renders components into a parsed document, so tests assert on elements and attributes
  instead of on markup strings.

      html = render(~H"<.button color=\"primary\">Save</.button>")
      assert [button] = find(html, "button")
  """

  use ExUnit.CaseTemplate

  using do
    quote do
      use LineaUI
      import Phoenix.Component
      import Phoenix.LiveViewTest, only: [rendered_to_string: 1]
      import LineaUI.ComponentCase
    end
  end

  @doc "Renders a `~H` template given as `fn assigns -> ~H\"...\" end`."
  defmacro render(template) do
    quote do
      var!(assigns) = %{__changed__: nil}
      Phoenix.LiveViewTest.rendered_to_string(unquote(template))
    end
  end

  @doc "The elements of `html` that match the CSS `selector`."
  @spec find(String.t(), String.t()) :: LazyHTML.t()
  def find(html, selector), do: html |> LazyHTML.from_fragment() |> LazyHTML.query(selector)

  @doc "The class list of the first element of `html` matching `selector`."
  @spec classes(String.t(), String.t()) :: [String.t()]
  def classes(html, selector) do
    html
    |> find(selector)
    |> LazyHTML.attribute("class")
    |> List.first("")
    |> String.split()
  end
end
