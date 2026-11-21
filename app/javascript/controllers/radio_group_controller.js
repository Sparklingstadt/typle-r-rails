import { Controller } from "@hotwired/stimulus"
import { Turbo } from "@hotwired/turbo-rails"

// typle-r's ModeToggle (Radix RadioGroup): a row of radio buttons. Only the chosen one is in the tab order; the arrow
// keys, Home and End move to another and choose it. Choosing one goes to its data-url, so the page shows that choice.
export default class extends Controller {
  static targets = ["radio"]

  choose(event) {
    const radio = event.currentTarget
    if (radio.disabled || radio.getAttribute("aria-checked") === "true") return
    Turbo.visit(radio.dataset.url)
  }

  key(event) {
    const radios = this.radioTargets.filter(radio => !radio.disabled)
    const index = radios.indexOf(event.currentTarget)
    const next = { ArrowRight: index + 1, ArrowDown: index + 1, ArrowLeft: index - 1, ArrowUp: index - 1, Home: 0, End: radios.length - 1 }[event.key]
    if (next === undefined) return
    event.preventDefault()
    const target = radios[(next + radios.length) % radios.length]
    target.focus()
    target.click()
  }
}
