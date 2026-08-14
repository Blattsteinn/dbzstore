import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["input", "status", "button"]

  async apply(event) {
    event.preventDefault() // stop the browser from navigating

    const code = this.inputTarget.value.trim()
    if (!code) return

    // Show feedback while we wait for the server to respond
    this.setStatus("Checking code…", "loading")
    this.setBusy(true)

    let response
    try {
      // Ask the server in the background (same URL your form would have used)
      response = await fetch(`${this.element.action}?code=${encodeURIComponent(code)}`, {
        headers: { "Accept": "application/json" }
      })
    } catch {
      this.setStatus("Couldn't reach the server. Please try again.", "error")
      this.setBusy(false)
      return
    }

    if (!response.ok) {            // 429/403 -> throttled
      this.setStatus("Too many attempts. Try again later.", "error")
      this.setBusy(false)
      return
    }

    const data = await response.json()

    if (data.valid) {
      this.setStatus(`Code activated. ${data.percentage}% off applied.`, "success")
      // (a) write the code into the ORDER form's hidden field
      document.querySelector('.hero-purchase-form [name="code"]').value = code
      // (b) update the displayed prices
      this.applyPercentage(data.percentage)
      // (c) lock the code in
      this.setBusy(true)
    } else {
      this.setStatus("Invalid code", "error")
      this.setBusy(false)
    }
  }

  setStatus(message, kind) {
    this.statusTarget.textContent = message
    this.statusTarget.classList.remove('success', 'error', 'loading')
    this.statusTarget.classList.add(kind)
  }

  setBusy(busy) {
    this.inputTarget.disabled = busy
    this.buttonTarget.disabled = busy
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