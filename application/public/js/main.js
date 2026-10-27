import { api } from "./api.js";
import { $, formatDate, plural, toast } from "./ui.js";
import { initAuth } from "./auth.js";
import { clearImages, loadImages, onImagesChange, onOpenImage } from "./gallery.js";
import { enableDropUploads, uploadFiles } from "./uploads.js";
import { openLightbox } from "./lightbox.js";

let me = null;

function renderMeta() {
  if (!me) return;
  $("#user-meta").textContent =
    `${plural(me.imageCount, "image")}, joined ${formatDate(me.createdAt)}`;
}

async function showApp() {
  me = await api("/api/me");
  $("#username").textContent = `@${me.username}`;
  document.title = `@${me.username} · S3 Uploads`;
  renderMeta();

  $("#auth-view").hidden = true;
  $("#app-view").hidden = false;
  await loadImages();
}

function showAuth() {
  me = null;
  clearImages();
  document.title = "S3 Uploads";
  $("#app-view").hidden = true;
  $("#auth-view").hidden = false;
  $("#auth-form").username.focus();
}

initAuth({ onSignedIn: showApp, onSignedOut: showAuth });
onOpenImage(openLightbox);

// The count in the header follows the gallery, so uploads and deletes update it without a refetch.
onImagesChange((images) => {
  if (me) me.imageCount = images.length;
  renderMeta();
});

$("#file-input").addEventListener("change", (e) => {
  uploadFiles(e.target.files);
  e.target.value = ""; // so choosing the same file again still fires "change"
});
enableDropUploads(() => Boolean(me));

showApp().catch((err) => {
  showAuth();
  if (err.status !== 401) toast(err.message, { error: true });
});
