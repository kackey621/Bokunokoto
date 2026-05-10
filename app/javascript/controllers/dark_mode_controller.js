import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["checkbox", "switcher"]

  connect() {
    this.isDarkMode = JSON.parse(localStorage.getItem('darkMode'))

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
    this.checkboxTarget.checked = this.isDarkMode

    if (this.isDarkMode) {
      document.body.classList.add('dark')
    } else {
      document.body.classList.remove('dark')
    }
  }
}
