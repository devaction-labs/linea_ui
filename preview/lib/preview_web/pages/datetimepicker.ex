defmodule PreviewWeb.Pages.Datetimepicker do
  use PreviewWeb.Page, title: "Datetimepicker", category: :forms, lineone: "forms-datetimepicker"

  def render(assigns) do
    ~H"""
    <.example title="Basic Datetimepicker" class="max-w-xl">
      <.intro />
      <div class="mt-5">
        <.datetime_picker
          id="dtp1"
          name="basic"
          label="Starts at"
          value={~N[2026-10-14 10:30:00]}
          today={~D[2026-10-14]}
        />
      </div>
    </.example>
    <.example title="Type the time" class="max-w-xl">
      <.intro />
      <div class="mt-5">
        <.datetime_picker
          id="dtp2"
          name="typed"
          time="input"
          interval={15}
          placeholder="Choose datetime..."
        />
      </div>
    </.example>
    <.example title="Restrictions" class="max-w-xl">
      <.intro />
      <div class="mt-5">
        <.datetime_picker
          id="dtp3"
          name="limited"
          today={~D[2026-10-14]}
          min="2026-10-10"
          max="2026-10-30"
          min_time="08:00"
          max_time="18:00"
          unavailable="2026-10-16, 12:00-13:00, 2026-10-14T10:00"
          placeholder="Choose datetime..."
        />
      </div>
    </.example>
    <.example title="Range" class="max-w-xl">
      <.intro />
      <div class="mt-5">
        <.datetime_picker
          id="dtp4"
          name="range"
          mode="range"
          label="Window"
          default_time="09:00/17:00"
          today={~D[2026-10-14]}
        />
      </div>
    </.example>
    <.example title="Custom trigger" class="max-w-xl">
      <.intro />
      <div class="mt-5">
        <.datetime_picker id="dtp5" name="custom">
          <:trigger>
            <.button variant="outline" color="primary">Pick a date and time</.button>
          </:trigger>
        </.datetime_picker>
      </div>
    </.example>
    <.example title="Português" class="max-w-xl">
      <.intro />
      <div class="mt-5">
        <.datetime_picker
          id="dtp6"
          name="pt"
          locale="pt_BR"
          week_start={1}
          value="2026-10-14T15:45"
          today={~D[2026-10-14]}
        />
      </div>
    </.example>
    """
  end

  defp intro(assigns) do
    ~H"""
    <p>
      The Datetimepicker is used to allow the user to select a date and time in one panel, and to display that date and time in the specified format. Its value is wall-clock text such as <code>2026-10-14T10:30</code>, like a native datetime-local input.
    </p>
    """
  end
end
