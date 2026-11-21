// Configure your import map in config/importmap.rb. Read more: https://github.com/rails/importmap-rails
import { Turbo } from "@hotwired/turbo-rails"
import "controllers"
import "confirm_dialog"

// The top bar's ログイン link names the page's path, as typle-r's does; a plain click comes back with its query too.
document.addEventListener("click", event => {
  const link = event.target instanceof Element && event.target.closest("a[data-return-href]")
  if (!link || event.button !== 0 || event.metaKey || event.ctrlKey || event.shiftKey || event.altKey) return
  event.preventDefault()
  Turbo.visit(link.dataset.returnHref)
})
