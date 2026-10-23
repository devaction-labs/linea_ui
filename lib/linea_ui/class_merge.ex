defmodule LineaUI.ClassMerge do
  @moduledoc """
  Joins Tailwind class lists so that a later class replaces an earlier one of the same kind.

  Every component builds its classes as `[base, variant, color, size, @class]` and passes the
  list here, so `<.button class="rounded-full px-8">` drops the default `rounded-lg px-5`
  instead of leaving both in the attribute and letting the stylesheet order decide.

  A class is reduced to a key made of its variants (`dark:hover:`), its important flag and its
  group (`bg-color`, `px`, `rounded-tl`). A later class removes every earlier class whose key
  is the same or belongs to a group it covers (`p-4` removes `px-2` and `pt-1`). Classes that
  belong to no known group are always kept, in order.

  Results are cached in ETS, since the same lists are merged on every render.
  """

  alias LineaUI.ClassMerge.Cache
  alias LineaUI.ClassMerge.Groups

  @doc "Merges a class list (strings, nested lists, `nil` and `false` allowed) into one string."
  @spec merge(term()) :: String.t()
  def merge(classes) when is_list(classes) do
    classes
    |> List.flatten()
    |> Enum.filter(&is_binary/1)
    |> Enum.join(" ")
    |> merge()
  end

  def merge(classes) when is_binary(classes), do: Cache.fetch(classes, &resolve/1)

  def merge(nil), do: ""
  def merge(false), do: ""

  @doc false
  @spec resolve(String.t()) :: String.t()
  def resolve(classes) do
    classes
    |> String.split()
    |> Enum.reverse()
    |> Enum.reduce({[], MapSet.new()}, &keep_unless_overridden/2)
    |> elem(0)
    |> Enum.join(" ")
  end

  defp keep_unless_overridden(class, {kept, taken}) do
    class
    |> Groups.key()
    |> keep(class, kept, taken)
  end

  defp keep(nil, class, kept, taken), do: {[class | kept], taken}

  defp keep({prefix, group}, class, kept, taken) do
    case MapSet.member?(taken, {prefix, group}) do
      true -> {kept, taken}
      false -> {[class | kept], cover(taken, prefix, group)}
    end
  end

  defp cover(taken, prefix, group) do
    group
    |> Groups.covers()
    |> Enum.reduce(MapSet.put(taken, {prefix, group}), &MapSet.put(&2, {prefix, &1}))
  end
end
