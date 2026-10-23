defmodule PreviewWeb.Pages.Modal do
  use PreviewWeb.Page, title: "Modal", category: :components, lineone: "components-modal"

  import PreviewWeb.Pages.NarrowExample

  @text "The Modal component inform users about a specific task and may contain critical information, require decisions, or involve multiple tasks."

  @checkbox "form-checkbox is-basic size-5 rounded-sm border-slate-400/70 checked:border-primary checked:bg-primary hover:border-primary focus:border-primary dark:border-navy-400 dark:checked:border-accent dark:checked:bg-accent dark:hover:border-accent dark:focus:border-accent"
  @switch "form-switch is-outline h-5 w-10 rounded-full border border-slate-400/70 bg-transparent before:rounded-full before:bg-slate-300 checked:border-primary checked:before:bg-primary dark:border-navy-400 dark:before:bg-navy-300 dark:checked:border-accent dark:checked:before:bg-accent"

  @users [
    {"1", "Cy Ganderton", "Admin", "Online"},
    {"2", "Travis Fuller", "Teacher", "Online"},
    {"3", "Konnor Guzman", "Moderator", "Online"},
    {"4", "Alfredo Elliott", "Admin", "Offline"},
    {"5", "Derrick Simmons", "Teacher", "Offline"}
  ]

  def render(assigns) do
    assigns =
      assign(assigns,
        text: @text,
        checkbox: @checkbox,
        switch: @switch,
        users: @users,
        columns: [
          {"ID", true},
          {"Name", true},
          {"Email", true},
          {"Address", false},
          {"Created at", true},
          {"Updated at", false}
        ]
      )

    ~H"""
    <.narrow title="Basic Modal" text={@text} class="mt-5">
      <.button phx-click={LineaUI.open("modal1")}>Basic Modal</.button>
    </.narrow>
    <.narrow title="Backdrop Blur" text={@text} class="mt-5">
      <.button phx-click={LineaUI.open("modal2")}>Backdrop Blur</.button>
    </.narrow>
    <.narrow title="Modal Transition" text={@text} class="inline-space mt-5 flex">
      <.button phx-click={LineaUI.open("modal3")}>Shift Up</.button>
      <.button phx-click={LineaUI.open("modal4")}>Shift Down</.button>
    </.narrow>
    <.narrow title="Modal Scale" text={@text} class="inline-space mt-5 flex">
      <.button phx-click={LineaUI.open("modal5")}>Origin Top</.button>
      <.button phx-click={LineaUI.open("modal6")}>Origin bottom</.button>
    </.narrow>

    <.modal
      :for={{id, blur} <- [{"modal1", false}, {"modal2", true}]}
      id={id}
      blur={blur}
      close_button={false}
      class="items-center px-4 py-10 text-center sm:px-5"
    >
      <svg
        xmlns="http://www.w3.org/2000/svg"
        class="inline size-28 shrink-0 text-success"
        fill="none"
        viewBox="0 0 24 24"
        stroke="currentColor"
      >
        <path
          stroke-linecap="round"
          stroke-linejoin="round"
          stroke-width="2"
          d="M9 12l2 2 4-4m6 2a9 9 0 11-18 0 9 9 0 0118 0z"
        />
      </svg>
      <div class="mt-4">
        <h2 class="text-2xl text-slate-700 dark:text-navy-100">Success Message</h2>
        <p class="mt-2">
          Lorem ipsum dolor sit amet, consectetur adipisicing elit. Consequuntur dignissimos soluta totam?
        </p>
        <.button color="success" class="mt-6" phx-click={LineaUI.close(id)}>Close</.button>
      </div>
    </.modal>

    <.modal
      id="modal3"
      animation="shift-up"
      size="md"
      close_button={false}
      class="pt-10 pb-4 text-center"
    >
      <div class="avatar mx-auto size-20">
        <img class="rounded-full" src="/lineone/images/avatar/avatar-8.jpg" alt="avatar" />
        <div class="absolute right-0 m-1 size-4 rounded-full border-2 border-white bg-primary dark:border-navy-700 dark:bg-accent">
        </div>
      </div>
      <div class="mt-4 px-4 sm:px-12">
        <h3 class="text-lg text-slate-800 dark:text-navy-50">Follow Request</h3>
        <p class="mt-1 text-slate-500 dark:text-navy-200">
          Lorem ipsum dolor sit amet, consectetur adipisicing elit. Fuga sunt vel vero.
        </p>
      </div>
      <div class="my-4 mt-16 h-px bg-slate-200 dark:bg-navy-500"></div>
      <div class="space-x-3">
        <.button
          variant="outline"
          shape="pill"
          class="min-w-[7rem]"
          phx-click={LineaUI.close("modal3")}
        >
          Cancel
        </.button>
        <.button color="primary" shape="pill" class="min-w-[7rem]" phx-click={LineaUI.close("modal3")}>
          Apply
        </.button>
      </div>
    </.modal>

    <.modal id="modal4" animation="shift-down" size="sm">
      <:header variant="plain">Table Settings</:header>
      <p>Lorem ipsum dolor sit amet consectetur adipisicing elit. Aut dignissimos.</p>
      <div class="mt-4 grid grid-cols-2 gap-4">
        <label :for={{label, checked} <- @columns} class="inline-flex items-center space-x-2">
          <input checked={checked} class={@checkbox} type="checkbox" />
          <p>{label}</p>
        </label>
        <label class="col-span-2 inline-flex items-center space-x-2">
          <input class={@switch} type="checkbox" />
          <span>Show Avatar</span>
        </label>
      </div>
      <div class="mt-4 text-right">
        <.button variant="flat" size="sm" shape="pill" class="h-8">Cancel</.button>
        <.button
          color="primary"
          size="sm"
          shape="pill"
          class="h-8"
          phx-click={LineaUI.close("modal4")}
        >
          Apply
        </.button>
      </div>
    </.modal>

    <.modal id="modal5" animation="scale" origin="top">
      <:header>Edit Pin</:header>
      <p>Lorem ipsum dolor sit amet, consectetur adipisicing elit. Assumenda incidunt</p>
      <div class="mt-4 space-y-4">
        <label class="block">
          <span>Choose category :</span>
          <select class="form-select mt-1.5 w-full rounded-lg border border-slate-300 bg-white px-3 py-2 hover:border-slate-400 focus:border-primary dark:border-navy-450 dark:bg-navy-700 dark:hover:border-navy-400 dark:focus:border-accent">
            <option>Laravel</option>
            <option>Node JS</option>
            <option>Django</option>
            <option>Other</option>
          </select>
        </label>
        <label class="block">
          <span>Description:</span>
          <textarea
            rows="4"
            placeholder=" Enter Text"
            class="form-textarea mt-1.5 w-full resize-none rounded-lg border border-slate-300 bg-transparent p-2.5 placeholder:text-slate-400/70 hover:border-slate-400 focus:border-primary dark:border-navy-450 dark:hover:border-navy-400 dark:focus:border-accent"
          ></textarea>
        </label>
        <label class="block">
          <span>Website Address:</span>
          <input
            class="form-input mt-1.5 w-full rounded-lg border border-slate-300 bg-transparent px-3 py-2 placeholder:text-slate-400/70 hover:border-slate-400 focus:border-primary dark:border-navy-450 dark:hover:border-navy-400 dark:focus:border-accent"
            placeholder="URL Address"
            type="text"
          />
        </label>
        <label class="inline-flex items-center space-x-2">
          <input class={@switch} type="checkbox" />
          <span>Public pin</span>
        </label>
        <div class="space-x-2 text-right">
          <.button
            variant="outline"
            shape="pill"
            class="min-w-[7rem]"
            phx-click={LineaUI.close("modal5")}
          >
            Cancel
          </.button>
          <.button
            color="primary"
            shape="pill"
            class="min-w-[7rem]"
            phx-click={LineaUI.close("modal5")}
          >
            Apply
          </.button>
        </div>
      </div>
    </.modal>

    <.modal
      id="modal6"
      animation="scale"
      origin="bottom"
      size="xl"
      class="pb-4"
      body_class="overflow-visible p-0 sm:px-0"
    >
      <:header>Users Status</:header>
      <div>
        <div class="scrollbar-sm min-w-full overflow-auto">
          <table class="w-full text-left">
            <thead>
              <tr class="border-y border-transparent border-b-slate-200 dark:border-b-navy-500">
                <th
                  :for={head <- ~w(# Name Role Status)}
                  class="whitespace-nowrap px-3 py-3 font-semibold uppercase text-slate-800 dark:text-navy-100 lg:px-5"
                >
                  {head}
                </th>
              </tr>
            </thead>
            <tbody>
              <tr
                :for={{n, name, role, status} <- @users}
                class="border-y border-transparent border-b-slate-200 dark:border-b-navy-500"
              >
                <td class="whitespace-nowrap px-4 py-3 sm:px-5">{n}</td>
                <td class="whitespace-nowrap px-4 py-3 sm:px-5">{name}</td>
                <td class="whitespace-nowrap px-4 py-3 sm:px-5">{role}</td>
                <td class="whitespace-nowrap px-4 py-3 sm:px-5">
                  <div class={[
                    "badge space-x-2.5 rounded-full",
                    status_class(n)
                  ]}>
                    <div class="size-2 rounded-full bg-current"></div>
                    <span>{status}</span>
                  </div>
                </td>
              </tr>
            </tbody>
          </table>
        </div>
        <div class="text-center">
          <.button
            color="primary"
            variant="bordered"
            class="mt-4"
            phx-click={LineaUI.close("modal6")}
          >
            Show All
          </.button>
        </div>
      </div>
    </.modal>
    """
  end

  defp status_class("4"), do: "bg-warning/10 text-warning dark:bg-warning/15"

  defp status_class(_n),
    do: "bg-primary/10 text-primary dark:bg-accent-light/15 dark:text-accent-light"
end
