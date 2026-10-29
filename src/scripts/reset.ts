// "Reset progress" with a confirmation dialog, and "follow device setting" for the theme.
import { all, reset, storageOk } from './progress';

for (const box of document.querySelectorAll<HTMLElement>('[data-reset]')) {
  const open = box.querySelector<HTMLButtonElement>('[data-reset-open]');
  const dlg = box.querySelector<HTMLDialogElement>('[data-reset-dialog]')!;

  const status = box.querySelector<HTMLElement>('[data-reset-status]')!;
  const L = box.dataset;
  const sync = () => {
    const n = Object.keys(all()).length;
    open.disabled = n === 0 && !localStorage.getItem('simplyeeglab:quiz.v1');
    status.textContent = open.disabled ? L.lNone! : '';
  };
  if (open && storageOk()) {
    open.hidden = false;
    sync();
    addEventListener('progress-changed', () => { const msg = status.textContent; sync(); if (msg === L.lDone && open.disabled) status.textContent = msg; });
    addEventListener('pageshow', sync);
    open.addEventListener('click', () => {
      box.querySelector('[data-reset-body]')!.textContent = L.lBody!.replace('{n}', String(Object.keys(all()).length));
      dlg.showModal();
      box.querySelector<HTMLButtonElement>('[data-reset-cancel]')!.focus();
    });
    box.querySelector('[data-reset-cancel]')!.addEventListener('click', () => dlg.close());
    box.querySelector('[data-reset-confirm]')!.addEventListener('click', () => {
      reset();
      dlg.close();
      sync();
      status.textContent = L.lDone!;
      open.focus();
      dispatchEvent(new CustomEvent('progress-reset'));
    });
  }
  const follow = box.querySelector<HTMLButtonElement>('[data-follow-system]');
  if (follow) {
    follow.hidden = false;
    follow.addEventListener('click', () => {
      try { localStorage.removeItem('simplyeeglab:theme'); } catch {}
      document.documentElement.removeAttribute('data-theme');
      document.getElementById('theme-btn')?.dispatchEvent(new Event('theme-sync'));
    });
  }
}
