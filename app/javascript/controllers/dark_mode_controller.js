import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["checkbox", "switcher"]

  connect() {
    try {
      const stored = localStorage.getItem('darkMode')
      if (stored === null || stored === 'undefined' || stored === undefined) {
        this.isDarkMode = null
      } else {
        this.isDarkMode = JSON.parse(stored)
      }
    } catch (e) {
      console.warn("Invalid darkMode value in localStorage", e)
      this.isDarkMode = null
    }

    if (this.isDarkMode === null) {
      // Check system preference
      this.isDarkMode = window.matchMedia('(prefers-color-scheme: dark)').matches
    }

    this.applyTheme()
  }

  toggle(event) {
    this.isDarkMode = event.target.checked
    localStorage.setItem('darkMode', JSON.stringify(this.isDarkMode))
    this.applyTheme()
  }

  applyTheme() {
    if (this.hasCheckboxTarget) {
      this.checkboxTarget.checked = this.isDarkMode
    }

    if (this.isDarkMode) {
      document.body.classList.add('dark')
    } else {
      document.body.classList.remove('dark')
    }
  }
}
