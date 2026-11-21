import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  submit() { this.element.requestSubmit() }

  // A button that opens the form's file picker (the file input itself stays out of sight and out of the tab order).
  pick() { this.element.querySelector("input[type=file]")?.click() }
}
