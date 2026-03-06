import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";
import { generateSuggestions } from "./purchase_logic.ts";

const CORS_HEADERS = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
};

serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response(null, { status: 204, headers: CORS_HEADERS });
  }

  const json = (data: unknown, status = 200) =>
    new Response(JSON.stringify(data), {
      status,
      headers: { "Content-Type": "application/json", ...CORS_HEADERS },
    });

  try {
    const supabase = createClient(
      Deno.env.get("SUPABASE_URL") ?? "",
      Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? "",
    );

    const body = await req.json();
    const { user_id } = body;

    if (!user_id) {
      return json({ error: "user_id required" }, 400);
    }

    // Fetch wardrobe data in parallel
    const [{ data: items }, { data: profile }, { data: categories }] =
      await Promise.all([
        supabase.from("clothing_items").select("*").eq("user_id", user_id),
        supabase
          .from("user_profiles")
          .select("style_preferences")
          .eq("id", user_id)
          .single(),
        supabase.from("categories").select("id, name"),
      ]);

    const result = generateSuggestions(
      items ?? [],
      profile ?? {},
      categories ?? [],
    );

    // Upsert recommendations — avoid duplicating recent entries (same day)
    const today = new Date().toISOString().split("T")[0];
    for (const rec of result.recommendations) {
      await supabase.from("purchase_recommendations").upsert(
        {
          user_id,
          category: rec.category,
          reason: rec.reason,
          description: rec.description,
          style_tags: rec.style_tags,
          season: rec.season,
          priority: rec.priority,
          date: today,
        },
        { onConflict: "user_id,category,reason,date" },
      );
    }

    return json(result);
  } catch (err) {
    return json({ error: String(err) }, 500);
  }
});
