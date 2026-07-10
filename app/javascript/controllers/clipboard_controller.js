import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = { text: String }

  copy() {
    navigator.clipboard.writeText(this.textValue).then(() => {
      const original = this.element.innerHTML
      this.element.innerHTML = "✓"
      this.element.classList.add("btn-sm--success")
      setTimeout(() => {
        this.element.innerHTML = original
        this.element.classList.remove("btn-sm--success")
      }, 1500)
    })
  }
}
