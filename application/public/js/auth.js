import { api } from "./api.js";
import { $ } from "./ui.js";

let mode = "login";

function setMode(next) {
  mode = next;
  const registering = mode === "register";
  $("#auth-title").textContent = registering ? "Create your account" : "Welcome back";
  $("#auth-lede").textContent = registering
    ? "Start saving your images to CloudSave"
    : "Log in to your CloudSave account";
  $("#auth-switch-text").textContent = registering ? "Already have an account?" : "New to CloudSave?";
  $("#auth-switch").textContent = registering ? "Log in" : "Create an account";
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
  $("#auth-switch").addEventListener("click", () =>
    setMode(mode === "login" ? "register" : "login"),
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
    $("#account-menu").hidePopover();
    await api("/api/auth/logout", { method: "POST" });
    onSignedOut();
  });
}
