import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2.39.7";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
};

interface EmailPayload {
  emailType: string;
  recipient: string;
  subject?: string;
  data: Record<string, any>;
  createdBy?: string;
}

const COLLEGE_NAME = "Placement Connect Portal";
const BRAND_GOLD = "#D4AF37";

serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
    const supabaseUrl = Deno.env.get("SUPABASE_URL") ?? "";
    const supabaseServiceKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? "";
    const supabase = createClient(supabaseUrl, supabaseServiceKey);

    const smtpHost = Deno.env.get("SMTP_HOST") || "smtp.gmail.com";
    const smtpPort = parseInt(Deno.env.get("SMTP_PORT") || "465");
    const smtpEmail = Deno.env.get("SMTP_EMAIL") || "";
    const smtpPassword = Deno.env.get("SMTP_PASSWORD") || "";

    if (!smtpEmail || !smtpPassword) {
      throw new Error(
        "SMTP credentials missing. Please set SMTP_EMAIL and SMTP_PASSWORD in Supabase Secrets."
      );
    }

    const payload: EmailPayload = await req.json();
    const { emailType, recipient, data, createdBy } = payload;

    if (!recipient) {
      return new Response(
        JSON.stringify({ success: false, error: "Recipient email is required." }),
        { headers: { ...corsHeaders, "Content-Type": "application/json" }, status: 400 }
      );
    }

    const { subject, html } = generateEmailTemplate(emailType, payload.subject, data);

    let status = "sent";
    let errorMessage: string | null = null;

    try {
      await sendSmtpEmail({
        hostname: smtpHost,
        port: smtpPort,
        username: smtpEmail,
        password: smtpPassword,
        from: `${COLLEGE_NAME} <${smtpEmail}>`,
        to: recipient,
        subject: subject,
        html: html,
      });
    } catch (err: any) {
      status = "failed";
      errorMessage = err?.message || String(err);
      console.error(`[Edge Function] Failed to send ${emailType} to ${recipient}:`, err);
    }

    // Audit log in email_logs
    try {
      await supabase.from("email_logs").insert({
        recipient,
        subject,
        email_type: emailType,
        status,
        error_message: errorMessage,
        sent_at: status === "sent" ? new Date().toISOString() : null,
        created_by: createdBy || null,
      });
    } catch (logErr) {
      console.error("[Edge Function] Error writing to email_logs:", logErr);
    }

    if (status === "failed") {
      return new Response(
        JSON.stringify({ success: false, error: errorMessage }),
        { headers: { ...corsHeaders, "Content-Type": "application/json" }, status: 500 }
      );
    }

    return new Response(
      JSON.stringify({ success: true, message: `Email ${emailType} sent to ${recipient}` }),
      { headers: { ...corsHeaders, "Content-Type": "application/json" }, status: 200 }
    );
  } catch (error: any) {
    console.error("[Edge Function] Unexpected error:", error);
    return new Response(
      JSON.stringify({ success: false, error: error.message }),
      { headers: { ...corsHeaders, "Content-Type": "application/json" }, status: 500 }
    );
  }
});

// ─────────────────────────────────────────────────────────────────────────────
// Robust Deno Native SMTP Client (Supports Port 465 SSL/TLS & Port 587 STARTTLS)
// ─────────────────────────────────────────────────────────────────────────────
interface SmtpOptions {
  hostname: string;
  port: number;
  username: string;
  password: string;
  from: string;
  to: string;
  subject: string;
  html: string;
}

