const ControlTextarea = {
  mounted() {
    this.el.addEventListener("keydown", this.onKeydown.bind(this));
    this.el.addEventListener("input", this.onInput.bind(this));
  },
  updated() {
    if (this.el) {
      this.el.rows = this.el.value.split("\n").length;
    }
  },
  onKeydown(event) {
    if (event.key === "Enter") {
      if (event.shiftKey) {
        if (this.el && this.el.rows) {
          this.el.rows = this.el.rows + 1;
        }
      } else {
        event.preventDefault();

        const form = event.target.form;
        const submitButton = form && form.querySelector('button[type="submit"]');

        if (submitButton) {
          // remove focus from input so phoenix will overwrite the value
          // https://github.com/phoenixframework/phoenix_live_view/issues/624#issuecomment-585230754
          submitButton.focus();
          submitButton.click();

          // refocus on input after timeout
          setTimeout(() => {
            this.el.value = "";
            event.target.focus();
          });
        }
      }
    }
  },
  onInput(event) {
    const rows = event.target.value.split("\n").length;
    if (this.el) {
      this.el.rows = rows;
    }
  },
};

export default ControlTextarea;
