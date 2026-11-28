import { Controller } from "@hotwired/stimulus"

// The words of the user's lists by list id, lowercased, as the page carries them once (practice/_aside).
const wordsCache = new WeakMap()
function listWords() {
  const script = document.getElementById("list-search-words")
  if (!script) return {}
  if (!wordsCache.has(script)) wordsCache.set(script, JSON.parse(script.textContent))
  return wordsCache.get(script)
}

// An item is found by its names and labels (data-search) or by a word of one of its lists (data-list-ids).
function matches(item, query, words) {
  if (item.dataset.search.includes(query)) return true
  return (item.dataset.listIds || "").split(" ").some(id => words[id]?.includes(query))
}

// The practice screen's list panel (typle-r's ListChooserAside): narrows the packs by text and category, opens a pack to
// choose its list, and keeps the chosen list in view inside its own scroll area.
export default class extends Controller {
  static targets = ["query", "category", "pack", "scroller", "empty"]

  connect() {
    const chosen = this.scrollerTarget.querySelector('[aria-pressed="true"]')
    if (chosen) {
      const box = this.scrollerTarget
      const top = chosen.offsetTop - box.offsetTop
      if (top < box.scrollTop || top + chosen.offsetHeight > box.scrollTop + box.clientHeight) box.scrollTop = top - 8
    }
  }

  go(event) {
    const url = event.currentTarget.dataset.url
    window.Turbo ? window.Turbo.visit(url) : (window.location.href = url)
  }

  toggle(event) {
    const button = event.currentTarget
    this.setOpen(button, button.getAttribute("aria-expanded") !== "true")
  }

  setOpen(button, open) {
    button.setAttribute("aria-expanded", String(open))
    button.querySelector("svg.lucide-chevron-down")?.classList.toggle("rotate-180", open)
    document.getElementById(button.getAttribute("aria-controls")).hidden = !open
  }

  filter() {
    const query = this.queryTarget.value.trim().toLowerCase()
    const category = this.hasCategoryTarget ? this.categoryTarget.value : ""
    const words = query ? listWords() : {}
    let shown = 0
    for (const pack of this.packTargets) {
      const inCategory = !category || (category === "none" ? !pack.dataset.category : category === `category:${pack.dataset.category}`)
      const found = !query || matches(pack, query, words)
      pack.hidden = !(inCategory && found)
      if (!pack.hidden) shown += 1
      // A pack found by one of its lists opens to show which.
      const levels = pack.querySelectorAll("[role=group] li[data-search]")
      levels.forEach(item => {
        const button = item.querySelector("button")
        if (query && matches(item, query, words)) button.dataset.match = ""
        else delete button.dataset.match
      })
      const toggle = pack.querySelector(":scope > button[aria-expanded]")
      if (toggle && query && [...levels].some(item => matches(item, query, words))) this.setOpen(toggle, true)
    }
    this.emptyTarget.hidden = shown > 0
  }
}
