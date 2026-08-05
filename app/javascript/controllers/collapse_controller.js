import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["header", "body"]

  toggle() {
    const collapsed = this.element.classList.toggle("is-collapsed")
    this.headerTarget.setAttribute("aria-expanded", String(!collapsed))
  }
}
