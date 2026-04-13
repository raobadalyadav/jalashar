// deno-lint-ignore-file no-explicit-any
import { serve } from "https://deno.land/std@0.224.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";
import { createHmac } from "https://deno.land/std@0.224.0/crypto/mod.ts";

const WEBHOOK_SECRET = Deno.env.get("RAZORPAY_WEBHOOK_SECRET")!;

serve(async (req) => {
  const body = await req.text();
  const signature = req.headers.get("x-razorpay-signature") ?? "";

  const key = await crypto.subtle.importKey(
    "raw",
    new TextEncoder().encode(WEBHOOK_SECRET),
    { name: "HMAC", hash: "SHA-256" },
    false,
    ["sign"],
  );
  const sig = await crypto.subtle.sign("HMAC", key, new TextEncoder().encode(body));
  const hex = Array.from(new Uint8Array(sig))
    .map((b) => b.toString(16).padStart(2, "0")).join("");

  if (hex !== signature) return new Response("Invalid signature", { status: 401 });

  const payload = JSON.parse(body);
  const event = payload.event;
  const payment = payload.payload?.payment?.entity;
  if (!payment) return new Response("OK");

  const supabase = createClient(
    Deno.env.get("SUPABASE_URL")!,
    Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!,
  );

  const status = event === "payment.captured" ? "captured"
    : event === "payment.failed" ? "failed" : "authorized";

  await supabase.from("payments")
    .update({ status, razorpay_payment_id: payment.id })
    .eq("razorpay_order_id", payment.order_id);

  if (status === "captured") {
    const bookingId = payment.notes?.booking_id;
    if (bookingId) {
      await supabase.from("bookings")
        .update({ status: "confirmed", advance_paid: payment.amount / 100 })
        .eq("id", bookingId);
    }
  }

  return new Response("OK");
});
