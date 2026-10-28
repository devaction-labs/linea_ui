import {test} from "node:test"
import assert from "node:assert/strict"
import {choose, createRow, createsOnTab, fitCount, highlight, isFull, limitState, moveIndex, removeLast, removeValue, sameValues, shows, splitTags} from "./select_box.js"

test("highlight cuts the label around the term", () => {
  assert.deepEqual(highlight("Alabama", "lab"), [
    {text: "A", hit: false},
    {text: "lab", hit: true},
    {text: "ama", hit: false},
  ])
  assert.deepEqual(highlight("Alabama", ""), [{text: "Alabama", hit: false}])
  assert.deepEqual(highlight("Alabama", "xyz"), [{text: "Alabama", hit: false}])
  assert.deepEqual(highlight("Ohio", "oh"), [{text: "Oh", hit: true}, {text: "io", hit: false}])
})

test("shows hides chosen options of a multiple listbox and filters locally", () => {
  const base = {values: ["CA"], multiple: true, term: "", local: true}
  assert.equal(shows({value: "CA", label: "California"}, base), false)
  assert.equal(shows({value: "CA", label: "California"}, {...base, multiple: false}), true)
  assert.equal(shows({value: "AL", label: "Alabama"}, {...base, term: "ala"}), true)
  assert.equal(shows({value: "AK", label: "Alaska"}, {...base, term: "bam"}), false)
  assert.equal(shows({value: "AK", label: "Alaska"}, {...base, term: "bam", local: false}), true)
})

test("shows also matches the keywords of an option", () => {
  const base = {values: [], multiple: false, term: "ca", local: true}
  assert.equal(shows({value: "BR", label: "Brazil", keywords: "brasil"}, {...base, term: "bra"}), true)
  assert.equal(shows({value: "BR", label: "Brazil", keywords: "brasil tupiniquim"}, {...base, term: "tupi"}), true)
  assert.equal(shows({value: "BR", label: "Brazil", keywords: "brasil"}, {...base, term: "zzz"}), false)
  assert.equal(shows({value: "BR", label: "Brazil"}, {...base, term: "bas"}), false)
})

test("moveIndex stops at the ends", () => {
  assert.equal(moveIndex(-1, "ArrowDown", 3), 0)
  assert.equal(moveIndex(2, "ArrowDown", 3), 2)
  assert.equal(moveIndex(0, "ArrowUp", 3), 0)
  assert.equal(moveIndex(1, "Home", 3), 1)
  assert.equal(moveIndex(1, "ArrowDown", 0), -1)
})

test("choose and isFull follow single, multiple and max", () => {
  assert.deepEqual(choose(["a"], "b", {multiple: false}), ["b"])
  assert.deepEqual(choose(["a"], "b", {multiple: true, max: null}), ["a", "b"])
  assert.deepEqual(choose(["a"], "a", {multiple: true, max: null}), ["a"])
  assert.deepEqual(choose(["a", "b"], "c", {multiple: true, max: 2}), ["a", "b"])
  assert.equal(isFull(1, false, null), true)
  assert.equal(isFull(0, false, null), false)
  assert.equal(isFull(3, true, null), false)
  assert.equal(isFull(2, true, 2), true)
})

test("removing values", () => {
  assert.deepEqual(removeValue(["a", "b"], "a"), ["b"])
  assert.deepEqual(removeLast(["a", "b"]), {values: ["a"], removed: "b"})
  assert.deepEqual(removeLast([]), {values: [], removed: null})
})

test("splitTags keeps the text after the last delimiter", () => {
  assert.deepEqual(splitTags("one, two,thr"), {done: ["one", "two"], rest: "thr"})
  assert.deepEqual(splitTags("one"), {done: [], rest: "one"})
  assert.deepEqual(splitTags(" ,x,"), {done: ["x"], rest: ""})
})

test("sameValues compares in order", () => {
  assert.equal(sameValues(["a", "b"], ["a", "b"]), true)
  assert.equal(sameValues(["a", "b"], ["b", "a"]), false)
  assert.equal(sameValues([], []), true)
})

test("Tab creates a tag only in a tag input with text typed", () => {
  assert.equal(createsOnTab("tags", "pri"), true)
  assert.equal(createsOnTab("tags", "  "), false)
  assert.equal(createsOnTab("tags", ""), false)
  assert.equal(createsOnTab("select", "pri"), false)
})

test("a comma ends a tag, Backspace in an empty input takes the last one back", () => {
  assert.deepEqual(splitTags("pri,"), {done: ["pri"], rest: ""})
  assert.deepEqual(splitTags("a,,b"), {done: ["a"], rest: "b"})
  assert.deepEqual(removeLast(["a", "b", "c"]), {values: ["a", "b"], removed: "c"})
})

test("limitState turns the input off and counts at the limit", () => {
  const spec = {max: 3, placeholder: "Add", limitPlaceholder: "Limit reached"}
  assert.deepEqual(limitState({...spec, count: 2}), {full: false, disabled: false, placeholder: "Add", counter: "2 / 3", showCounter: false})
  assert.deepEqual(limitState({...spec, count: 3}), {full: true, disabled: true, placeholder: "Limit reached", counter: "3 / 3", showCounter: true})
  assert.equal(limitState({...spec, count: 3, limitPlaceholder: null}).placeholder, "Add")
  assert.deepEqual(limitState({count: 9, max: null, placeholder: "x"}), {full: false, disabled: false, placeholder: "x", counter: null, showCounter: false})
})

test("createRow puts the term between curly quotes and drops an empty hint", () => {
  assert.deepEqual(createRow("Enter", "Add", "pri"), {hint: "Enter", label: "Add", quoted: "“pri”"})
  assert.equal(createRow("", "Add", "pri").hint, null)
  assert.equal(createRow(undefined, "Add", "pri").hint, null)
})

test("fitCount keeps every chip that fits, making room for the +N badge", () => {
  const badge = (hidden) => (hidden > 9 ? 40 : 30)
  assert.equal(fitCount([50, 50, 50], 200, badge), 3)
  assert.equal(fitCount([50, 50, 50], 150, badge), 3)
  assert.equal(fitCount([50, 50, 50], 140, badge), 2)
  assert.equal(fitCount([50, 50, 50], 100, badge), 1)
  assert.equal(fitCount([50, 50, 50], 40, badge), 0)
  assert.equal(fitCount([], 0, badge), 0)
  assert.equal(fitCount(Array(12).fill(10), 100, badge), 7)
})
