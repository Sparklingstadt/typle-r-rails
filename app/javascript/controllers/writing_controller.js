import { Controller } from "@hotwired/stimulus"
import { accuracyOf } from "typing"
import { matchesWriting, normalizeWriting } from "writing"
import { hasHandwritingModel, loadRecognizer } from "handwriting"
import { finishRun, missedWords, message, speedOf, formatClock, noteMistake, startReview, endReview, chooseList, lockControl, guardSwitches } from "practice_run"

// Typle Handwriting: copying each word's display by hand. The words are written into the field with the OS's
// handwriting input, or (for languages the app reads itself, Korean for now) drawn on the pad. A match moves on at
// once; 判定 (Enter) counts a mismatch; 飛ばす counts a mistake and moves on. As typle-r's src/lib/writing.ts.

const READ_DELAY = 600
const MIN_HEIGHT_SHARE = 0.25
const LINE_WIDTH = 4
const INPUT_KEY = "typle-r:writing-input"
let penSeen = false

export default class extends Controller {
  static targets = ["display", "annotation", "field", "fieldArea", "padArea", "canvas", "padStatus", "reading", "feedback",
                    "progress", "bar", "time", "mistakes", "accuracy", "board", "result", "resultBody", "inputSwitch", "reload",
                    "resultMissed", "speed", "padStatusText", "padHint"]
  static values = { words: Array, options: Object, language: String, saveUrl: String, weakUrl: String, listId: Number,
                    messages: Object, mode: { type: String, default: "writing" }, records: Array }

  connect() {
    this.unguard = guardSwitches(this)
    this.padAvailable = hasHandwritingModel(this.languageValue)
    let stored = null
    try { stored = localStorage.getItem(INPUT_KEY) } catch {}
    this.usePad = this.padAvailable && stored !== "field"
    this.strokes = []
    this.active = null
    this.reset()
    this.tick = setInterval(() => this.renderStats(), 100)
    this.onKey = event => this.padKey(event)
    window.addEventListener("keydown", this.onKey)
    if (this.padAvailable) this.loadPad()
  }

  disconnect() {
    this.unguard?.()
    clearInterval(this.tick)
    clearTimeout(this.timer)
    window.removeEventListener("keydown", this.onKey)
  }

  reset() {
    this.currentRun = null
    this.index = 0
    this.attempts = 0
    this.mistakes = 0
    this.startedAt = null
    this.finishedAt = null
    this.pausedAt = null
    this.wordMistakes = new Map()
    this.composing = false
    this.resultTarget.hidden = true
    this.boardTarget.hidden = false
    this.fieldTarget.disabled = false
    this.fieldTarget.value = ""
    this.clearPad()
    this.feedbackTarget.textContent = ""
    this.render()
    this.focusInput()
  }

  restart() {
    endReview(this)
    this.reset()
  }

  reviewMissed() {
    startReview(this)
    this.reset()
  }

  chooseList() { chooseList(this) }

  get word() { return this.wordsValue[this.index] }

  // --- the clock ---

  start() {
    const now = performance.now()
    if (this.pausedAt !== null) { this.startedAt += now - this.pausedAt; this.pausedAt = null }
    if (this.startedAt === null) this.startedAt = now
  }

  elapsed() {
    if (this.startedAt === null) return 0
    return Math.max(0, (this.finishedAt ?? this.pausedAt ?? performance.now()) - this.startedAt)
  }

  blur() {
    if (this.usePad) return
    if (this.startedAt !== null && !this.finishedAt && this.pausedAt === null) this.pausedAt = performance.now()
  }

  focus() {
    if (this.pausedAt !== null) { this.startedAt += performance.now() - this.pausedAt; this.pausedAt = null }
  }

  // --- judging ---

  // A match moves on. A mismatch counts only when asked for (explicit) and something was written.
  judge(candidates, explicit) {
    if (this.finishedAt || !this.word) return
    if (matchesWriting(candidates, this.word.display, this.languageValue, this.optionsValue)) {
      this.start()
      this.attempts += 1
      this.feedbackTarget.textContent = ""
      return this.advance()
    }
    const typed = candidates.find(candidate => normalizeWriting(candidate, this.languageValue) !== "")
    if (!explicit || typed === undefined) return
    this.start()
    this.attempts += 1
    this.mistakes += 1
    noteMistake(this.wordMistakes, this.index, { wrong: { typed } })
    this.feedbackTarget.textContent = this.messagesValue.readAs.replace("%{text}", typed)
    this.render()
  }

  skip() {
    if (this.finishedAt) return
    this.start()
    this.attempts += 1
    this.mistakes += 1
    noteMistake(this.wordMistakes, this.index, { skipped: true })
    this.feedbackTarget.textContent = ""
    this.advance()
  }

  advance() {
    this.fieldTarget.value = ""
    this.clearPad()
    if (this.index >= this.wordsValue.length - 1) return this.finish()
    this.index += 1
    this.render()
    this.focusInput()
  }

