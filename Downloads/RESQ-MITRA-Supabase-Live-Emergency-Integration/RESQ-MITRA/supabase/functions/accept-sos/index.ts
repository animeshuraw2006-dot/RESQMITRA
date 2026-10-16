import { createClient } from 'https://esm.sh/@supabase/supabase-js@2';
import { corsHeaders } from '../_shared/cors.ts';
Deno.serve(async (req) => {
  if (req.method === 'OPTIONS') return new Response('ok', { headers: corsHeaders });
  const headers={...corsHeaders,'Content-Type':'application/json'};
  try {
    const auth=req.headers.get('Authorization'); if(!auth) return new Response(JSON.stringify({error:'Authentication required'}),{status:401,headers});
    const url=Deno.env.get('SUPABASE_URL')!; const anon=createClient(url,Deno.env.get('SUPABASE_ANON_KEY')!,{global:{headers:{Authorization:auth}}});
    const {data:{user},error:ae}=await anon.auth.getUser(); if(ae||!user) return new Response(JSON.stringify({error:'Invalid session'}),{status:401,headers});
    const {emergency_id}=await req.json(); const admin=createClient(url,Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!);
    const {data:profile,error:pe}=await admin.from('responder_profiles').select('verified,available').eq('user_id',user.id).maybeSingle();
    if(pe||!profile?.verified||!profile?.available) return new Response(JSON.stringify({error:'Responder is not verified and available'}),{status:403,headers});
    const {data:assignment,error}=await admin.rpc('claim_emergency',{p_emergency_id:emergency_id,p_responder_id:user.id});
    if(error) return new Response(JSON.stringify({error:'Emergency already claimed or no eligible assignment'}),{status:409,headers});
    return new Response(JSON.stringify(assignment),{status:200,headers});
  } catch (_) { return new Response(JSON.stringify({error:'Could not accept SOS'}),{status:400,headers}); }
});
