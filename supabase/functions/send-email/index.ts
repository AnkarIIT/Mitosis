import { createClient } from "npm:@supabase/supabase-js@2";

// =============================================================================
//  send-email — transactional email for NEET Mitosis
// =============================================================================
//  Delivers password-reset, 2FA, verification and security-notice email through
//  a transactional provider.
//
//  ## Why this exists
//  The client previously had no usable mail path at all: `EmailService` read a
//  backend URL from SharedPreferences that no screen ever wrote, so
//  `isConfigured` was permanently false and password-reset / 2FA mail could
//  never be delivered. There was also no Edge Function behind it.
//
//  ## Design constraints
//
//  * **No HTML from the client.** The request carries a template *name*, never
//    markup. The client previously interpolated `users.username` into security
//    email HTML unescaped, which let a crafted username render as markup in
//    every reset and 2FA message. Owning the HTML here closes that class of bug
//    on both sides of the wire.
//
//  * **Authenticated, rate-limited, allowlisted.** Mirrors gemini-proxy's
//    posture. Without this the function is an open relay that spends the
//    provider's quota on behalf of anyone who learns the URL.
//
//  * **Provider secret never leaves the server.** RESEND_API_KEY is a Supabase
//    secret; the device only ever holds the anon key.
//
//  ## Configuration
//  supabase secrets set RESEND_API_KEY=<key>
//  supabase secrets set EMAIL_FROM="NEET Mitos <no-reply@yourdomain.com>"
//  supabase secrets set ALLOWED_ORIGINS=https://your.app,http://localhost:3000
//
//  ## Deploy
//  supabase functions deploy send-email
//  (JWT verification stays ON — that is what scopes sending to a session.)
// =============================================================================

const ALLOWED_ORIGINS = (Deno.env.get("ALLOWED_ORIGINS") ?? "")
  .split(",")
  .map((o) => o.trim())
  .filter((o) => o.length > 0);

/** Reads a positive-integer ceiling from the environment.
 *
 *  `Number(env ?? fallback)` fails OPEN on a bad value: `Number("")` is 0,
 *  `Number("30/hour")` is NaN, and every `count >= NaN` comparison is false —
 *  so a one-character config typo silently removes the only spend ceiling.
 *  Anything unparseable falls back to the documented default instead. */
function readLimit(name: string, fallback: number): number {
  const raw = Deno.env.get(name);
  if (raw === undefined || raw.trim() === "") return fallback;
  const parsed = Number(raw);
  if (!Number.isFinite(parsed) || parsed <= 0) {
    console.error(
      `send-email: ${name}="${raw}" is not a positive number; using ${fallback}`,
    );
    return fallback;
  }
  return Math.floor(parsed);
}

/** Per-identity hourly ceiling for live sends. */
const RATE_LIMIT_PER_HOUR = readLimit("EMAIL_RATE_LIMIT", 10);
/** Per-recipient ceiling, independent of identity, so one target cannot be
 *  hammered by rotating sessions. */
const RATE_LIMIT_PER_RECIPIENT = readLimit(
  "EMAIL_RATE_LIMIT_PER_RECIPIENT",
  5,
);
const WINDOW_MS = 60 * 60 * 1000;

/** Templates the function will render. Anything else is rejected, so a caller
 *  cannot smuggle arbitrary content through the `template` field. */
const TEMPLATES = {
  password_reset: { subject: "Reset your NEET Mitosis password" },
  login_verification: { subject: "Your NEET Mitosis sign-in code" },
  two_factor_enable: {
    subject: "Turn on two-factor authentication",
  },
  email_verification: { subject: "Verify your email address" },
  welcome: { subject: "Welcome to NEET Mitosis" },
  account_deleted: { subject: "Your NEET Mitosis account was deleted" },
  security_notice: { subject: "A security change on your account" },
} as const;

type TemplateName = keyof typeof TEMPLATES;

/** True when [origin] is on the allowlist. */
function isOriginAllowed(origin: string): boolean {
  return ALLOWED_ORIGINS.includes(origin);
}

function json(
  data: unknown,
  status = 200,
  origin: string | null = null,
): Response {
  const allowed = origin && isOriginAllowed(origin);
  return new Response(JSON.stringify(data), {
    status,
    headers: {
      ...(allowed ? { "Access-Control-Allow-Origin": origin } : {}),
      "Access-Control-Allow-Headers":
        "authorization, x-client-info, apikey, content-type",
      "Access-Control-Allow-Methods": "POST, OPTIONS",
      "Vary": "Origin",
      "Content-Type": "application/json",
    },
  });
}

/** Escapes text for HTML interpolation. The single most important function
 *  here: every user-influenced value passes through it. */
function escapeHtml(value: string): string {
  return value
    .replaceAll("&", "&amp;")
    .replaceAll("<", "&lt;")
    .replaceAll(">", "&gt;")
    .replaceAll('"', "&quot;")
    .replaceAll("'", "&#39;");
}

/** Trims and length-caps free text so a hostile value cannot bloat a mail. */
function clean(value: unknown, max = 200): string {
  if (typeof value !== "string") return "";
  return value.trim().slice(0, max);
}

