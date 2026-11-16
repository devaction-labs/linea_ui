defmodule LineaUI.Components.Segments do
  @moduledoc false

  @spec group() :: String.t()
  def group, do: "inline-flex gap-0.5 rounded-lg bg-base-200 p-0.5"

  @spec item() :: String.t()
  def item,
    do:
      "inline-flex h-7.5 items-center justify-center rounded-md px-3 text-xs-plus font-medium whitespace-nowrap text-base-content/65 outline-hidden transition-colors duration-200 hover:text-base-content/85 focus-visible:outline-2 focus-visible:outline-offset-1 focus-visible:outline-primary/50 disabled:pointer-events-none disabled:opacity-60 aria-pressed:bg-base-100 aria-pressed:text-base-content aria-pressed:shadow-soft dark:focus-visible:outline-accent/50 dark:aria-pressed:shadow-none"
end
