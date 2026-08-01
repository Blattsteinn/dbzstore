import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["dropdown", "enBody", "itBody", "enLabel", "itLabel", "langLabel"]

  connect() {
    this.currentLang = "en" // default: English visible, label shows "EN"
  }

  toggleDropdown(event) {
    event.stopPropagation()
    this.dropdownTarget.classList.toggle("lang-dropdown--open")
  }

  switchToEnglish(event) {
    event.stopPropagation()
    this.itBodyTarget.classList.add("desc-body--hidden")
    this.itBodyTarget.classList.remove("desc-body--visible")
    this.enBodyTarget.classList.remove("desc-body--hidden")
    this.enBodyTarget.classList.add("desc-body--visible")
    this.enLabelTarget.classList.add("lang-option--active")
    this.itLabelTarget.classList.remove("lang-option--active")
    this.langLabelTarget.textContent = "EN"
    this.currentLang = "en"
    this.hideDropdown()
  }

  switchToItalian(event) {
    event.stopPropagation()
    this.enBodyTarget.classList.add("desc-body--hidden")
    this.enBodyTarget.classList.remove("desc-body--visible")
    this.itBodyTarget.classList.remove("desc-body--hidden")
    this.itBodyTarget.classList.add("desc-body--visible")
    this.itLabelTarget.classList.add("lang-option--active")
    this.enLabelTarget.classList.remove("lang-option--active")
    this.langLabelTarget.textContent = "IT"
    this.currentLang = "it"
    this.hideDropdown()
  }

  hideDropdown() {
    this.dropdownTarget.classList.remove("lang-dropdown--open")
  }

  // Close dropdown when clicking outside
  closeOnClickOutside(event) {
    if (!this.element.contains(event.target)) {
      this.hideDropdown()
    }
  }
}