/** Rejects anything that is not a single, plausibly-formed address. */
function isValidEmail(value: string): boolean {
  return /^[^\s@]+@[^\s@]+\.[^\s@]{2,}$/.test(value) && value.length <= 254;
}

function renderHtml(
  template: TemplateName,
  purpose: string,
  username: string,
  code: string,
): string {
  const greeting = username
    ? `Hi ${escapeHtml(username)},`
    : "Hi there,";
  const reason = escapeHtml(
    purpose || "complete a request on your account",
  );

  const codeBlock = code
    ? `
    <p style="margin:24px 0;">
      <span style="display:inline-block;font-size:30px;font-weight:700;
        letter-spacing:6px;padding:14px 22px;border-radius:10px;
        background:#eef2ff;color:#3730a3;">${escapeHtml(code)}</span>
    </p>
    <p style="margin:0 0 8px;font-size:13px;color:#6b7280;">
      This code expires in 15 minutes.</p>`
    : "";

  return `<!doctype html>
<html><body style="margin:0;padding:0;background:#f9fafb;">
<div style="font-family:-apple-system,Segoe UI,Roboto,Helvetica,Arial,sans-serif;
  max-width:560px;margin:0 auto;padding:24px;color:#111827;background:#ffffff;">
  <div style="border-bottom:3px solid #4f46e5;padding-bottom:14px;margin-bottom:22px;">
    <span style="font-size:19px;font-weight:700;color:#4f46e5;">NEET Mitosis</span>
  </div>
  <p style="margin:0 0 14px;font-size:15px;line-height:1.55;">${greeting}</p>
  <p style="margin:0 0 6px;font-size:15px;line-height:1.55;">
    Use this email to ${reason}.</p>
  ${codeBlock}
  <p style="margin:22px 0 0;font-size:13px;line-height:1.6;color:#4b5563;">
    If you did not request this, no action is needed &mdash; you can ignore this
    message and nothing has changed on your account.</p>
  <div style="margin-top:26px;padding-top:16px;border-top:1px solid #e5e7eb;
    font-size:12px;line-height:1.6;color:#6b7280;">
    <p style="margin:0 0 6px;">NEET Mitosis &middot; support@neetmitos.app</p>
    <p style="margin:0;">Read our
      <a href="https://neetmitos.app/privacy" style="color:#4f46e5;">Privacy Policy</a>
      and <a href="https://neetmitos.app/terms" style="color:#4f46e5;">Terms</a>.
    </p>
  </div>
</div>
</body></html>`;
}

/** Strips characters that let a caller forge extra lines or a fake URL in the
 *  text/plain part of a branded security email.
 *
 *  The HTML path escapes via escapeHtml(); this path interpolates the same
 *  caller-controlled `username`, `purpose` and `code` raw. That is not HTML or
 *  header injection (the body goes through the provider's JSON API), but a
 *  username of `Alice\nhttps://evil.example/reset` rendered as a real-looking
 *  second line in the plain-text alternative. The asymmetry was unintentional. */
function cleanText(value: string, max: number): string {
  return value.trim().slice(0, max).replace(/[\r\n\t]+/g, " ");
}

/** Plain-text alternative. Some clients and filters prefer it. */
function renderText(purpose: string, username: string, code: string): string {
  const who = username ? `Hi ${cleanText(username, 80)},` : "Hi there,";
  const lines = [
    who,
    "",
    `Use this email to ${cleanText(purpose, 120)}.`,
  ];
  if (code) {
    lines.push(
      "",
      `Your code: ${cleanText(code, 12)}`,
      "This code expires in 15 minutes.",
    );
  }
  lines.push(
    "",
    "If you did not request this, no action is needed.",
    "",
    "NEET Mitosis",
    "Privacy: https://neetmitos.app/privacy",
    "Terms: https://neetmitos.app/terms",
  );
  return lines.join("\n");
}

