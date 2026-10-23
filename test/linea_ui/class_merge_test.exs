defmodule LineaUI.ClassMergeTest do
  use ExUnit.Case, async: true

  import LineaUI.ClassMerge, only: [merge: 1]

  test "a later class of the same kind replaces the earlier one" do
    assert merge("px-5 py-2 rounded-lg px-8") == "py-2 rounded-lg px-8"
    assert merge(["bg-primary text-white", "bg-error"]) == "text-white bg-error"
  end

  test "a broader class removes the narrower ones before it, not after it" do
    assert merge("px-2 pt-1 p-4") == "p-4"
    assert merge("p-4 px-2") == "p-4 px-2"
    assert merge("w-4 h-4 size-9") == "size-9"
    assert merge("rounded-l-lg rounded-full") == "rounded-full"
  end

  test "variants and important are part of the key" do
    assert merge("hover:bg-primary bg-white hover:bg-error") == "bg-white hover:bg-error"
    assert merge("dark:text-navy-50 text-slate-700") == "dark:text-navy-50 text-slate-700"
    assert merge("bg-white !bg-black") == "bg-white !bg-black"
  end

  test "kinds that share a prefix stay apart" do
    assert merge("text-xs text-slate-700 text-center") == "text-xs text-slate-700 text-center"
    assert merge("border border-slate-300 border-2") == "border-slate-300 border-2"
    assert merge("font-medium font-inter") == "font-medium font-inter"
    assert merge("bg-center bg-no-repeat bg-slate-150") == "bg-center bg-no-repeat bg-slate-150"
    assert merge("shadow-lg shadow-primary/50") == "shadow-lg shadow-primary/50"
    assert merge("translate-x-0 translate-y-2") == "translate-x-0 translate-y-2"
  end

  test "unknown classes and arbitrary values are kept or merged by property" do
    assert merge("btn card btn") == "btn card btn"
    assert merge("[--x:1] [--x:2]") == "[--x:2]"
    assert merge("text-[13px] text-sm") == "text-sm"
  end

  test "nil, false and nested lists are accepted" do
    assert merge(["a", nil, false, ["b", ["c"]]]) == "a b c"
    assert merge(nil) == ""
  end
end
