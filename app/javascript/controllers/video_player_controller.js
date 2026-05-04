import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = { src: String, type: String }

  connect() {
    if (typeof window.Plyr === "undefined") {
      console.warn("Plyr not loaded — video player unavailable")
      return
    }

    // Inject <source> so Plyr and the browser both see it
    if (this.srcValue) {
      this.element.innerHTML = ""
      const source = document.createElement("source")
      source.src  = this.srcValue
      source.type = this.typeValue || "video/mp4"
      this.element.appendChild(source)
    }

    this.player = new window.Plyr(this.element, {
      controls: [
        "play-large", "play", "progress", "current-time", "duration",
        "mute", "volume", "captions", "fullscreen"
      ],
      autoplay:   false,
      muted:      false,
      resetOnEnd: false,
      keyboard:   { focused: true, global: false },
      tooltips:   { controls: true, seek: true },
      captions:   { active: false },
      loadSprite: false,
      iconUrl:    "https://cdn.jsdelivr.net/npm/plyr@3.7.8/dist/plyr.svg",
    })
  }

  disconnect() {
    this.player?.destroy()
    this.player = null
  }
}
