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

  @doc """
  A DOM id that is the same on every render of the same component, for one that needs an id
  (hooks, `for=`) and was not given it.

  Derived from `name` in `assigns` when there is one (sanitized to a valid id), else from a hash of
  the identifying `keys` (never `value`, which changes as the user types). Two instances on a page
  with neither `id` nor `name` and equal `keys` get the same id: pass `id` to tell them apart.
  """
  @spec stable_id(String.t(), map(), [atom()]) :: String.t()
  def stable_id(prefix, assigns, keys \\ [:label, :placeholder, :help]) do
    case Map.get(assigns, :name) do
      name when is_binary(name) and name != "" ->
        "#{prefix}-#{String.replace(name, ~r/[^A-Za-z0-9_\-:.]/, "_")}"

      _ ->
        hash = :erlang.phash2(for(key <- keys, do: Map.get(assigns, key)))
        "#{prefix}-#{hash}"
    end
  end

  @doc "A unique DOM id; changes on every call, so use it only outside render (e.g. toast ids)."
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

  def assign_field(assigns), do: put_default(assigns, :errors, [])

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

  @doc """
  Assigns `key` to the value `fun` computes from other assigns, marking it as changed only
  when one of `deps` changed.

  A value put with `assign/3` in a function component is new on every render (the component
  gets fresh assigns), so every expression reading it is sent again. With `assign_derived/4`
  the value is still computed (the template may need it next to something else that changed),
  but LiveView skips what reads only it while its inputs stay the same.
  """
  @spec assign_derived(map(), atom(), [atom()], (-> term())) :: map()
  def assign_derived(%{__changed__: changed} = assigns, key, deps, fun) when is_map(changed) do
    if Enum.any?(deps, &is_map_key(changed, &1)),
      do: assign(assigns, key, fun.()),
      else: Map.put(assigns, key, fun.())
  end

  def assign_derived(assigns, key, _deps, fun), do: assign(assigns, key, fun.())

  @doc """
  Puts `value` under `key` when the assigns have no such key, like `assign_new/3`, but as a
  constant: it is not marked as changed on every render.
  """
  @spec put_default(map(), atom(), term()) :: map()
  def put_default(assigns, key, _value) when is_map_key(assigns, key), do: assigns
  def put_default(assigns, key, value), do: assign_derived(assigns, key, [], fn -> value end)

  @doc "`\"true\"` or `\"false\"`, for `data-*` and `aria-*` attributes."
  @spec bool(boolean()) :: String.t()
  def bool(true), do: "true"
  def bool(false), do: "false"
end
