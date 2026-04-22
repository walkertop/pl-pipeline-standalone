// theme.js — dark/light 切换（默认暗色）
export function initTheme() {
  const root = document.documentElement;
  const saved = localStorage.getItem('pl-dashboard-theme');
  const initial = saved || 'dark';
  setTheme(initial);

  const btn = document.getElementById('theme-toggle');
  if (btn) {
    btn.addEventListener('click', () => {
      const cur = root.getAttribute('data-theme') || 'dark';
      setTheme(cur === 'dark' ? 'light' : 'dark');
    });
  }
}

function setTheme(t) {
  document.documentElement.setAttribute('data-theme', t);
  localStorage.setItem('pl-dashboard-theme', t);
  const icon = document.getElementById('theme-icon');
  if (icon) icon.textContent = t === 'dark' ? '☀' : '☾';
}
