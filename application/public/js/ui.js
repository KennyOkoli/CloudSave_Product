export const $ = (selector, root = document) => root.querySelector(selector);

export function toast(message, { error = false } = {}) {
  const el = document.createElement("p");
  el.className = error ? "toast toast-error" : "toast";
  el.textContent = message;
  $("#toasts").append(el);
  setTimeout(() => el.remove(), error ? 6000 : 3000);
}

export function formatBytes(bytes) {
  if (bytes < 1024) return `${bytes} B`;
  if (bytes < 1024 * 1024) return `${Math.round(bytes / 1024)} KB`;
  return `${(bytes / 1024 / 1024).toFixed(1)} MB`;
}

// SQLite stores UTC as "YYYY-MM-DD HH:MM:SS" with no zone, so mark it as UTC before parsing.
export function formatDate(sqliteDate) {
  return new Date(sqliteDate.replace(" ", "T") + "Z").toLocaleDateString(
    undefined,
    { day: "numeric", month: "short", year: "numeric" },
  );
}

export const plural = (n, word) => `${n} ${word}${n === 1 ? "" : "s"}`;
