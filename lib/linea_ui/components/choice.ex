defmodule LineaUI.Components.Choice do
  @moduledoc false

  @tones %{
    {"basic", false} => %{
      "neutral" =>
        "border-slate-400/70 checked:border-slate-500 checked:bg-slate-500 hover:border-slate-500 focus:border-slate-500 dark:border-navy-400 dark:checked:bg-navy-400",
      "primary" =>
        "border-slate-400/70 checked:border-primary checked:bg-primary hover:border-primary focus:border-primary dark:border-navy-400 dark:checked:border-accent dark:checked:bg-accent dark:hover:border-accent dark:focus:border-accent",
      "secondary" =>
        "border-slate-400/70 checked:border-secondary checked:bg-secondary hover:border-secondary focus:border-secondary dark:border-navy-400 dark:checked:border-secondary-light dark:checked:bg-secondary-light dark:hover:border-secondary-light dark:focus:border-secondary-light",
      "info" =>
        "border-slate-400/70 checked:!border-info checked:bg-info hover:!border-info focus:!border-info dark:border-navy-400",
      "success" =>
        "border-slate-400/70 checked:!border-success checked:bg-success hover:!border-success focus:!border-success dark:border-navy-400",
      "warning" =>
        "border-slate-400/70 checked:!border-warning checked:bg-warning hover:!border-warning focus:!border-warning dark:border-navy-400",
      "error" =>
        "border-slate-400/70 checked:!border-error checked:bg-error hover:!border-error focus:!border-error dark:border-navy-400"
    },
    {"basic", true} => %{
      "neutral" =>
        "border-slate-400/70 bg-slate-100 checked:border-slate-500 checked:bg-slate-500 hover:border-slate-500 focus:border-slate-500 dark:border-navy-500 dark:bg-navy-900 dark:checked:border-navy-400 dark:checked:bg-navy-400",
      "primary" =>
        "border-slate-400/70 bg-slate-100 checked:border-primary checked:bg-primary hover:border-primary focus:border-primary dark:border-navy-500 dark:bg-navy-900 dark:checked:border-accent dark:checked:bg-accent dark:hover:border-accent dark:focus:border-accent",
      "secondary" =>
        "border-slate-400/70 bg-slate-100 checked:border-secondary checked:bg-secondary hover:border-secondary focus:border-secondary dark:border-navy-500 dark:bg-navy-900 dark:checked:border-secondary-light dark:checked:bg-secondary-light dark:hover:border-secondary-light dark:focus:border-secondary-light",
      "info" =>
        "border-slate-400/70 bg-slate-100 checked:!border-info checked:!bg-info hover:!border-info focus:!border-info dark:border-navy-500 dark:bg-navy-900",
      "success" =>
        "border-slate-400/70 bg-slate-100 checked:!border-success checked:!bg-success hover:!border-success focus:!border-success dark:border-navy-500 dark:bg-navy-900",
      "warning" =>
        "border-slate-400/70 bg-slate-100 checked:!border-warning checked:!bg-warning hover:!border-warning focus:!border-warning dark:border-navy-500 dark:bg-navy-900",
      "error" =>
        "border-slate-400/70 bg-slate-100 checked:!border-error checked:!bg-error hover:!border-error focus:!border-error dark:border-navy-500 dark:bg-navy-900"
    },
    {"outline", false} => %{
      "neutral" =>
        "border-slate-400/70 before:bg-slate-500 checked:border-slate-500 hover:border-slate-500 focus:border-slate-500 dark:border-navy-400 dark:before:bg-navy-200 dark:checked:border-navy-200 dark:hover:border-navy-200 dark:focus:border-navy-200",
      "primary" =>
        "border-slate-400/70 before:bg-primary checked:border-primary hover:border-primary focus:border-primary dark:border-navy-400 dark:before:bg-accent dark:checked:border-accent dark:hover:border-accent dark:focus:border-accent",
      "secondary" =>
        "border-slate-400/70 before:bg-secondary checked:border-secondary hover:border-secondary focus:border-secondary dark:border-navy-400 dark:before:bg-secondary-light dark:checked:border-secondary-light dark:hover:border-secondary-light dark:focus:border-secondary-light",
      "info" =>
        "border-slate-400/70 before:!bg-info checked:!border-info hover:!border-info focus:!border-info dark:border-navy-400",
      "success" =>
        "border-slate-400/70 before:!bg-success checked:!border-success hover:!border-success focus:!border-success dark:border-navy-400",
      "warning" =>
        "border-slate-400/70 before:!bg-warning checked:!border-warning hover:!border-warning focus:!border-warning dark:border-navy-400",
      "error" =>
        "border-slate-400/70 before:!bg-error checked:!border-error hover:!border-error focus:!border-error dark:border-navy-400"
    },
    {"outline", true} => %{
      "neutral" =>
        "border-slate-400/70 bg-slate-100 before:bg-slate-500 checked:border-slate-500 hover:border-slate-500 focus:border-slate-500 dark:border-navy-500 dark:bg-navy-900 dark:before:bg-navy-200 dark:checked:border-navy-200 dark:hover:border-navy-200 dark:focus:border-navy-200",
      "primary" =>
        "border-slate-400/70 bg-slate-100 before:bg-primary checked:border-primary hover:border-primary focus:border-primary dark:border-navy-500 dark:bg-navy-900 dark:before:bg-accent dark:checked:border-accent dark:hover:border-accent dark:focus:border-accent",
      "secondary" =>
        "border-slate-400/70 bg-slate-100 before:bg-secondary checked:border-secondary hover:border-secondary focus:border-secondary dark:border-navy-500 dark:bg-navy-900 dark:before:bg-secondary-light dark:checked:border-secondary-light dark:hover:border-secondary-light dark:focus:border-secondary-light",
      "info" =>
        "border-slate-400/70 bg-slate-100 before:!bg-info checked:!border-info hover:!border-info focus:!border-info dark:border-navy-500 dark:bg-navy-900",
      "success" =>
        "border-slate-400/70 bg-slate-100 before:!bg-success checked:!border-success hover:!border-success focus:!border-success dark:border-navy-500 dark:bg-navy-900",
      "warning" =>
        "border-slate-400/70 bg-slate-100 before:!bg-warning checked:!border-warning hover:!border-warning focus:!border-warning dark:border-navy-500 dark:bg-navy-900",
      "error" =>
        "border-slate-400/70 bg-slate-100 before:!bg-error checked:!border-error hover:!border-error focus:!border-error dark:border-navy-500 dark:bg-navy-900"
    }
  }

  @variants %{
    "basic" => "is-basic",
    "outline" => "is-outline"
  }

  @sizes %{
    "xs" => "size-3",
    "sm" => "size-4",
    "md" => "size-5",
    "lg" => "size-6"
  }

  @disabled "disabled:pointer-events-none disabled:border-slate-300 disabled:opacity-60 dark:disabled:border-navy-450"

  @spec classes(String.t(), map()) :: [String.t()]
  def classes(base, %{variant: variant, filled: filled, color: color, size: size}) do
    [base, @variants[variant], @sizes[size], @tones[{variant, filled}][color], @disabled]
  end

  @spec sizes() :: [String.t()]
  def sizes, do: ~w(xs sm md lg)
end
