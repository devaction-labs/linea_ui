defmodule PreviewWeb.Pages.FormLayout1 do
  use PreviewWeb.Page, title: "Form Layout 1", category: :forms, lineone: "forms-layout-1"

  import PreviewWeb.FormIcons

  def mount(socket), do: assign(socket, form: to_form(%{}, as: :shipping))

  def handle_event("validate", %{"shipping" => params}, socket) do
    {:noreply, assign(socket, form: to_form(params, as: :shipping, errors: errors(params)))}
  end

  def handle_event("save", %{"shipping" => params}, socket) do
    {:noreply,
     socket
     |> assign(form: to_form(params, as: :shipping, errors: errors(params), action: :insert))
     |> put_flash(:info, "Address saved")}
  end

  defp errors(params) do
    [company: "Company name", email: "Email Address"]
    |> Enum.filter(fn {key, _label} -> Map.get(params, to_string(key), "") == "" end)
    |> Enum.map(fn {key, label} -> {key, {"#{label} can't be blank", []}} end)
  end

  def render(assigns) do
    ~H"""
    <div class="grid grid-cols-12 gap-4 sm:gap-5 lg:gap-6">
      <div class="sm:order-last sm:col-span-4">
        <div class="sticky top-24 mt-3">
          <ol class="steps is-vertical line-space">
            <.step title="Create Account" done />
            <.step title="Select Service" done />
            <.step title="Address" number="3" current />
            <.step title="Submit" number="4" />
          </ol>
        </div>
      </div>
      <div class="col-span-12 sm:col-span-8">
        <.form
          for={@form}
          id="shipping-form"
          class="card p-4 sm:p-5"
          phx-change="validate"
          phx-submit="save"
        >
          <p class="text-base font-medium text-slate-700 dark:text-navy-100">Shipping Address</p>
          <div class="mt-4 space-y-4">
            <.input field={@form[:company]} label="Company name" placeholder="Your Company">
              <:prefix><.lineone_icon name="building" /></:prefix>
            </.input>
            <div class="grid grid-cols-1 gap-4 sm:grid-cols-2">
              <.input field={@form[:client]} label="Client name" placeholder="Your Name">
                <:prefix><.lineone_icon name="user" /></:prefix>
              </.input>
              <.input
                field={@form[:phone]}
                label="Phone number"
                placeholder="(999) 999-9999"
                mask="blocks"
                mask_options={%{blocks: [0, 3, 3, 4], delimiters: ["(", ") ", "-"], numeric: true}}
              >
                <:prefix><.lineone_icon name="phone" class="size-4" /></:prefix>
              </.input>
            </div>
            <div class="grid grid-cols-1 gap-4 sm:grid-cols-12">
              <.input
                field={@form[:email]}
                type="email"
                label="Email Address"
                placeholder="Email address"
                wrapper_class="sm:col-span-8"
              >
                <:prefix><.lineone_icon name="envelope" /></:prefix>
              </.input>
              <.input
                field={@form[:pincode]}
                label="Pincode"
                placeholder="Pincode"
                wrapper_class="sm:col-span-4"
              >
                <:prefix><.lineone_icon name="pin" /></:prefix>
              </.input>
            </div>
            <.textarea
              field={@form[:address]}
              label="Address"
              resizable
              placeholder="Your Address (Area and Street)"
            />
            <div class="grid grid-cols-1 gap-4 sm:grid-cols-2">
              <.input field={@form[:city]} label="City" placeholder="Your City/Town">
                <:prefix><.lineone_icon name="city" /></:prefix>
              </.input>
              <.input field={@form[:state]} label="State" placeholder="Your State">
                <:prefix><.lineone_icon name="flag" class="size-4" /></:prefix>
              </.input>
            </div>
            <.textarea
              field={@form[:billing]}
              label="Billing Address"
              resizable
              placeholder="Enter billing address"
              wrapper_class="pt-4"
            />
            <div class="flex justify-end space-x-2">
              <.button class="space-x-2">
                <.lineone_icon name="prev" class="size-5" /><span>Prev</span>
              </.button>
              <.button type="submit" color="primary" class="space-x-2">
                <span>Next</span><.lineone_icon name="next" class="size-5" />
              </.button>
            </div>
          </div>
        </.form>
      </div>
    </div>
    """
  end

  attr :title, :string, required: true
  attr :number, :string, default: nil
  attr :done, :boolean, default: false
  attr :current, :boolean, default: false

  defp step(assigns) do
    ~H"""
    <li class={[
      "step pb-8",
      @done && "before:bg-primary dark:before:bg-accent",
      !@done && "before:bg-slate-200 dark:before:bg-navy-500"
    ]}>
      <div class={[
        "step-header rounded-full",
        (@done || @current) && "bg-primary text-white dark:bg-accent",
        !(@done || @current) && "bg-slate-200 text-slate-800 dark:bg-navy-500 dark:text-white"
      ]}>
        <.lineone_icon :if={@done} name="done" class="size-5" />
        {@number}
      </div>
      <h3 class="ml-4 text-slate-700 dark:text-navy-100">{@title}</h3>
    </li>
    """
  end
end
