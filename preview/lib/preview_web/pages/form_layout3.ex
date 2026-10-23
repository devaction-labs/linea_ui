defmodule PreviewWeb.Pages.FormLayout3 do
  use PreviewWeb.Page, title: "Form Layout 3", category: :forms, lineone: "forms-layout-3"

  def mount(socket), do: assign(socket, card: %{"number" => "", "name" => ""})

  def handle_event("card", %{"card" => card}, socket) do
    {:noreply, assign(socket, card: card)}
  end

  def render(assigns) do
    ~H"""
    <div class="grid place-items-center">
      <div class="card mt-20 w-full max-w-xl p-4 sm:p-5">
        <div class="relative mx-auto -mt-20 h-40 w-72 rounded-lg text-white shadow-xl transition-transform hover:scale-110 lg:h-48 lg:w-80">
          <div class="h-full w-full rounded-lg bg-gradient-to-r from-indigo-400 to-indigo-600"></div>
          <div class="absolute top-0 flex h-full w-full flex-col justify-between p-4 sm:p-5">
            <div class="flex justify-between">
              <div>
                <p class="text-xs-plus font-light">Name</p>
                <p id="card-name" class="font-medium uppercase tracking-wide">
                  {blank(@card["name"], "John Doe")}
                </p>
              </div>
              <img
                src="/lineone/images/payments/cc-visa.svg"
                class="w-12 rounded-lg"
                alt="creditcard"
              />
            </div>
            <div class="pt-4">
              <p class="text-xs-plus font-light">Card Number</p>
              <p id="card-number" class="font-medium tracking-wide">
                {blank(@card["number"], "4684 6894 6626 6491")}
              </p>
            </div>
          </div>
        </div>
        <div class="flex items-center justify-between py-4">
          <p class="text-xl font-semibold text-primary dark:text-accent-light">Visa</p>
          <div class="badge rounded-full border border-primary text-primary dark:border-accent-light dark:text-accent-light">
            Primary
          </div>
        </div>
        <form id="card-form" class="space-y-4" phx-change="card">
          <.input
            id="cardNumber"
            name="card[number]"
            label="Card number"
            variant="filled"
            placeholder="**** **** **** ****"
            mask="credit_card"
          />
          <.input name="card[name]" label="Name on card" variant="filled" placeholder="John Doe" />
          <div class="grid grid-cols-2 gap-4">
            <.input
              id="expireDate"
              name="card[expire]"
              label="Expiration date"
              variant="filled"
              placeholder="mm/yy"
              mask="date"
              mask_options={%{pattern: ["m", "y"]}}
            />
            <.input
              id="cvv"
              name="card[cvv]"
              type="password"
              label="CVV"
              variant="filled"
              placeholder="***"
              maxlength="3"
              mask="numeral"
              mask_options={%{thousands: "none", decimals: 0, positive: true}}
            />
          </div>
          <div class="flex justify-center space-x-2 pt-4">
            <.button variant="outline" class="min-w-[7rem]">Cancel</.button>
            <.button color="primary" class="min-w-[7rem]">Save</.button>
          </div>
        </form>
      </div>
    </div>
    """
  end

  defp blank("", fallback), do: fallback
  defp blank(nil, fallback), do: fallback
  defp blank(value, _fallback), do: value
end
