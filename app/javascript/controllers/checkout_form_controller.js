import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  connect() {
    this.submitting = false
  }

  positionEmailField(event) {
    if (!window.matchMedia("(max-width: 480px)").matches) return

    const field = event.currentTarget
    window.setTimeout(() => {
      const viewportHeight = window.visualViewport?.height || window.innerHeight
      const fieldTop = field.getBoundingClientRect().top
      const scrollTop = window.scrollY + fieldTop - viewportHeight * 0.25

      window.scrollTo({ top: Math.max(scrollTop, 0), behavior: "smooth" })
    }, 150)
  }

  submit(event) {
    if (this.submitting) return

    // Honor HTML5 form validation
    if (!this.element.checkValidity()) {
      this.element.reportValidity()
      event.preventDefault()
      return
    }

    event.preventDefault()
    this.submitting = true

    document.getElementById('stripe-loading-overlay').style.display = 'flex'

    // Small delay so the browser paints the overlay before navigating
    setTimeout(() => { this.element.submit() }, 150)
  }
}
