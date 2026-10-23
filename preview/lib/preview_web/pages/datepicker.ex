defmodule PreviewWeb.Pages.Datepicker do
  use PreviewWeb.Page, title: "Datepicker", category: :forms, lineone: "forms-datepicker"

  def mount(socket), do: assign(socket, form: to_form(%{"day" => nil}, as: :booking), picked: nil)

  def handle_event("booking", %{"booking" => params}, socket),
    do: {:noreply, assign(socket, form: to_form(params, as: :booking), picked: params["day"])}

  def render(assigns) do
    ~H"""
    <.example title="Basic Datepricker" class="max-w-xl">
      <.intro />
      <div class="mt-5">
        <.form for={@form} id="flatpickr1-form" phx-change="booking">
          <.date_picker id="flatpickr1" field={@form[:day]} placeholder="Choose date..." />
        </.form>
      </div>
    </.example>
    <.example title="Custom Format" class="max-w-xl">
      <.intro />
      <div class="mt-5">
        <.date_picker
          id="flatpickr2"
          name="custom"
          display_format="F j, Y"
          placeholder="Choose date..."
        />
      </div>
    </.example>
    <.example title="Disabled Date" class="max-w-xl">
      <.intro />
      <div class="mt-5">
        <.date_picker
          id="flatpickr3"
          name="weekdays"
          disabled_weekdays={[0, 6]}
          week_start={1}
          placeholder="Choose date..."
        />
      </div>
    </.example>
    <.example title="Multiple Date" class="max-w-xl">
      <.intro />
      <div class="mt-5">
        <.date_picker
          id="flatpickr4"
          name="multiple"
          mode="multiple"
          value={["2022-10-10", "2022-10-12", "2022-10-18"]}
          placeholder="Choose date..."
        />
      </div>
    </.example>
    <.example title="Date Range" class="max-w-xl">
      <.intro />
      <div class="mt-5">
        <.date_picker
          id="flatpickr5"
          name="range"
          mode="range"
          value={{~D[2016-10-10], ~D[2016-10-20]}}
          placeholder="Choose date..."
        />
      </div>
    </.example>
    <.example title="External Elements" class="max-w-xl">
      <.intro />
      <div class="mt-5">
        <.date_picker id="flatpickr6" name="external" placeholder="Choose date">
          <:trailing>
            <.button
              class="rounded-none px-3"
              phx-click={LineaUI.toggle("flatpickr6")}
              aria-label="Toggle"
            >
              <svg
                xmlns="http://www.w3.org/2000/svg"
                class="size-5"
                fill="none"
                viewBox="0 0 24 24"
                stroke="currentColor"
                stroke-width="1.5"
              >
                <path
                  stroke-linecap="round"
                  stroke-linejoin="round"
                  d="M8 7V3m8 4V3m-9 8h10M5 21h14a2 2 0 002-2V7a2 2 0 00-2-2H5a2 2 0 00-2 2v12a2 2 0 002 2z"
                />
              </svg>
            </.button>
            <.button
              color="error"
              class="rounded-l-none px-3"
              phx-click={date_picker_clear("flatpickr6")}
              aria-label="Clear"
            >
              <svg
                xmlns="http://www.w3.org/2000/svg"
                class="size-5"
                fill="none"
                viewBox="0 0 24 24"
                stroke="currentColor"
                stroke-width="2"
              >
                <path stroke-linecap="round" stroke-linejoin="round" d="M6 18L18 6M6 6l12 12" />
              </svg>
            </.button>
          </:trailing>
        </.date_picker>
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
