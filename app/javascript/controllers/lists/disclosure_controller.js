import { Controller } from "@hotwired/stimulus"

// A pack row that opens to show its lists (typle-r's PackRow): the button in the pack's heading shows or hides them.
export default class extends Controller {
  static targets = ["button", "panel"]

  toggle() {
    const open = this.buttonTarget.getAttribute("aria-expanded") !== "true"
    this.buttonTarget.setAttribute("aria-expanded", String(open))
    this.panelTarget.hidden = !open
  }
}
