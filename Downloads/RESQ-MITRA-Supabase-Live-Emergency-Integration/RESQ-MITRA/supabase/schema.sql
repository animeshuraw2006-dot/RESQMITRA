-- Run in Supabase SQL Editor. Review policies with your deployment/security team.
create extension if not exists pgcrypto;

do $$ begin
  create type public.app_role as enum ('citizen','responder','admin');
exception when duplicate_object then null; end $$;
do $$ begin
  create type public.emergency_status as enum ('pending','assigned','accepted','responding','arrived','resolved','cancelled','expired');
exception when duplicate_object then null; end $$;

create table if not exists public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  display_name text not null default '',
  phone text,
  role public.app_role not null default 'citizen',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);
create table if not exists public.responder_profiles (
  user_id uuid primary key references public.profiles(id) on delete cascade,
  verified boolean not null default false,
  available boolean not null default false,
  organization text,
  verified_at timestamptz,
  updated_at timestamptz not null default now()
);
create table if not exists public.emergency_requests (
  id uuid primary key default gen_random_uuid(),
  requester_id uuid not null references auth.users(id),
  client_request_id text not null,
  category text not null check (category in ('general','women','child')),
  emergency_type text not null,
  priority text not null check (priority in ('normal','high_alert')),
  instructions text not null default '',
  do_not_call boolean not null default false,
  blood_group text,
  audio_requested boolean not null default false,
  latitude double precision,
  longitude double precision,
  accuracy_meters double precision,
  status public.emergency_status not null default 'pending',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  expires_at timestamptz not null default now() + interval '2 hours',
  unique(requester_id, client_request_id),
  check ((latitude is null and longitude is null) or
         (latitude between -90 and 90 and longitude between -180 and 180))
);
create table if not exists public.responder_assignments (
  id uuid primary key default gen_random_uuid(),
  emergency_id uuid not null references public.emergency_requests(id) on delete cascade,
  responder_id uuid not null references auth.users(id),
  status text not null default 'assigned' check (status in ('assigned','accepted','declined','responding','arrived','resolved','cancelled')),
  -- Denormalized minimum incident fields for RLS-scoped responder realtime stream.
  category text not null,
  emergency_type text not null,
  priority text not null,
  instructions text not null default '',
  latitude double precision,
  longitude double precision,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique(emergency_id, responder_id)
);
create table if not exists public.device_tokens (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  fcm_token text not null unique,
  platform text not null default 'android',
  updated_at timestamptz not null default now()
);

create or replace function public.handle_new_user()
returns trigger language plpgsql security definer set search_path = '' as $$
begin
  insert into public.profiles(id, display_name, phone, role)
  values (new.id, coalesce(new.raw_user_meta_data ->> 'display_name',''), new.phone, 'citizen')
  on conflict (id) do nothing;
  return new;
end; $$;
drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created after insert on auth.users
for each row execute procedure public.handle_new_user();

alter table public.profiles enable row level security;
alter table public.responder_profiles enable row level security;
alter table public.emergency_requests enable row level security;
alter table public.responder_assignments enable row level security;
alter table public.device_tokens enable row level security;

drop policy if exists "profile read own" on public.profiles;
create policy "profile read own" on public.profiles for select to authenticated using (id = (select auth.uid()));
drop policy if exists "profile update own nonprivileged" on public.profiles;
create policy "profile update own nonprivileged" on public.profiles for update to authenticated using (id = (select auth.uid())) with check (id = (select auth.uid()) and role = 'citizen');
drop policy if exists "responder profile visible to self" on public.responder_profiles;
create policy "responder profile visible to self" on public.responder_profiles for select to authenticated using (user_id = (select auth.uid()));
drop policy if exists "requester read own emergencies" on public.emergency_requests;
create policy "requester read own emergencies" on public.emergency_requests for select to authenticated using (requester_id = (select auth.uid()));
drop policy if exists "assigned responder read assignment" on public.responder_assignments;
create policy "assigned responder read assignment" on public.responder_assignments for select to authenticated using (
  responder_id = (select auth.uid()) and exists (
    select 1 from public.responder_profiles rp where rp.user_id = (select auth.uid()) and rp.verified = true and rp.available = true
  )
);
drop policy if exists "user manage own device tokens" on public.device_tokens;
create policy "user manage own device tokens" on public.device_tokens for all to authenticated using (user_id = (select auth.uid())) with check (user_id = (select auth.uid()));
-- Intentionally no client INSERT/UPDATE/DELETE policy on emergencies or assignments.
-- Only trusted Edge Functions using server-side credentials may dispatch/claim/cancel.

create index if not exists emergency_requests_status_created_idx on public.emergency_requests(status, created_at desc);
create index if not exists responder_assignments_responder_status_idx on public.responder_assignments(responder_id, status, created_at desc);
-- Enable responder_assignments in Dashboard > Database > Publications > supabase_realtime.

