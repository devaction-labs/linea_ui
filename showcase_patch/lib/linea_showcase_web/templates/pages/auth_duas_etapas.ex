defmodule LineaShowcaseWeb.Templates.Pages.AuthDuasEtapas do
  @moduledoc """
  The two-step verification of the design canvas: six one-digit boxes (typing advances, pasting spreads
  the digits, `otp_input/1`) or a recovery code, on a segmented control.
  """

  use LineaShowcaseWeb.Template,
    title: "Verificação em duas etapas",
    section: :signetum,
    group: "Auth",
    order: 9,
    layout: :blank

  alias LineaShowcaseWeb.Templates.Auth.Form
  alias LineaShowcaseWeb.Templates.Auth.Shell

  @modes [
    {"app", "App autenticador", "huge-smart-phone-01"},
    {"recovery", "Código de recuperação", "huge-key-01"}
  ]

  @leads %{
    "app" => "Digite o código de 6 dígitos do seu app autenticador.",
    "recovery" => "Sem acesso ao app? Entre com um dos seus códigos de recuperação."
  }

  def mount(socket),
    do: assign(socket, mode: "app", form: Form.blank(%{"code" => "482", "recovery" => ""}, :otp))

  def handle_event("mode", %{"value" => mode}, socket) when mode in ~w(app recovery),
    do: {:noreply, assign(socket, mode: mode, form: Form.blank(socket.assigns.form.params, :otp))}

  def handle_event("validate", %{"otp" => params}, socket),
    do: {:noreply, assign(socket, :form, typing(socket.assigns, params))}

  def handle_event("submit", %{"otp" => params}, socket) do
    case Form.check(params, :otp, rules(socket.assigns.mode)) do
      {:ok, _form} -> {:noreply, verified(socket)}
      {:error, form} -> {:noreply, rejected(socket, form)}
    end
  end

  defp rules("app"), do: [code: [{:digits, 6}]]
  defp rules("recovery"), do: [recovery: [:required]]

  defp typing(%{mode: "app", form: form}, params),
    do: Form.blank(Map.merge(form.params, params), :otp)

  defp typing(%{mode: "recovery", form: form}, params),
    do: Form.validate(Map.merge(form.params, params), :otp, rules("recovery"))

  defp verified(socket) do
    socket
    |> put_toast("Identidade verificada.", color: "success")
    |> push_navigate(to: Shell.app_path())
  end

  defp rejected(socket, form) do
    socket
    |> assign(:form, form)
    |> send_toast("Confira o código e tente de novo.", color: "error")
  end

  def render(assigns) do
    assigns = assign(assigns, modes: @modes, lead: Map.fetch!(@leads, assigns.mode))

    ~H"""
    <Shell.screen>
      <Shell.frame>
        <Shell.hero title="Verificação em duas etapas">
          <:mark>
            <Shell.mark><.icon name="huge-smart-phone-01" class="size-[26px]" /></Shell.mark>
          </:mark>
          <:lead>{@lead}</:lead>
        </Shell.hero>

        <Shell.segmented
          id="otp-mode"
          selected={@mode}
          on_change="mode"
          label="Tipo de código"
          options={@modes}
        />

        <.form for={@form} id="otp-form" phx-change="validate" phx-submit="submit">
          <Shell.stack>
            <.code :if={@mode == "app"} form={@form} />
            <.recovery :if={@mode == "recovery"} form={@form} />
            <.button type="submit" color="primary" class="h-11 w-full text-[15px]">Verificar</.button>
          </Shell.stack>
        </.form>

        <Shell.foot>
          <Shell.go navigate={Shell.path("entrar")}>Usar outra conta</Shell.go>
        </Shell.foot>
      </Shell.frame>
    </Shell.screen>
    """
  end

  attr :form, :any, required: true

  defp code(assigns) do
    ~H"""
    <.otp_input
      field={@form[:code]}
      id="otp-code"
      label="Código de 6 dígitos"
      label_class="text-sm font-medium text-slate-800 dark:text-navy-50"
      help="O código muda a cada 30 segundos no app autenticador."
      digit_label="Dígito"
      aria_label="Código de 6 dígitos"
    />
    """
  end

  attr :form, :any, required: true

  defp recovery(assigns) do
    ~H"""
    <Shell.group>
      <Shell.caption for="tf-recovery" label="Código de recuperação" />
      <.input
        field={@form[:recovery]}
        id="tf-recovery"
        autocapitalize="characters"
        spellcheck="false"
        autocomplete="one-time-code"
        placeholder="Digite um dos seus códigos"
        help="Use um dos códigos que você guardou ao ativar a verificação em duas etapas."
        class={[Shell.field_class(), "font-mono text-sm tracking-[0.06em] uppercase"]}
      >
        <:prefix><.icon name="huge-key-01" class="size-4" /></:prefix>
      </.input>
    </Shell.group>
    """
  end
end
