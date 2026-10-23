defmodule PreviewWeb.Pages.Datetimepicker do
  use PreviewWeb.Page, title: "Datetimepicker", category: :forms, lineone: "forms-datetimepicker"

  def render(assigns) do
    ~H"""
    <.example title="Basic Datetimepicker" class="max-w-xl">
      <.intro />
      <div class="mt-5">
        <.datetime_picker id="flatpickr1" name="basic" placeholder="Choose datetime..." />
      </div>
    </.example>
    <.example title="Limit Time" class="max-w-xl">
      <.intro />
      <div class="mt-5">
        <.datetime_picker
          id="flatpickr2"
          name="limited"
          min_time="16:00"
          max_time="22:00"
          placeholder="Choose datetime..."
        />
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
