import { Controller } from "@hotwired/stimulus"

// typle-r's sign-in and forgot forms: the submit button is disabled until every required field has text.
export default class extends Controller {
  static targets = ["submit"]

  connect() { this.update() }

  update() {
    const empty = [...this.element.querySelectorAll("input[required]")].some(input => !input.value.trim())
    this.submitTargets.forEach(button => { button.disabled = empty })
  }
}
