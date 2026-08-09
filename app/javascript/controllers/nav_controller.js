import { Controller } from "@hotwired/stimulus"

// Site navigation: mobile hamburger menu + games dropdown.
// Closes both on outside click or Escape.
export default class extends Controller {
  static targets = ["menu", "dropdown", "dropdownTrigger"]

  connect() {
    this.onDocumentClick = this.handleDocumentClick.bind(this)
    this.onKeydown = this.handleKeydown.bind(this)
    document.addEventListener("click", this.onDocumentClick)
    document.addEventListener("keydown", this.onKeydown)
  }

  disconnect() {
    document.removeEventListener("click", this.onDocumentClick)
    document.removeEventListener("keydown", this.onKeydown)
  }

  toggleMenu(event) {
    event.stopPropagation()
    const open = this.menuTarget.classList.toggle("is-open")
    event.currentTarget.setAttribute("aria-expanded", String(open))
  }

  toggleDropdown(event) {
    event.stopPropagation()
    const open = this.dropdownTarget.classList.toggle("is-open")
    this.dropdownTriggerTarget.setAttribute("aria-expanded", String(open))
  }

  closeAll() {
    this.menuTarget.classList.remove("is-open")
    this.dropdownTarget.classList.remove("is-open")
    this.dropdownTriggerTarget.setAttribute("aria-expanded", "false")
  }

  handleDocumentClick(event) {
    if (!this.element.contains(event.target)) {
      this.closeAll()
    }
  }

  handleKeydown(event) {
    if (event.key === "Escape") {
      this.closeAll()
    }
  }
}