async function sendSmtpEmail(opts: SmtpOptions): Promise<void> {
  const encoder = new TextEncoder();
  const decoder = new TextDecoder();

  let conn: Deno.Conn;

  if (opts.port === 465) {
    conn = await Deno.connectTls({
      hostname: opts.hostname,
      port: opts.port,
    });
  } else {
    conn = await Deno.connect({
      hostname: opts.hostname,
      port: opts.port,
    });
  }

  const reader = conn.readable.getReader();
  const writer = conn.writable.getWriter();

  async function readResponse(): Promise<string> {
    let fullResponse = "";
    while (true) {
      const { value, done } = await reader.read();
      if (done || !value) break;
      const text = decoder.decode(value);
      fullResponse += text;
      // Multi-line SMTP responses have a dash on line 4 (e.g. 250-SIZE).
      // The final line of a multi-line response has a space (e.g. 250 OK or 250 HELP).
      const lines = fullResponse.trim().split("\r\n");
      const lastLine = lines[lines.length - 1];
      if (lastLine && lastLine.length >= 4 && lastLine[3] === " ") {
        break;
      }
    }
    return fullResponse;
  }

  async function sendCmd(cmd: string, expectedCode?: string): Promise<string> {
    await writer.write(encoder.encode(cmd + "\r\n"));
    const res = await readResponse();
    if (expectedCode && !res.startsWith(expectedCode)) {
      throw new Error(`SMTP Error [cmd: ${cmd.split(" ")[0]}]: ${res.trim()}`);
    }
    return res;
  }

  await readResponse(); // Initial server greeting

  await sendCmd(`EHLO localhost`, "250");

  if (opts.port === 587) {
    await sendCmd("STARTTLS", "220");
    conn = await Deno.startTls(conn, { hostname: opts.hostname });
    await sendCmd(`EHLO ${opts.hostname}`, "250");
  }

  // AUTH LOGIN (Base64)
  await sendCmd("AUTH LOGIN", "334");
  await sendCmd(btoa(opts.username), "334");
  await sendCmd(btoa(opts.password), "235");

  // MAIL FROM / RCPT TO / DATA
  const cleanFrom = opts.username.trim();
  const cleanTo = opts.to.trim();
  await sendCmd(`MAIL FROM:<${cleanFrom}>`, "250");
  await sendCmd(`RCPT TO:<${cleanTo}>`, "250");
  await sendCmd("DATA", "354");

  // MIME Email Content
  const mailContent = [
    `From: ${opts.from}`,
    `To: ${opts.to}`,
    `Subject: ${opts.subject}`,
    "MIME-Version: 1.0",
    "Content-Type: text/html; charset=UTF-8",
    "",
    opts.html,
    ".",
  ].join("\r\n");

  await sendCmd(mailContent, "250");
  await sendCmd("QUIT", "221");

  try {
    writer.releaseLock();
    reader.releaseLock();
    conn.close();
  } catch (_) {}
}

// ─────────────────────────────────────────────────────────────────────────────
// HTML Email Templates (Black & Gold Premium Branding)
// ─────────────────────────────────────────────────────────────────────────────
function wrapTemplate(title: string, bodyContent: string): string {
  return `
<!DOCTYPE html>
<html>
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>${title}</title>
  <style>
    body { margin: 0; padding: 0; background-color: #0F0F0F; font-family: 'Helvetica Neue', Helvetica, Arial, sans-serif; color: #E0E0E0; }
    .container { max-width: 600px; margin: 20px auto; background: #1A1A1A; border: 1px solid #333333; border-radius: 12px; overflow: hidden; box-shadow: 0 8px 24px rgba(0,0,0,0.5); }
    .header { background: linear-gradient(135deg, #1A1A1A 0%, #2A2A2A 100%); padding: 30px 20px; text-align: center; border-bottom: 2px solid ${BRAND_GOLD}; }
    .header h1 { margin: 0; color: ${BRAND_GOLD}; font-size: 24px; font-weight: 700; letter-spacing: 1px; }
    .header p { margin: 5px 0 0 0; color: #A0A0A0; font-size: 13px; text-transform: uppercase; letter-spacing: 1.5px; }
    .content { padding: 30px 25px; line-height: 1.6; font-size: 15px; }
    .content h2 { color: #FFFFFF; font-size: 18px; margin-top: 0; margin-bottom: 15px; border-bottom: 1px solid #333; padding-bottom: 8px; }
    .info-table { width: 100%; border-collapse: collapse; margin: 20px 0; background: #222222; border-radius: 8px; overflow: hidden; }
    .info-table td { padding: 12px 16px; border-bottom: 1px solid #2C2C2C; font-size: 14px; }
    .info-table td.label { color: ${BRAND_GOLD}; font-weight: 600; width: 40%; }
    .info-table td.value { color: #FFFFFF; }
    .info-table tr:last-child td { border-bottom: none; }
    .highlight-box { background: rgba(212, 175, 55, 0.1); border-left: 4px solid ${BRAND_GOLD}; padding: 15px; border-radius: 4px; margin: 20px 0; color: #F0F0F0; }
    .badge { display: inline-block; padding: 4px 12px; border-radius: 20px; font-size: 12px; font-weight: bold; text-transform: uppercase; }
    .badge-success { background: #1B4D3E; color: #4EAE87; }
    .badge-warning { background: #4D3B1B; color: #D4AF37; }
    .badge-danger { background: #4D1B1B; color: #E57373; }
    .footer { background: #121212; padding: 20px; text-align: center; font-size: 12px; color: #777777; border-top: 1px solid #262626; }
    .footer p { margin: 4px 0; }
  </style>
</head>
<body>
  <div class="container">
    <div class="header">
      <h1>PLACEMENT CONNECT</h1>
      <p>${COLLEGE_NAME}</p>
    </div>
    <div class="content">
      ${bodyContent}
    </div>
    <div class="footer">
      <p>This is an automated placement notification. Please do not reply directly to this email.</p>
      <p>&copy; ${new Date().getFullYear()} ${COLLEGE_NAME}. All rights reserved.</p>
    </div>
  </div>
</body>
</html>
  `;
}

