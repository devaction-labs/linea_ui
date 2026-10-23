defmodule LineaUI.Component.Helpers do
  @moduledoc """
  What every component shares: ids, form fields and the color vocabulary.

  The colors are LineOne's: `neutral`, `primary`, `secondary`, `accent`, `info`, `success`,
  `warning`, `error`. In dark mode LineOne paints `primary` with `accent`, so every `primary`
  style carries its `dark:` accent counterpart.
  """

  use Phoenix.Component

  @colors ~w(neutral primary secondary accent info success warning error)

  @doc "The color names every colored component accepts."
  @spec colors() :: [String.t()]
  def colors, do: @colors

  @doc "A unique DOM id, for a component that needs one and was not given it."
  @spec gen_id(String.t()) :: String.t()
  def gen_id(prefix \\ "linea"),
    do: "#{prefix}-#{System.unique_integer([:positive, :monotonic])}"

  @doc """
  Fills `id`, `name`, `value` and `errors` from `field` when one is given.

  `errors` is the list of translated messages, shown only once the field has been used
  (`Phoenix.Component.used_input?/1`).
  """
  @spec assign_field(map()) :: map()
  def assign_field(%{field: %Phoenix.HTML.FormField{} = field} = assigns) do
    errors = errors(field)

    assigns
    |> assign(field: nil)
    |> fill(:id, field.id)
    |> fill(:name, field_name(field, assigns))
    |> fill(:value, field.value)
    |> assign(:errors, Enum.map(errors, &translate_error/1) ++ Map.get(assigns, :errors, []))
  end

  def assign_field(assigns), do: assign_new(assigns, :errors, fn -> [] end)

  defp fill(assigns, key, value) do
    case Map.get(assigns, key) do
      nil -> assign(assigns, key, value)
      _given -> assigns
    end
  end

  defp field_name(field, %{multiple: true}), do: field.name <> "[]"
  defp field_name(field, _assigns), do: field.name

  defp errors(field) do
    case Phoenix.Component.used_input?(field) do
      true -> field.errors
      false -> []
    end
  end

  @doc """
  Turns an Ecto-style error tuple into text. Set your own translator with

      config :linea_ui, :translate_error, &MyAppWeb.CoreComponents.translate_error/1
  """
  @spec translate_error({String.t(), keyword()} | String.t()) :: String.t()
  def translate_error({message, opts}) do
    case Application.get_env(:linea_ui, :translate_error) do
      nil -> interpolate(message, opts)
      translate -> translate.({message, opts})
    end
  end

  def translate_error(message) when is_binary(message), do: message

  defp interpolate(message, opts) do
    Enum.reduce(opts, message, fn {key, value}, acc ->
      String.replace(acc, "%{#{key}}", fn _ -> to_string(value) end)
    end)
  end

  @doc "`\"true\"` or `\"false\"`, for `data-*` and `aria-*` attributes."
  @spec bool(boolean()) :: String.t()
  def bool(true), do: "true"
  def bool(false), do: "false"
end
