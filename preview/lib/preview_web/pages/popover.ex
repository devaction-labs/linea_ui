defmodule PreviewWeb.Pages.Popover do
  use PreviewWeb.Page, title: "Popover", category: :components, lineone: "components-popover"

  import PreviewWeb.Pages.NarrowExample

  @text "The Popover component is similar to tooltips. The difference is that the popover can contain much more content. Check out code for detail of usage."

  @profiles [
    {"popover4", "avatar-19", "John Doe", "@johndoeaccount"},
    {"popover5", "avatar-11", "Sally Ramos", "@sallyramos"},
    {"popover6", "avatar-8", "Katrina West", "@katrinawest"}
  ]

  @cards [
    {"popover7", "avatar-19", "Konnor G.", "Web Developer", "Free",
     "bg-success/10 text-success dark:bg-success/15"},
    {"popover8", "avatar-12", "John D.", "UI/UX Designer", "Busy",
     "bg-error/10 text-error dark:bg-error/15"},
    {"popover9", "avatar-20", "Simon T.", "Fronend Developer", "At work",
     "bg-warning/10 text-warning dark:bg-warning/15"}
  ]

  def render(assigns) do
    assigns =
      assign(assigns,
        text: @text,
        profiles: @profiles,
        cards: @cards
      )

    ~H"""
    <.narrow title="Basic Popover" text={@text} class="mt-5">
      <.popover id="popover1" class="max-w-xs">
        <:trigger><.button color="primary">Basic Popover</.button></:trigger>
        <:title>UI/UX Design</:title>
        <p class="mt-2">Lorem ipsum dolor sit amet, consectetur adipisicing elit.</p>
        <div class="mt-3 flex space-x-2">
          <.tag :for={n <- 1..3} href="#">Tag {n}</.tag>
        </div>
        <p class="mt-3 text-xs text-slate-400 dark:text-navy-300">
          Lorem ipsum dolor sit amet, elit.
        </p>
      </.popover>
    </.narrow>

    <.narrow title="Advanced Popover" text={@text} class="mt-5">
      <.popover id="popover2" class="max-w-xs px-4 py-3">
        <:trigger><.button color="primary">Lessons</.button></:trigger>
        <:title>Group Lesson</:title>
        <div class="mt-3">
          <p class="font-medium text-slate-600 dark:text-navy-100">Social Media Marketing</p>
          <p class="mt-1 text-xs">Lorem ipsum dolor sit amet consectetur adipisicing elit.</p>
        </div>
        <div class="mt-4 flex flex-wrap -space-x-2">
          <div class="avatar size-8 hover:z-10">
            <img
              class="rounded-full ring-2 ring-white dark:ring-navy-700"
              src="/lineone/images/avatar/avatar-16.jpg"
              alt="avatar"
            />
          </div>
          <div class="avatar size-8 hover:z-10">
            <div class="is-initial rounded-full bg-info text-xs-plus uppercase text-white ring-2 ring-white dark:ring-navy-700">
              jd
            </div>
          </div>
          <div :for={face <- ~w(avatar-20 avatar-19)} class="avatar size-8 hover:z-10">
            <img
              class="rounded-full ring-2 ring-white dark:ring-navy-700"
              src={"/lineone/images/avatar/#{face}.jpg"}
              alt="avatar"
            />
          </div>
        </div>
        <div class="mt-4 flex items-center justify-between">
          <p class="flex items-center space-x-2">
            <svg
              xmlns="http://www.w3.org/2000/svg"
              class="size-4.5 text-slate-400 dark:text-navy-300"
              fill="none"
              viewBox="0 0 24 24"
              stroke="currentColor"
            >
              <path
                stroke-linecap="round"
                stroke-linejoin="round"
                stroke-width="1.5"
                d="M8 7V3m8 4V3m-9 8h10M5 21h14a2 2 0 002-2V7a2 2 0 00-2-2H5a2 2 0 00-2 2v12a2 2 0 002 2z"
              />
            </svg>
            <span class="text-xs">25 May, 2022</span>
          </p>
          <.button variant="glow" icon size="sm" shape="pill" aria-label="Open">
            <svg
              xmlns="http://www.w3.org/2000/svg"
              class="size-5 rotate-45"
              fill="none"
              viewBox="0 0 24 24"
              stroke="currentColor"
            >
              <path
                stroke-linecap="round"
                stroke-linejoin="round"
                stroke-width="2"
                d="M7 11l5-5m0 0l5 5m-5-5v12"
              />
            </svg>
          </.button>
        </div>
      </.popover>
    </.narrow>

    <.narrow title="Form Popover" text={@text} class="mt-5">
      <.popover id="popover3" class="max-w-[16rem]">
        <:trigger><.button color="primary">Choose Columns</.button></:trigger>
        <:title>Select Columns</:title>
        <p class="mt-1 text-xs-plus">Lorem ipsum dolor sit amet, consectetur.</p>
        <div class="mt-4 flex flex-col space-y-4 text-slate-600 dark:text-navy-100">
          <.checkbox
            :for={
              {text, checked} <- [{"ID", true}, {"Name", true}, {"Email", true}, {"Address", false}]
            }
            name={text}
            label={text}
            color="primary"
            checked={checked}
          />
        </div>
        <div class="my-4 h-px bg-slate-200 dark:bg-navy-500"></div>
        <div class="flex flex-col space-y-4 text-slate-600 dark:text-navy-100">
          <.checkbox
            :for={{text, checked} <- [{"Created at", true}, {"Updated at", false}]}
            name={text}
            label={text}
            color="primary"
            checked={checked}
          />
        </div>
        <.button color="primary" size="sm" class="mt-4 w-full">Apply</.button>
      </.popover>
    </.narrow>

    <.narrow title="Profile Popover" text={@text} class="mt-5">
      <div class="flex flex-wrap justify-center -space-x-2 sm:justify-start">
        <.popover
          :for={{id, face, name, handle} <- @profiles}
          id={id}
          trigger_on="hover"
          placement="top"
          fallbacks={[]}
          class="w-48 px-4 py-5 text-center"
        >
          <:trigger>
            <div class="avatar size-8 hover:z-10">
              <img
                class="rounded-full ring-2 ring-white dark:ring-navy-700"
                src={"/lineone/images/avatar/#{face}.jpg"}
                alt="avatar"
              />
            </div>
          </:trigger>
          <div class="avatar size-16">
            <img class="rounded-full" src={"/lineone/images/avatar/#{face}.jpg"} alt="avatar" />
          </div>
          <p class="pt-2 text-base font-medium tracking-wide text-slate-700 dark:text-navy-100">
            {name}
          </p>
          <a
            href="#"
            class="font-inter tracking-wide hover:text-primary focus:text-primary dark:hover:text-accent-light dark:focus:text-accent-light"
          >
            {handle}
          </a>
          <.button color="primary" size="sm" shape="pill" class="mt-4">Follow</.button>
        </.popover>
      </div>
    </.narrow>

    <.narrow title="Profile Popover" text={@text} class="mt-5">
      <div class="flex flex-wrap justify-center -space-x-2 sm:justify-start">
        <.popover
          :for={{id, face, name, job, status, badge} <- @cards}
          id={id}
          trigger_on="hover"
          placement="top"
          fallbacks={[]}
          class="w-72 p-3"
        >
          <:trigger>
            <div class="avatar size-8 hover:z-10">
              <img
                class="rounded-full ring-2 ring-white dark:ring-navy-700"
                src={"/lineone/images/avatar/#{face}.jpg"}
                alt="avatar"
              />
            </div>
          </:trigger>
          <div class="flex space-x-3">
            <div class="avatar size-10">
              <img class="rounded-full" src={"/lineone/images/avatar/#{face}.jpg"} alt="avatar" />
            </div>
            <div class="flex w-full items-start justify-between">
              <div>
                <p class="text-xs-plus font-medium text-slate-700 line-clamp-1 dark:text-navy-100">
                  {name}
                </p>
                <p class="text-xs text-primary line-clamp-1 dark:text-accent-light">{job}</p>
              </div>
              <div class={["badge h-5 space-x-1.5 rounded-full px-1.5", badge]}>
                <div class="size-1.5 rounded-full bg-current"></div>
                <span>{status}</span>
              </div>
            </div>
          </div>
          <p class="pt-2 text-xs text-slate-400 dark:text-navy-300">
            Lorem ipsum dolor sit, amet consectetur adipisicing elit. Consequuntur.
          </p>
          <div class="flex justify-end space-x-1 pt-4">
            <.button
              :for={
                {path, width} <- [
                  {"M3 5a2 2 0 012-2h3.28a1 1 0 01.948.684l1.498 4.493a1 1 0 01-.502 1.21l-2.257 1.13a11.042 11.042 0 005.516 5.516l1.13-2.257a1 1 0 011.21-.502l4.493 1.498a1 1 0 01.684.949V19a2 2 0 01-2 2h-1C9.716 21 3 14.284 3 6V5z",
                   "1.5"},
                  {"M8 12h.01M12 12h.01M16 12h.01M21 12c0 4.418-4.03 8-9 8a9.863 9.863 0 01-4.255-.949L3 20l1.395-3.72C3.512 15.042 3 13.574 3 12c0-4.418 4.03-8 9-8s9 3.582 9 8z",
                   "1.5"},
                  {"M5 12h.01M12 12h.01M19 12h.01M6 12a1 1 0 11-2 0 1 1 0 012 0zm7 0a1 1 0 11-2 0 1 1 0 012 0zm7 0a1 1 0 11-2 0 1 1 0 012 0z",
                   "2"}
                ]
              }
              variant="flat"
              icon
              size="sm"
              shape="pill"
              class="text-inherit dark:text-inherit"
              aria-label="Action"
            >
              <svg
                xmlns="http://www.w3.org/2000/svg"
                class="size-4.5"
                fill="none"
                viewBox="0 0 24 24"
                stroke="currentColor"
                stroke-width={width}
              >
                <path stroke-linecap="round" stroke-linejoin="round" d={path} />
              </svg>
            </.button>
          </div>
        </.popover>
      </div>
    </.narrow>
    """
  end
end
