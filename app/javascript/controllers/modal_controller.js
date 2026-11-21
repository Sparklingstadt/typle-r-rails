import { Controller } from "@hotwired/stimulus"
import { Turbo } from "@hotwired/turbo-rails"

// A dialog the page opens as it shows (typle-r's Dialog over its page): Esc, the X and キャンセル close it and go back to
// the page without it.
export default class extends Controller {
  static values = { closeUrl: String }

  connect() {
    if (!this.element.open) this.element.showModal()
    this.onClose = () => { if (!this.leaving) Turbo.visit(this.closeUrlValue, { action: "replace" }) }
    this.element.addEventListener("close", this.onClose)
  }

  disconnect() {
    this.element.removeEventListener("close", this.onClose)
  }

  close() { this.element.close() }
}
