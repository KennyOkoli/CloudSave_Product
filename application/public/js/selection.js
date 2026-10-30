import { api } from "./api.js";
import { $, plural, toast } from "./ui.js";
import { clearSelection, getSelected, onSelectionChange, removeImage } from "./gallery.js";

function setConfirming(on) {
  $("#sel-actions").hidden = on;
  $("#sel-confirm").hidden = !on;
  if (on) $("#sel-cancel").focus();
}

async function deleteSelected() {
  const items = getSelected();
  $("#sel-delete").disabled = true;
  const results = await Promise.allSettled(
    items.map(async (image) => {
      await api(`/api/files/${image.id}`, { method: "DELETE" });
      removeImage(image.id);
    }),
  );
  $("#sel-delete").disabled = false;

  const failed = results.filter((r) => r.status === "rejected").length;
  const deleted = items.length - failed;
  if (deleted) toast(`Deleted ${plural(deleted, "image")}`);
  if (failed) toast(`Couldn't delete ${plural(failed, "image")}`, { error: true });
}

export function initSelection() {
  onSelectionChange((items) => {
    $("#selection-bar").hidden = items.length === 0;
    $("#sel-count").textContent = `${items.length} selected`;
    if (!items.length) setConfirming(false);
  });

  $("#sel-clear").addEventListener("click", clearSelection);
  $("#sel-ask-delete").addEventListener("click", () => setConfirming(true));
  $("#sel-cancel").addEventListener("click", () => setConfirming(false));
  $("#sel-delete").addEventListener("click", deleteSelected);

  document.addEventListener("keydown", (e) => {
    if (e.key === "Escape" && !$("#lightbox").open && getSelected().length) clearSelection();
  });
}
