import { Controller } from "@hotwired/stimulus"

// The handwriting switch of the list editor: on, the recognition language is chosen and sent; off, an empty
// writing_language is sent instead.
export default class extends Controller {
  static targets = ["switch", "language", "select"]

  toggle() {
    const on = this.switchTarget.checked
    this.languageTarget.hidden = !on
    this.selectTarget.disabled = !on
  }
}
