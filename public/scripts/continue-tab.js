// Site-wide: points the "continue" links at the last lesson, keeps the section hash when switching
// language, opens the "more" sheet.
(function () {
  var me = document.currentScript, base = me.dataset.base || '/', lang = me.dataset.lang;
  var P = 'simplyeeglab:';
  function get(k) { try { return JSON.parse(localStorage.getItem(P + k)); } catch (e) { return null; } }
  function cont() {
    var last = get('last.v1'), slug = last && typeof last.slug === 'string' && /^[a-z0-9-]+$/.test(last.slug) && last.slug;
    var href = slug ? base + (lang === 'en' ? 'en/' : '') + 'lesson/' + slug + '/' : me.dataset.first;
    document.querySelectorAll('[data-continue]').forEach(function (a) {
      a.href = href;
      var label = slug ? a.dataset.lCont : a.dataset.lStart, s = a.querySelector('span') || a;
      if (label) s.textContent = label;
    });
  }
  function langHash() {
    document.querySelectorAll('[data-lang-link]').forEach(function (a) {
      a.addEventListener('click', function () { if (location.hash) a.href = a.href.split('#')[0] + location.hash; });
    });
  }
  function more() {
    var b = document.getElementById('more-btn'), s = document.getElementById('more-sheet');
    if (!b || !s || !s.showPopover) return;
    s.hidden = false;
    b.setAttribute('aria-haspopup', 'dialog');
    b.addEventListener('click', function (e) { e.preventDefault(); s.togglePopover(); });
    s.addEventListener('toggle', function (e) { b.setAttribute('aria-expanded', String(e.newState === 'open')); });
  }
  cont(); langHash(); more();
  addEventListener('pageshow', cont);
})();
