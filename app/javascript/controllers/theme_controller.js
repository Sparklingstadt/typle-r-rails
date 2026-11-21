import { Controller } from "@hotwired/stimulus"

const KEY = "typle-r:theme:v1"
const DARK = "(prefers-color-scheme: dark)"

// The top bar's dark mode button, as typle-r's ThemeSwitcher: toggles light and dark, kept in this browser.
export default class extends Controller {
  static targets = ["button", "failed"]

  connect() {
    this.media = window.matchMedia(DARK)
    this.sync = () => { this.apply(this.preference()); this.show() }
    this.media.addEventListener("change", this.sync)
    this.show()
  }

  disconnect() { this.media.removeEventListener("change", this.sync) }

  preference() {
    const value = document.documentElement.dataset.themePreference
    return value === "light" || value === "dark" ? value : "system"
  }

  apply(preference) {
    const root = document.documentElement
    root.dataset.themePreference = preference
    root.classList.toggle("dark", preference === "dark" || (preference === "system" && this.media.matches))
  }

  toggle() {
    const preference = document.documentElement.classList.contains("dark") ? "light" : "dark"
    this.apply(preference)
    let saved = true
    try { localStorage.setItem(KEY, preference) } catch { saved = false }
    this.failedTarget.hidden = saved
    this.show()
  }

  show() {
    const dark = document.documentElement.classList.contains("dark")
    this.buttonTarget.setAttribute("aria-pressed", String(dark))
    this.buttonTarget.title = dark ? this.buttonTarget.dataset.toLight : this.buttonTarget.dataset.toDark
  }
}