Deno.serve(async (req) => {
  const origin = req.headers.get("Origin");
  if (req.method === "OPTIONS") return json({ ok: true }, 200, origin);
  if (req.method !== "POST") return json({ error: "Method not allowed" }, 405, origin);

  // Reject disallowed origins outright rather than merely omitting the CORS
  // header. The browser would block the response, but the handler had already
  // run and already sent real mail on the app's sending domain.
  if (origin && !isOriginAllowed(origin)) {
    return json({ error: "Origin not allowed" }, 403, null);
  }

  const apiKey = Deno.env.get("RESEND_API_KEY");
  const from = Deno.env.get("EMAIL_FROM");
  if (!apiKey || !from) {
    console.error("send-email: RESEND_API_KEY / EMAIL_FROM not configured");
    return json({ error: "Email service is not configured" }, 503, origin);
  }

  // ── Authenticate ─────────────────────────────────────────────────────────
  // The provider key must never be reachable by an anonymous caller.
  const authHeader = req.headers.get("Authorization");
  const token = authHeader?.startsWith("Bearer ") ? authHeader.slice(7) : null;
  if (!token) return json({ error: "Unauthorized" }, 401, origin);

  const supabase = createClient(
    Deno.env.get("SUPABASE_URL")!,
    Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!,
  );
  const { data, error: userErr } = await supabase.auth.getUser(token);
  if (userErr || !data.user?.id) {
    return json({ error: "Unauthorized" }, 401, origin);
  }
  const identity = data.user.id;

  // ── Validate ─────────────────────────────────────────────────────────────
  let body: Record<string, unknown>;
  try {
    body = await req.json();
  } catch {
    return json({ error: "Invalid JSON body" }, 400, origin);
  }

  const template = clean(body.template, 40);
  // `in` walks the prototype chain, so "toString"/"constructor"/"__proto__"
  // passed the guard and resolved `meta.subject` to undefined. Own-property
  // check only.
  if (!Object.hasOwn(TEMPLATES, template)) {
    return json({ error: "Unknown template" }, 400, origin);
  }
  const templateName = template as TemplateName;

  const to = clean(body.to, 254).trim().toLowerCase();
  if (!isValidEmail(to)) {
    return json({ error: "Invalid recipient" }, 400, origin);
  }

  // The recipient must be the authenticated account's own verified address.
  // Otherwise any signed-up user can send a branded password-reset mail, with
  // attacker-chosen greeting and body text, to an arbitrary victim on the
  // app's real sending domain. Rejecting foreign addresses preserves
  // anti-enumeration: a caller still cannot probe whether an account exists,
  // because the request simply never sends.
  const accountEmail = (data.user.email ?? "").trim().toLowerCase();
  if (!accountEmail || to !== accountEmail) {
    console.warn(
      `send-email: rejected foreign recipient for identity ${identity}`,
    );
    return json(
      { error: "Recipient must match the signed-in account" },
      403,
      origin,
    );
  }

  const username = clean(body.username, 80);
  const code = clean(body.code, 12);
  const purpose = clean(body.purpose, 120) || "complete a request on your account";

  // ── Rate limit ───────────────────────────────────────────────────────────
  // Two independent ceilings: per session, and per recipient. The second matters
  // because rotating sessions must not let one mailbox be flooded.
  const windowStart = new Date(Date.now() - WINDOW_MS).toISOString();

  const { count: byIdentity, error: identityCountErr } = await supabase
    .from("email_send_log")
    .select("*", { count: "exact", head: true })
    .eq("identity", identity)
    .gte("created_at", windowStart);

  // Fail CLOSED. Both count queries discard their error, so `count` came back
  // undefined, `?? 0` compared `0 >= limit` as false, and the send proceeded —
  // turning any DB fault (missing table, 5xx, stale schema cache) into an
  // unlimited relay. A limiter we could not evaluate is never "allowed".
  if (identityCountErr) {
    console.error(
      "send-email: identity rate-limit query failed",
      identityCountErr,
    );
    return json(
      { error: "Email service is temporarily unavailable" },
      503,
      origin,
    );
  }

  if ((byIdentity ?? 0) >= RATE_LIMIT_PER_HOUR) {
    return json(
      { error: "Rate limit exceeded. Please try again in an hour." },
      429,
      origin,
    );
  }

  const { count: byRecipient, error: recipientCountErr } = await supabase
    .from("email_send_log")
    .select("*", { count: "exact", head: true })
    .eq("recipient", to)
    .gte("created_at", windowStart);

  if (recipientCountErr) {
    console.error(
      "send-email: recipient rate-limit query failed",
      recipientCountErr,
    );
    return json(
      { error: "Email service is temporarily unavailable" },
      503,
      origin,
    );
  }

  if ((byRecipient ?? 0) >= RATE_LIMIT_PER_RECIPIENT) {
    return json(
      { error: "Rate limit exceeded. Please try again later." },
      429,
      origin,
    );
  }

  // ── Send ─────────────────────────────────────────────────────────────────
  const meta = TEMPLATES[templateName];
  try {
    const res = await fetch("https://api.resend.com/emails", {
      method: "POST",
      headers: {
        Authorization: `Bearer ${apiKey}`,
        "Content-Type": "application/json",
      },
      body: JSON.stringify({
        // `from` is fixed server-side. The client cannot choose a sender, which
        // is what stops this endpoint being used to spoof.
        from,
        to,
        subject: meta.subject,
        html: renderHtml(templateName, purpose, username, code),
        text: renderText(purpose, username, code),
      }),
    });

    // Record the attempt either way, so a failing provider still consumes
    // budget and cannot be retried into a bill.
    await supabase.from("email_send_log").insert({ identity, recipient: to });

    if (!res.ok) {
      const detail = (await res.text()).slice(0, 400);
      console.error(`send-email: provider ${res.status}: ${detail}`);
      return json({ error: "Email could not be sent" }, 502, origin);
    }

    return json({ ok: true }, 200, origin);
  } catch (error) {
    await supabase.from("email_send_log").insert({ identity, recipient: to });
    console.error("send-email: request failed", error);
    return json({ error: "Email service unavailable" }, 502, origin);
  }
});