function generateEmailTemplate(
  emailType: string,
  customSubject: string | undefined,
  data: Record<string, any>
): { subject: string; html: string } {
  switch (emailType) {
    case "otp": {
      const subject = customSubject || `Your Placement Connect Verification Code: ${data.otp || ''}`;
      const html = wrapTemplate(
        "Verification Code",
        `
        <h2>Account Verification Code</h2>
        <p>Use the 6-digit verification code below to confirm your account on <strong>Placement Connect</strong>.</p>
        
        <div class="highlight-box" style="text-align: center; font-size: 28px; font-weight: bold; letter-spacing: 6px; color: ${BRAND_GOLD}; margin: 30px 0;">
          ${data.otp || "000000"}
        </div>
        
        <p>This code will expire shortly. If you did not request this registration, please ignore this email.</p>
        `
      );
      return { subject, html };
    }

    case "welcome": {
      const subject = customSubject || `Welcome to Placement Connect — ${data.studentName || 'Student'}`;
      const html = wrapTemplate(
        "Welcome to Placement Connect",
        `
        <h2>Welcome aboard, ${data.studentName || "Student"}!</h2>
        <p>Your email registration and profile verification for <strong>Placement Connect</strong> at <strong>${COLLEGE_NAME}</strong> has been completed successfully.</p>
        
        <table class="info-table">
          <tr><td class="label">Student Name</td><td class="value">${data.studentName || "N/A"}</td></tr>
          <tr><td class="label">Role</td><td class="value">${data.role || "Student"}</td></tr>
          <tr><td class="label">Department</td><td class="value">${data.department || "N/A"}</td></tr>
          <tr><td class="label">Institution</td><td class="value">${COLLEGE_NAME}</td></tr>
        </table>
        
        <p>You can now log in to access active placement drives, monitor your application status, and track drive attendance seamlessly.</p>
        `
      );
      return { subject, html };
    }

    case "faculty_appointment": {
      const subject = customSubject || `Appointment as Faculty Coordinator — ${data.department || ''}`;
      const html = wrapTemplate(
        "Faculty Coordinator Appointment",
        `
        <h2>Faculty Coordinator Appointment Notice</h2>
        <p>Dear <strong>${data.facultyName || "Faculty Member"}</strong>,</p>
        <p>You have been officially appointed as the <strong>Faculty Coordinator</strong> for the Department of <strong>${data.department || "N/A"}</strong> by the Training & Placement Office (TPO).</p>
        
        <table class="info-table">
          <tr><td class="label">Faculty Name</td><td class="value">${data.facultyName || "N/A"}</td></tr>
          <tr><td class="label">Department</td><td class="value">${data.department || "N/A"}</td></tr>
          <tr><td class="label">Appointment Date</td><td class="value">${data.appointmentDate || new Date().toLocaleDateString()}</td></tr>
        </table>
        
        <p>You now have access to department placement analytics, student approval queues, and drive attendance reporting.</p>
        `
      );
      return { subject, html };
    }

    case "drive_published": {
      const subject = customSubject || `New Placement Drive Announced: ${data.companyName} (${data.roleTitle})`;
      const html = wrapTemplate(
        "New Placement Drive",
        `
        <h2>New Placement Drive Announced</h2>
        <p>A new placement recruitment drive matching your department/branch eligibility has been published.</p>
        
        <table class="info-table">
          <tr><td class="label">Company Name</td><td class="value"><strong>${data.companyName || "N/A"}</strong></td></tr>
          <tr><td class="label">Role Title</td><td class="value">${data.roleTitle || "N/A"}</td></tr>
          <tr><td class="label">Package (CTC)</td><td class="value">${data.package || "As per policy"}</td></tr>
          <tr><td class="label">Registration Deadline</td><td class="value">${data.registrationDeadline || "N/A"}</td></tr>
          <tr><td class="label">Drive Start Date</td><td class="value">${data.driveDate || "To be announced"}</td></tr>
        </table>
        
        <div class="highlight-box">
          Please log into Placement Connect before the registration deadline to review full job requirements and submit your application.
        </div>
        `
      );
      return { subject, html };
    }

    case "application_submitted": {
      const subject = customSubject || `Application Confirmed: ${data.companyName}`;
      const html = wrapTemplate(
        "Application Confirmation",
        `
        <h2>Application Submitted Successfully</h2>
        <p>Dear <strong>${data.studentName || "Student"}</strong>,</p>
        <p>Your application for the following campus recruitment drive has been successfully registered.</p>
        
        <table class="info-table">
          <tr><td class="label">Company</td><td class="value"><strong>${data.companyName || "N/A"}</strong></td></tr>
          <tr><td class="label">Role</td><td class="value">${data.roleTitle || "N/A"}</td></tr>
          <tr><td class="label">Application Date</td><td class="value">${data.applicationDate || new Date().toLocaleDateString()}</td></tr>
          <tr><td class="label">Status</td><td class="value"><span class="badge badge-success">${data.status || "Applied"}</span></td></tr>
        </table>
        `
      );
      return { subject, html };
    }

    case "attendance_marked": {
      const subject = customSubject || `Attendance Confirmed: ${data.companyName} Drive`;
      const html = wrapTemplate(
        "Attendance Confirmation",
        `
        <h2>QR Attendance Recorded</h2>
        <p>Your attendance for the recruitment drive has been verified via QR scan.</p>
        
        <table class="info-table">
          <tr><td class="label">Company</td><td class="value"><strong>${data.companyName || "N/A"}</strong></td></tr>
          <tr><td class="label">Date</td><td class="value">${data.date || new Date().toLocaleDateString()}</td></tr>
          <tr><td class="label">Time</td><td class="value">${data.time || new Date().toLocaleTimeString()}</td></tr>
          <tr><td class="label">Attendance Status</td><td class="value"><span class="badge badge-success">${data.attendanceStatus || "Present"}</span></td></tr>
        </table>
        `
      );
      return { subject, html };
    }

    case "round_qualified": {
      const subject = customSubject || `Congratulations! Qualified for ${data.nextRoundName || "Next Round"} — ${data.companyName}`;
      const html = wrapTemplate(
        "Round Advancement Notice",
        `
        <h2>Congratulations! You Have Shortlisted</h2>
        <p>Dear <strong>${data.studentName || "Student"}</strong>,</p>
        <p>We are pleased to inform you that you have cleared the selection criteria for <strong>${data.companyName}</strong>.</p>
        
        <table class="info-table">
          <tr><td class="label">Company</td><td class="value"><strong>${data.companyName || "N/A"}</strong></td></tr>
          <tr><td class="label">Cleared Round</td><td class="value">${data.qualifiedRound || "Previous Round"}</td></tr>
          <tr><td class="label">Upcoming Round</td><td class="value"><strong>${data.nextRoundName || "Next Round"}</strong></td></tr>
          <tr><td class="label">Schedule Date</td><td class="value">${data.interviewDate || "TBA"}</td></tr>
          <tr><td class="label">Venue / Mode</td><td class="value">${data.venue || "TBA"}</td></tr>
        </table>
        
        ${data.remarks ? `<div class="highlight-box"><strong>Coordinator Remarks:</strong> ${data.remarks}</div>` : ""}
        `
      );
      return { subject, html };
    }

    case "round_rejected": {
      const subject = customSubject || `Drive Status Update: ${data.companyName}`;
      const html = wrapTemplate(
        "Drive Update",
        `
        <h2>Selection Process Update</h2>
        <p>Dear <strong>${data.studentName || "Student"}</strong>,</p>
        <p>Thank you for participating in the campus recruitment drive for <strong>${data.companyName}</strong>.</p>
        
        <table class="info-table">
          <tr><td class="label">Company</td><td class="value">${data.companyName || "N/A"}</td></tr>
          <tr><td class="label">Round Evaluated</td><td class="value">${data.rejectedRound || "N/A"}</td></tr>
          <tr><td class="label">Status</td><td class="value"><span class="badge badge-danger">Not Shortlisted</span></td></tr>
        </table>
        
        ${data.remarks ? `<p><strong>Feedback/Remarks:</strong> ${data.remarks}</p>` : ""}
        <p>Keep pursuing opportunities — new recruitment drives are added regularly on Placement Connect.</p>
        `
      );
      return { subject, html };
    }

    case "offer_released": {
      const subject = customSubject || `JOB OFFER: Congratulations on your selection at ${data.companyName}!`;
      const html = wrapTemplate(
        "Job Offer Released",
        `
        <h2>Congratulations on Your Job Offer! 🎉</h2>
        <p>Dear <strong>${data.studentName || "Student"}</strong>,</p>
        <p>The Training & Placement Office is proud to announce that you have been selected for a job offer with <strong>${data.companyName}</strong>!</p>
        
        <table class="info-table">
          <tr><td class="label">Company</td><td class="value"><strong>${data.companyName || "N/A"}</strong></td></tr>
          <tr><td class="label">Role Title</td><td class="value">${data.roleTitle || "N/A"}</td></tr>
          <tr><td class="label">Offered Package</td><td class="value"><strong>${data.package || "N/A"}</strong></td></tr>
          <tr><td class="label">Joining Date</td><td class="value">${data.joiningDate || "As per Offer Letter"}</td></tr>
        </table>
        
        <div class="highlight-box">
          <strong>Next Steps:</strong> Please check Placement Connect under 'My Offers' to review offer letter details and submit your decision.
        </div>
        `
      );
      return { subject, html };
    }

    case "drive_cancelled": {
      const subject = customSubject || `URGENT: Placement Drive Update — ${data.companyName}`;
      const html = wrapTemplate(
        "Placement Drive Update",
        `
        <h2>Placement Drive Schedule Update</h2>
        <p>Please note an important update regarding the recruitment drive for <strong>${data.companyName}</strong>.</p>
        
        <table class="info-table">
          <tr><td class="label">Company</td><td class="value">${data.companyName || "N/A"}</td></tr>
          <tr><td class="label">Reason / Details</td><td class="value">${data.reason || "Schedule adjustment by company"}</td></tr>
          <tr><td class="label">Updated Date</td><td class="value">${data.updatedDate || "To be communicated"}</td></tr>
        </table>
        `
      );
      return { subject, html };
    }

    case "reminder": {
      const subject = customSubject || `Placement Action Required: ${data.reminderTitle || 'Reminder'}`;
      const html = wrapTemplate(
        "Placement Action Reminder",
        `
        <h2>Action Required</h2>
        <p>Dear <strong>${data.studentName || "Student"}</strong>,</p>
        <p>${data.message || "You have a pending requirement on Placement Connect."}</p>
        
        <div class="highlight-box">
          <strong>Requirement:</strong> ${data.reminderTitle || "Pending Action"}<br>
          ${data.deadline ? `<strong>Deadline:</strong> ${data.deadline}` : ""}
        </div>
        `
      );
      return { subject, html };
    }

    default: {
      const subject = customSubject || `Placement Notice — ${COLLEGE_NAME}`;
      const html = wrapTemplate(
        "Placement Notice",
        `
        <h2>${customSubject || "Placement Notice"}</h2>
        <p>${data.message || "Please log in to Placement Connect to view recent updates."}</p>
        `
      );
      return { subject, html };
    }
  }
}
