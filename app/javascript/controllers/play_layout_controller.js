import { Controller } from "@hotwired/stimulus"

// The practice header's eye and panel buttons: show or hide the live stats and the side panel, remembered per browser
// with typle-r's keys (typle-r:live-stats = "hidden", typle-r:play-aside = "collapsed"; nothing stored when shown).
export default class extends Controller {
  static targets = ["statsButton", "asideButton"]

  connect() { this.show() }

  toggleStats() { this.flip("liveStats", "typle-r:live-stats", "hidden", "shown") }
  toggleAside() { this.flip("playAside", "typle-r:play-aside", "collapsed", "open") }

  flip(name, key, off, on) {
    const root = document.documentElement
    const next = root.dataset[name] === off ? on : off
    root.dataset[name] = next
    try { next === off ? localStorage.setItem(key, off) : localStorage.removeItem(key) } catch {}
    this.show()
    this.element.querySelector("[data-practice-target=field], [data-writing-target=field]:not([hidden])")?.focus()
  }

  show() {
    const root = document.documentElement
    if (this.hasStatsButtonTarget) this.statsButtonTarget.setAttribute("aria-pressed", String(root.dataset.liveStats !== "hidden"))
    if (this.hasAsideButtonTarget) this.asideButtonTarget.setAttribute("aria-pressed", String(root.dataset.playAside !== "collapsed"))
  }
}
