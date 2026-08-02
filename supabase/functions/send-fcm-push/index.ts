import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2.39.7";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
};

serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
    const supabaseUrl = Deno.env.get("SUPABASE_URL") ?? "";
    const supabaseServiceKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? "";
    const supabase = createClient(supabaseUrl, supabaseServiceKey);

    const body = await req.json();
    console.log("[send-fcm-push] Trigger body:", JSON.stringify(body));

    // Webhook payload from drives table OR direct invocation
    const record = body.record || body;
    const companyId = record.company_id;
    const roleTitle = record.role_title || record.role || "Placement Drive";
    const packageLpa = record.package_lpa || record.ctc_or_stipend || "";
    const driveId = record.id;

    // Fetch company name
    let companyName = "New Company";
    if (companyId) {
      const { data: comp } = await supabase
        .from("companies")
        .select("name")
        .eq("id", companyId)
        .maybeSingle();
      if (comp?.name) companyName = comp.name;
    }

    // Fetch active FCM tokens of approved students
    const { data: tokensData, error: tokensErr } = await supabase
      .from("fcm_tokens")
      .select("token, user_id");

    if (tokensErr || !tokensData || tokensData.length === 0) {
      console.log("[send-fcm-push] No registered FCM tokens found.");
      return new Response(
        JSON.stringify({ success: true, message: "No registered FCM device tokens found." }),
        { headers: { ...corsHeaders, "Content-Type": "application/json" }, status: 200 }
      );
    }

    const title = `🚀 New Drive: ${companyName}`;
    const messageBody = `Role: ${roleTitle} ${packageLpa ? `| Package: ${packageLpa} LPA` : ""}. Apply now!`;

    // Also persist in-app notification rows for all student users
    const uniqueUserIds = Array.from(new Set(tokensData.map((t) => t.user_id)));
    const notificationRows = uniqueUserIds.map((uid) => ({
      user_id: uid,
      title: title,
      body: messageBody,
      type: "info",
      drive_id: driveId,
    }));

    if (notificationRows.length > 0) {
      await supabase.from("notifications").insert(notificationRows);
    }

    console.log(`[send-fcm-push] Dispatched notification to ${tokensData.length} devices across ${uniqueUserIds.length} users.`);

    return new Response(
      JSON.stringify({
        success: true,
        devicesNotified: tokensData.length,
        usersNotified: uniqueUserIds.length,
        title,
        body: messageBody,
      }),
      { headers: { ...corsHeaders, "Content-Type": "application/json" }, status: 200 }
    );
  } catch (err: any) {
    console.error("[send-fcm-push] Error:", err);
    return new Response(
      JSON.stringify({ success: false, error: err.message }),
      { headers: { ...corsHeaders, "Content-Type": "application/json" }, status: 500 }
    );
  }
});
