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
    window.Turbo.config.drive.prefetch = false
  }
  initMentionAutocomplete()
})

/* ── @mention autocomplete ── */
function initMentionAutocomplete() {
  // Remove any leftover dropdown from a previous page
  const old = document.getElementById("mention-dropdown")
  if (old) old.remove()

  const dropdown = document.createElement("ul")
  dropdown.id = "mention-dropdown"
  dropdown.style.cssText = [
    "position:absolute", "z-index:9000", "background:#1e1e1e",
    "border:1px solid #3d9faf", "border-radius:3px", "margin:0", "padding:0",
    "list-style:none", "min-width:180px", "max-width:260px",
    "box-shadow:0 4px 16px rgba(0,0,0,0.5)", "display:none", "font-size:12px",
    "font-family:Verdana,Arial,sans-serif"
  ].join(";")
  document.body.appendChild(dropdown)

  let activeIndex  = -1
  let currentInput = null
  let mentionStart = -1
  let debounceTimer = null

  function positionDropdown(textarea) {
    // Approximate caret position using a mirror div
    const style   = window.getComputedStyle(textarea)
    const mirror  = document.createElement("div")
    const props   = ["boxSizing","width","height","overflowX","overflowY",
                     "borderTopWidth","borderRightWidth","borderBottomWidth","borderLeftWidth",
                     "paddingTop","paddingRight","paddingBottom","paddingLeft",
                     "fontStyle","fontVariant","fontWeight","fontStretch","fontSize",
                     "lineHeight","fontFamily","textAlign","letterSpacing","wordSpacing"]
    mirror.style.cssText = "position:absolute;visibility:hidden;white-space:pre-wrap;word-wrap:break-word;"
    props.forEach(p => mirror.style[p] = style[p])
    mirror.style.width = textarea.offsetWidth + "px"
    document.body.appendChild(mirror)

    const text   = textarea.value.substring(0, textarea.selectionEnd)
    const span   = document.createElement("span")
    mirror.textContent = text
    mirror.appendChild(span)
    span.textContent = "."

    const rect   = textarea.getBoundingClientRect()
    const sRect  = span.getBoundingClientRect()
    const mRect  = mirror.getBoundingClientRect()
    document.body.removeChild(mirror)

    const top  = rect.top  + window.scrollY + (sRect.top  - mRect.top)  + parseInt(style.lineHeight || 16) + 2
    const left = rect.left + window.scrollX + (sRect.left - mRect.left)
    dropdown.style.top  = top  + "px"
    dropdown.style.left = left + "px"
  }

  function closeDropdown() {
    dropdown.style.display = "none"
    dropdown.innerHTML = ""
    activeIndex = -1
  }

  function setActive(index) {
    const items = dropdown.querySelectorAll("li")
    items.forEach((li, i) => {
      li.style.background = i === index ? "#2a7080" : ""
      li.style.color      = i === index ? "#fff" : "#d0d0d0"
    })
    activeIndex = index
  }

  function insertMention(username, textarea) {
    const before = textarea.value.substring(0, mentionStart)
    const after  = textarea.value.substring(textarea.selectionEnd)
    textarea.value = before + "@" + username + " " + after
    const pos = mentionStart + username.length + 2
    textarea.setSelectionRange(pos, pos)
    textarea.focus()
    closeDropdown()
  }

  function fetchSuggestions(query, textarea) {
    if (!query) return closeDropdown()
    clearTimeout(debounceTimer)
    debounceTimer = setTimeout(() => {
      fetch("/users/search?q=" + encodeURIComponent(query), {
        headers: { "Accept": "application/json", "X-Requested-With": "XMLHttpRequest" }
      })
      .then(r => r.json())
      .then(users => {
        if (!users.length) return closeDropdown()
        dropdown.innerHTML = ""
        activeIndex = -1
        users.forEach((u, i) => {
          const li = document.createElement("li")
          li.style.cssText = "padding:6px 10px;cursor:pointer;color:#d0d0d0;display:flex;align-items:center;gap:6px;"
          li.innerHTML = `<span style="color:#3d9faf;font-weight:bold;">@</span>${u.username}`
          li.addEventListener("mousedown", e => {
            e.preventDefault()
            insertMention(u.username, textarea)
          })
          li.addEventListener("mouseenter", () => setActive(i))
          dropdown.appendChild(li)
        })
        positionDropdown(textarea)
        dropdown.style.display = "block"
      })
      .catch(() => closeDropdown())
    }, 120)
  }

  document.addEventListener("input", e => {
    const ta = e.target
    if (ta.tagName !== "TEXTAREA") return
    currentInput = ta

    const caret  = ta.selectionEnd
    const text   = ta.value.substring(0, caret)
    const match  = text.match(/@([A-Za-z0-9_\-]{0,30})$/)

    if (match) {
      mentionStart = caret - match[0].length
      fetchSuggestions(match[1], ta)
    } else {
      closeDropdown()
    }
  }, true)

  document.addEventListener("keydown", e => {
    if (dropdown.style.display === "none") return
    const items = dropdown.querySelectorAll("li")
    if (!items.length) return

    if (e.key === "ArrowDown") {
      e.preventDefault()
      setActive(Math.min(activeIndex + 1, items.length - 1))
    } else if (e.key === "ArrowUp") {
      e.preventDefault()
      setActive(Math.max(activeIndex - 1, 0))
    } else if (e.key === "Enter" || e.key === "Tab") {
      if (activeIndex >= 0) {
        e.preventDefault()
        const username = items[activeIndex].textContent.trim()
        insertMention(username, currentInput)
      } else if (e.key === "Tab") {
        closeDropdown()
      }
    } else if (e.key === "Escape") {
      closeDropdown()
    }
  }, true)

  document.addEventListener("click", e => {
    if (!dropdown.contains(e.target)) closeDropdown()
  })

  document.addEventListener("scroll", () => {
    if (dropdown.style.display !== "none" && currentInput) positionDropdown(currentInput)
  }, true)
}
