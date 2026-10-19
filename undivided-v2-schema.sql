-- =====================================================================
-- UNDIVIDED v2 · Supabase schema
-- Run once in Supabase → SQL Editor → New query → paste → Run.
-- Safe to re-run: tables use IF NOT EXISTS, functions use CREATE OR REPLACE.
--
-- Privacy design
--  * Players are anonymous: no name, email or written answer is ever stored.
--  * Nothing is readable directly. Every read/write goes through the
--    SECURITY DEFINER functions below.
--  * Group leaders see group totals only, and only once a group has at
--    least 5 runs (min_group). Individual results are never returned to them.
--  * A link code (for The Integrity Commons / The Three Fires) exists only
--    when the player ticks "carry my scores", and expires after 30 days.
-- =====================================================================

create extension if not exists pgcrypto;

-- ---------- Tables ----------
create table if not exists public.ud_cohorts (
  id          uuid primary key default gen_random_uuid(),
  code        text unique not null,
  name        text not null check (char_length(name) between 2 and 80),
  kind        text not null default 'other' check (kind in ('school','church','workplace','other')),
  lens        text check (lens in ('f','c')),
  setting     text check (setting in ('a','y')),
  owner       uuid not null references auth.users(id) on delete cascade,
  min_group   int  not null default 5 check (min_group >= 5),
  created_at  timestamptz not null default now()
);

create table if not exists public.ud_runs (
  id               uuid primary key default gen_random_uuid(),
  token            uuid not null default gen_random_uuid(),   -- lets the same browser add a link code later
  created_at       timestamptz not null default now(),
  cohort_id        uuid references public.ud_cohorts(id) on delete set null,
  lens             text, setting text, mode text, exam boolean,
  iq int, choices int, wholeness int, discernment int,
  mirrors          jsonb,
  elements         jsonb,
  events           jsonb,
  research_consent boolean not null default false,
  link_code        text unique,
  link_consent     boolean not null default false,
  link_expires     timestamptz
);
create index if not exists ud_runs_cohort_idx on public.ud_runs(cohort_id);

create table if not exists public.ud_external_links (
  id           uuid primary key default gen_random_uuid(),
  run_id       uuid not null references public.ud_runs(id) on delete cascade,
  source       text not null check (source in ('integrity-commons','three-fires')),
  external_ref text,           -- e.g. a hashed Firebase uid; never an email
  summary      jsonb,          -- totals only (e.g. IPI domain scores), never item-level answers
  created_at   timestamptz not null default now()
);

-- Used by the `guide` Edge Function for simple per-IP rate limiting.
create table if not exists public.ud_guide_calls (
  id      bigint generated always as identity primary key,
  ip_hash text not null,
  at      timestamptz not null default now()
);
create index if not exists ud_guide_calls_idx on public.ud_guide_calls(ip_hash, at);

-- Lock every table: no direct access for anon or signed-in users.
alter table public.ud_cohorts        enable row level security;
alter table public.ud_runs           enable row level security;
alter table public.ud_external_links enable row level security;
alter table public.ud_guide_calls    enable row level security;
revoke all on public.ud_cohorts, public.ud_runs, public.ud_external_links, public.ud_guide_calls from anon, authenticated;

-- ---------- Helpers ----------
-- 32-character alphabet without I, O, 0, 1 (easy to read aloud in a classroom).
create or replace function public.ud_code(n int)
returns text language plpgsql volatile set search_path = public, extensions as $$
declare a text := 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789'; r text := ''; i int;
begin
  for i in 1..n loop
    r := r || substr(a, 1 + (get_byte(gen_random_bytes(1), 0) % 32), 1);
  end loop;
  return r;
end $$;

create or replace function public.ud_int(v jsonb)
returns int language sql immutable as $$
  select case when jsonb_typeof(v) = 'number' then greatest(0, least(100, round((v)::text::numeric)))::int else null end
$$;

-- ---------- Player functions (anon) ----------
create or replace function public.ud_check_cohort(p_code text)
returns table(name text, kind text, lens text, setting text)
language sql stable security definer set search_path = public as $$
  select c.name, c.kind, c.lens, c.setting from ud_cohorts c where c.code = upper(trim(p_code))
$$;

