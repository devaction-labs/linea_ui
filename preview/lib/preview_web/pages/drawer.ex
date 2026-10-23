defmodule PreviewWeb.Pages.Drawer do
  use PreviewWeb.Page, title: "Drawer", category: :components, lineone: "components-drawer"

  import PreviewWeb.Pages.NarrowExample

  @text "Drawer is similar to modal, with a bit difference on placement. Check out code for detail of usage."

  @link "group flex space-x-2 rounded-full px-5 py-2.5 tracking-wide outline-hidden transition-all hover:bg-primary/10 hover:text-primary focus:bg-primary/10 focus:text-primary dark:hover:bg-accent-light/15 dark:hover:text-accent-light dark:focus:bg-accent-light/15 dark:focus:text-accent-light"
  @icon "size-5 text-slate-400 transition-colors group-hover:text-primary group-focus:text-primary dark:text-navy-300 dark:group-hover:text-accent dark:group-focus:text-accent"

  def render(assigns) do
    assigns = assign(assigns, text: @text)

    ~H"""
    <.narrow title="Left Drawer" text={@text} wide class="mt-5">
      <.button phx-click={LineaUI.toggle("drawer1")}>Left Drawer</.button>
    </.narrow>
    <.narrow title="Right Drawer" text={@text} wide class="mt-5">
      <.button phx-click={LineaUI.toggle("drawer2")}>Right Drawer</.button>
    </.narrow>

    <.drawer id="drawer1">
      <.profile id="drawer1" image="object-2" avatar="avatar-2" />
    </.drawer>
    <.drawer id="drawer2" side="right">
      <.profile id="drawer2" image="object-3" avatar="avatar-19" />
    </.drawer>
    """
  end

  attr :id, :string, required: true
  attr :image, :string, required: true
  attr :avatar, :string, required: true

  defp profile(assigns) do
    assigns = assign(assigns, link: @link, icon: @icon)

    ~H"""
    <div class="h-24">
      <img
        class="h-full w-full object-cover object-center"
        src={"/lineone/images/object/#{@image}.jpg"}
        alt="image"
      />
    </div>
    <div class="flex space-x-5 px-5">
      <div class="avatar -mt-5 size-20">
        <img
          class="rounded-full border-2 border-white dark:border-navy-700"
          src={"/lineone/images/avatar/#{@avatar}.jpg"}
          alt="avatar"
        />
      </div>
      <div class="mt-2 w-full">
        <div class="flex justify-between space-x-3">
          <h4 class="text-base font-medium text-slate-700 line-clamp-1 dark:text-navy-50">
            John Doe
          </h4>
          <.dropdown id={"#{@id}-menu"}>
            <:toggle>
              <.button
                variant="flat"
                icon
                size="xs"
                shape="pill"
                class="-mr-1.5 text-inherit dark:text-inherit"
                aria-label="Menu"
              >
                <svg
                  xmlns="http://www.w3.org/2000/svg"
                  class="size-4"
                  fill="none"
                  viewBox="0 0 24 24"
                  stroke="currentColor"
                  stroke-width="2"
                >
                  <path
                    stroke-linecap="round"
                    stroke-linejoin="round"
                    d="M5 12h.01M12 12h.01M19 12h.01M6 12a1 1 0 11-2 0 1 1 0 012 0zm7 0a1 1 0 11-2 0 1 1 0 012 0zm7 0a1 1 0 11-2 0 1 1 0 012 0z"
                  />
                </svg>
              </.button>
            </:toggle>
            <.dropdown_item href="#">Action</.dropdown_item>
            <.dropdown_item href="#">Another Action</.dropdown_item>
            <.dropdown_item href="#">Something else</.dropdown_item>
            <.dropdown_separator />
            <.dropdown_item href="#">Separated Link</.dropdown_item>
          </.dropdown>
        </div>
        <a
          href="#"
          class="cursor-pointer text-xs-plus text-primary hover:text-primary-focus dark:text-accent-light dark:hover:text-accent"
        >
          @johndoe
        </a>
      </div>
    </div>
    <div class="my-4 mx-5 h-px bg-slate-200 dark:bg-navy-500"></div>
    <ul class="grow space-y-1.5 px-5 font-inter font-medium">
      <li>
        <a
          class="flex items-center space-x-2 rounded-full bg-primary px-5 py-2.5 tracking-wide text-white outline-hidden transition-all dark:bg-accent"
          href="#"
        >
          <svg
            xmlns="http://www.w3.org/2000/svg"
            class="size-5"
            fill="none"
            viewBox="0 0 24 24"
            stroke="currentColor"
          >
            <path
              stroke-linecap="round"
              stroke-linejoin="round"
              stroke-width="1.5"
              d="M13 7h8m0 0v8m0-8l-8 8-4-4-6 6"
            />
          </svg>
          <span>Getting start</span>
        </a>
      </li>
      <li>
        <a class={@link} href="#">
          <svg
            xmlns="http://www.w3.org/2000/svg"
            class={@icon}
            fill="none"
            viewBox="0 0 24 24"
            stroke="currentColor"
          >
            <path d="M9 17a2 2 0 11-4 0 2 2 0 014 0zM19 17a2 2 0 11-4 0 2 2 0 014 0z" />
            <path
              stroke-linecap="round"
              stroke-linejoin="round"
              stroke-width="1.5"
              d="M13 16V6a1 1 0 00-1-1H4a1 1 0 00-1 1v10a1 1 0 001 1h1m8-1a1 1 0 01-1 1H9m4-1V8a1 1 0 011-1h2.586a1 1 0 01.707.293l3.414 3.414a1 1 0 01.293.707V16a1 1 0 01-1 1h-1m-6-1a1 1 0 001 1h1M5 17a2 2 0 104 0m-4 0a2 2 0 114 0m6 0a2 2 0 104 0m-4 0a2 2 0 114 0"
            />
          </svg>
          <span>Shipping</span>
        </a>
      </li>
      <li :for={
        {label, path} <- [
          {"Payments",
           "M3 10h18M7 15h1m4 0h1m-7 4h12a3 3 0 003-3V8a3 3 0 00-3-3H6a3 3 0 00-3 3v8a3 3 0 003 3z"},
          {"Returns",
           "M16 15v-1a4 4 0 00-4-4H8m0 0l3 3m-3-3l3-3m9 14V5a2 2 0 00-2-2H6a2 2 0 00-2 2v16l4-2 4 2 4-2 4 2z"},
          {"My Account", "M16 7a4 4 0 11-8 0 4 4 0 018 0zM12 14a7 7 0 00-7 7h14a7 7 0 00-7-7z"}
        ]
      }>
        <a class={@link} href="#">
          <svg
            xmlns="http://www.w3.org/2000/svg"
            class={@icon}
            fill="none"
            viewBox="0 0 24 24"
            stroke="currentColor"
          >
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="1.5" d={path} />
          </svg>
          <span>{label}</span>
        </a>
      </li>
      <li>
        <a class={@link} href="#">
          <svg xmlns="http://www.w3.org/2000/svg" class={@icon} viewBox="0 0 24 24" fill="none">
            <path
              d="M21 12C21 13.1819 20.7672 14.3522 20.3149 15.4442C19.8626 16.5361 19.1997 17.5282 18.364 18.364C17.5282 19.1997 16.5361 19.8626 15.4442 20.3149C14.3522 20.7672 13.1819 21 12 21C10.8181 21 9.64778 20.7672 8.55585 20.3149C7.46392 19.8626 6.47177 19.1997 5.63604 18.364C4.80031 17.5282 4.13738 16.5361 3.68508 15.4442C3.23279 14.3522 3 13.1819 3 12C3 9.61305 3.94821 7.32387 5.63604 5.63604C7.32387 3.94821 9.61305 3 12 3C14.3869 3 16.6761 3.94821 18.364 5.63604C20.0518 7.32387 21 9.61305 21 12Z"
              stroke="currentColor"
              stroke-width="1.5"
              stroke-linecap="round"
              stroke-linejoin="round"
            />
            <path
              d="M12.0449 15.8486C12.625 15.8486 13.1318 15.6729 13.5654 15.3213C13.999 14.9697 14.2393 14.5303 14.2861 14.0029H15.8242C15.7949 14.5479 15.6074 15.0664 15.2617 15.5586C14.916 16.0508 14.4531 16.4434 13.873 16.7363C13.2988 17.0293 12.6895 17.1758 12.0449 17.1758C10.75 17.1758 9.71875 16.7451 8.95117 15.8838C8.18945 15.0166 7.80859 13.833 7.80859 12.333V12.0605C7.80859 11.1348 7.97852 10.3115 8.31836 9.59082C8.6582 8.87012 9.14453 8.31055 9.77734 7.91211C10.416 7.51367 11.1689 7.31445 12.0361 7.31445C13.1025 7.31445 13.9873 7.63379 14.6904 8.27246C15.3994 8.91113 15.7773 9.74023 15.8242 10.7598H14.2861C14.2393 10.1445 14.0049 9.64062 13.583 9.24805C13.167 8.84961 12.6514 8.65039 12.0361 8.65039C11.21 8.65039 10.5684 8.94922 10.1113 9.54688C9.66016 10.1387 9.43457 10.9971 9.43457 12.1221V12.4297C9.43457 13.5254 9.66016 14.3691 10.1113 14.9609C10.5625 15.5527 11.207 15.8486 12.0449 15.8486Z"
              fill="currentColor"
            />
          </svg>
          <span>Copyright &amp; Legal</span>
        </a>
      </li>
    </ul>
    <div class="p-5">
      <.button color="warning" variant="soft" class="w-full space-x-2">
        <svg
          xmlns="http://www.w3.org/2000/svg"
          class="size-5"
          fill="none"
          viewBox="0 0 24 24"
          stroke="currentColor"
        >
          <path
            stroke-linecap="round"
            stroke-linejoin="round"
            stroke-width="2"
            d="M17 16l4-4m0 0l-4-4m4 4H7m6 4v1a3 3 0 01-3 3H6a3 3 0 01-3-3V7a3 3 0 013-3h4a3 3 0 013 3v1"
          />
        </svg>
        <span>Logout</span>
      </.button>
    </div>
    """
  end
end
