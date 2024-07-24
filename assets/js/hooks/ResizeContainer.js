const BORDER_SIZE = 4;

// https://stackoverflow.com/questions/26233180/resize-a-div-on-border-drag-and-drop-without-adding-extra-markup
const ResizeContainer = {
  mounted() {
    this.pushResize = debounce(this.pushResize.bind(this), 100);
    this.onDocumentMousemove = this.onDocumentMousemove.bind(this);
    this.onMouseup = this.onMouseup.bind(this);

    this.el.addEventListener("mousemove", this.onMousemove.bind(this));
    this.el.addEventListener("mouseleave", this.onMouseleave.bind(this));
    this.el.addEventListener("mousedown", this.onMousedown.bind(this));
  },

  destroyed() {
    // clean up global event listeners
    document.removeEventListener("mousemove", this.onDocumentMousemove, false);
    document.removeEventListener("mousemove", this.onDocumentMousemove, false);
  },

  pushResize(width) {
    this.pushEvent(this.el.getAttribute("phx-resize") || "resize", { width });
  },

  onMousemove(event) {
    // hover isn't supported for pseudo elements, so manually change opacity on mouseover
    if (this.detectInDragArea(event)) {
      this.el.style.setProperty('--resize-indicator-opacity', 1);
    } else {
      this.el.style.setProperty('--resize-indicator-opacity', 0);
    }
  },

  onMouseleave(event) {
    this.el.style.setProperty('--resize-indicator-opacity', 0);
  },

  onMousedown(event) {
    if (this.detectInDragArea(event)) {
      this.mouseX = event.x;

      document.body.classList.add("select-none");

      document.addEventListener("mousemove", this.onDocumentMousemove, false);
      document.addEventListener("mouseup", this.onMouseup, false);
    }
  },

  onDocumentMousemove(event) {
    const isLeft = this.el.classList.contains("resize-container-left");
    const dx = isLeft ? event.x - this.mouseX : this.mouseX - event.x;

    this.mouseX = event.x;

    let width = this.el.getBoundingClientRect().width - dx;
    width = Math.min(width, parseInt(this.el.dataset["maxWidth"]))
    width = Math.max(width, parseInt(this.el.dataset["minWidth"]))
    width = Math.round(width)

    this.el.style.width = `${width}px`;
    this.pushResize(width);
  },

  onMouseup(event) {
    // re-enable global text selection
    document.body.classList.remove("select-none");

    // clean up global event listeners
    document.removeEventListener("mousemove", this.onDocumentMousemove, false);
    document.removeEventListener("mouseup", this.onDocumentMousemove, false);
  },

  detectInDragArea(event) {
    if (this.el.classList.contains("resize-container-left")) {
      return event.offsetX < BORDER_SIZE;
    }

    if (this.el.classList.contains("resize-container-right")) {
      return this.el.getBoundingClientRect().width - event.offsetX < BORDER_SIZE;
    }

    throw new Error("Missing container class");
  }
}

function debounce(func, wait) {
  let timeout;
  return function executedFunction(...args) {
    const later = () => {
      clearTimeout(timeout);
      func(...args);
    };
    clearTimeout(timeout);
    timeout = setTimeout(later, wait);
  };
}


export default ResizeContainer;