create or replace function public.ud_submit_run(p jsonb)
returns jsonb language plpgsql security definer set search_path = public, extensions as $$
declare v_cohort uuid; v_link text; v_row ud_runs;
begin
  if p is null or pg_column_size(p) > 20000 then raise exception 'payload too large'; end if;
  if nullif(p->>'cohort_code','') is not null then
    select id into v_cohort from ud_cohorts where code = upper(trim(p->>'cohort_code'));
  end if;
  if coalesce((p->>'link_consent')::boolean, false) then
    loop
      v_link := ud_code(8);
      exit when not exists (select 1 from ud_runs where link_code = v_link);
    end loop;
  end if;
  insert into ud_runs(cohort_id, lens, setting, mode, exam, iq, choices, wholeness, discernment,
                      mirrors, elements, events, research_consent, link_code, link_consent, link_expires)
  values (v_cohort,
          case when p->>'lens' in ('f','c') then p->>'lens' end,
          case when p->>'setting' in ('a','y') then p->>'setting' end,
          case when p->>'mode' in ('solo','council') then p->>'mode' end,
          coalesce((p->>'exam')::boolean, false),
          ud_int(p->'iq'), ud_int(p->'choices'), ud_int(p->'wholeness'), ud_int(p->'discernment'),
          p->'mirrors', p->'elements', p->'events',
          coalesce((p->>'research_consent')::boolean, false),
          v_link, v_link is not null,
          case when v_link is not null then now() + interval '30 days' end)
  returning * into v_row;
  return jsonb_build_object('id', v_row.id, 'token', v_row.token, 'link_code', v_row.link_code);
end $$;

create or replace function public.ud_enable_link(p_id uuid, p_token uuid)
returns text language plpgsql security definer set search_path = public, extensions as $$
declare v_link text; v_existing text;
begin
  select link_code into v_existing from ud_runs where id = p_id and token = p_token;
  if not found then raise exception 'run not found'; end if;
  if v_existing is not null then
    update ud_runs set link_consent = true, link_expires = now() + interval '30 days' where id = p_id;
    return v_existing;
  end if;
  loop
    v_link := ud_code(8);
    exit when not exists (select 1 from ud_runs where link_code = v_link);
  end loop;
  update ud_runs set link_code = v_link, link_consent = true, link_expires = now() + interval '30 days' where id = p_id;
  return v_link;
end $$;

-- ---------- Portfolio bridge (called from the Firebase sites) ----------
create or replace function public.ud_get_link_summary(p_code text)
returns jsonb language sql stable security definer set search_path = public as $$
  select jsonb_build_object(
    'code', r.link_code, 'played_at', r.created_at, 'lens', r.lens, 'setting', r.setting,
    'iq', r.iq, 'choices', r.choices, 'wholeness', r.wholeness, 'discernment', r.discernment,
    'mirrors', r.mirrors, 'elements', r.elements)
  from ud_runs r
  where r.link_code = upper(trim(p_code)) and r.link_consent and r.link_expires > now()
$$;

create or replace function public.ud_attach_external(p_code text, p_source text, p_ref text, p_summary jsonb)
returns boolean language plpgsql security definer set search_path = public as $$
declare v_run uuid;
begin
  if p_source not in ('integrity-commons','three-fires') then raise exception 'unknown source'; end if;
  if pg_column_size(p_summary) > 8000 then raise exception 'summary too large'; end if;
  select id into v_run from ud_runs where link_code = upper(trim(p_code)) and link_consent and link_expires > now();
  if v_run is null then return false; end if;
  insert into ud_external_links(run_id, source, external_ref, summary) values (v_run, p_source, left(p_ref, 200), p_summary);
  return true;
end $$;

-- ---------- Leader functions (signed in) ----------
create or replace function public.ud_create_cohort(p_name text, p_kind text, p_lens text, p_setting text)
returns jsonb language plpgsql security definer set search_path = public, extensions as $$
declare v_code text; v_id uuid;
begin
  if auth.uid() is null then raise exception 'sign in first'; end if;
  loop
    v_code := ud_code(6);
    exit when not exists (select 1 from ud_cohorts where code = v_code);
  end loop;
  insert into ud_cohorts(code, name, kind, lens, setting, owner)
  values (v_code, trim(p_name),
          case when p_kind in ('school','church','workplace','other') then p_kind else 'other' end,
          case when p_lens in ('f','c') then p_lens end,
          case when p_setting in ('a','y') then p_setting end,
          auth.uid())
  returning id into v_id;
  return jsonb_build_object('id', v_id, 'code', v_code);
