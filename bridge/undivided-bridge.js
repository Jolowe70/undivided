// UNDIVIDED bridge for the Firebase sites (The Integrity Commons, The Three Fires).
// Drop this file into each site and import it. No npm packages and no Supabase SDK are needed.
//
// How the link works
//   1. A player finishes Undivided and ticks "Carry my scores with me".
//   2. The game opens your site as  https://theintegritycommons.com/?ud=AB12CD34
//   3. readUndividedHandoff() reads that code and fetches the player's SCORES (never their written answers).
//   4. You save the code and summary on the player's Firebase user doc.
//   5. Later, with the player's consent, attachToUndivided() sends back TOTALS from your instrument
//      (e.g. IPI domain scores or the FIRE Index), so behaviour (game) and self-report (IPI) can be compared.
//
// Codes expire 30 days after the player creates them.

const UD = {
  supabaseUrl: "https://YOUR-PROJECT-REF.supabase.co",   // same values as the game's config.js
  supabaseKey: "YOUR-ANON-OR-PUBLISHABLE-KEY"
};

async function rpc(name, args) {
  const r = await fetch(`${UD.supabaseUrl.replace(/\/$/, "")}/rest/v1/rpc/${name}`, {
    method: "POST",
    headers: { "Content-Type": "application/json", apikey: UD.supabaseKey },
    body: JSON.stringify(args)
  });
  if (!r.ok) throw new Error(`Undivided ${name} failed (${r.status})`);
  return r.json();
}

/** Reads ?ud=CODE from the current URL. Returns {code, summary} or null if there is no valid code. */
export async function readUndividedHandoff() {
  const code = new URLSearchParams(location.search).get("ud");
  if (!code || !/^[A-Za-z0-9]{6,10}$/.test(code)) return null;
  try {
    const summary = await rpc("ud_get_link_summary", { p_code: code });
    if (!summary) return null;
    try { sessionStorage.setItem("undividedCode", code.toUpperCase()); } catch (_) {}
    return { code: code.toUpperCase(), summary };
  } catch (_) { return null; }
}

/** Remembered code for the rest of the visit (survives page changes, not new tabs). */
export function undividedCodeThisVisit() {
  try { return sessionStorage.getItem("undividedCode"); } catch (_) { return null; }
}

/**
 * Sends your instrument's totals back to Undivided. Call only after the player agrees.
 * source: "integrity-commons" or "three-fires"
 * externalRef: something you can match later WITHOUT identifying the person, e.g. a SHA-256 of the Firebase uid.
 * summary: totals only, e.g. { ipi_total: 72, domains: { honesty: 80, ... } }. Max ~8 KB.
 */
export async function attachToUndivided({ code, source, externalRef, summary }) {
  return rpc("ud_attach_external", { p_code: code, p_source: source, p_ref: externalRef ?? null, p_summary: summary ?? {} });
}

/** Helper: SHA-256 hex of a string (use on the Firebase uid before sending it as externalRef). */
export async function hashId(s) {
  const b = await crypto.subtle.digest("SHA-256", new TextEncoder().encode(String(s)));
  return Array.from(new Uint8Array(b)).map(x => x.toString(16).padStart(2, "0")).join("");
}

/* ---------------- Example (Integrity Commons, Firebase v9+ modular) ----------------
import { readUndividedHandoff, attachToUndivided, hashId, undividedCodeThisVisit } from "./undivided-bridge.js";
import { doc, setDoc, serverTimestamp } from "firebase/firestore";

// On page load, after Firebase Auth has a user:
const handoff = await readUndividedHandoff();
if (handoff && auth.currentUser) {
  await setDoc(doc(db, "users", auth.currentUser.uid),
    { undivided: { code: handoff.code, summary: handoff.summary, linkedAt: serverTimestamp() } }, { merge: true });
  // e.g. show: "Welcome from Undivided. Your Integrity Quotient was " + handoff.summary.iq
}

// After the player finishes the IPI and ticks "Share my totals with Undivided for research":
const code = handoff?.code || undividedCodeThisVisit();
if (code) await attachToUndivided({
  code, source: "integrity-commons",
  externalRef: await hashId(auth.currentUser.uid),
  summary: { ipi_total: ipiTotal, domains: ipiDomainScores }   // totals only, never item answers
});
------------------------------------------------------------------------------------- */
