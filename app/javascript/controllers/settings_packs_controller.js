import { Controller } from "@hotwired/stimulus"
import { confirmDialog } from "confirm_dialog"

// 関心に合う公式パック, as typle-r's InterestPacks: a switch per pack (follow[]), a checkbox per pack to pick it, the bar
// that follows or unfollows the picked packs at once, and a confirmation before a change that unfollows a pack.
export default class extends Controller {
  static targets = ["switch", "check", "all", "count", "follow", "unfollow", "add"]
  static values = { counts: Array, title: String, description: String, separator: String, quote: String, delete: String, followLabel: String, unfollowLabel: String, addLabel: String }

  connect() { this.update() }

  update() {
    const picked = this.checkTargets.filter(check => check.checked)
    if (this.hasAllTarget) {
      this.allTarget.checked = picked.length > 0 && picked.length === this.checkTargets.length
      this.allTarget.indeterminate = picked.length > 0 && picked.length < this.checkTargets.length
    }
    if (this.hasCountTarget) this.countTarget.textContent = this.countsValue[picked.length] ?? ""
    const switches = picked.map(check => this.switchFor(check))
    if (this.hasFollowTarget) this.followTarget.disabled = !switches.some(item => !this.followed(item))
    if (this.hasUnfollowTarget) this.unfollowTarget.disabled = !switches.some(item => this.followed(item))
    if (this.hasAddTarget) this.addTarget.disabled = !this.switchTargets.some(item => item.checked !== this.followed(item))
  }

  toggleAll() {
    this.checkTargets.forEach(check => { check.checked = this.allTarget.checked })
    this.update()
  }

  followSelected() { this.applyPicked(true) }
  unfollowSelected() { this.applyPicked(false) }

  // Only the picked packs change: the other switches go back to whether their pack is followed.
  applyPicked(follow) {
    this.switchTargets.forEach(item => { item.checked = this.followed(item) })
    this.checkTargets.filter(check => check.checked).forEach(check => { this.switchFor(check).checked = follow })
    this.label = follow ? this.followLabelValue : this.unfollowLabelValue
    this.element.requestSubmit()
  }

  // typle-r's DeleteConfirmation before a change that unfollows a pack, its button named after what asked for it.
  confirm(event) {
    if (this.confirmed) { this.confirmed = false; return }
    const names = this.switchTargets.filter(item => this.followed(item) && !item.checked)
      .map(item => this.quoteValue.replace("%s", item.dataset.name))
    if (!names.length) return
    event.preventDefault()
    event.stopImmediatePropagation()
    const submitter = event.submitter
    const action = submitter?.textContent.trim() || this.label || this.addLabelValue
    this.label = null
    const description = this.deleteValue.replace("%{description}", this.descriptionValue.replace("%{names}", names.join(this.separatorValue)))
    confirmDialog({ title: this.titleValue, description, action }).then(ok => {
      if (ok) { this.confirmed = true; this.element.requestSubmit(submitter) }
      else this.update()
    })
  }

  followed(item) { return item.dataset.followed === "true" }
  switchFor(check) { return this.switchTargets.find(item => item.value === check.dataset.catalogId) }
}
