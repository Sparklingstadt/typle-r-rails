import { Controller } from "@hotwired/stimulus"

// typle-r's Toast: slides in from below, closes by itself after five seconds unless pointed at or focused.
export default class extends Controller {
  connect() {
    // The starting place is laid out first, so the slide plays (a frame callback would wait in a hidden tab).
    void this.element.offsetHeight
    this.element.classList.remove("translate-y-4", "opacity-0")
    this.held = false
    this.schedule()
  }

  disconnect() { clearTimeout(this.timer) }

  schedule() {
    clearTimeout(this.timer)
    if (!this.held) this.timer = setTimeout(() => this.close(), 5000)
  }

  hold() { this.held = true; clearTimeout(this.timer) }

  release(event) {
    if (event?.type === "focusout" && this.element.contains(event.relatedTarget)) return
    this.held = false
    this.schedule()
  }

  close() {
    clearTimeout(this.timer)
    this.element.classList.add("translate-y-4", "opacity-0", "pointer-events-none")
    setTimeout(() => this.element.remove(), 300)
  }
}
