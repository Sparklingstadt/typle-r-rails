// Character matching for practice, ported from typle-r's src/lib/typing.ts.

export const cyrillicLatin = {
  а: "a", б: "b", в: "v", г: "g", д: "d", е: "e", ё: "yo", ж: "zh", з: "z",
  и: "i", й: "y", к: "k", л: "l", м: "m", н: "n", о: "o", п: "p", р: "r",
  с: "s", т: "t", у: "u", ф: "f", х: "kh", ц: "ts", ч: "ch", ш: "sh", щ: "shch",
  ъ: '"', ы: "y", ь: "'", э: "e", ю: "yu", я: "ya",
}

// A Latin letter with its accents taken off, or null for anything else (kana such as が are not folded).
export function latinBase(char) {
  const base = char.normalize("NFD").replace(/\p{M}/gu, "")
  return /^\p{Script=Latin}$/u.test(base) ? base : null
}

export function cyrillicAlternatives(target) {
  const lower = target.toLowerCase()
  const latin = cyrillicLatin[lower]
  if (!latin) return []
  // Capital letters accept title case (Sh) and all caps (SH).
  return target === lower ? [latin] : [latin[0].toUpperCase() + latin.slice(1), latin.toUpperCase()]
}

// The characters of `text` that simple input lets you type with other keys, each once and in order, with the key to press:
// [["é", "e"], ["ш", "sh"]]. Capitals show their title case (Ш → Sh).
export function simpleInputKeys(text) {
  const keys = new Map()
  for (const char of Array.from(text)) {
    if (keys.has(char)) continue
    const key = char === "ß" ? "ss" : char === "¿" ? "?" : cyrillicAlternatives(char)[0] ?? latinBase(char)
    if (key && key !== char) keys.set(char, key)
  }
  return [...keys]
}

export function matchesCharacter(typed, target, options = {}) {
  if (options.ignoreCase) {
    typed = typed.toLowerCase()
    target = target.toLowerCase()
  }
  if (typed === target) return true
  if (!options.ignoreAccents) return false
  if (target === "¿" && typed === "?") return true
  if (cyrillicAlternatives(target).includes(typed)) return true
  return latinBase(target) === typed
}

// The keys simple input accepts for a target that takes more than one key (ш → sh, ß → ss), or [].
export function multiKeyAlternatives(target, options = {}) {
  if (!options.ignoreAccents) return []
  const alternatives = target === "ß" ? ["ss"] : cyrillicAlternatives(target).filter(key => key.length > 1)
  return options.ignoreCase ? alternatives.map(key => key.toLowerCase()) : alternatives
}

// Feeds one key to a word in progress. `pending` holds keys of a multi-key letter typed so far.
// Returns "accept" (the letter is done), "pending" (more keys to come) or "miss".
export function feedKey(key, target, pending, options = {}) {
  const typed = options.ignoreCase ? (pending + key).toLowerCase() : pending + key
  const alternatives = multiKeyAlternatives(target, options)
  if (alternatives.includes(typed)) return "accept"
  if (alternatives.some(alternative => alternative.startsWith(typed))) return "pending"
  if (!pending && matchesCharacter(key, target, options)) return "accept"
  return "miss"
}

export function accuracyOf(attempts, mistakes) {
  return attempts ? Math.round((attempts - mistakes) / attempts * 10000) / 100 : 100
}
