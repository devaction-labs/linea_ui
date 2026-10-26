defmodule PreviewWeb.Pages.TomSelect do
  use PreviewWeb.Page, title: "Tom Select", category: :forms, lineone: "forms-tom-select"

  @states [
    {"Alabama", "AL"},
    {"Alaska", "AK"},
    {"Arizona", "AZ"},
    {"Arkansas", "AR"},
    {"California", "CA"},
    {"Colorado", "CO"},
    {"Connecticut", "CT"},
    {"Delaware", "DE"},
    {"District of Columbia", "DC"},
    {"Florida", "FL"},
    {"Georgia", "GA"},
    {"Hawaii", "HI"},
    {"Idaho", "ID"},
    {"Illinois", "IL"},
    {"Indiana", "IN"},
    {"Iowa", "IA"},
    {"Kansas", "KS"},
    {"Kentucky", "KY"},
    {"Louisiana", "LA"},
    {"Maine", "ME"},
    {"Maryland", "MD"},
    {"Massachusetts", "MA"},
    {"Michigan", "MI"},
    {"Minnesota", "MN"},
    {"Mississippi", "MS"},
    {"Missouri", "MO"},
    {"Montana", "MT"},
    {"Nebraska", "NE"},
    {"Nevada", "NV"},
    {"New Hampshire", "NH"},
    {"New Jersey", "NJ"},
    {"New Mexico", "NM"},
    {"New York", "NY"},
    {"North Carolina", "NC"},
    {"North Dakota", "ND"},
    {"Ohio", "OH"},
    {"Oklahoma", "OK"},
    {"Oregon", "OR"},
    {"Pennsylvania", "PA"},
    {"Rhode Island", "RI"},
    {"South Carolina", "SC"},
    {"South Dakota", "SD"},
    {"Tennessee", "TN"},
    {"Texas", "TX"},
    {"Utah", "UT"},
    {"Vermont", "VT"},
    {"Virginia", "VA"},
    {"Washington", "WA"},
    {"West Virginia", "WV"},
    {"Wisconsin", "WI"},
    {"Wyoming", "WY"}
  ]

  @authors [
    %{
      value: 1,
      label: "John Doe",
      job: "Web designer",
      src: "/lineone/images/avatar/avatar-20.jpg"
    },
    %{
      value: 2,
      label: "Emilie Watson",
      job: "Developer",
      src: "/lineone/images/avatar/avatar-11.jpg"
    },
    %{
      value: 3,
      label: "Nancy Clarke",
      job: "Software Engineer",
      src: "/lineone/images/avatar/avatar-7.jpg"
    }
  ]

  def mount(socket) do
    assign(socket,
      states: @states,
      authors: @authors,
      author_options: @authors,
      form: to_form(%{"states" => ["CA", "WY"]}, as: :place)
    )
  end

  def handle_event("place", %{"place" => params}, socket),
    do: {:noreply, assign(socket, form: to_form(params, as: :place))}

  def handle_event("search_authors", %{"query" => query}, socket) do
    term = String.downcase(query)
    found = Enum.filter(@authors, &String.contains?(String.downcase(&1.label), term))
    {:noreply, assign(socket, author_options: found)}
  end

  def render(assigns) do
    ~H"""
    <.example title="Input Tags" class="max-w-xl">
      <.intro />
      <div class="inline-space mt-5">
        <.tags_input id="tom1" name="tags1" label="Enter Tags:" placeholder="Enter tags" />
      </div>
    </.example>
    <.example title="Remove Button" class="max-w-xl">
      <.intro />
      <div class="mt-5">
        <.tags_input id="tom2" name="tags2" label="Enter Tags:" placeholder="Enter tags" removable />
      </div>
    </.example>
    <.example title="Restore on Backspace" class="max-w-xl">
      <.intro />
      <div class="inline-space mt-5">
        <.tags_input
          id="tom3"
          name="tags3"
          label="Enter Tags:"
          placeholder="Enter tags"
          value="awesome,neat"
          restore_on_backspace
        />
      </div>
    </.example>
    <.example title="Clear Button" class="max-w-xl">
      <.intro />
      <div class="inline-space mt-5">
        <.tags_input
          id="tom4"
          name="tags4"
          label="Enter Tags:"
          placeholder="Enter tags"
          value="clear,items"
          clearable
          clear_label="Remove all selected options"
          persist={false}
        />
      </div>
    </.example>
    <.example title="Single Select" class="max-w-xl">
      <.intro />
      <div class="inline-space mt-5">
        <.select
          id="tom5"
          name="event"
          label="What type of event is it?"
          options={["Birthday", "Corporate event", "Other", "Wedding"]}
          value="Corporate event"
          create
        />
      </div>
    </.example>
    <.example title="Select Multiple" class="max-w-xl">
      <.intro />
      <div class="inline-space mt-5">
        <.form for={@form} id="tom6-form" phx-change="place">
          <.select
            id="tom6"
            field={@form[:states]}
            label="Select Countries"
            options={@states}
            multiple
            placeholder="Select a state..."
          />
        </.form>
      </div>
    </.example>
    <.example title="Pillbox (one line, +N)" class="max-w-xl">
      <.intro />
      <div class="inline-space mt-5">
        <.select
          id="tom-pillbox"
          name="pillbox"
          label="Select Countries"
          options={@states}
          value={~w(AL AK AZ AR CA CO CT DE)}
          multiple
          removable
          overflow="count"
          placeholder="Select a state..."
        />
      </div>
    </.example>
    <.example title="Custom HTML" class="max-w-xl">
      <.intro />
      <div class="inline-space mt-5">
        <.select
          id="tom7"
          name="authors"
          label="Select Authors"
          options={@author_options}
          multiple
          placeholder="Select the author"
          on_search="search_authors"
        >
          <:option :let={author}>
            <div class="flex space-x-3">
              <.avatar src={author.data.src} size="xs" />
              <div class="flex flex-col">
                <span>{author.label}</span>
                <span class="text-xs opacity-80">{author.data.job}</span>
              </div>
            </div>
          </:option>
          <:item :let={author}>
            <.badge color="primary" shape="pill" class="mr-2 p-px">
              <.avatar src={author.data.src} size="xs" class="size-6" />
              <span class="mx-2">{author.label}</span>
            </.badge>
          </:item>
        </.select>
      </div>
    </.example>
    <.example title="Disable Persist" class="max-w-xl">
      <.intro />
      <div class="inline-space mt-5">
        <.tags_input
          id="tom8"
          name="tags8"
          label="Enter Tags:"
          placeholder="Enter tags"
          persist={false}
        />
      </div>
    </.example>
    """
  end

  defp intro(assigns) do
    ~H"""
    <p>
      <a
        href="https://tom-select.js.org/"
        class="text-primary transition-colors hover:text-primary-focus dark:text-accent-light dark:hover:text-accent"
      >Tom Select</a>
      is a versatile and dynamic &lt;select&gt; UI control. With autocomplete and native-feeling keyboard navigation, it's useful for tagging, contact lists, country selectors, and so on.
    </p>
    """
  end
end
