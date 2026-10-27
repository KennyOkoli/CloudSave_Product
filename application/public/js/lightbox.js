import { api } from "./api.js";
import { $, formatBytes, formatDate, toast } from "./ui.js";
import { getImages, onImagesChange, removeImage } from "./gallery.js";

const dialog = $("#lightbox");
// Track the open image by id, not list position: the list can reload or
// reorder while the lightbox is open, and a stale index would point at
// (and delete) the wrong image.
let currentId = null;
let lastIndex = 0;
let returnFocusTo = null;

function currentIndex() {
  return getImages().findIndex((image) => image.id === currentId);
}

export function openLightbox(i) {
  currentId = getImages()[i]?.id ?? null;
  returnFocusTo = document.activeElement;
  render();
  dialog.showModal();
}

function close() {
  dialog.close();
}

function step(delta) {
  const images = getImages();
  const next = (currentIndex() + delta + images.length) % images.length;
  currentId = images[next].id;
  render();
}

function setConfirming(on) {
  $("#lb-actions").hidden = on;
  $("#lb-confirm").hidden = !on;
  if (on) $('[data-action="cancel-delete"]').focus();
}

function render() {
  const images = getImages();
  const index = currentIndex();
  const image = images[index];
  if (!image) return;
  lastIndex = index;

  $("#lb-img").src = image.url;
  $("#lb-img").alt = image.name || "";
  $("#lb-name").textContent = image.name || "Untitled image";
  $("#lb-details").textContent =
    `${formatBytes(image.size)}, uploaded ${formatDate(image.createdAt)}`;
  $("#lb-count").textContent = `${index + 1} of ${images.length}`;
  $("#lb-open").href = image.url;
  dialog.classList.toggle("is-single", images.length < 2);
  setConfirming(false);

  // Warm the cache so arrowing through feels instant.
  for (const near of [images[index + 1], images[index - 1]]) {
    if (near) new Image().src = near.url;
  }
}

async function deleteCurrent() {
  const image = getImages()[currentIndex()];
  if (!image) return;
  const button = $('[data-action="delete"]');
  button.disabled = true;
  try {
    await api(`/api/files/${image.id}`, { method: "DELETE" });
    removeImage(image.id);
    toast(`Deleted ${image.name || "image"}`);
  } catch (err) {
    toast(err.message, { error: true });
    setConfirming(false);
  } finally {
    button.disabled = false;
  }
}

// Keep the lightbox in step when the list changes underneath it (delete, new upload).
onImagesChange((images) => {
  if (!dialog.open) return;
  if (!images.length) return close();
  // If the open image was deleted, show whichever one slid into its place.
  if (currentIndex() === -1) {
    currentId = images[Math.min(lastIndex, images.length - 1)].id;
  }
  render();
});

dialog.addEventListener("click", (e) => {
  const action = e.target.closest("[data-action]")?.dataset.action;
  if (action === "close") close();
  if (action === "prev") step(-1);
  if (action === "next") step(1);
  if (action === "ask-delete") setConfirming(true);
  if (action === "cancel-delete") setConfirming(false);
  if (action === "delete") deleteCurrent();
  // A click on the backdrop lands on the <dialog> or the stage itself, not on the image or controls.
  if (e.target === dialog || e.target.classList.contains("lb-stage")) close();
});

dialog.addEventListener("keydown", (e) => {
  if (e.target.closest("button, a") && e.key === "Enter") return;
  if (e.key === "ArrowLeft") step(-1);
  if (e.key === "ArrowRight") step(1);
});

dialog.addEventListener("close", () => {
  $("#lb-img").removeAttribute("src");
  returnFocusTo?.focus();
});
