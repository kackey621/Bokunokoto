import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["line1", "line2", "line3"]

  connect() {
    this.isOpen = false
  }

  toggle(event) {
    if (event) {
      event.preventDefault()
      event.stopPropagation()
    }

    this.isOpen = !this.isOpen
    
    // Toggle sidebar translation
    if (this.isOpen) {
      this.element.classList.remove("-translate-x-full")
    } else {
      this.element.classList.add("-translate-x-full")
    }

    // Toggle hamburger icon animation
    if (this.hasLine1Target && this.hasLine2Target && this.hasLine3Target) {
      if (this.isOpen) {
        this.line1Target.classList.add("rotate-45", "translate-y-1.5")
        this.line2Target.classList.add("opacity-0")
        this.line3Target.classList.add("-rotate-45", "-translate-y-1.5")
      } else {
        this.line1Target.classList.remove("rotate-45", "translate-y-1.5")
        this.line2Target.classList.remove("opacity-0")
        this.line3Target.classList.remove("-rotate-45", "-translate-y-1.5")
      }
    }
  }

  // Handle clicking outside to close
  close(event) {
    if (this.isOpen && !this.element.contains(event.target)) {
      // Find hamburger button and make sure we didn't click it
      const button = document.querySelector('[data-action="click->sidebar#toggle"]')
      if (!button || !button.contains(event.target)) {
        this.toggle()
      }
    }
  }
}
