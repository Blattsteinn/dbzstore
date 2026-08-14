import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = [ "variantMax", "entireDiv",
    "stripeQuantity", "stripeVariantId", 
    // "addToCartQuantity", "addToCartVariantId",
    "price",
    // "addToWishListQuantity","addToWishListVariantId"
    "image", "dot", "imageCounter"
  ]

  connect() {
    this.currentImageIndex = 0
    this.showImage(0)
  }

  // ---- Image carousel ----

  openLightbox(event) {
    // Remove any existing lightbox first
    this.closeLightbox()

    // Determine the clicked image index
    const clickedSrc = event.currentTarget.src
    const sources = this.imageTargets.map(img => img.src)
    let currentIdx = sources.indexOf(clickedSrc)
    if (currentIdx === -1) currentIdx = 0

    const overlay = document.createElement('div')
    overlay.id = 'image-lightbox'
    overlay.addEventListener('click', () => this.closeLightbox())

    const img = document.createElement('img')
    img.src = sources[currentIdx]

    // ---- Close button ----
    const closeBtn = document.createElement('button')
    closeBtn.className = 'lightbox-close'
    closeBtn.innerHTML = '<svg width="16" height="16" viewBox="0 0 16 16" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round"><line x1="3" y1="3" x2="13" y2="13"/><line x1="13" y1="3" x2="3" y2="13"/></svg>'
    closeBtn.setAttribute('aria-label', 'Close')
    closeBtn.addEventListener('click', (e) => {
      e.stopPropagation()
      this.closeLightbox()
    })

    // ---- Counter ----
    const counter = document.createElement('span')
    counter.className = 'lightbox-counter'
    counter.textContent = `${currentIdx + 1} / ${sources.length}`

    // ---- Navigation arrows (only if multiple images) ----
    const prevArrow = document.createElement('button')
    prevArrow.className = 'lightbox-arrow lightbox-prev'
    prevArrow.innerHTML = '‹'
    prevArrow.setAttribute('aria-label', 'Previous')
    prevArrow.addEventListener('click', (e) => { e.stopPropagation(); this._lightboxNavigate(-1, sources, img, counter, dots) })

    const nextArrow = document.createElement('button')
    nextArrow.className = 'lightbox-arrow lightbox-next'
    nextArrow.innerHTML = '›'
    nextArrow.setAttribute('aria-label', 'Next')
    nextArrow.addEventListener('click', (e) => { e.stopPropagation(); this._lightboxNavigate(1, sources, img, counter, dots) })

    // ---- Dots ----
    const dots = document.createElement('div')
    dots.className = 'lightbox-dots'
    const dotElements = []
    sources.forEach((_, i) => {
      const dot = document.createElement('button')
      dot.className = 'lightbox-dot' + (i === currentIdx ? ' active' : '')
      dot.setAttribute('aria-label', `Image ${i + 1}`)
      dot.addEventListener('click', (e) => {
        e.stopPropagation()
        img.src = sources[i]
        counter.textContent = `${i + 1} / ${sources.length}`
        dotElements.forEach(d => d.classList.remove('active'))
        dot.classList.add('active')
      })
      dots.appendChild(dot)
      dotElements.push(dot)
    })

    // ---- Keyboard handler ----
    this._escHandler = (e) => {
      if (e.key === 'Escape') this.closeLightbox()
      if (e.key === 'ArrowLeft') this._lightboxNavigate(-1, sources, img, counter, dotElements)
      if (e.key === 'ArrowRight') this._lightboxNavigate(1, sources, img, counter, dotElements)
    }
    document.addEventListener('keydown', this._escHandler)

    // ---- Android/system back button ----
    // Push a history entry so the browser/OS "back" button closes the
    // lightbox (via popstate) instead of navigating away from the page.
    this._prevState = history.state
    this._onPopState = () => this.closeLightbox(true)
    window.addEventListener('popstate', this._onPopState)
    history.pushState({ lightboxOpen: true }, '')

    // ---- Touch swipe ----
    if (sources.length > 1) {
      let touchStartX = 0
      overlay.addEventListener('touchstart', (e) => {
        touchStartX = e.touches[0].clientX
      }, { passive: true })
      overlay.addEventListener('touchend', (e) => {
        const diff = touchStartX - e.changedTouches[0].clientX
        if (Math.abs(diff) > 50) {
          this._lightboxNavigate(diff > 0 ? 1 : -1, sources, img, counter, dotElements)
        }
      })
    }

    overlay.appendChild(closeBtn)
    overlay.appendChild(counter)
    if (sources.length > 1) {
      overlay.appendChild(prevArrow)
      overlay.appendChild(nextArrow)
      overlay.appendChild(dots)
    }
    overlay.appendChild(img)
    document.body.appendChild(overlay)
    document.body.style.overflow = 'hidden'
  }

  _lightboxNavigate(direction, sources, img, counter, dots) {
    const currentSrc = img.src
    let idx = sources.indexOf(currentSrc)
    if (idx === -1) idx = 0
    idx = (idx + direction + sources.length) % sources.length
    img.src = sources[idx]
    counter.textContent = `${idx + 1} / ${sources.length}`
    if (dots) {
      dots.forEach((d, i) => d.classList.toggle('active', i === idx))
    }
  }

  closeLightbox(byBackButton = false) {
    const overlay = document.getElementById('image-lightbox')
    if (overlay) {
      overlay.classList.add('fade-out')
      setTimeout(() => {
        overlay.remove()
        document.body.style.overflow = ''
        document.removeEventListener('keydown', this._escHandler)
        window.removeEventListener('popstate', this._onPopState)
      }, 150)
    }
    // Undo the pushed history entry without triggering popstate. Calling
    // history.back() here would make Turbo Drive treat it as a real
    // navigation and restore/re-render the page from cache. replaceState
    // just clears our marker so a later back press behaves normally.
    if (!byBackButton && history.state?.lightboxOpen) {
      history.replaceState(this._prevState, '')
    }
  }

  showImage(index) {
    if (!this.hasImageTarget) return

    this.imageTargets.forEach((img, i) => {
      img.hidden = (i !== index)
    })

    if (this.hasDotTarget) {
      this.dotTargets.forEach((dot, i) => {
        dot.classList.toggle("active", i === index)
      })
    }

    if (this.hasImageCounterTarget) {
      this.imageCounterTarget.textContent = `${index + 1} / ${this.imageTargets.length}`
    }

    this.currentImageIndex = index
  }

  nextImage() {
    const next = (this.currentImageIndex + 1) % this.imageTargets.length
    this.showImage(next)
  }

  prevImage() {
    const prev = (this.currentImageIndex - 1 + this.imageTargets.length) % this.imageTargets.length
    this.showImage(prev)
  }

  goToImage(event) {
    const index = parseInt(event.currentTarget.dataset.index, 10)
    this.showImage(index)
  }

  // ---- Variant / quantity ----

  update_form_values(event){
    this.entireDivTarget.hidden = false;

    const stock = event.target.dataset.stock;
    const variantId = event.target.dataset.variantId;
    this.price = event.target.dataset.price

    this.variantMaxTarget.value = 1;
    this.variantMaxTarget.max = stock;

    this.stripeVariantIdTarget.value = variantId;
    this.stripeQuantityTarget.value = 1;

    this.priceTarget.textContent = `${(1 * this.price) / 100} EUR`
  }

  increase(){
    const quantity = Number(this.variantMaxTarget.value) + 1;
    if(quantity > Number(this.variantMaxTarget.max)){
      return;
    }

    this.variantMaxTarget.value = quantity
    this.stripeQuantityTarget.value = quantity;
    this.priceTarget.textContent = `${(quantity * this.price) / 100} EUR`
  }

  decrease(){
    const quantity = Number(this.variantMaxTarget.value) - 1;
    if(quantity <= 0){
      return;
    }

    this.variantMaxTarget.value = quantity
    this.stripeQuantityTarget.value = quantity;
    this.priceTarget.textContent = `${(quantity * this.price) / 100} EUR`
  }
}
