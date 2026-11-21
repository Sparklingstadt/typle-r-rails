import { Controller } from "@hotwired/stimulus"

// typle-r's useRowHighlight: the row a save points at is scrolled into view and lit for a moment.
export default class extends Controller {
  static values = { classes: String }

  connect() {
    this.element.scrollIntoView({ block: "nearest" })
    this.timer = setTimeout(() => this.element.classList.remove(...this.classesValue.split(" ")), 2400)
  }

  disconnect() { clearTimeout(this.timer) }
}
