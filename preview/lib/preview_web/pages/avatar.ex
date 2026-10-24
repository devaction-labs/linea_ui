defmodule PreviewWeb.Pages.Avatar do
  use PreviewWeb.Page, title: "Avatar", category: :elements, lineone: "elements-avatar"

  @colors ~w(neutral primary secondary info success warning error)
  @photos [
    {"xs", "avatar-16"},
    {"sm", "avatar-10"},
    {"md", "avatar-20"},
    {"lg", "avatar-19"},
    {"xl", "avatar-8"},
    {"2xl", "avatar-5"}
  ]
  @sizes ~w(xs sm md lg xl 2xl)
  @dot_photos ~w(avatar-16 avatar-10 avatar-20 avatar-19 avatar-8 avatar-5 avatar-12)
  @group ~w(avatar-16 initials avatar-20 avatar-19 avatar-8 avatar-5)
  @gradients [
    {"sky-blue", "avatar-16", nil},
    {"amber-orange", "avatar-10", nil},
    {"pink-rose", "avatar-20", nil},
    {"purple-orange", "avatar-19", "error"},
    {"green-fuchsia", "avatar-8", nil}
  ]

  def render(assigns) do
    assigns =
      assign(assigns,
        colors: @colors,
        photos: @photos,
        sizes: @sizes,
        dot_photos: Enum.zip(@colors, @dot_photos),
        group: @group,
        gradients: @gradients
      )

    ~H"""
    <.example
      title="Rounded Avatar"
      text="The Avatar component creates a scalable, colorable element that can have text, icon or image within its shape. Check out code for detail of usage."
      class="inline-space mt-5"
    >
      <.avatar :for={{size, photo} <- @photos} size={size} src={src(photo)} />
    </.example>

    <.example title="Square Avatar" class="">
      <.text class="max-w-2xl">
        Avatars can have a square shape. To do this, you should use the
        <.inline_code>rounded-lg</.inline_code>
        utility. Check out code for detail of usage.
      </.text>
      <div class="inline-space mt-5">
        <.avatar :for={{size, photo} <- @photos} size={size} src={src(photo)} shape="square" />
      </div>
    </.example>

    <.example title="Squircle Avatar" class="">
      <.text class="max-w-2xl">
        Avatars can have a squircle shape. To do this, you should use the
        <.inline_code>mask is-squircle</.inline_code>
        classes. Check out code for detail of usage.
      </.text>
      <div class="inline-space mt-5">
        <.avatar :for={{size, photo} <- @photos} size={size} src={src(photo)} shape="squircle" />
      </div>
    </.example>

    <.example
      title="Initial Avatar"
      text="In the absence of a image, you can use the initial. Initials can be used in various variants. Check out code for detail of usage."
      class="inline-space mt-5"
    >
      <.avatar :for={color <- @colors} size="md" color={color} initials="jd" />
    </.example>

    <.example title="Square Initial Avatar" class="">
      <.text class="max-w-2xl">
        Initial avatars can have a square shape. To do this, you should use the
        <.inline_code>rounded-lg</.inline_code>
        utility. Check out code for detail of usage.
      </.text>
      <div class="inline-space mt-5">
        <.avatar :for={color <- @colors} size="md" color={color} initials="jd" shape="square" />
      </div>
    </.example>

    <.example title="Squircle Initial Avatar" class="">
      <.text class="max-w-2xl">
        Initial avatars can have a squircle shape. To do this, you should use the
        <.inline_code>mask is-squircle</.inline_code>
        utility. Check out code for detail of usage.
      </.text>
      <div class="inline-space mt-5">
        <.avatar :for={color <- @colors} size="md" color={color} initials="jd" shape="squircle" />
      </div>
    </.example>

    <.example
      title="Soft Initial Avatar"
      text="Initial avatars can have a soft colors. To do this, you should use some opacity. Check out code for detail of usage."
      class="inline-space mt-5"
    >
      <.avatar :for={color <- tl(@colors)} size="md" color={color} initials="jd" variant="soft" />
    </.example>

    <.example
      title="Bordered Initial Avatar"
      text="Initial avatars can have a border. Check out code for detail of usage."
      class="inline-space mt-5"
    >
      <.avatar
        :for={color <- tl(@colors)}
        size="md"
        color={color}
        initials="jd"
        variant="bordered"
      />
    </.example>

    <.example
      title="Square Soft Initial"
      text="Initial avatars can have a soft colors and square shape. To do this, you should use some opacity and border-radius utility. Check out code for detail of usage."
      class="inline-space mt-5"
    >
      <.avatar
        :for={color <- tl(@colors)}
        size="md"
        color={color}
        initials="jd"
        variant="soft"
        shape="square"
      />
    </.example>

    <.example
      title="Avatar With Dots"
      text="Avatars can be a dot attached to it. It can be used to indicate the user status. Check out code for detail of usage."
      class="inline-space mt-5"
    >
      <.avatar :for={{size, photo} <- @photos} size={size} src={src(photo)} status="primary" />
    </.example>

    <.example
      title="Squircle Avatar Dots"
      text="Avatars can be a dot attached to it. It can be used to indicate the user status. Check out code for detail of usage."
      class="inline-space mt-5"
    >
      <.avatar
        :for={{size, photo} <- @photos}
        size={size}
        src={src(photo)}
        shape="squircle"
        status="primary"
      />
    </.example>

    <.example
      title="Initial With Dots"
      text="Initial avatars can be a dot attached to it, too. It can be used to indicate the user status. Check out code for detail of usage."
      class="inline-space mt-5 flex flex-wrap items-end"
    >
      <.avatar :for={size <- @sizes} size={size} initials="jd" status="primary" />
    </.example>

    <.example
      title="Avatar Dot Colors"
      text="Avatar dots can be used in various colors. It can be used to indicate the user status. Check out code for detail of usage."
      class="inline-space mt-5"
    >
      <.avatar :for={{color, photo} <- @dot_photos} size="md" src={src(photo)} status={color} />
    </.example>

    <.example
      title="Avatar Dot Ping"
      text="Avatar dots can have the ping animation. This can be used to indicate an important message. Check out code for detail of usage."
      class="inline-space mt-5 flex flex-wrap items-end"
    >
      <.avatar :for={color <- tl(@colors)} size="md" initials="jd" status={color} ping />
    </.example>

    <.example
      title="Avatar Dot Position"
      text="Avatar dot position can be up, down, left and right. Check out code for detail of usage."
      class="inline-space mt-5 flex flex-wrap items-end"
    >
      <.avatar
        :for={position <- ~w(top-right top-left bottom-right bottom-left)}
        size="md"
        initials="jd"
        status="primary"
        status_position={position}
        ping
      />
    </.example>

    <.example
      title="Avatar Group"
      text="The Avatar group renders its children as a stack. Check out code for detail of usage."
      class="mt-5"
    >
      <.avatar_group>
        <.group_member :for={member <- @group} member={member} shape="circle" />
      </.avatar_group>
    </.example>

    <.example
      title="Square Avatar Group"
      text="The Avatar group renders its children as a stack. Check out code for detail of usage."
      class="mt-5"
    >
      <.avatar_group>
        <.group_member :for={member <- @group} member={member} shape="rounded" />
      </.avatar_group>
    </.example>

    <.example
      title="Gradient Border"
      text="Border avatars can be gradient colors. Check out code for detail of usage."
      class="inline-space mt-5 flex flex-wrap"
    >
      <.avatar
        :for={{gradient, photo, status} <- @gradients}
        size="lg"
        src={src(photo)}
        gradient={gradient}
        status={status}
      />
    </.example>

    <.example
      title="Avatar Skeleton"
      text="It is also possible to use a skeleton to preview photos. Check out code for detail of usage."
      class="mt-5"
    >
      <.avatar_group pulse>
        <.avatar :for={_ <- 1..6} size="xs" variant="skeleton" ring class="hover:z-auto">
          <svg
            xmlns="http://www.w3.org/2000/svg"
            class="size-3"
            viewBox="0 0 20 20"
            fill="currentColor"
          >
            <path
              fill-rule="evenodd"
              d="M10 9a3 3 0 100-6 3 3 0 000 6zm-7 9a7 7 0 1114 0H3z"
              clip-rule="evenodd"
            />
          </svg>
        </.avatar>
      </.avatar_group>
    </.example>

    <.example
      title="Names, presence and kinds"
      text="Initials and a stable color from the name, a presence dot, a +N group and the kinds of Signetum."
      class="mt-5 flex flex-wrap items-end gap-4"
    >
      <.avatar :for={size <- ~w(24 32 40 48 64)} name="Ana Souza" color="auto" size={size} />
      <.avatar name="Ana Souza" color="auto" size="40" status="online" />
      <.avatar name="Carlos Lima" color="auto" size="40" status="away" />
      <.avatar name="Juliana Moraes" color="auto" size="40" status="busy" />
      <.avatar name="Marcos Oliveira" color="auto" size="40" status="offline" />
      <.avatar_group more={3} size="32">
        <.avatar
          :for={name <- ["Ana Souza", "Carlos Lima", "Juliana Moraes"]}
          name={name}
          color="auto"
          size="32"
          ring
        />
      </.avatar_group>
      <.avatar kind="company" name="Farmácia Signetum" size="48" />
      <.avatar kind="customer" name="Drogaria Feira" size="48" />
      <.avatar kind="supplier" name="Nordeste Farma" size="48" />
      <.avatar kind="assistant" size="48" />
      <.avatar kind="invite" size="48" />
    </.example>
    """
  end

  attr :member, :string, required: true
  attr :shape, :string, required: true

  defp group_member(%{member: "initials"} = assigns) do
    ~H"""
    <.avatar size="xs" initials="jd" color="info" shape={@shape} ring />
    """
  end

  defp group_member(assigns) do
    ~H"""
    <.avatar size="xs" src={src(@member)} shape={@shape} ring />
    """
  end

  defp src(photo), do: "/lineone/images/avatar/#{photo}.jpg"
end