end $$;

create or replace function public.ud_my_cohorts()
returns table(id uuid, code text, name text, kind text, lens text, setting text, min_group int, created_at timestamptz, players bigint)
language sql stable security definer set search_path = public as $$
  select c.id, c.code, c.name, c.kind, c.lens, c.setting, c.min_group, c.created_at,
         (select count(*) from ud_runs r where r.cohort_id = c.id)
  from ud_cohorts c where c.owner = auth.uid()
  order by c.created_at desc
$$;

create or replace function public.ud_cohort_summary(p_id uuid)
returns jsonb language plpgsql stable security definer set search_path = public as $$
declare c ud_cohorts; n int; v_out jsonb;
begin
  select * into c from ud_cohorts where id = p_id and owner = auth.uid();
  if not found then raise exception 'not your group'; end if;
  select count(*) into n from ud_runs where cohort_id = p_id;
  if n < c.min_group then
    return jsonb_build_object('n', n, 'min_group', c.min_group, 'locked', true);
  end if;
  with r as (select * from ud_runs where cohort_id = p_id)
  select jsonb_build_object(
    'n', n, 'min_group', c.min_group, 'locked', false,
    'iq',          (select round(avg(iq)) from r),
    'choices',     (select round(avg(choices)) from r),
    'wholeness',   (select round(avg(wholeness)) from r),
    'discernment', (select round(avg(discernment)) from r),
    'elements', (select coalesce(jsonb_object_agg(k, av), '{}'::jsonb) from (
        select e.key k, round(avg((e.value)::text::numeric)) av
        from r, jsonb_each(r.elements) e where jsonb_typeof(e.value) = 'number' group by e.key) x),
    'mirrors', (select coalesce(jsonb_object_agg(k, av), '{}'::jsonb) from (
        select m.key k, round(avg((m.value)::text::numeric)) av
        from r, jsonb_each(r.mirrors) m where jsonb_typeof(m.value) = 'number' group by m.key) x),
    'scenes', (select coalesce(jsonb_object_agg(scene, dist), '{}'::jsonb) from (
        select scene, jsonb_object_agg(opt, cnt) dist from (
          select a.key scene, a.value::text opt, count(*) cnt
          from r, jsonb_each(r.events->'ans') a group by 1, 2) y group by scene) z),
    'coins', (select jsonb_build_object(
        'flips', coalesce(sum((events->'coins'->>'n')::int), 0),
        'heads', coalesce(sum((events->'coins'->>'h')::int), 0))
        from r where jsonb_typeof(events->'coins') = 'object'),
    'promise_kept', (select count(*) from r where events->>'promise' = 'yes' and events->>'road' = 'market'),
    'promise_made', (select count(*) from r where events->>'promise' = 'yes')
  ) into v_out;
  return v_out;
end $$;

-- ---------- Permissions ----------
-- Revoke the default PUBLIC execute grant on these functions only (other apps in this project are untouched).
revoke execute on function public.ud_code(int), public.ud_int(jsonb), public.ud_check_cohort(text), public.ud_submit_run(jsonb),
  public.ud_enable_link(uuid, uuid), public.ud_get_link_summary(text), public.ud_attach_external(text, text, text, jsonb),
  public.ud_create_cohort(text, text, text, text), public.ud_my_cohorts(), public.ud_cohort_summary(uuid) from public, anon, authenticated;
grant execute on function public.ud_check_cohort(text)                    to anon, authenticated;
grant execute on function public.ud_submit_run(jsonb)                     to anon, authenticated;
grant execute on function public.ud_enable_link(uuid, uuid)               to anon, authenticated;
grant execute on function public.ud_get_link_summary(text)                to anon, authenticated;
grant execute on function public.ud_attach_external(text, text, text, jsonb) to anon, authenticated;
grant execute on function public.ud_create_cohort(text, text, text, text) to authenticated;
grant execute on function public.ud_my_cohorts()                          to authenticated;
grant execute on function public.ud_cohort_summary(uuid)                  to authenticated;
-- ud_code and ud_int are internal helpers and stay private.
