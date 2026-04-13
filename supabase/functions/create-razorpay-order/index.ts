// deno-lint-ignore-file no-explicit-any
import { serve } from "https://deno.land/std@0.224.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const RZP_KEY = Deno.env.get("RAZORPAY_KEY_ID")!;
const RZP_SECRET = Deno.env.get("RAZORPAY_KEY_SECRET")!;

serve(async (req) => {
  if (req.method !== "POST") return new Response("Method not allowed", { status: 405 });
  const auth = req.headers.get("Authorization") ?? "";
  const supabase = createClient(
    Deno.env.get("SUPABASE_URL")!,
    Deno.env.get("SUPABASE_ANON_KEY")!,
    { global: { headers: { Authorization: auth } } },
  );

  const { data: { user } } = await supabase.auth.getUser();
  if (!user) return new Response("Unauthorized", { status: 401 });

  const { booking_id, amount } = await req.json();

  const basic = btoa(`${RZP_KEY}:${RZP_SECRET}`);
  const rzpResp = await fetch("https://api.razorpay.com/v1/orders", {
    method: "POST",
    headers: {
      "Content-Type": "application/json",
      "Authorization": `Basic ${basic}`,
    },
    body: JSON.stringify({
      amount: Math.round(amount * 100),
      currency: "INR",
      receipt: booking_id,
      notes: { booking_id, user_id: user.id },
    }),
  });

  if (!rzpResp.ok) {
    const err = await rzpResp.text();
    return new Response(err, { status: 500 });
  }

  const order = await rzpResp.json();

  await supabase.from("payments").insert({
    booking_id,
    amount,
    method: "razorpay",
    status: "created",
    razorpay_order_id: order.id,
  });

  return new Response(JSON.stringify({ order_id: order.id, key: RZP_KEY }), {
    headers: { "Content-Type": "application/json" },
  });
});
