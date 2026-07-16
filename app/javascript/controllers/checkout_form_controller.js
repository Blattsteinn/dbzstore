import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  connect() {
    this.submitting = false
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
