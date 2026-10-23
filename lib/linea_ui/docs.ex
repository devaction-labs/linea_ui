defmodule LineaUI.Docs do
  @moduledoc """
  The installed components as data: their modules, docs, attrs and slots.

  It reads what the compiler recorded (`__components__/0` and the docs chunk), so it always
  describes the code that is running. `LineaUI.Skill` and documentation sites build on it.

      LineaUI.Docs.components()
      #=> [%{key: :accordion, module: LineaUI.Components.Accordion, summary: "...",
      #      moduledoc: "...", functions: [%{name: :accordion, doc: "...", attrs: [...],
      #      global: %{...}, slots: [...]}, ...]}, ...]
  """

  @type function_doc :: %{
          name: atom(),
          doc: String.t(),
          attrs: [map()],
          global: map() | nil,
          slots: [map()]
        }

  @type component :: %{
          key: atom(),
          module: module(),
          summary: String.t(),
          moduledoc: String.t(),
          functions: [function_doc()]
        }

  @doc "Every component with at least one public function, sorted by key."
  @spec components() :: [component()]
  def components do
    LineaUI.components()
    |> Enum.map(&describe/1)
    |> Enum.reject(&(&1.functions == []))
    |> Enum.sort_by(& &1.key)
  end

  @doc "One component by key, or `nil`."
  @spec component(atom()) :: component() | nil
  def component(key), do: Enum.find(components(), &(&1.key == key))

  defp describe({key, module}) do
    Code.ensure_loaded!(module)

    %{
      key: key,
      module: module,
      summary: summary(module),
      moduledoc: moduledoc(module),
      functions: functions(module)
    }
  end

  defp functions(module) do
    case function_exported?(module, :__components__, 0) do
      true ->
        module.__components__()
        |> Enum.filter(fn {name, _component} -> function_exported?(module, name, 1) end)
        |> Enum.sort_by(fn {_name, c} -> c.line end)
        |> Enum.map(&function(module, &1))

      false ->
        []
    end
  end

  defp function(module, {name, component}) do
    %{
      name: name,
      doc: function_doc(module, name),
      attrs: component.attrs |> Enum.reject(&(&1.type == :global)) |> Enum.sort_by(& &1.line),
      global: Enum.find(component.attrs, &(&1.type == :global)),
      slots: component.slots
    }
  end

  defp docs(module) do
    case Code.fetch_docs(module) do
      {:docs_v1, _, _, _, moduledoc, _, docs} -> {moduledoc, docs}
      _ -> {:none, []}
    end
  end

  defp moduledoc(module) do
    case docs(module) do
      {%{"en" => doc}, _} -> String.trim(doc)
      _ -> ""
    end
  end

  defp summary(module) do
    module |> moduledoc() |> String.split("\n\n", parts: 2) |> hd() |> String.replace("\n", " ")
  end

  defp function_doc(module, name) do
    {_moduledoc, docs} = docs(module)

    Enum.find_value(docs, "", fn
      {{:function, ^name, 1}, _, _, %{"en" => doc}, _} -> strip_generated(doc)
      _ -> nil
    end)
  end

  defp strip_generated(doc),
    do: doc |> String.split(~r/^## (Attributes|Slots)$/m) |> hd() |> String.trim()
end
