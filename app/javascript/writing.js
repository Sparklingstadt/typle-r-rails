// The matching rules of Typle Handwriting, ported from typle-r's src/lib/writing.ts.
import { cyrillicAlternatives, matchesCharacter } from "typing"

const SPACELESS = ["ja", "zh-Hans", "zh-Hant"]

// NFC, trimmed, runs of white space as one space; none at all for languages written without spaces.
export function normalizeWriting(text, language) {
  const composed = text.normalize("NFC")
  return SPACELESS.includes(language) ? composed.replace(/\s+/gu, "") : composed.replace(/\s+/gu, " ").trim()
}

// Reads the candidate from the front, one target character at a time; the whole candidate has to be used.
function matchesOne(candidate, target, options) {
  let p = 0
  const fold = value => options.ignoreCase ? value.toLowerCase() : value
  for (const t of target) {
    const here = candidate[p]
    if (here !== undefined && matchesCharacter(here, t, options)) {
      p += 1
      continue
    }
    if (!options.ignoreAccents) return false
    if (t === "ß" || t === "ẞ") {
      if (fold(candidate.slice(p, p + 2).join("")) !== fold(t === "ß" ? "ss" : "SS")) return false
      p += 2
      continue
    }
    const alternative = cyrillicAlternatives(options.ignoreCase ? t.toLowerCase() : t)
      .find(value => fold(candidate.slice(p, p + Array.from(value).length).join("")) === fold(value))
    if (alternative === undefined) return false
    p += Array.from(alternative).length
  }
  return p === candidate.length
}

export function matchesWriting(candidates, target, language, options = {}) {
  const expected = Array.from(normalizeWriting(target, language))
  return candidates.some(candidate => matchesOne(Array.from(normalizeWriting(candidate, language)), expected, options))
}
