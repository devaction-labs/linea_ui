defmodule LineaUI.PublicApiLeakTest do
  use ExUnit.Case, async: true

  # `use LineaUI` imports these modules into the host app: any extra public function would collide
  # with the host's own (a local `initials/1` once did).
  @generated [__components__: 0, __phoenix_component_verify__: 1]

  for {module, components} <- [
        {LineaUI.Components.Sidebar, [sidebar: 1]},
        {LineaUI.Components.Shell, [shell: 1]},
        {LineaUI.Components.ThemeSwitch, [theme_switch: 1]}
      ] do
    test "#{inspect(module)} exports only its components" do
      assert Enum.sort(unquote(module).__info__(:functions)) ==
               Enum.sort(unquote(components) ++ @generated)
    end
  end
end
