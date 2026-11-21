import { Controller } from "@hotwired/stimulus"

// Below 1280px the sidebar becomes a modal drawer: Esc, the backdrop or a link closes it and focus returns to the
// menu button (typle-r's MobileNav).
export default class extends Controller {
  static targets = ["drawer", "panel", "opener"]

  connect() {
    this.onKey = event => { if (event.key === "Escape") this.close() }
    this.desktop = window.matchMedia("(min-width: 1280px)")
    this.onWide = () => { if (this.desktop.matches) this.close() }
    this.desktop.addEventListener("change", this.onWide)
    this.panelTarget.addEventListener("click", event => { if (event.target.closest("a")) this.close() })
  }

  disconnect() {
    document.removeEventListener("keydown", this.onKey)
    this.desktop.removeEventListener("change", this.onWide)
  }

  open() {
    this.drawerTarget.hidden = false
    this.openerTarget.setAttribute("aria-expanded", "true")
    document.addEventListener("keydown", this.onKey)
    this.panelTarget.querySelector("a, button")?.focus()
  }

  close() {
    if (this.drawerTarget.hidden) return
    this.drawerTarget.hidden = true
    this.openerTarget.setAttribute("aria-expanded", "false")
    document.removeEventListener("keydown", this.onKey)
    this.openerTarget.focus()
  }
}
