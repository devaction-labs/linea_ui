defmodule PreviewWeb.Pages.Select do
  use PreviewWeb.Page, title: "Select", category: :forms, lineone: "forms-select"

  @events ["Corporate event", "Wedding", "Birthday", "Other"]

  def mount(socket) do
    assign(socket, events: @events, form: to_form(%{"event" => "Wedding"}, as: :party))
  end

  def handle_event("change", %{"party" => params}, socket),
    do: {:noreply, assign(socket, form: to_form(params, as: :party))}

  def render(assigns) do
    ~H"""
    <.example title="Basic Select" class="max-w-xl">
      <p>
        The
        <.inline_code>&lt;select&gt;</.inline_code>
        HTML element represents a control that provides a menu of options. Check out code for detail of usage.
      </p>
      <div class="mt-5">
        <.form for={@form} phx-change="change" id="basic-select-form">
          <.select native label="What type of event is it?" field={@form[:event]} options={@events} />
        </.form>
      </div>
    </.example>
    <.example title="Rounded Select" class="max-w-xl">
      <p>
        Select can have a rounded-sm shape. To do this, you should use the
        <.inline_code>rounded-full</.inline_code>
        utility. Check out code for detail of usage.
      </p>
      <div class="mt-5">
        <.select
          native
          shape="pill"
          name="rounded"
          label="What type of event is it?"
          options={@events}
        />
      </div>
    </.example>
    <.example title="Filled Select" class="max-w-xl">
      <p>The select component can be filled. Check out code for detail of usage.</p>
      <div class="mt-5">
        <.select
          native
          variant="filled"
          name="filled"
          label="What type of event is it?"
          options={@events}
        />
      </div>
    </.example>
    <.example title="Select Size" class="max-w-xl">
      <p>Select component can have various sizes. Check out code for detail of usage.</p>
      <div class="mt-5 space-y-4">
        <.select native size="sm" name="small" label="What type of event is it?" options={@events} />
        <.select native name="medium" label="What type of event is it?" options={@events} />
        <.select native size="lg" name="large" label="What type of event is it?" options={@events} />
      </div>
    </.example>
    <.example title="Disabled Select" class="max-w-xl">
      <p>
        The selcet component have their own style when disabled.. Check out code for detail of usage.
      </p>
      <div class="mt-5">
        <.select native disabled name="disabled" label="What type of event is it?" options={@events} />
      </div>
    </.example>
    <.example title="Multipie Select" class="max-w-xl">
      <p>
        The
        <.inline_code>multiple</.inline_code>
        attribute indicates that multiple options can be selected in the list. Check out code for detail of usage.
      </p>
      <div class="mt-5">
        <.select
          native
          multiple
          name="multiple"
          label="What type of event is it?"
          options={@events}
          value={["Wedding"]}
        />
      </div>
    </.example>
    """
  end
end
