import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["dropdown", "langLabel", "langButton"]
  static values = { languages: Array }

  connect() {
    // Prefer English; fall back to the first available language.
    const defaultLang = this.languagesValue.includes("en") ? "en" : this.languagesValue[0]
    this.langLabelTarget.innerText = (defaultLang || "EN").toUpperCase()
    this.setActiveLanguage(defaultLang)
    this.hideAllDescriptions()
    this.showDescription(defaultLang)
  }

  toggleDropdown(event) {
    event.stopPropagation()
    this.dropdownTarget.classList.toggle("lang-dropdown--open")
  }

  // Single action for every language button. The language comes from a
  // data-param, never from a dynamically-generated method name.
  switchTo(event) {
    event.preventDefault()
    event.stopPropagation()

    const lang = event.params.lang
    if (!this.languagesValue.includes(lang)) return // allowlist guard

    this.hideAllDescriptions()
    this.langLabelTarget.innerText = lang.toUpperCase()
    this.showDescription(lang)
    this.setActiveLanguage(lang)
    this.hideDropdown()
  }

  // ---- helpers ----

  // Moves the "active" highlight to the button matching the given language.
  setActiveLanguage(lang) {
    this.langButtonTargets.forEach((button) => {
      const isActive = button.dataset.languageSwitcherLangParam === lang
      button.classList.toggle("lang-option--active", isActive)
    })
  }

  hideAllDescriptions() {
    for (const lang of this.languagesValue) {
      this.setDescriptionHidden(lang, true)
    }
  }

  showDescription(lang) {
    this.setDescriptionHidden(lang, false)
  }

  setDescriptionHidden(lang, hidden) {
    const element = document.getElementById(lang)
    if (element) element.hidden = hidden // missing language → safe no-op
  }

  hideDropdown() {
    this.dropdownTarget.classList.remove("lang-dropdown--open")
  }

  // Optional: wire with data-action="click@window->language-switcher#closeOnClickOutside"
  closeOnClickOutside(event) {
    if (!this.element.contains(event.target)) {
      this.hideDropdown()
    }
  }
}
