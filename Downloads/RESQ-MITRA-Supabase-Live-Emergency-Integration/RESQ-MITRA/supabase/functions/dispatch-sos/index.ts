import { createClient } from 'https://esm.sh/@supabase/supabase-js@2';
import { corsHeaders } from '../_shared/cors.ts';
Deno.serve(async (req) => {
  if (req.method === 'OPTIONS') return new Response('ok', { headers: corsHeaders });
  try {
    const authHeader = req.headers.get('Authorization');
    if (!authHeader) return json({ error: 'Authentication required' }, 401);
    const url = Deno.env.get('SUPABASE_URL')!;
    const anon = Deno.env.get('SUPABASE_ANON_KEY')!;
    const serviceKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!;
    const authClient = createClient(url, anon, { global: { headers: { Authorization: authHeader } } });
    const { data: { user }, error: authError } = await authClient.auth.getUser();
    if (authError || !user) return json({ error: 'Invalid session' }, 401);
    const body = await req.json();
    const category = String(body.category ?? '');
    const priority = String(body.priority ?? 'normal');
    const lat = body.latitude == null ? null : Number(body.latitude);
    const lng = body.longitude == null ? null : Number(body.longitude);
    if (!['general','women','child'].includes(category)) return json({ error: 'Invalid category' }, 400);
    if (!['normal','high_alert'].includes(priority)) return json({ error: 'Invalid priority' }, 400);
    if ((lat === null) !== (lng === null) || (lat !== null && (!Number.isFinite(lat) || lat < -90 || lat > 90 || !Number.isFinite(lng) || lng! < -180 || lng! > 180))) return json({ error: 'Invalid coordinates' }, 400);
    const clientRequestId = String(body.client_request_id ?? '');
    if (clientRequestId.length < 8 || clientRequestId.length > 160) return json({ error: 'Invalid request ID' }, 400);
    const service = createClient(url, serviceKey);
    const { data, error } = await service.rpc('dispatch_emergency', {
      p_requester_id: user.id,
      p_client_request_id: clientRequestId,
      p_category: category,
      p_emergency_type: String(body.emergency_type ?? 'Emergency').slice(0, 120),
      p_priority: priority,
      p_instructions: String(body.instructions ?? '').slice(0, 2000),
      p_do_not_call: body.do_not_call === true,
      p_blood_group: String(body.blood_group ?? '').slice(0, 30),
      p_audio_requested: body.audio_requested === true,
      p_latitude: lat,
      p_longitude: lng,
      p_accuracy_meters: body.accuracy_meters == null ? null : Math.max(0, Math.min(Number(body.accuracy_meters), 100000)),
    });
    if (error) throw error;
    return json(data, 200);
  } catch (e) { return json({ error: 'Unable to dispatch SOS', detail: String(e?.message ?? e) }, 400); }
});
function json(data: unknown, status: number) { return new Response(JSON.stringify(data), { status, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }); }
