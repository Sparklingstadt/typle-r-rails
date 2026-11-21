import { Controller } from "@hotwired/stimulus"

// The button that opens typle-r's ListPickerDialog, and the dialog: a click on the backdrop, Esc or the X closes it, the
// search is cleared on closing, and the focus goes back to the trigger (or, on the practice screen, to the practice).
export default class extends Controller {
  static targets = ["dialog", "trigger"]
  static values = { returnFocus: String }

  open() {
    this.dialogTarget.showModal()
  }

  close() {
    if (this.dialogTarget.open) this.dialogTarget.close()
  }

  backdrop(event) {
    if (event.target === this.dialogTarget) this.close()
  }

  closed() {
    const query = this.dialogTarget.querySelector("input[type=search]")
    if (query && query.value) {
      query.value = ""
      query.dispatchEvent(new Event("input", { bubbles: true }))
    }
    const target = this.returnFocusValue ? document.querySelector(this.returnFocusValue) : null
    ;(target && target.offsetParent !== null ? target : this.hasTriggerTarget ? this.triggerTarget : null)?.focus()
  }
}
