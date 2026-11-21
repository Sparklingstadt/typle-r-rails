import { Controller } from "@hotwired/stimulus"
import { message } from "practice_run"

// The lists a new pack is made of (typle-r's PackListChoices): how many are chosen, and a search over them.
export default class extends Controller {
  static targets = ["query", "item", "count", "empty"]
  static values = { chosen: Object }

  connect() { this.count() }

  count() {
    const chosen = this.itemTargets.filter(item => item.querySelector("input[type=checkbox]").checked).length
    this.countTarget.textContent = message(this.chosenValue, { count: chosen })
  }

  filter() {
    const query = this.queryTarget.value.trim().toLowerCase()
    let shown = 0
    for (const item of this.itemTargets) {
      item.hidden = !!query && !item.dataset.search.includes(query)
      if (!item.hidden) shown += 1
    }
    this.emptyTarget.hidden = shown > 0
  }
}
