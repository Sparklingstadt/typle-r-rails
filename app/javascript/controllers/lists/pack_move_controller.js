import { Controller } from "@hotwired/stimulus"

// typle-r's packWillBeDeleted: moving the only list of a pack to another pack says the pack goes.
export default class extends Controller {
  static targets = ["note"]
  static values = { original: String }

  changed(event) {
    if (!this.hasNoteTarget) return
    this.noteTarget.hidden = event.target.value === this.originalValue
    const select = event.target
    select.setAttribute("aria-describedby", this.noteTarget.hidden ? "word_list_pack_help" : "word_list_pack_deleted word_list_pack_help")
  }
}
