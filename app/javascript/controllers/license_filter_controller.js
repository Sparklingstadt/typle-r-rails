import { Controller } from "@hotwired/stimulus"

// typle-r's LicenseList filter: by name or license, with the count of what is shown.
export default class extends Controller {
  static targets = ["query", "entry", "count"]
  static values = { count: String }

  apply() {
    const query = this.queryTarget.value.trim().toLowerCase()
    let shown = 0
    this.entryTargets.forEach(entry => {
      const match = !query || entry.dataset.search.includes(query)
      entry.hidden = !match
      if (match) shown++
    })
    this.countTarget.textContent = this.countValue.replace("%{total}", this.entryTargets.length).replace("%{shown}", shown)
  }
}
