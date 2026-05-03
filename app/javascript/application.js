// Configure your import map in config/importmap.rb. Read more: https://github.com/rails/importmap-rails
import "@hotwired/turbo-rails"
import "controllers"

function siteConfirm(message, options = {}) {
  const modal = document.getElementById("site-confirm-modal")
  const messageEl = document.getElementById("site-confirm-message")
  const okButton = document.getElementById("site-confirm-ok")
  const cancelButton = document.getElementById("site-confirm-cancel")

  if (!modal || !messageEl || !okButton || !cancelButton) return Promise.resolve(false)

  messageEl.textContent = message || "Are you sure?"
  okButton.textContent = options.confirmText || "Confirm"
  cancelButton.textContent = options.cancelText || "Cancel"
  cancelButton.style.display = options.alert ? "none" : ""
  okButton.className = options.danger === false ? "btn btn-primary" : "btn btn-danger"
  modal.classList.add("active")
  modal.setAttribute("aria-hidden", "false")
  okButton.focus()

  return new Promise((resolve) => {
    let resolved = false
    const finish = (value) => {
      if (resolved) return
      resolved = true
      modal.classList.remove("active")
      modal.setAttribute("aria-hidden", "true")
      cancelButton.style.display = ""
      okButton.removeEventListener("click", confirm)
      cancelButton.removeEventListener("click", cancel)
      modal.removeEventListener("click", backdrop)
      document.removeEventListener("keydown", keydown)
      resolve(value)
    }
    const confirm = () => finish(true)
    const cancel = () => finish(false)
    const backdrop = (event) => {
      if (event.target === modal) cancel()
    }
    const keydown = (event) => {
      if (event.key === "Escape") cancel()
    }

    okButton.addEventListener("click", confirm)
    cancelButton.addEventListener("click", cancel)
    modal.addEventListener("click", backdrop)
    document.addEventListener("keydown", keydown)
  })
}

window.siteConfirm = siteConfirm
window.siteAlert = (message) => siteConfirm(message, { alert: true, danger: false, confirmText: "OK" })

document.addEventListener("turbo:load", () => {
  if (window.Turbo) {
    window.Turbo.config.forms.confirm = (message) => siteConfirm(message)
  }
})
