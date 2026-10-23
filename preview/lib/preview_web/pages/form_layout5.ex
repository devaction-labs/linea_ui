defmodule PreviewWeb.Pages.FormLayout5 do
  use PreviewWeb.Page, title: "Form Layout 5", category: :forms, lineone: "forms-layout-5"

  import PreviewWeb.FormIcons

  @menu [
    {"bell", "Notification"},
    {"shield", "Security"},
    {"cube", "Apps"},
    {"briefcase", "Privacy & data"}
  ]

  def mount(socket), do: assign(socket, form: to_form(%{}, as: :account))

  def handle_event("validate", %{"account" => params}, socket) do
    errors =
      case Map.get(params, "email", "") =~ "@" do
        true -> []
        false -> [email: {"must be an email address", []}]
      end

    {:noreply, assign(socket, form: to_form(params, as: :account, errors: errors))}
  end

  def render(assigns) do
    assigns = assign(assigns, menu: @menu)

    ~H"""
    <div class="grid grid-cols-12 gap-4 sm:gap-5 lg:gap-6">
      <div class="col-span-12 lg:col-span-4">
        <div class="card p-4 sm:p-5">
          <div class="flex items-center space-x-4">
            <div class="avatar size-14">
              <img class="rounded-full" src="/lineone/images/avatar/avatar-20.jpg" alt="avatar" />
            </div>
            <div>
              <h3 class="text-base font-medium text-slate-700 dark:text-navy-100">Travis Fuller</h3>
              <p class="text-xs-plus">Author</p>
            </div>
          </div>
          <ul class="mt-6 space-y-1.5 font-inter font-medium">
            <li>
              <a
                class="flex items-center space-x-2 rounded-lg bg-primary px-4 py-2.5 tracking-wide text-white outline-hidden transition-all dark:bg-accent"
                href="#"
              >
                <.icon name="account" class="size-5" /><span>Account</span>
              </a>
            </li>
            <li :for={{icon, label} <- @menu}>
              <a
                class="group flex space-x-2 rounded-lg px-4 py-2.5 tracking-wide outline-hidden transition-all hover:bg-slate-100 hover:text-slate-800 focus:bg-slate-100 focus:text-slate-800 dark:hover:bg-navy-600 dark:hover:text-navy-100 dark:focus:bg-navy-600 dark:focus:text-navy-100"
                href="#"
              >
                <.icon
                  name={icon}
                  class="size-5 text-slate-400 transition-colors group-hover:text-slate-500 group-focus:text-slate-500 dark:text-navy-300 dark:group-hover:text-navy-200 dark:group-focus:text-navy-200"
                />
                <span>{label}</span>
              </a>
            </li>
          </ul>
        </div>
      </div>
      <div class="col-span-12 lg:col-span-8">
        <.form for={@form} id="account-settings" class="card" phx-change="validate">
          <div class="flex flex-col items-center space-y-4 border-b border-slate-200 p-4 dark:border-navy-500 sm:flex-row sm:justify-between sm:space-y-0 sm:px-5">
            <h2 class="text-lg font-medium tracking-wide text-slate-700 dark:text-navy-100">
              Account Setting
            </h2>
            <div class="flex justify-center space-x-2">
              <.button
                variant="outline"
                shape="pill"
                class="min-w-[7rem] text-slate-700 dark:text-navy-100"
              >
                Cancel
              </.button>
              <.button color="primary" shape="pill" class="min-w-[7rem]">Save</.button>
            </div>
          </div>
          <div class="p-4 sm:p-5">
            <div class="flex flex-col">
              <span class="text-base font-medium text-slate-600 dark:text-navy-100">Avatar</span>
              <div class="avatar mt-1.5 size-20">
                <img class="mask is-squircle" src="/lineone/images/avatar/avatar-20.jpg" alt="avatar" />
                <div class="absolute bottom-0 right-0 flex items-center justify-center rounded-full bg-white dark:bg-navy-700">
                  <.button
                    variant="flat"
                    icon
                    shape="pill"
                    class="size-6 border border-slate-200 text-current dark:border-navy-500"
                    aria-label="Edit avatar"
                  >
                    <.icon name="pencil" class="size-3.5" />
                  </.button>
                </div>
              </div>
            </div>
            <div class="my-7 h-px bg-slate-200 dark:bg-navy-500"></div>
            <div class="grid grid-cols-1 gap-4 sm:grid-cols-2">
              <.input
                field={@form[:display_name]}
                label="Display name "
                shape="pill"
                class="px-3 pl-9"
                placeholder="Enter name"
              >
                <:prefix><.icon name="user" /></:prefix>
              </.input>
              <.input
                field={@form[:full_name]}
                label="Full Name "
                shape="pill"
                class="px-3 pl-9"
                placeholder="Enter full name"
              >
                <:prefix><.icon name="user" /></:prefix>
              </.input>
              <.input
                field={@form[:email]}
                label="Email Address "
                shape="pill"
                class="px-3 pl-9"
                placeholder="Enter email address"
              >
                <:prefix><.icon name="envelope" /></:prefix>
              </.input>
              <.input
                field={@form[:phone]}
                type="tel"
                label="Phone Number"
                shape="pill"
                class="px-3 pl-9"
                placeholder="Enter phone number"
                mask="phone"
              >
                <:prefix><.icon name="phone" class="size-4" /></:prefix>
              </.input>
            </div>
            <div class="my-7 h-px bg-slate-200 dark:bg-navy-500"></div>
            <div>
              <h3 class="text-base font-medium text-slate-600 dark:text-navy-100">Linked Accounts</h3>
              <p class="text-xs-plus text-slate-400 dark:text-navy-300">
                Lorem ipsum dolor sit amet consectetur.
              </p>
              <div class="flex items-center justify-between pt-4">
                <div class="flex items-center space-x-4">
                  <div class="size-12">
                    <img src="/lineone/images/logos/google.svg" alt="logo" />
                  </div>
                  <p class="font-medium line-clamp-1">Sign In with Google</p>
                </div>
                <.button
                  variant="outline"
                  shape="pill"
                  size="sm"
                  class="border-slate-200 px-3 text-primary dark:border-navy-500 dark:text-accent-light"
                >
                  Connect
                </.button>
              </div>
            </div>
          </div>
        </.form>
      </div>
    </div>
    """
  end
end
