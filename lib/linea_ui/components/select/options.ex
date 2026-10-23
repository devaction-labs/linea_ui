defmodule LineaUI.Components.Select.Options do
  @moduledoc """
  The options of a select, in every shape the components accept, read into one shape.

  An option is a string or number (label and value alike), a `{label, value}` tuple, a
  keyword entry `label: value`, or a map with `:label` and `:value` (and optionally
  `:disabled`; any other keys are kept for the `:option` and `:item` slots). A group is
  `{group_label, [options]}`.

      iex> LineaUI.Components.Select.Options.normalize(["Wedding", {"Other", "other"}])
      [
        %{type: :option, label: "Wedding", value: "Wedding", disabled: false, data: "Wedding"},
        %{type: :option, label: "Other", value: "other", disabled: false, data: {"Other", "other"}}
      ]
  """

  @type option :: %{
          type: :option,
          label: String.t(),
          value: String.t(),
          disabled: boolean(),
          data: term()
        }
  @type group :: %{type: :group, label: String.t(), options: [option()]}

  @doc "Reads a list of options and groups."
  @spec normalize(list()) :: [option() | group()]
  def normalize(options), do: Enum.map(options, &entry/1)

  @doc "The options alone, with the groups flattened."
  @spec flat([option() | group()]) :: [option()]
  def flat(entries), do: Enum.flat_map(entries, &flatten/1)

  @doc "The values of a select's `value` as a list of strings."
  @spec values(term()) :: [String.t()]
  def values(nil), do: []
  def values(""), do: []

  def values(list) when is_list(list),
    do: list |> Enum.reject(&(&1 in [nil, ""])) |> Enum.map(&text/1)

  def values(value), do: [text(value)]

  @doc "The option whose value is `value`, among `options`; a value that is not one of them becomes its own option."
  @spec find([option()], String.t()) :: option()
  def find(options, value) do
    Enum.find(options, &(&1.value == value)) ||
      %{type: :option, label: value, value: value, disabled: false, data: value}
  end

  defp flatten(%{type: :group, options: options}), do: options
  defp flatten(option), do: [option]

  defp entry({label, options}) when is_list(options),
    do: %{type: :group, label: text(label), options: Enum.map(options, &entry/1)}

  defp entry({label, value} = data), do: option(text(label), value, false, data)

  defp entry(%{value: value} = data),
    do: option(text(Map.get(data, :label, value)), value, Map.get(data, :disabled, false), data)

  defp entry(value), do: option(text(value), value, false, value)

  defp option(label, value, disabled, data),
    do: %{type: :option, label: label, value: text(value), disabled: disabled == true, data: data}

  defp text(value) when is_binary(value), do: value
  defp text(value), do: to_string(value)
end
