const BORDER_SIZE = 4;

// https://stackoverflow.com/questions/26233180/resize-a-div-on-border-drag-and-drop-without-adding-extra-markup
const ResizeContainer = {
  mounted() {
    this.pushResize = debounce(this.pushResize.bind(this), 100);
    this.onMousemove = this.onMousemove.bind(this);
    this.onMouseup = this.onMouseup.bind(this);

    this.el.addEventListener("mouseover", this.onMouseover.bind(this));
    this.el.addEventListener("mouseleave", this.onMouseleave.bind(this));
    this.el.addEventListener("mousedown", this.onMousedown.bind(this));
  },

  destroyed() {
    // clean up global event listeners
    document.removeEventListener("mousemove", this.onMousemove, false);
    document.removeEventListener("mousemove", this.onMousemove, false);
  },

  pushResize(width) {
    this.pushEvent(this.el.dataset["phx-resize"] || "resize", { width });
  },

  onMouseover(event) {
    // hover isn't supported for pseudo elements, so manually change opacity on mouseover
    if (this.el.getBoundingClientRect().width - event.offsetX < BORDER_SIZE) {
      this.el.style.setProperty('--resize-indicator-opacity', 1);
    } else {
      this.el.style.setProperty('--resize-indicator-opacity', 0);
    }
  },

  onMouseleave(event) {
    this.el.style.setProperty('--resize-indicator-opacity', 0);
  },

  onMousedown(event) {
    if (this.el.getBoundingClientRect().width - event.offsetX < BORDER_SIZE) {
      this.mouseX = event.x;

      document.body.classList.add("select-none");

      document.addEventListener("mousemove", this.onMousemove, false);
      document.addEventListener("mouseup", this.onMouseup, false);
    }
  },

  onMousemove(event) {
    const dx = this.mouseX - event.x;
    this.mouseX = event.x;

    const width = this.el.getBoundingClientRect().width - dx;
    this.el.style.width = `${width}px`;

    this.pushResize(width);
  },

  onMouseup(event) {
    // re-enable global text selection
    document.body.classList.remove("select-none");

    // clean up global event listeners
    document.removeEventListener("mousemove", this.onMousemove, false);
    document.removeEventListener("mouseup", this.onMousemove, false);
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
