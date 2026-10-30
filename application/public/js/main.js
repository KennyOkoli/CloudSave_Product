import { api } from "./api.js";
import { $, formatBytes, formatDate, plural, toast } from "./ui.js";
import { initAuth, setMode } from "./auth.js";
import { clearImages, loadImages, onImagesChange, onOpenImage, setQuery, setSort, setView } from "./gallery.js";
import { clearTray, enableDropUploads, uploadFiles } from "./uploads.js";
import { openLightbox } from "./lightbox.js";
import { initSelection } from "./selection.js";

let me = null;

const TYPES = [
  ["image/jpeg", "JPEG", "--type-1"],
  ["image/png", "PNG", "--type-2"],
  ["image/webp", "WebP", "--type-3"],
  ["image/gif", "GIF", "--type-4"],
];

function renderStorage(images) {
  const total = images.reduce((sum, image) => sum + image.size, 0);
  $("#user-meta").textContent = `${plural(images.length, "image")} · ${formatBytes(total)}`;
  $("#nav-count").textContent = images.length || "";
  $("#storage-used").textContent = `${formatBytes(total)} used`;

  const bar = [];
  const legend = [];
  for (const [type, label, color] of TYPES) {
    const bytes = images
      .filter((image) => image.contentType === type)
      .reduce((sum, image) => sum + image.size, 0);
    if (!bytes) continue;
    const segment = document.createElement("span");
    segment.style.cssText = `--c: var(${color}); flex: ${bytes}`;
    bar.push(segment);
    const item = document.createElement("li");
    item.style.setProperty("--c", `var(${color})`);
    item.innerHTML = `<span></span><b></b>`;
    item.querySelector("span").textContent = label;
    item.querySelector("b").textContent = formatBytes(bytes);
    legend.push(item);
  }
  $("#storage-bar").replaceChildren(...bar);
  $("#storage-legend").replaceChildren(...legend);
}

async function showApp() {
  me = await api("/api/me");
  $("#username").textContent = `@${me.username}`;
  $("#joined").textContent = `Joined ${formatDate(me.createdAt)}`;
  const initial = me.username.slice(0, 1);
  $("#avatar").textContent = initial;
  $("#menu-avatar").textContent = initial;
  document.title = "My images · CloudSave";

  showView("app");
  await loadImages();
}

// One of landing, auth or app shows at a time; swaps crossfade where the browser supports it.
function showView(name) {
  const swap = () => {
    for (const view of ["landing", "auth", "app"]) $(`#${view}-view`).hidden = view !== name;
    window.scrollTo(0, 0);
  };
  if (!document.startViewTransition) return Promise.resolve(swap());
  return document.startViewTransition(swap).updateCallbackDone;
}

function showLanding() {
  me = null;
  clearImages();
  clearTray();
  document.title = "CloudSave";
  showView("landing");
}

function showAuth(mode) {
  setMode(mode);
  showView("auth").then(() => $("#auth-form").username.focus());
}

document.addEventListener("click", (e) => {
  const go = e.target.closest("[data-go]")?.dataset.go;
  if (go === "landing") showView("landing");
  else if (go) showAuth(go);
});

initAuth({ onSignedIn: showApp, onSignedOut: showLanding });
initSelection();
onOpenImage(openLightbox);

// Totals follow the gallery, so uploads and deletes update them without a refetch.
onImagesChange(renderStorage);

$("#search").addEventListener("input", (e) => setQuery(e.target.value));
$("#sort").addEventListener("change", (e) => setSort(e.target.value));

function chooseView(view) {
  setView(view);
  document.querySelectorAll(".segmented [data-view]").forEach((button) => {
    button.setAttribute("aria-pressed", String(button.dataset.view === view));
  });
  try {
    localStorage.setItem("view", view);
  } catch {}
}
document.querySelectorAll(".segmented [data-view]").forEach((button) => {
  button.addEventListener("click", () => chooseView(button.dataset.view));
});
try {
  if (localStorage.getItem("view") === "list") chooseView("list");
} catch {}

$("#file-input").addEventListener("change", (e) => {
  uploadFiles(e.target.files);
  e.target.value = ""; // so choosing the same file again still fires "change"
});
enableDropUploads(() => Boolean(me));

showApp().catch((err) => {
  showLanding();
  if (err.status !== 401) toast(err.message, { error: true });
});
