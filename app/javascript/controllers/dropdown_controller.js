import { Controller } from "@hotwired/stimulus"

// typle-r's Radix DropdownMenu: a trigger button and the menu after it. The root carries the `open` attribute while the
// menu is shown (so Tailwind's open: and in-open: variants apply) and the trigger its aria-expanded. The menu closes on
// Esc, Tab or a click outside it. From the keyboard: ↓/↑ (or Enter and Space on the trigger) open it on the first or last
// item, ↓/↑ move between the items, Home/End go to the ends and a letter goes to the next item starting with it.
const ITEMS = '[role^="menuitem"]:not(:disabled):not([aria-disabled="true"]), input[type="text"], input[type="search"]'
let menus = 0

export default class extends Controller {
  static targets = ["trigger"]

  connect() {
    this.trigger = this.hasTriggerTarget ? this.triggerTarget : this.element.querySelector(":scope > button")
    this.trigger?.setAttribute("aria-haspopup", "menu")
    this.onTrigger = event => { event.preventDefault(); this.open = !this.open }
    this.trigger?.addEventListener("click", this.onTrigger)
    this.menu = [...this.element.children].find(child => child !== this.trigger)
    this.prepareMenu()
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

  // The menu as Radix builds it: role menu, named by its trigger; links and buttons are menu items; a label around a
  // radio or checkbox input is a menuitemradio or menuitemcheckbox; the choices sit in a group; a label is plain text.
  prepareMenu() {
    const menu = this.menu
    if (!menu || !this.trigger) return
    if (!this.trigger.id) this.trigger.id = `dropdown-trigger-${++menus}`
    menu.setAttribute("role", "menu")
    if (!menu.hasAttribute("aria-label")) menu.setAttribute("aria-labelledby", this.trigger.id)
    for (const label of menu.querySelectorAll(":scope > p")) label.setAttribute("role", "none")
    for (const item of menu.querySelectorAll("a[href], button")) if (!item.hasAttribute("role")) item.setAttribute("role", "menuitem")
    for (const input of menu.querySelectorAll('label > input[type="radio"], label > input[type="checkbox"]')) {
      const label = input.closest("label")
      label.setAttribute("role", input.type === "radio" ? "menuitemradio" : "menuitemcheckbox")
      label.tabIndex = -1
      input.tabIndex = -1
      input.setAttribute("aria-hidden", "true")
    }
    this.syncChecked = () => {
      for (const input of menu.querySelectorAll('label > input[type="radio"], label > input[type="checkbox"]')) input.closest("label").setAttribute("aria-checked", String(input.checked))
    }
    this.syncChecked()
    menu.addEventListener("change", this.syncChecked)
    // Runs of choices go into a group, as Radix's DropdownMenuRadioGroup.
    const isChoice = child => child.matches('[role="menuitemradio"], [role="menuitemcheckbox"]') || !!child.querySelector(':scope > [role="menuitemradio"]')
    let run = []
    const wrap = () => {
      if (!run.length) return
      const group = document.createElement("div")
      group.setAttribute("role", "group")
      run[0].before(group)
      group.append(...run)
      run = []
    }
    for (const child of [...menu.children]) {
      if (child.getAttribute("role") !== "group" && isChoice(child)) run.push(child)
      else wrap()
    }
    wrap()
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
      .filter(item => item.offsetParent !== null)
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
    if ((event.key === "Enter" || event.key === " ") && event.target.matches("label[role]")) {
      event.preventDefault()
      event.target.querySelector("input")?.click()
      return
    }
    if (event.key === "ArrowDown") { event.preventDefault(); this.focusItem(items[(index + 1) % items.length]) }
    else if (event.key === "ArrowUp") { event.preventDefault(); this.focusItem(items[(index - 1 + items.length) % items.length]) }
    else if (event.key === "Home") { event.preventDefault(); this.focusItem(items[0]) }
    else if (event.key === "End") { event.preventDefault(); this.focusItem(items.at(-1)) }
    else if (event.key.length === 1 && /\S/.test(event.key) && !event.metaKey && !event.ctrlKey && !event.altKey) {
      const text = item => item.textContent.trim().toLocaleLowerCase()
      const after = [...items.slice(index + 1), ...items.slice(0, index + 1)]
      const match = after.find(item => text(item).startsWith(event.key.toLocaleLowerCase()))
      if (match) { event.preventDefault(); this.focusItem(match) }
    }
  }
}
