// Site-wide: points the "continue" links at the last lesson, shows the one-time back-button
// note on lessons, keeps the section hash when switching language, opens the "more" sheet.
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
  function backnote() {
    var n = document.querySelector('[data-backnote]');
    if (!n || !document.body.classList.contains('lesson-page')) return;
    var t = get('tips.v1'), closed = (t && t.closed) || [];
    if (closed.indexOf('back') >= 0) return;
    n.hidden = false;
    function close() {
      n.hidden = true;
      closed.push('back');
      try { localStorage.setItem(P + 'tips.v1', JSON.stringify({ v: 1, closed: closed })); } catch (e) {}
      removeEventListener('keydown', esc);
    }
    function esc(e) { var open = false; try { open = !!document.querySelector(':popover-open'); } catch (x) {} if (e.key === 'Escape' && !open) close(); }
    n.querySelector('[data-backnote-close]').addEventListener('click', close);
    addEventListener('keydown', esc);
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
  cont(); backnote(); langHash(); more();
  addEventListener('pageshow', cont);
})();
