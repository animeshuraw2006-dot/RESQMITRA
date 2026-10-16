import { createClient } from 'https://esm.sh/@supabase/supabase-js@2';
import { corsHeaders } from '../_shared/cors.ts';
Deno.serve(async (req) => {
  if (req.method === 'OPTIONS') return new Response('ok', { headers: corsHeaders });
  const headers = { ...corsHeaders, 'Content-Type': 'application/json' };
  try {
    const auth = req.headers.get('Authorization'); if (!auth) return new Response(JSON.stringify({error:'Authentication required'}), {status:401,headers});
    const url = Deno.env.get('SUPABASE_URL')!;
    const client = createClient(url, Deno.env.get('SUPABASE_ANON_KEY')!, {global:{headers:{Authorization:auth}}});
    const {data:{user},error:authError}=await client.auth.getUser(); if(authError||!user) return new Response(JSON.stringify({error:'Invalid session'}),{status:401,headers});
    const {emergency_id}=await req.json();
    const admin=createClient(url,Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!);
    const {data,error}=await admin.from('emergency_requests').update({status:'cancelled',updated_at:new Date().toISOString()}).eq('id',emergency_id).eq('requester_id',user.id).in('status',['pending','assigned','accepted']).select('id,status').maybeSingle();
    if(error) throw error; if(!data) return new Response(JSON.stringify({error:'Emergency not found or cannot be cancelled'}),{status:409,headers});
    await admin.from('responder_assignments').update({status:'cancelled',updated_at:new Date().toISOString()}).eq('emergency_id',emergency_id).in('status',['assigned','accepted']);
    return new Response(JSON.stringify(data),{status:200,headers});
  } catch (_) { return new Response(JSON.stringify({error:'Cancellation failed'}),{status:400,headers}); }
});
