const SetTimeZoneValue = {
  mounted() {
    this.el.value = Intl.DateTimeFormat().resolvedOptions().timeZone;
  }
};

export default SetTimeZoneValue;
