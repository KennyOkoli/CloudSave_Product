import { api } from "./api.js";
import { $ } from "./ui.js";

let mode = "login";

function setMode(next) {
  mode = next;
  document.querySelectorAll(".switch [data-mode]").forEach((tab) => {
    tab.setAttribute("aria-selected", String(tab.dataset.mode === mode));
  });
  const registering = mode === "register";
  $("#auth-submit").textContent = registering ? "Create account" : "Log in";
  $("#password-hint").hidden = !registering;
  $("#auth-form").password.autocomplete = registering
    ? "new-password"
    : "current-password";
  showError(null);
}

function showError(message) {
  $("#auth-error").textContent = message ?? "";
  $("#auth-error").hidden = !message;
}

export function initAuth({ onSignedIn, onSignedOut }) {
  document
    .querySelectorAll(".switch [data-mode]")
    .forEach((tab) =>
      tab.addEventListener("click", () => setMode(tab.dataset.mode)),
    );

  $("#auth-form").addEventListener("submit", async (e) => {
    e.preventDefault();
    const form = e.currentTarget;
    const username = form.username.value.trim();
    const password = form.password.value;
    if (!username || !password) return showError("Enter a username and password");

    $("#auth-submit").disabled = true;
    try {
      await api(`/api/auth/${mode}`, {
        method: "POST",
        body: { username, password },
      });
      form.reset();
      setMode("login");
      await onSignedIn();
    } catch (err) {
      showError(err.message);
    } finally {
      $("#auth-submit").disabled = false;
    }
  });

  $("#logout").addEventListener("click", async () => {
    await api("/api/auth/logout", { method: "POST" });
    onSignedOut();
  });
}
