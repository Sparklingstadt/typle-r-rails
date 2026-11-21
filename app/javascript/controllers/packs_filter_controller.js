import { Controller } from "@hotwired/stimulus"
import { message } from "practice_run"

// The packs page's toolbar (typle-r's ListToolbar): narrows the packs by text, by one category and by every chosen
// tag, and says how many are shown.
export default class extends Controller {
  static targets = ["query", "category", "categoryText", "categoryTrigger", "tag", "tagsText", "tagsTrigger", "pack", "list", "empty", "count", "clear"]
  static values = { count: Object, filtered: Object, allCategories: String, noCategory: String, allTags: String, separator: String, categoryCurrent: String, tagsCurrent: String }

  apply() {
    const query = this.queryTarget.value.trim().toLowerCase()
    const category = this.categoryTargets.find(input => input.checked)?.value ?? ""
    const tags = this.tagTargets.filter(input => input.checked).map(input => input.value.toLowerCase())
    let shown = 0
    for (const pack of this.packTargets) {
      const own = JSON.parse(pack.dataset.tags || "[]").map(tag => tag.toLowerCase())
      const fits = (!query || pack.dataset.search.includes(query)) &&
        (!category || (category === "none" ? !pack.dataset.category : category === `category:${pack.dataset.category}`)) &&
        tags.every(tag => own.includes(tag))
      pack.hidden = !fits
      if (fits) shown += 1
    }
    const total = this.packTargets.length
    const narrowed = shown !== total
    // typle-r's plurals are on `total` (and `shown`); the forms come as they are, chosen here by that number.
    this.countTarget.textContent = narrowed ? message(this.filteredValue, { count: shown, shown, total }) : message(this.countValue, { count: total, total })
    this.listTarget.hidden = shown === 0
    this.emptyTarget.hidden = shown !== 0
    const filtered = !!category || tags.length > 0
    this.clearTarget.hidden = !filtered
    if (this.hasCategoryTextTarget) {
      this.categoryTextTarget.textContent = this.categoryTargets.find(input => input.checked)?.dataset.text ?? this.allCategoriesValue
      this.categoryTriggerTarget.setAttribute("aria-label", message(this.categoryCurrentValue, { category: this.categoryTextTarget.textContent }))
      this.categoryTriggerTarget.classList.toggle("border-primary/60", !!category)
    }
    if (this.hasTagsTextTarget) {
      const chosen = this.tagTargets.filter(input => input.checked).map(input => input.value)
      this.tagsTextTarget.textContent = chosen.length ? chosen.join(this.separatorValue) : this.allTagsValue
      this.tagsTriggerTarget.setAttribute("aria-label", chosen.length ? message(this.tagsCurrentValue, { tags: chosen.join(this.separatorValue) }) : this.allTagsValue)
      this.tagsTriggerTarget.classList.toggle("border-primary/60", chosen.length > 0)
    }
  }

  clear() {
    this.queryTarget.value = ""
    this.categoryTargets.forEach(input => { input.checked = input.value === "" })
    this.tagTargets.forEach(input => { input.checked = false })
    this.apply()
  }
}
