import { api, ApiError } from "./api.js";
import { $, formatBytes, plural } from "./ui.js";
import { addImage } from "./gallery.js";

const ALLOWED = ["image/jpeg", "image/png", "image/webp", "image/gif"];
const MAX_BYTES = 10 * 1024 * 1024;
const PARALLEL = 3;


// PUT to the signed S3 URL. XHR instead of fetch because fetch can't report upload progress.
function putToS3(url, file, onProgress) {
  return new Promise((resolve, reject) => {
    const xhr = new XMLHttpRequest();
    xhr.open("PUT", url);
    xhr.setRequestHeader("Content-Type", file.type); // must match what the server signed
    xhr.upload.addEventListener("progress", (e) => {
      if (e.lengthComputable) onProgress(e.loaded / e.total);
    });
    xhr.addEventListener("load", () =>
      xhr.status < 300
        ? resolve()
        : reject(new Error(`Storage rejected the upload (${xhr.status})`)),
    );
    xhr.addEventListener("error", () =>
      reject(new Error("Couldn't reach storage")),
    );
    xhr.send(file);
  });
}

function validate(file) {
  if (!ALLOWED.includes(file.type)) return "Not a JPEG, PNG, WebP or GIF";
  if (file.size > MAX_BYTES) return `${formatBytes(file.size)} is over 10 MB`;
  return null;
}

async function uploadOne(file, row) {
  const problem = validate(file);
  if (problem) throw new Error(problem);

  // 1. Our server records the file against this user and signs an upload URL.
  const { id, uploadUrl } = await api("/api/uploads", {
    method: "POST",
    body: { contentType: file.type, size: file.size, name: file.name },
  });
  // 2. The bytes go straight to S3.
  row.setState("uploading");
  await putToS3(uploadUrl, file, row.setProgress);
  // 3. Our server checks the object landed and marks it ready.
  row.setState("checking");
  return api(`/api/uploads/${id}/complete`, { method: "POST" });
}

function trayRow(file) {
  const li = document.createElement("li");
  li.className = "tray-item";
  li.dataset.state = "waiting";

  const thumb = document.createElement("img");
  thumb.alt = "";
  const preview = file.type.startsWith("image/")
    ? URL.createObjectURL(file)
    : "";
  if (preview) thumb.src = preview;
  else thumb.style.visibility = "hidden";

  const name = document.createElement("span");
  name.className = "tray-name";
  name.textContent = file.name;

  const status = document.createElement("span");
  status.className = "tray-status";
  status.textContent = "Waiting";

  const bar = document.createElement("span");
  bar.className = "tray-bar";

  li.append(thumb, name, status, bar);
  $("#tray-list").append(li);

  const labels = { uploading: "Uploading", checking: "Saving", done: "Done" };
  return {
    setState(state, message) {
      li.dataset.state = state;
      status.textContent = message ?? labels[state];
      if (state === "done" || state === "failed") URL.revokeObjectURL(preview);
    },
    setProgress(fraction) {
      li.style.setProperty("--progress", fraction);
      status.textContent = `${Math.round(fraction * 100)}%`;
    },
  };
}

let active = 0;

export async function uploadFiles(fileList) {
  const files = [...fileList];
  if (!files.length) return;

  $("#tray").hidden = false;
  const queue = files.map((file) => ({ file, row: trayRow(file) }));
  let failed = 0;
  active += files.length;

  async function worker() {
    for (let job = queue.shift(); job; job = queue.shift()) {
      try {
        addImage(await uploadOne(job.file, job.row));
        job.row.setState("done");
      } catch (err) {
        failed++;
        job.row.setState("failed", err.message);
        if (err instanceof ApiError && err.status === 401) location.reload();
      }
    }
  }
  await Promise.all(Array.from({ length: PARALLEL }, worker));

  active -= files.length;
  if (active === 0) finishTray(failed);
}

function finishTray(failed) {
  const clear = () => {
    $("#tray-list").replaceChildren();
    $("#tray").hidden = true;
  };
  if (!failed) return setTimeout(() => active === 0 && clear(), 2500);

  // Leave failures on screen until dismissed.
  $("#tray-list")
    .querySelectorAll('[data-state="done"]')
    .forEach((li) => li.remove());
  const dismiss = document.createElement("li");
  dismiss.className = "tray-dismiss";
  dismiss.innerHTML = `<span></span><button type="button" class="btn btn-quiet">Dismiss</button>`;
  dismiss.querySelector("span").textContent =
    `${plural(failed, "upload")} failed`;
  dismiss.querySelector("button").addEventListener("click", clear);
  $("#tray-list").prepend(dismiss);
}

// Drag files anywhere over the window to upload.
export function enableDropUploads(isSignedIn) {
  const overlay = $("#drop-overlay");
  let depth = 0;
  const hasFiles = (e) => e.dataTransfer?.types.includes("Files");

  window.addEventListener("dragenter", (e) => {
    if (!hasFiles(e) || !isSignedIn()) return;
    e.preventDefault();
    depth++;
    overlay.hidden = false;
  });
  window.addEventListener("dragover", (e) => {
    if (hasFiles(e)) e.preventDefault();
  });
  window.addEventListener("dragleave", () => {
    if (depth && --depth === 0) overlay.hidden = true;
  });
  window.addEventListener("drop", (e) => {
    if (!hasFiles(e)) return;
    e.preventDefault();
    depth = 0;
    overlay.hidden = true;
    if (isSignedIn()) uploadFiles(e.dataTransfer.files);
  });
}
