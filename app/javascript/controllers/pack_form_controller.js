import { Controller } from "@hotwired/stimulus"
import { Turbo } from "@hotwired/turbo-rails"
import { confirmDialog } from "confirm_dialog"

// typle-r's PackEditor: the save bar says whether anything changed, and leaving with changes asks first
// (DiscardChangesDialog, useUnsavedWarning).
export default class extends Controller {
  static targets = ["dirty", "dirtyDot", "clean"]
  static values = { labels: Object }

  connect() {
    // The pickers and the order fill their fields as they connect, so the first state is taken once they have.
    requestAnimationFrame(() => { this.initial = this.snapshot(); this.changed() })
  }

  snapshot() {
    return JSON.stringify([...new FormData(this.element)].filter(([name]) => name !== "authenticity_token" && name !== "_method"))
  }

  get dirty() { return this.initial !== undefined && this.snapshot() !== this.initial }

  changed() {
    if (!this.hasDirtyTarget) return
    const dirty = this.dirty
    this.dirtyTarget.hidden = !dirty
    this.dirtyDotTarget.hidden = !dirty
    this.cleanTarget.hidden = dirty
  }

  submitting() { this.saving = true }

  unload(event) { if (this.dirty && !this.saving) event.preventDefault() }

  leave(event) {
    if (!this.dirty || this.saving) return
    event.preventDefault()
    const l = this.labelsValue
    confirmDialog({ title: l.discard, description: l.discardDescription, cancel: l.keepEditing, action: l.discardAction })
      .then(ok => { if (ok) { this.saving = true; Turbo.visit(event.detail.url) } })
  }
}
