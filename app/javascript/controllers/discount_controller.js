import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["input", "status", "button"]

  async apply(event) {
    event.preventDefault() // stop the browser from navigating

    const code = this.inputTarget.value.trim()
    if (!code) return

    // Ask the server in the background (same URL your form would have used)
    const response = await fetch(`${this.element.action}?code=${encodeURIComponent(code)}`, {
      headers: { "Accept": "application/json" }
    })

    if (!response.ok) {            // 429/403 -> throttled
      this.statusTarget.textContent = "Too many attempts. Try again later."
      this.statusTarget.classList.add('error')
      this.statusTarget.classList.remove('success')
      return
    }
    
    const data = await response.json()

    if (data.valid) {
      this.statusTarget.textContent = `Code activated. ${data.percentage}% off applied.`
      this.statusTarget.classList.add('success')
      this.statusTarget.classList.remove('error')
      // (a) write the code into the ORDER form's hidden field
      document.querySelector('.hero-purchase-form [name="code"]').value = code
      // (b) update the displayed prices
      this.applyPercentage(data.percentage)
      this.inputTarget.disabled = true
      this.buttonTarget.disabled = true
    } else {
      this.statusTarget.textContent = "Invalid code"
      this.statusTarget.classList.add('error')
      this.statusTarget.classList.remove('success')
    }
  }

  applyPercentage(percentage) {
    document.querySelectorAll('.hero-variant-option').forEach((label) => {
      const base = parseFloat(label.dataset.price)            // original, untouched
      const discounted = base * (100 - percentage) / 100

      label.classList.add('is-discounted')
      const priceEl = label.querySelector('.hero-variant-price-discounted')
      priceEl.hidden = false
      priceEl.textContent = discounted.toFixed(2) + '€'
    })
  }
}