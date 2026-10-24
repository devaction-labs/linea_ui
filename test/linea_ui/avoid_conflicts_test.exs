defmodule LineaUI.AvoidConflictsTest do
  use ExUnit.Case, async: true

  import ExUnit.CaptureIO

  @phoenix_names ~w(button input header table icon label error theme_toggle)a

  defp compile_with(options) do
    module = Module.concat(__MODULE__, "Layouts#{System.unique_integer([:positive])}")
    definitions = Enum.map_join(@phoenix_names, "\n", &"def #{&1}(assigns), do: assigns")

    Code.compile_string("""
    defmodule #{inspect(module)} do
      use LineaUI#{options}
      #{definitions}
      def run, do: theme_toggle(%{})
    end
    """)

    module
  end

  test "avoid_conflicts lets a module define the names Phoenix's CoreComponents and Layouts define" do
    assert compile_with(", avoid_conflicts: true").run() == %{}
  end

  test "without avoid_conflicts the same names collide with the imported components" do
    capture_io(:stderr, fn ->
      assert_raise CompileError, fn -> compile_with("") end
    end)
  end
end
