import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2.39.7";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
};

const OTP_TTL_MS = 10 * 60 * 1000; // 10 minutes
const RESEND_COOLDOWN_MS = 60 * 1000; // 1 minute
const MAX_ATTEMPTS = 5;

async function sha256Hex(input: string): Promise<string> {
  const data = new TextEncoder().encode(input);
  const digest = await crypto.subtle.digest("SHA-256", data);
  return Array.from(new Uint8Array(digest))
    .map((b) => b.toString(16).padStart(2, "0"))
    .join("");
}

function generateOtp(): string {
  const buf = new Uint8Array(3);
  crypto.getRandomValues(buf);
  const value = (buf[0] << 16) | (buf[1] << 8) | buf[2];
  return String(value % 1000000).padStart(6, "0");
}

function json(body: unknown, status = 200): Response {
  return new Response(JSON.stringify(body), {
    headers: { ...corsHeaders, "Content-Type": "application/json" },
    status,
  });
}

serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  const supabaseUrl = Deno.env.get("SUPABASE_URL") ?? "";
  const supabaseServiceKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? "";
  const supabase = createClient(supabaseUrl, supabaseServiceKey);

  try {
    const body = await req.json();
    const action = String(body.action || "");
    const email = String(body.email || "").toLowerCase().trim();
    const purpose = String(body.purpose || "signup").trim();
    const code = String(body.code || "").trim();
    console.log(`[send-otp] Request received: action=${action}, email=${email}, purpose=${purpose}`);

    if (!["signup", "password_reset"].includes(purpose)) {
      return json({ success: false, error: "Invalid purpose." }, 400);
    }
    if (!email || !email.includes("@")) {
      return json({ success: false, error: "A valid email is required." }, 400);
    }
    if (
      !email.endsWith("@ms.mcehassan.ac.in") &&
      !email.endsWith("@mcehassan.ac.in")
    ) {
      return json(
        { success: false, error: "Only MCE Hassan institutional emails are allowed." },
        400
      );
    }

    if (action === "send") {
      // Cooldown: reuse of an existing unused code within 60s is rejected.
      const { data: existing } = await supabase
        .from("otp_verifications")
        .select("id, created_at")
        .eq("email", email)
        .eq("purpose", purpose)
        .eq("used", false)
        .order("created_at", { ascending: false })
        .limit(1);

      if (existing && existing.length > 0) {
        const age = Date.now() - new Date(existing[0].created_at).getTime();
        if (age < RESEND_COOLDOWN_MS) {
          const wait = Math.ceil((RESEND_COOLDOWN_MS - age) / 1000);
          return json(
            { success: false, error: `Please wait ${wait}s before requesting a new code.` },
            429
          );
        }
      }

      // Invalidate all prior unused codes for this email+purpose.
      await supabase
        .from("otp_verifications")
        .update({ used: true })
        .eq("email", email)
        .eq("purpose", purpose)
        .eq("used", false);

      const otp = generateOtp();
      const codeHash = await sha256Hex(otp);
      const expiresAt = new Date(Date.now() + OTP_TTL_MS).toISOString();

      const { error: insertErr } = await supabase
        .from("otp_verifications")
        .insert({ email, purpose, code_hash: codeHash, expires_at: expiresAt, max_attempts: MAX_ATTEMPTS });
      if (insertErr) throw insertErr;
      console.log(`[send-otp] OTP stored for ${email} (hash only), expires ${expiresAt}`);

      // Deliver via the existing SMTP send-email function.
      const sendRes = await fetch(`${supabaseUrl}/functions/v1/send-email`, {
        method: "POST",
        headers: {
          Authorization: `Bearer ${supabaseServiceKey}`,
          "Content-Type": "application/json",
        },
        body: JSON.stringify({
          emailType: "otp",
          recipient: email,
          subject: `Your Placement Connect Verification Code: ${otp}`,
          data: { otp },
        }),
      });
      const sendData = await sendRes.json().catch(() => ({}));
      console.log(`[send-otp] send-email responded with status ${sendRes.status}`);
      if (!sendRes.ok || sendData.success !== true) {
        // Email failed — do not leave a dangling valid code.
        await supabase
          .from("otp_verifications")
          .update({ used: true })
          .eq("email", email)
          .eq("purpose", purpose)
          .eq("used", false);
        return json(
          { success: false, error: sendData.error || "Failed to deliver the code by email." },
          502
        );
      }

      // Cleanup: drop rows older than 24h.
      await supabase
        .from("otp_verifications")
        .delete()
        .lt("created_at", new Date(Date.now() - 24 * 60 * 60 * 1000).toISOString());

      return json({ success: true, message: "Verification code sent." });
    }

    if (action === "verify") {
      const { data: rows } = await supabase
        .from("otp_verifications")
        .select("*")
        .eq("email", email)
        .eq("purpose", purpose)
        .eq("used", false)
        .order("created_at", { ascending: false })
        .limit(1);

      if (!rows || rows.length === 0) {
        return json(
          { success: false, error: "No active code found for this email. Request a new one." },
          400
        );
      }
      const row = rows[0];

      if (Date.now() > new Date(row.expires_at).getTime()) {
        await supabase.from("otp_verifications").update({ used: true }).eq("id", row.id);
        return json({ success: false, error: "This code has expired. Request a new one." }, 400);
      }
      if (row.attempts >= row.max_attempts) {
        await supabase.from("otp_verifications").update({ used: true }).eq("id", row.id);
        return json({ success: false, error: "Too many incorrect attempts. Request a new code." }, 400);
      }
      if (row.code_hash !== (await sha256Hex(code))) {
        await supabase
          .from("otp_verifications")
          .update({ attempts: row.attempts + 1 })
          .eq("id", row.id);
        const remaining = row.max_attempts - row.attempts - 1;
        return json(
          {
            success: false,
            error: remaining <= 0
              ? "Incorrect code. Request a new code."
              : `Incorrect code. ${remaining} attempt(s) left.`,
          },
          400
        );
      }

      await supabase.from("otp_verifications").update({ used: true }).eq("id", row.id);
      console.log(`[send-otp] OTP verified for ${email} (purpose=${purpose})`);
      return json({ success: true, message: "Email verified successfully." });
    }

    if (action === "reset_password") {
      const { data: rows } = await supabase
        .from("otp_verifications")
        .select("*")
        .eq("email", email)
        .eq("purpose", "password_reset")
        .eq("used", false)
        .order("created_at", { ascending: false })
        .limit(1);

      if (!rows || rows.length === 0) {
        return json(
          { success: false, error: "No active code found for this email. Request a new one." },
          400
        );
      }
      const row = rows[0];

      if (Date.now() > new Date(row.expires_at).getTime()) {
        await supabase.from("otp_verifications").update({ used: true }).eq("id", row.id);
        return json({ success: false, error: "This code has expired. Request a new one." }, 400);
      }
      if (row.attempts >= row.max_attempts) {
        await supabase.from("otp_verifications").update({ used: true }).eq("id", row.id);
        return json({ success: false, error: "Too many incorrect attempts. Request a new code." }, 400);
      }
      if (row.code_hash !== (await sha256Hex(code))) {
        await supabase
          .from("otp_verifications")
          .update({ attempts: row.attempts + 1 })
          .eq("id", row.id);
        const remaining = row.max_attempts - row.attempts - 1;
        return json(
          {
            success: false,
            error: remaining <= 0
              ? "Incorrect code. Request a new code."
              : `Incorrect code. ${remaining} attempt(s) left.`,
          },
          400
        );
      }
      await supabase.from("otp_verifications").update({ used: true }).eq("id", row.id);

      const newPassword = String(body.newPassword || "");
      if (newPassword.length < 8) {
        return json({ success: false, error: "Password must be at least 8 characters." }, 400);
      }

      const { data: userList } = await supabase.auth.admin.listUsers({ perPage: 1000 });
      const target = userList?.users?.find((u) => u.email?.toLowerCase() === email);
      if (!target) {
        return json({ success: false, error: "No account found for this email." }, 404);
      }

      const { error: updateErr } = await supabase.auth.admin.updateUserById(target.id, {
        password: newPassword,
      });
      if (updateErr) throw updateErr;

      return json({ success: true, message: "Password updated successfully." });
    }

    return json({ success: false, error: "Unknown action." }, 400);
  } catch (error: any) {
    console.error(`[send-otp] Error (action=${action}):`, error, error?.stack || "");
    return json({ success: false, error: error.message }, 500);
  }
});
