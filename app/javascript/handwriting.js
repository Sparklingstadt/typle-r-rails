// Reading handwriting drawn on the pad, in the browser: the strokes become one text line image read by PaddleOCR's
// Korean recognition model with onnxruntime-web (public/handwriting). Ported from typle-r's src/lib/handwriting.ts and
// src/lib/handwritingRecognizer.ts.

export const LINE_HEIGHT = 48
const LINE_PADDING = 4
const MAX_LINE_WIDTH = 1280
// How much less likely than the best reading the expected text may be and still count as written (see typle-r).
export const ACCEPT_MARGIN = 3

const MODELS = {
  ko: { model: "/handwriting/ko/korean_PP-OCRv5_mobile_rec.onnx", dictionary: "/handwriting/ko/ppocrv5_korean_dict.txt" },
}

export function hasHandwritingModel(language) { return language in MODELS }

export function inkBounds(strokes) {
  let x0 = Infinity, y0 = Infinity, x1 = -Infinity, y1 = -Infinity
  for (const stroke of strokes) for (const { x, y } of stroke) {
    x0 = Math.min(x0, x); x1 = Math.max(x1, x); y0 = Math.min(y0, y); y1 = Math.max(y1, y)
  }
  return x0 === Infinity ? null : { x: x0, y: y0, width: x1 - x0, height: y1 - y0 }
}

export function inkLayout(bounds, minHeight) {
  const inner = LINE_HEIGHT - 2 * LINE_PADDING
  const height = Math.max(bounds.height, minHeight, 1)
  const scale = Math.min(inner / height, (MAX_LINE_WIDTH - 2 * LINE_PADDING) / Math.max(bounds.width, 1))
  const width = Math.max(Math.ceil(bounds.width * scale) + 2 * LINE_PADDING, 2 * LINE_HEIGHT)
  const top = (LINE_HEIGHT - bounds.height * scale) / 2
  return { width, scale, map: ({ x, y }) => ({ x: LINE_PADDING + (x - bounds.x) * scale, y: top + (y - bounds.y) * scale }) }
}

export function lineTensor(rgba, width) {
  const size = LINE_HEIGHT * width
  const data = new Float32Array(3 * size)
  for (let i = 0; i < size; i++) {
    for (let c = 0; c < 3; c++) data[c * size + i] = rgba[i * 4 + 2 - c] / 127.5 - 1 // BGR
  }
  return data
}

export function recognitionClasses(dictionary) {
  return ["", ...dictionary.split(/\r?\n/u).filter(line => line !== ""), " "]
}

const logOf = p => Math.log(Math.max(p, 1e-12))

export function readBestPath({ probabilities, steps, classes: count }, classes) {
  let text = "", previous = -1, logProbability = 0
  for (let t = 0; t < steps; t++) {
    let best = 0, bestValue = -1
    for (let c = 0; c < count; c++) {
      const value = probabilities[t * count + c]
      if (value > bestValue) { bestValue = value; best = c }
    }
    logProbability += logOf(bestValue)
    if (best !== previous && best !== 0) text += classes[best] ?? ""
    previous = best
  }
  return { text: text.normalize("NFC"), logProbability }
}

function addLog(a, b) {
  if (a === -Infinity) return b
  if (b === -Infinity) return a
  return Math.max(a, b) + Math.log1p(Math.exp(-Math.abs(a - b)))
}

// The log-probability that the model read exactly `text`, by the CTC forward algorithm.
export function textLogProbability({ probabilities, steps, classes: count }, classes, text) {
  const index = new Map(classes.map((character, i) => [character, i]))
  const labels = []
  for (const character of text.normalize("NFC")) {
    const label = index.get(character)
    if (label === undefined || label === 0) return -Infinity
    labels.push(label)
  }
  const extended = [0]
  for (const label of labels) extended.push(label, 0)
  const at = (t, c) => logOf(probabilities[t * count + c])
  let alpha = extended.map(() => -Infinity)
  alpha[0] = at(0, extended[0])
  if (extended.length > 1) alpha[1] = at(0, extended[1])
  for (let t = 1; t < steps; t++) {
    alpha = extended.map((label, s) => {
      let value = alpha[s]
      if (s > 0) value = addLog(value, alpha[s - 1])
      if (s > 1 && label !== 0 && label !== extended[s - 2]) value = addLog(value, alpha[s - 2])
      return value + at(t, label)
    })
  }
  const last = extended.length - 1
  return addLog(alpha[last], last > 0 ? alpha[last - 1] : -Infinity)
}