  finish() {
    this.finishedAt = performance.now()
    this.fieldTarget.disabled = true
    this.render()
    finishRun(this, {
      time_ms: Math.max(1, Math.round(this.elapsed())),
      mistakes: this.mistakes,
      accuracy: accuracyOf(this.attempts, this.mistakes),
      mode: this.modeValue,
      missed: missedWords(this.wordMistakes, this.wordsValue),
    })
  }

  // --- the field (OS handwriting input) ---

  compositionStart() { this.composing = true }
  compositionEnd() { this.composing = false; this.fieldInput() }

  fieldInput(event) {
    if (this.composing || event?.isComposing) return
    if (this.fieldTarget.value) this.start()
    this.judge([this.fieldTarget.value], false)
  }

  fieldKey(event) {
    if (event.isComposing) return
    if (event.key === "Enter") {
      event.preventDefault()
      if (this.fieldTarget.value.trim()) this.judge([this.fieldTarget.value], true)
    } else if (event.key === "Escape") {
      event.preventDefault()
      this.reset()
    }
  }

  check() {
    if (this.usePad) this.read(true)
    else if (this.fieldTarget.value.trim()) this.judge([this.fieldTarget.value], true)
  }

  // --- the pad ---

  // The arrow keys move to the other way of writing and choose it, as in typle-r's ModeToggle.
  inputKey(event) {
    if (!["ArrowLeft", "ArrowRight", "ArrowUp", "ArrowDown", "Home", "End"].includes(event.key)) return
    event.preventDefault()
    const other = [...this.inputSwitchTarget.querySelectorAll("[role=radio]")].find(radio => radio !== event.currentTarget)
    other?.focus()
    other?.click()
  }

  chooseInput(event) {
    this.usePad = event.params.input === "pad"
    try { this.usePad ? localStorage.removeItem(INPUT_KEY) : localStorage.setItem(INPUT_KEY, "field") } catch {}
    this.render()
    this.focusInput()
  }

  loadPad() {
    this.padStatus = "loading"
    this.render()
    loadRecognizer(this.languageValue).then(
      recognizer => { this.recognizer = recognizer; this.padStatus = "ready"; this.render() },
      error => { console.error(error); this.padStatus = "failed"; this.render() })
  }

  padKey(event) {
    if (!this.usePad || this.finishedAt || event.defaultPrevented || event.isComposing) return
    if (event.target.closest?.("input, textarea, select, button, dialog")) return
    if (event.key === "Enter") { event.preventDefault(); if (this.padStatus === "ready") this.read(true) }
    else if (event.key === "Escape") { event.preventDefault(); this.reset() }
    else if (event.key.toLowerCase() === "z" && (event.metaKey || event.ctrlKey) && !event.shiftKey) { event.preventDefault(); this.undo() }
  }

  point(event) {
    const box = this.canvasTarget.getBoundingClientRect()
    return { x: event.clientX - box.left, y: event.clientY - box.top }
  }

  down(event) {
    if (this.padStatus !== "ready" || this.active || this.finishedAt) return
    if (event.pointerType === "pen") penSeen = true
    else if (event.pointerType === "touch" && penSeen) return // a hand resting on the screen
    if (event.pointerType === "mouse" && event.button !== 0) return
    event.preventDefault()
    this.canvasTarget.setPointerCapture(event.pointerId)
    clearTimeout(this.timer)
    this.reading = (this.reading ?? 0) + 1
    this.start()
    this.active = { id: event.pointerId, stroke: [this.point(event)] }
    this.draw()
  }

  move(event) {
    if (!this.active || this.active.id !== event.pointerId) return
    event.preventDefault()
    this.active.stroke.push(this.point(event))
    this.draw()
  }

  up(event) {
    if (!this.active || this.active.id !== event.pointerId) return
    this.strokes.push(this.active.stroke)
    this.active = null
    this.draw()
    this.renderPadHint()
    clearTimeout(this.timer)
    this.timer = setTimeout(() => this.read(false), READ_DELAY)
  }

  preventMenu(event) { event.preventDefault() }

  undo() {
    this.strokes.pop()
    this.draw()
    this.renderPadHint()
    this.readingTarget.textContent = ""
  }

  clearPad() {
    this.strokes = []
    this.active = null
    clearTimeout(this.timer)
    if (this.hasCanvasTarget) this.draw()
    if (this.hasReadingTarget) this.readingTarget.textContent = ""
    this.renderPadHint()
  }

