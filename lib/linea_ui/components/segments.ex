defmodule LineaUI.Components.Segments do
  @moduledoc false

  @spec group() :: String.t()
  def group, do: "inline-flex gap-0.5 rounded-lg bg-slate-150 p-0.5 dark:bg-navy-800"

  @spec item() :: String.t()
  def item,
    do:
      "inline-flex h-7.5 items-center justify-center rounded-md px-3 text-xs-plus font-medium whitespace-nowrap text-slate-500 outline-hidden transition-colors duration-200 hover:text-slate-700 focus-visible:outline-2 focus-visible:outline-offset-1 focus-visible:outline-primary/50 disabled:pointer-events-none disabled:opacity-60 aria-pressed:bg-white aria-pressed:text-slate-800 aria-pressed:shadow-soft dark:text-navy-200 dark:hover:text-navy-50 dark:focus-visible:outline-accent/50 dark:aria-pressed:bg-navy-500 dark:aria-pressed:text-navy-50 dark:aria-pressed:shadow-none"
end
