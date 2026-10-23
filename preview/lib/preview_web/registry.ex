defmodule PreviewWeb.Registry do
  @moduledoc "The preview pages, found among the modules of the `:preview` application."

  @categories [elements: "Elements", components: "Components", forms: "Forms", layout: "Layout"]

  @spec categories() :: keyword(String.t())
  def categories, do: @categories

  @spec pages() :: [map()]
  def pages do
    {:ok, modules} = :application.get_key(:preview, :modules)

    modules
    |> Enum.filter(&page?/1)
    |> Enum.map(&describe/1)
    |> Enum.sort_by(& &1.title)
  end

  @spec by_category() :: [{String.t(), [map()]}]
  def by_category do
    grouped = Enum.group_by(pages(), & &1.category)
    Enum.map(@categories, fn {key, label} -> {label, Map.get(grouped, key, [])} end)
  end

  @spec fetch(String.t()) :: {:ok, map()} | :error
  def fetch(slug) do
    case Enum.find(pages(), &(&1.slug == slug)) do
      nil -> :error
      page -> {:ok, page}
    end
  end

  defp page?(module) do
    match?(["PreviewWeb", "Pages", _], Module.split(module)) and
      Code.ensure_loaded?(module) and function_exported?(module, :__page__, 0)
  end

  defp describe(module) do
    slug =
      module
      |> Module.split()
      |> List.last()
      |> Macro.underscore()
      |> String.replace("_", "-")
      |> String.replace(~r/([a-z])(\d)/, "\\1-\\2")

    module.__page__()
    |> Map.put_new(:slug, slug)
    |> Map.put(:module, module)
    |> Map.put_new(:lineone, nil)
  end
end
