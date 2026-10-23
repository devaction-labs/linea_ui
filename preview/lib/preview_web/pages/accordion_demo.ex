defmodule PreviewWeb.Pages.AccordionDemo do
  @moduledoc "The sections LineOne's Accordion and Collapse pages share; only the words and `multiple` differ."

  use PreviewWeb, :html
  import PreviewWeb.Pages.NarrowExample

  @lorem "Lorem ipsum dolor sit amet, consectetur adipisicing elit. Commodi earum magni officiis possimus repellendus. Accusantium adipisci aliquid praesentium quaerat voluptate."

  @people [
    {"simon", {:img, "avatar-10"}, "Simon Tods", "Web Developer"},
    {"konnor", {:initial, "KG"}, "Konnor Guzman", "Frontend Developer"},
    {"derrick", {:img, "avatar-19"}, "Derrick Simmons", "UI/UX Designer"}
  ]

  attr :prefix, :string,
    required: true,
    doc: "The id prefix and the item word, `accordion` or `collapse`."

  attr :word, :string, required: true, doc: "`Accordion` or `Collapse`."
  attr :text, :string, required: true, doc: "The first section's text."
  attr :others, :string, required: true, doc: "The text of the other sections."
  attr :multiple, :boolean, required: true

  def sections(assigns) do
    assigns = assign(assigns, lorem: @lorem, people: @people)

    ~H"""
    <.narrow title={"Basic #{@word}"} text={@text} class="mt-5">
      <.accordion id={"#{@prefix}_1"} multiple={@multiple}>
        <.accordion_item :for={n <- 1..3} id={"#{@prefix}_1_#{n}"} title={"#{@word} Item #{n}"}>
          <.tags lorem={@lorem} />
        </.accordion_item>
      </.accordion>
    </.narrow>

    <.narrow
      :for={
        {title, variant, n} <- [
          {"Border Bottom", "border-bottom", 2},
          {"Full Bordered", "bordered", 3}
        ]
      }
      title={title}
      text={@others}
      class="mt-5"
    >
      <.accordion id={"#{@prefix}_#{n}"} variant={variant} multiple={@multiple}>
        <.accordion_item :for={i <- 1..3} id={"#{@prefix}_#{n}_#{i}"} title={"#{@word} Item #{i}"}>
          <.tags lorem={@lorem} />
        </.accordion_item>
      </.accordion>
    </.narrow>

    <.narrow title="Divided Items" text={@others} class="mt-5">
      <.accordion id={"#{@prefix}_4"} variant="divided" multiple={@multiple}>
        <.accordion_item :for={i <- 1..3} id={"#{@prefix}_4_#{i}"} title={"#{@word} Item #{i}"}>
          <.team lorem={@lorem} />
        </.accordion_item>
      </.accordion>
    </.narrow>

    <.narrow title={"Primary #{@word}"} text={@others} class="mt-5">
      <.accordion id={"#{@prefix}_5"} variant="primary" multiple={@multiple}>
        <.accordion_item
          :for={i <- 1..3}
          id={"#{@prefix}_5_#{i}"}
          title={"#{@word} Item #{i}"}
          open={i == 1}
        >
          <.tags lorem={@lorem} />
        </.accordion_item>
      </.accordion>
    </.narrow>

    <.narrow title={"Advanced #{@word}"} text={@others} class="mt-5">
      <.accordion id={"#{@prefix}_6"} variant="advanced" multiple={@multiple}>
        <.accordion_item :for={{key, face, name, job} <- @people} id={"#{@prefix}_6_#{key}"}>
          <:header>
            <.face face={face} />
            <div>
              <p class="text-slate-700 line-clamp-1 dark:text-navy-100">{name}</p>
              <p class="text-xs text-slate-500 dark:text-navy-300">{job}</p>
            </div>
          </:header>
          <.team lorem={@lorem} />
        </.accordion_item>
      </.accordion>
    </.narrow>
    """
  end

  attr :lorem, :string, required: true

  defp tags(assigns) do
    ~H"""
    <p>{@lorem}</p>
    <div class="flex space-x-2 pt-3">
      <a
        :for={n <- 1..2}
        href="#"
        class="tag rounded-full border border-primary text-primary dark:border-accent-light dark:text-accent-light"
      >
        Tag {n}
      </a>
    </div>
    """
  end

  attr :lorem, :string, required: true

  defp team(assigns) do
    ~H"""
    <p>{@lorem}</p>
    <div class="mt-4 flex justify-between">
      <div class="flex flex-wrap -space-x-2">
        <div class="avatar size-7 hover:z-10">
          <img
            class="rounded-full ring-2 ring-white dark:ring-navy-700"
            src="/lineone/images/avatar/avatar-16.jpg"
            alt="avatar"
          />
        </div>
        <div class="avatar size-7 hover:z-10">
          <div class="is-initial rounded-full bg-info text-xs-plus uppercase text-white ring-2 ring-white dark:ring-navy-700">
            jd
          </div>
        </div>
        <div :for={face <- ~w(avatar-20 avatar-8 avatar-5)} class="avatar size-7 hover:z-10">
          <img
            class="rounded-full ring-2 ring-white dark:ring-navy-700"
            src={"/lineone/images/avatar/#{face}.jpg"}
            alt="avatar"
          />
        </div>
      </div>
      <.button icon size="sm" shape="pill" aria-label="Open">
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
    """
  end

  attr :face, :any, required: true

  defp face(%{face: {:img, name}} = assigns) do
    assigns = assign(assigns, :name, name)

    ~H"""
    <div class="avatar size-10">
      <img class="rounded-full" src={"/lineone/images/avatar/#{@name}.jpg"} alt="avatar" />
    </div>
    """
  end

  defp face(%{face: {:initial, text}} = assigns) do
    assigns = assign(assigns, :text, text)

    ~H"""
    <div class="avatar size-10">
      <div class="is-initial rounded-full bg-warning uppercase text-white">{@text}</div>
    </div>
    """
  end
end
