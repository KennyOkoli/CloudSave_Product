import { api } from "./api.js";
import { $, formatBytes, formatDate } from "./ui.js";

// The single list of images the gallery and lightbox both read from.
let images = [];
// What's on screen after search and sort; the lightbox steps through this.
let visible = [];
let query = "";
let sort = "newest";
const selected = new Set();
const listeners = new Set();
const selectionListeners = new Set();
let openImage = () => {};

export const getImages = () => images;
export const getVisible = () => visible;
export const getSelected = () => images.filter((image) => selected.has(image.id));
export const onImagesChange = (fn) => listeners.add(fn);
export const onSelectionChange = (fn) => selectionListeners.add(fn);
export const onOpenImage = (fn) => (openImage = fn);

const sorters = {
  newest: (a, b) => b.createdAt.localeCompare(a.createdAt),
  oldest: (a, b) => a.createdAt.localeCompare(b.createdAt),
  name: (a, b) => (a.name || "").localeCompare(b.name || ""),
  largest: (a, b) => b.size - a.size,
};

function changed() {
  for (const id of selected) {
    if (!images.some((image) => image.id === id)) selected.delete(id);
  }
  render();
  listeners.forEach((fn) => fn(images));
  selectionChanged();
}

export async function loadImages() {
  $("#gallery").setAttribute("aria-busy", "true");
  images = await api("/api/files");
  $("#gallery").setAttribute("aria-busy", "false");
  changed();
}

export function addImage(image) {
  images = [image, ...images];
  changed();
}

export function removeImage(id) {
  images = images.filter((image) => image.id !== id);
  changed();
}

export function clearImages() {
  images = [];
  selected.clear();
  changed();
}

export function setQuery(value) {
  query = value.trim().toLowerCase();
  render();
}

export function setSort(value) {
  sort = value;
  render();
}

export function setView(view) {
  $("#gallery").dataset.view = view;
}

export function clearSelection() {
  selected.clear();
  selectionChanged();
}

function toggleSelected(id, on) {
  if (on) selected.add(id);
  else selected.delete(id);
  selectionChanged();
}

// Selection only flips classes, so thumbnails aren't rebuilt on every click.
function selectionChanged() {
  const gallery = $("#gallery");
  gallery.classList.toggle("has-selection", selected.size > 0);
  gallery.querySelectorAll(".card").forEach((card) => {
    const on = selected.has(card.dataset.id);
    card.classList.toggle("is-selected", on);
    card.querySelector(".check input").checked = on;
  });
  const items = getSelected();
  selectionListeners.forEach((fn) => fn(items));
}

// View URLs are signed and expire after 15 minutes. If one fails to load, fetch fresh ones (at most once a minute).
let lastRefresh = 0;
function refreshExpiredUrls() {
  if (Date.now() - lastRefresh < 60_000) return;
  lastRefresh = Date.now();
  loadImages().catch(() => {});
}

function listHead() {
  const head = document.createElement("div");
  head.className = "list-head";
  head.setAttribute("aria-hidden", "true");
  for (const label of ["", "", "Name", "Size", "Uploaded"]) {
    const cell = document.createElement("span");
    cell.textContent = label;
    head.append(cell);
  }
  return head;
}

function card(image, index) {
  const name = image.name || "Untitled image";
  const el = document.createElement("div");
  el.className = "card";
  el.dataset.id = image.id;

  const check = document.createElement("label");
  check.className = "check";
  check.innerHTML = `<input type="checkbox" /><span><svg class="icon" aria-hidden="true"><use href="#i-check" /></svg></span>`;
  const box = check.querySelector("input");
  box.setAttribute("aria-label", `Select ${name}`);
  box.addEventListener("change", () => toggleSelected(image.id, box.checked));

  const thumb = document.createElement("button");
  thumb.type = "button";
  thumb.className = "card-thumb";
  thumb.setAttribute("aria-label", `Open ${name}`);
  thumb.addEventListener("click", () => openImage(index));

  const img = document.createElement("img");
  img.alt = "";
  img.loading = "lazy";
  img.decoding = "async";
  img.addEventListener("load", () => el.classList.add("is-loaded"), { once: true });
  // Ignore errors from thumbnails a re-render already threw away.
  img.addEventListener("error", () => img.isConnected && refreshExpiredUrls(), { once: true });
  img.src = image.url;
  thumb.append(img);

  const body = document.createElement("div");
  body.className = "card-body";
  const title = document.createElement("span");
  title.className = "card-name";
  title.textContent = name;
  title.title = name;
  const meta = document.createElement("span");
  meta.className = "card-meta";
  const size = document.createElement("span");
  size.className = "card-size";
  size.textContent = formatBytes(image.size);
  const date = document.createElement("span");
  date.className = "card-date";
  date.textContent = formatDate(image.createdAt);
  meta.append(size, date);
  body.append(title, meta);

  el.append(check, thumb, body);
  return el;
}

function render() {
  visible = images
    .filter((image) => (image.name || "").toLowerCase().includes(query))
    .sort(sorters[sort]);

  const gallery = $("#gallery");
  gallery.replaceChildren(
    ...(visible.length ? [listHead()] : []),
    ...visible.map(card),
  );
  selectionChanged();

  $("#empty").hidden = images.length > 0;
  const noResults = images.length > 0 && visible.length === 0;
  $("#no-results").hidden = !noResults;
  if (noResults) $("#no-results").textContent = `No images match “${query}”`;
}