-- Trusted transactional dispatch: writes the emergency and its eligible responder
-- assignments in one database transaction. Location-aware ranking can be added once
-- responder last-known locations and a reviewed dispatch radius are implemented.
create or replace function public.dispatch_emergency(
  p_requester_id uuid, p_client_request_id text, p_category text,
  p_emergency_type text, p_priority text, p_instructions text,
  p_do_not_call boolean, p_blood_group text, p_audio_requested boolean,
  p_latitude double precision, p_longitude double precision, p_accuracy_meters double precision
) returns jsonb language plpgsql security definer set search_path = '' as $$
declare v_emergency public.emergency_requests%rowtype; v_count integer := 0;
begin
  insert into public.emergency_requests(requester_id,client_request_id,category,emergency_type,priority,instructions,do_not_call,blood_group,audio_requested,latitude,longitude,accuracy_meters,status)
  values(p_requester_id,p_client_request_id,p_category,p_emergency_type,p_priority,p_instructions,p_do_not_call,p_blood_group,p_audio_requested,p_latitude,p_longitude,p_accuracy_meters,'pending')
  on conflict(requester_id,client_request_id) do update set client_request_id=excluded.client_request_id
  returning * into v_emergency;

  insert into public.responder_assignments(emergency_id,responder_id,status,category,emergency_type,priority,instructions,latitude,longitude)
  select v_emergency.id, rp.user_id, 'assigned', v_emergency.category, v_emergency.emergency_type,
         v_emergency.priority, v_emergency.instructions, v_emergency.latitude, v_emergency.longitude
  from public.responder_profiles rp
  where rp.verified = true and rp.available = true
  on conflict(emergency_id,responder_id) do nothing;
  get diagnostics v_count = row_count;
  if v_count > 0 then
    update public.emergency_requests set status='assigned', updated_at=now() where id=v_emergency.id returning * into v_emergency;
  end if;
  return jsonb_build_object('id',v_emergency.id,'status',v_emergency.status,'assigned_count',v_count);
end; $$;
revoke all on function public.dispatch_emergency(uuid,text,text,text,text,text,boolean,text,boolean,double precision,double precision,double precision) from public, anon, authenticated;
grant execute on function public.dispatch_emergency(uuid,text,text,text,text,text,boolean,text,boolean,double precision,double precision,double precision) to service_role;

alter table public.emergency_requests add column if not exists accepted_responder_id uuid references auth.users(id);
create or replace function public.claim_emergency(p_emergency_id uuid, p_responder_id uuid)
returns jsonb language plpgsql security definer set search_path = '' as $$
declare v_emergency public.emergency_requests%rowtype; v_assignment public.responder_assignments%rowtype;
begin
  if not exists(select 1 from public.responder_profiles rp where rp.user_id=p_responder_id and rp.verified=true and rp.available=true) then
    raise exception 'Responder is not verified and available';
  end if;
  update public.emergency_requests set status='accepted', accepted_responder_id=p_responder_id, updated_at=now()
    where id=p_emergency_id and status='assigned' and accepted_responder_id is null returning * into v_emergency;
  if not found then raise exception 'Emergency already claimed or not active'; end if;
  update public.responder_assignments set status='accepted', updated_at=now()
    where emergency_id=p_emergency_id and responder_id=p_responder_id and status='assigned' returning * into v_assignment;
  if not found then raise exception 'No eligible assignment for this responder'; end if;
  update public.responder_assignments set status='cancelled', updated_at=now()
    where emergency_id=p_emergency_id and responder_id<>p_responder_id and status='assigned';
  return jsonb_build_object('id',v_assignment.id,'emergency_id',v_emergency.id,'status','accepted');
end; $$;
revoke all on function public.claim_emergency(uuid,uuid) from public, anon, authenticated;
grant execute on function public.claim_emergency(uuid,uuid) to service_role;

do $$ begin
  alter publication supabase_realtime add table public.responder_assignments;
exception when duplicate_object then null; when undefined_object then null; end $$;

-- Private emergency audio recordings (uploaded after recording; not a live audio stream).
create table if not exists public.emergency_audio_recordings (
  id uuid primary key default gen_random_uuid(),
  emergency_id uuid not null references public.emergency_requests(id) on delete cascade,
  requester_id uuid not null references auth.users(id) on delete cascade,
  storage_path text not null unique,
  mime_type text not null default 'audio/m4a',
  duration_ms integer,
  created_at timestamptz not null default now()
);
alter table public.emergency_audio_recordings enable row level security;
drop policy if exists "requester or accepted responder read emergency audio metadata" on public.emergency_audio_recordings;
create policy "requester or accepted responder read emergency audio metadata"
on public.emergency_audio_recordings for select to authenticated using (
  requester_id = (select auth.uid()) or exists (
    select 1 from public.emergency_requests e
    where e.id = emergency_audio_recordings.emergency_id
      and e.accepted_responder_id = (select auth.uid())
  )
);
drop policy if exists "requester adds own emergency audio metadata" on public.emergency_audio_recordings;
create policy "requester adds own emergency audio metadata"
on public.emergency_audio_recordings for insert to authenticated with check (
  requester_id = (select auth.uid()) and exists (
    select 1 from public.emergency_requests e
    where e.id = emergency_audio_recordings.emergency_id
      and e.requester_id = (select auth.uid())
  )
);

-- Private bucket. Object paths must begin with the emergency UUID.
insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values ('emergency-audio', 'emergency-audio', false, 26214400, array['audio/m4a','audio/mp4','audio/aac','audio/wav','audio/webm','audio/ogg'])
on conflict (id) do update set public = false, file_size_limit = 26214400,
  allowed_mime_types = excluded.allowed_mime_types;
drop policy if exists "requester uploads audio for own SOS" on storage.objects;
create policy "requester uploads audio for own SOS" on storage.objects
for insert to authenticated with check (
  bucket_id = 'emergency-audio' and exists (
    select 1 from public.emergency_requests e
    where e.id::text = split_part(name, '/', 1) and e.requester_id = (select auth.uid())
  )
);
drop policy if exists "requester or accepted responder reads emergency audio" on storage.objects;
create policy "requester or accepted responder reads emergency audio" on storage.objects
for select to authenticated using (
  bucket_id = 'emergency-audio' and exists (
    select 1 from public.emergency_requests e
    where e.id::text = split_part(name, '/', 1)
      and (e.requester_id = (select auth.uid()) or e.accepted_responder_id = (select auth.uid()))
  )
);
