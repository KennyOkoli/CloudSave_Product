import { api } from "./api.js";
import { $ } from "./ui.js";

// The single list of images the gallery and lightbox both read from.
let images = [];
const listeners = new Set();
let openImage = () => {};

export const getImages = () => images;
export const onImagesChange = (fn) => listeners.add(fn);
export const onOpenImage = (fn) => (openImage = fn);

function changed() {
  render();
  listeners.forEach((fn) => fn(images));
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
  changed();
}

// View URLs are signed and expire after 15 minutes. If one fails to load, fetch fresh ones (at most once a minute).
let lastRefresh = 0;
function refreshExpiredUrls() {
  if (Date.now() - lastRefresh < 60_000) return;
  lastRefresh = Date.now();
  loadImages().catch(() => {});
}

function render() {
  const gallery = $("#gallery");
  gallery.replaceChildren(
    ...images.map((image, index) => {
      const frame = document.createElement("button");
      frame.type = "button";
      frame.className = "frame";
      frame.setAttribute("aria-label", `Open ${image.name || "image"}`);
      frame.addEventListener("click", () => openImage(index));

      const img = document.createElement("img");
      img.alt = "";
      img.loading = "lazy";
      img.decoding = "async";
      img.addEventListener("load", () => frame.classList.add("is-loaded"), {
        once: true,
      });
      // Ignore errors from thumbnails a re-render already threw away.
      img.addEventListener(
        "error",
        () => img.isConnected && refreshExpiredUrls(),
        { once: true },
      );
      img.src = image.url;

      frame.append(img);
      return frame;
    }),
  );
  $("#empty").hidden = images.length > 0;
}
