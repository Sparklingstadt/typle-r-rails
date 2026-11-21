import { Controller } from "@hotwired/stimulus"

// typle-r's TrendChart reading: the plot is a slider over the runs. Pointing at it or moving with ←/→ (Home/End) shows a
// run's value and date in a tooltip with a guide line, and the slider reads it out; focus starts on the latest run.
export default class extends Controller {
  static targets = ["dot", "cursor", "tooltip", "tooltipValue", "tooltipDate"]
  static values = { points: Array }

  connect() {
    this.active = null
    this.render()
  }

  get last() { return this.pointsValue.length - 1 }
  get shown() { return this.active ?? this.last }

  focus() { this.active = this.last; this.render() }
  blur() { this.active = null; this.render() }
  leave() { this.active = null; this.render() }

  point(event) {
    const box = this.element.getBoundingClientRect()
    this.active = Math.min(this.last, Math.max(0, Math.round((event.clientX - box.left) / box.width * this.last)))
    this.render()
  }

  key(event) {
    const next = { ArrowLeft: this.shown - 1, ArrowRight: this.shown + 1, Home: 0, End: this.last }[event.key]
    if (next === undefined) return
    event.preventDefault()
    this.active = Math.min(this.last, Math.max(0, next))
    this.render()
  }

  render() {
    const point = this.pointsValue[this.shown]
    if (!point) return
    this.element.setAttribute("aria-valuenow", String(this.shown + 1))
    this.element.setAttribute("aria-valuetext", `${point.date} ${point.value}`)
    this.dotTarget.style.left = `${point.x}%`
    this.dotTarget.style.top = `${point.y}%`
    const active = this.active !== null
    this.cursorTarget.style.display = active ? "" : "none"
    this.tooltipTarget.hidden = !active
    if (!active) return
    this.cursorTarget.setAttribute("x1", point.x)
    this.cursorTarget.setAttribute("x2", point.x)
    this.tooltipValueTarget.textContent = point.value
    this.tooltipDateTarget.textContent = point.date
    this.tooltipTarget.style.left = `${point.x}%`
    this.tooltipTarget.style.transform = `translateX(${point.x < 25 ? "-8px" : point.x > 75 ? "calc(-100% + 8px)" : "-50%"})`
  }
}
