import {test} from "node:test"
import assert from "node:assert/strict"
import {choose, highlight, isFull, moveIndex, removeLast, removeValue, sameValues, shows, splitTags} from "./select_box.js"

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
