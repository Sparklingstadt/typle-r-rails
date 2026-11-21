import { Controller } from "@hotwired/stimulus"

// A <details> menu that closes on Esc, Tab or a click outside it, and is used from the keyboard as typle-r's Radix
// DropdownMenu: ↓/↑ (or Enter and Space on the trigger) open it on the first or last item, ↓/↑ move between the items,
// Home/End go to the ends and a letter goes to the next item starting with it.
const ITEMS = 'a[href], button:not(:disabled), input:not([type="hidden"]):not(:disabled)'

export default class extends Controller {
  connect() {
    this.summary = this.element.querySelector(":scope > summary")
    // Radix sets aria-expanded on the trigger, which typle-r's buttons style (aria-expanded:bg-muted).
    this.sync = () => this.summary?.setAttribute("aria-expanded", String(this.element.open))
    this.sync()
    this.element.addEventListener("toggle", this.sync)
    this.outside = event => { if (!this.element.contains(event.target)) this.element.open = false }
    this.key = event => this.keydown(event)
    document.addEventListener("click", this.outside)
    this.element.addEventListener("keydown", this.key)
    this.escape = event => { if (event.key === "Escape" && this.element.open) this.close(event) }
    document.addEventListener("keydown", this.escape)
  }

  disconnect() {
    document.removeEventListener("click", this.outside)
    document.removeEventListener("keydown", this.escape)
    this.element.removeEventListener("keydown", this.key)
    this.element.removeEventListener("toggle", this.sync)
  }

  get items() {
    return [...this.element.querySelectorAll(`:scope > :not(summary) :is(${ITEMS})`)].filter(item => item.offsetParent !== null || item.closest("label")?.offsetParent)
  }

  close(event) {
    event?.preventDefault()
    this.element.open = false
    this.summary?.focus()
  }

  focusItem(item) {
    if (!item) return
    item.focus()
  }

  keydown(event) {
    if (event.defaultPrevented || event.isComposing) return
    const onTrigger = event.target === this.summary
    if (onTrigger && (event.key === "ArrowDown" || event.key === "ArrowUp")) {
      event.preventDefault()
      this.element.open = true
      requestAnimationFrame(() => { const items = this.items; this.focusItem(event.key === "ArrowDown" ? items[0] : items.at(-1)) })
      return
    }
    if (!this.element.open || onTrigger) return
    const items = this.items
    const index = items.indexOf(document.activeElement)
    if (event.key === "Tab") { this.element.open = false; return }
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