  async read(explicit) {
    clearTimeout(this.timer)
    const number = this.reading = (this.reading ?? 0) + 1
    if (!this.recognizer) return
    if (this.strokes.length === 0) return
    try {
      const { text } = await this.recognizer.read(this.strokes, {
        minHeight: this.canvasTarget.clientHeight * MIN_HEIGHT_SHARE, lineWidth: LINE_WIDTH, expected: this.word.display,
      })
      if (number !== this.reading) return // newer strokes came in
      this.readingTarget.textContent = text ? this.messagesValue.reading.replace("%{text}", text) : ""
      this.judge([text], explicit)
    } catch (error) {
      console.error(error)
      this.padStatus = "failed"
      this.render()
    }
  }

  draw() {
    // 1画戻す and 消す have nothing to do on an empty pad (as typle-r).
    this.element.querySelectorAll('[data-action="writing#undo"], [data-action="writing#clearPad"]').forEach(button => {
      button.disabled = this.strokes.length === 0 && !this.active
    })
    const canvas = this.canvasTarget
    const ratio = window.devicePixelRatio || 1
    const width = canvas.clientWidth, height = canvas.clientHeight
    if (canvas.width !== Math.round(width * ratio)) { canvas.width = Math.round(width * ratio); canvas.height = Math.round(height * ratio) }
    const context = canvas.getContext("2d")
    context.setTransform(ratio, 0, 0, ratio, 0, 0)
    context.clearRect(0, 0, width, height)
    context.strokeStyle = getComputedStyle(canvas).color
    context.lineWidth = LINE_WIDTH
    context.lineCap = "round"
    context.lineJoin = "round"
    for (const stroke of [...this.strokes, ...(this.active ? [this.active.stroke] : [])]) {
      context.beginPath()
      context.moveTo(stroke[0].x, stroke[0].y)
      for (const point of stroke.slice(1)) context.lineTo(point.x, point.y)
      if (stroke.length === 1) context.lineTo(stroke[0].x + 0.1, stroke[0].y)
      context.stroke()
    }
  }

  // --- view ---

  focusInput() {
    if (!this.usePad) this.fieldTarget.focus()
  }

  render() {
    // A run going on locks the device and the recall switch (typle-r's PracticeHeader `running`).
    const running = this.startedAt !== null && !this.finishedAt
    this.element.dataset.running = String(running)
    this.element.querySelectorAll("[data-lock-while-running]").forEach(control => lockControl(control, running))
    const word = this.word
    this.displayTarget.textContent = word.display
    this.annotationTarget.textContent = word.annotation || ""
    this.fieldTarget.lang = this.languageValue
    this.fieldAreaTarget.hidden = this.usePad
    this.padAreaTarget.hidden = !this.usePad
    this.inputSwitchTarget.hidden = !this.padAvailable
    this.inputSwitchTarget.querySelectorAll("[data-writing-input-param]").forEach(button => {
      const chosen = (button.dataset.writingInputParam === "pad") === this.usePad
      button.setAttribute("aria-checked", String(chosen))
      button.tabIndex = chosen ? 0 : -1
    })
    const m = this.messagesValue
    const status = this.padStatus === "loading" ? (m.writingPadLoading ?? m.padLoading) : this.padStatus === "failed" ? (m.writingPadFailed ?? m.padFailed) : ""
    if (this.hasPadStatusTextTarget) {
      this.padStatusTextTarget.textContent = status
      this.padStatusTarget.hidden = !status
    } else {
      this.padStatusTarget.textContent = status
    }
    this.reloadTarget.hidden = this.padStatus !== "failed"
    this.renderPadHint()
    const total = this.wordsValue.length
    const done = this.finishedAt ? total : this.index
    const current = this.finishedAt ? total : this.index + 1
    this.progressTarget.textContent = m.progressValue ? message(m.progressValue, { current, count: total }) : `${done} / ${total}`
    this.barTarget.style.width = `${done / total * 100}%`
    // typle-r's PracticeProgress: the bar carries the numbers; the text beside it is only for the eye.
    const bar = this.barTarget.parentElement
    bar.setAttribute("aria-valuenow", done)
    bar.setAttribute("aria-valuetext", this.progressTarget.textContent)
    this.renderStats()
  }

  // "ここに書く" on the empty pad, once it is ready.
  renderPadHint() {
    if (this.hasPadHintTarget) this.padHintTarget.hidden = this.padStatus !== "ready" || this.strokes.length > 0 || this.active !== null
  }

  renderStats() {
    const elapsed = this.elapsed()
    this.timeTarget.textContent = this.hasSpeedTarget ? formatClock(elapsed) : `${(elapsed / 1000).toFixed(1)}${this.messagesValue.seconds}`
    if (this.hasSpeedTarget) {
      const speed = this.startedAt === null ? null : speedOf(this.attempts - this.mistakes, elapsed)
      this.speedTarget.textContent = speed === null ? "—" : String(speed)
    }
    this.mistakesTarget.textContent = String(this.mistakes)
    this.accuracyTarget.textContent = this.attempts || !this.hasSpeedTarget ? `${Math.round(accuracyOf(this.attempts, this.mistakes) * 10) / 10}%` : "—"
  }
}

