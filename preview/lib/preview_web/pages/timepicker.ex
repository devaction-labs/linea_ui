defmodule PreviewWeb.Pages.Timepicker do
  use PreviewWeb.Page, title: "Timepicker", category: :forms, lineone: "forms-timepicker"

  def render(assigns) do
    ~H"""
    <.example title="Basic Timepicker" class="max-w-xl">
      <.intro />
      <div class="mt-5">
        <.time_picker id="flatpickr1" name="basic" placeholder="Choose time..." />
      </div>
    </.example>
    <.example title="24h Timepicker" class="max-w-xl">
      <.intro />
      <div class="mt-5">
        <.time_picker id="flatpickr2" name="clock24" time_24hr placeholder="Choose time..." />
      </div>
    </.example>
    <.example title="Limit Time" class="max-w-xl">
      <.intro />
      <div class="mt-5">
        <.time_picker
          id="flatpickr3"
          name="limited"
          min_time="15:00"
          max_time="22:30"
          placeholder="Choose time..."
        />
      </div>
    </.example>
    <.example title="Default Time" class="max-w-xl">
      <.intro />
      <div class="mt-5">
        <.time_picker id="flatpickr4" name="default" value="13:13" placeholder="Choose time..." />
      </div>
    </.example>
    """
  end

  defp intro(assigns) do
    ~H"""
    <p>
      The Datetimepicker is used to allow the user to select a date and time, and to display that date and time in the specified format.
      <a
        class="font-normal text-primary transition-colors hover:text-primary-focus dark:text-accent-light dark:hover:text-accent"
        href="https://github.com/flatpickr/flatpickr"
      >Flatpickr</a>
      is a lightweight and powerful datetime picker.
    </p>
    """
  end
end