export function readHandwriting(output, classes, expected) {
  const best = readBestPath(output, classes)
  const text = best.text.trim()
  if (expected === undefined) return { text, accepted: false }
  const wanted = expected.normalize("NFC").trim()
  const spaceless = value => value.replace(/\s+/gu, "")
  if (spaceless(text) === spaceless(wanted)) return { text: wanted, accepted: true }
  const bestScore = Math.max(best.logProbability, textLogProbability(output, classes, best.text))
  const wantedScore = Math.max(textLogProbability(output, classes, wanted), textLogProbability(output, classes, spaceless(wanted)))
  const accepted = wantedScore >= bestScore - ACCEPT_MARGIN
  return { text: accepted ? wanted : text, accepted }
}

const loading = new Map()

// The recogniser for the language, loaded once per visit; a failed load is forgotten so the next call tries again.
export function loadRecognizer(language) {
  const model = MODELS[language]
  if (!model) return Promise.reject(new Error(`No handwriting model for ${language}`))
  let recognizer = loading.get(language)
  if (!recognizer) {
    recognizer = load(model)
    recognizer.catch(() => loading.delete(language))
    loading.set(language, recognizer)
  }
  return recognizer
}

async function load({ model, dictionary }) {
  const ort = await import("/handwriting/ort/ort.wasm.bundle.min.mjs")
  ort.env.wasm.wasmPaths = "/handwriting/ort/"
  ort.env.wasm.numThreads = 1
  const [session, classes] = await Promise.all([
    fetch(model).then(response => {
      if (!response.ok) throw new Error(`Handwriting model: HTTP ${response.status}`)
      return response.arrayBuffer()
    }).then(buffer => ort.InferenceSession.create(buffer, { executionProviders: ["wasm"] })),
    fetch(dictionary).then(response => {
      if (!response.ok) throw new Error(`Handwriting dictionary: HTTP ${response.status}`)
      return response.text()
    }).then(recognitionClasses),
  ])
  return {
    async read(strokes, { minHeight, lineWidth, expected }) {
      const bounds = inkBounds(strokes)
      if (!bounds) return { text: "", accepted: false }
      const layout = inkLayout(bounds, minHeight)
      const canvas = document.createElement("canvas")
      canvas.width = layout.width
      canvas.height = LINE_HEIGHT
      const context = canvas.getContext("2d", { willReadFrequently: true })
      drawLine(context, strokes, layout, lineWidth)
      const pixels = context.getImageData(0, 0, layout.width, LINE_HEIGHT).data
      const input = new ort.Tensor("float32", lineTensor(pixels, layout.width), [1, 3, LINE_HEIGHT, layout.width])
      const outputs = await session.run({ [session.inputNames[0]]: input })
      const result = outputs[session.outputNames[0]]
      const [, steps, count] = result.dims
      return readHandwriting({ probabilities: result.data, steps, classes: count }, classes, expected)
    },
  }
}

function drawLine(context, strokes, layout, lineWidth) {
  context.fillStyle = "#fff"
  context.fillRect(0, 0, layout.width, LINE_HEIGHT)
  context.strokeStyle = "#000"
  context.fillStyle = "#000"
  context.lineCap = "round"
  context.lineJoin = "round"
  context.lineWidth = Math.max(lineWidth * layout.scale, 2.5)
  for (const stroke of strokes) {
    const points = stroke.map(layout.map)
    if (points.length === 1) {
      context.beginPath()
      context.arc(points[0].x, points[0].y, context.lineWidth / 2, 0, Math.PI * 2)
      context.fill()
      continue
    }
    context.beginPath()
    context.moveTo(points[0].x, points[0].y)
    for (const point of points.slice(1)) context.lineTo(point.x, point.y)
    context.stroke()
  }
}
