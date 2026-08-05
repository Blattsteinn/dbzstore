import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = [
    "dropdown",
    "langLabel",
    "enLabel", "itLabel", "frLabel", "esLabel", "deLabel",
    "enBody", "itBody", "frBody", "esBody", "deBody",
  ]

  connect() {
    this.currentLang = "en" // default: English visible, label shows "EN"
    document.addEventListener("click", this.closeOnClickOutside)
  }

  disconnect() {
    document.removeEventListener("click", this.closeOnClickOutside)
  }

  toggleDropdown(event) {
    event.stopPropagation()
    this.dropdownTarget.classList.toggle("lang-dropdown--open")
  }

  switchToEnglish(event) { this.switchTo("en", event) }
  switchToItalian(event) { this.switchTo("it", event) }
  switchToFrench(event) { this.switchTo("fr", event) }
  switchToSpanish(event) { this.switchTo("es", event) }
  switchToGerman(event) { this.switchTo("de", event) }

  switchTo(lang, event) {
    event?.stopPropagation?.()

    const bodies = { en: "enBody", it: "itBody", fr: "frBody", es: "esBody", de: "deBody" }
    const labels = { en: "enLabel", it: "itLabel", fr: "frLabel", es: "esLabel", de: "deLabel" }
    const short  = { en: "EN", it: "IT", fr: "FR", es: "ES", de: "DE" }

    Object.keys(bodies).forEach((code) => {
      this[`${bodies[code]}Target`].hidden = code !== lang
      this[`${labels[code]}Target`].classList.toggle("lang-option--active", code === lang)
    })

    this.langLabelTarget.textContent = short[lang]
    this.currentLang = lang
    this.hideDropdown()
  }

  hideDropdown() {
    this.dropdownTarget.classList.remove("lang-dropdown--open")
  }

  // Close dropdown when clicking outside
  closeOnClickOutside = (event) => {
    if (!this.element.contains(event.target)) {
      this.hideDropdown()
    }
  }
}
