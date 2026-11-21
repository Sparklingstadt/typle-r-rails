import { Controller } from "@hotwired/stimulus"

// typle-r's Radix DropdownMenu: a trigger button and the menu after it. The root carries the `open` attribute while the
// menu is shown (so Tailwind's open: and in-open: variants apply) and the trigger its aria-expanded. The menu closes on
// Esc, Tab or a click outside it. From the keyboard: ↓/↑ (or Enter and Space on the trigger) open it on the first or last
// item, ↓/↑ move between the items, Home/End go to the ends and a letter goes to the next item starting with it.
const ITEMS = 'a[href], button:not(:disabled), input:not([type="hidden"]):not(:disabled)'

export default class extends Controller {
  static targets = ["trigger"]

  connect() {
    this.trigger = this.hasTriggerTarget ? this.triggerTarget : this.element.querySelector(":scope > button")
    this.trigger?.setAttribute("aria-haspopup", "menu")
    this.onTrigger = event => { event.preventDefault(); this.open = !this.open }
    this.trigger?.addEventListener("click", this.onTrigger)
    this.open = false
    this.outside = event => { if (!this.element.contains(event.target)) this.open = false }
    this.key = event => this.keydown(event)
    document.addEventListener("click", this.outside)
    this.element.addEventListener("keydown", this.key)
    this.escape = event => { if (event.key === "Escape" && this.open) this.close(event) }
    document.addEventListener("keydown", this.escape)
  }

  disconnect() {
    this.trigger?.removeEventListener("click", this.onTrigger)
    document.removeEventListener("click", this.outside)
    document.removeEventListener("keydown", this.escape)
    this.element.removeEventListener("keydown", this.key)
  }

  get open() { return this.element.hasAttribute("open") }

  set open(value) {
    const was = this.open
    this.element.toggleAttribute("open", value)
    this.trigger?.setAttribute("aria-expanded", String(value))
    for (const child of this.element.children) if (child !== this.trigger) child.hidden = !value
    if (was !== value) this.element.dispatchEvent(new Event("toggle", { bubbles: false }))
  }

  get items() {
    return [...this.element.querySelectorAll(`:scope > :not([data-dropdown-target=trigger]) :is(${ITEMS})`)]
      .filter(item => item.offsetParent !== null || item.closest("label")?.offsetParent)
  }

  close(event) {
    event?.preventDefault()
    this.open = false
    this.trigger?.focus()
  }

  focusItem(item) {
    if (!item) return
    item.focus()
  }

  keydown(event) {
    if (event.defaultPrevented || event.isComposing) return
    const onTrigger = event.target === this.trigger
    if (onTrigger && (event.key === "ArrowDown" || event.key === "ArrowUp")) {
      event.preventDefault()
      this.open = true
      requestAnimationFrame(() => { const items = this.items; this.focusItem(event.key === "ArrowDown" ? items[0] : items.at(-1)) })
      return
    }
    if (!this.open || onTrigger) return
    const items = this.items
    const index = items.indexOf(document.activeElement)
    if (event.key === "Tab") { this.open = false; return }
    if (event.target.matches('input[type="text"], input[type="search"], textarea')) return
    if (event.key === "ArrowDown") { event.preventDefault(); this.focusItem(items[(index + 1) % items.length]) }
    else if (event.key === "ArrowUp") { event.preventDefault(); this.focusItem(items[(index - 1 + items.length) % items.length]) }
    else if (event.key === "Home") { event.preventDefault(); this.focusItem(items[0]) }
    else if (event.key === "End") { event.preventDefault(); this.focusItem(items.at(-1)) }
    else if (event.key.length === 1 && /\S/.test(event.key) && !event.metaKey && !event.ctrlKey && !event.altKey) {
      const text = item => (item.closest("label") ?? item).textContent.trim().toLocaleLowerCase()
      const after = [...items.slice(index + 1), ...items.slice(0, index + 1)]
      const match = after.find(item => text(item).startsWith(event.key.toLocaleLowerCase()))
      if (match) { event.preventDefault(); this.focusItem(match) }
    }
  }
}
