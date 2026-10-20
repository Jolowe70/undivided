-- =====================================================================
-- UNDIVIDED v3b · Diligence link migration (run ONCE, after v2 schema and v3 migration)
-- Supabase → SQL Editor → New query → paste → Run.   Safe to re-run.
--  1. The Diligence Profile becomes a linked site (source 'diligence-profile').
--  2. Link codes last 120 days instead of 30, so they cover the 100-Day journey.
-- =====================================================================

-- 1 · allow the new source
alter table public.ud_external_links drop constraint if exists ud_external_links_source_check;
alter table public.ud_external_links add constraint ud_external_links_source_check
  check (source in ('integrity-commons','three-fires','diligence-profile'));

create or replace function public.ud_attach_external(p_code text, p_source text, p_ref text, p_summary jsonb)
returns boolean language plpgsql security definer set search_path = public as $$
declare v_run uuid;
begin
  if p_source not in ('integrity-commons','three-fires','diligence-profile') then raise exception 'unknown source'; end if;
  if pg_column_size(p_summary) > 8000 then raise exception 'summary too large'; end if;
  select id into v_run from ud_runs where link_code = upper(trim(p_code)) and link_consent and link_expires > now();
  if v_run is null then return false; end if;
  insert into ud_external_links(run_id, source, external_ref, summary) values (v_run, p_source, left(p_ref, 200), p_summary);
  return true;
end $$;

-- 2 · 120-day link codes
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
          case when v_link is not null then now() + interval '120 days' end)
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
    update ud_runs set link_consent = true, link_expires = now() + interval '120 days' where id = p_id;
    return v_existing;
  end if;
  loop
    v_link := ud_code(8);
    exit when not exists (select 1 from ud_runs where link_code = v_link);
  end loop;
  update ud_runs set link_code = v_link, link_consent = true, link_expires = now() + interval '120 days' where id = p_id;
  return v_link;
end $$;

-- extend codes already issued
update public.ud_runs set link_expires = created_at + interval '120 days' where link_code is not null and link_consent;

-- permissions (create or replace keeps grants, restated for safety)
revoke execute on function public.ud_attach_external(text, text, text, jsonb), public.ud_submit_run(jsonb), public.ud_enable_link(uuid, uuid) from public;
grant execute on function public.ud_attach_external(text, text, text, jsonb) to anon, authenticated;
grant execute on function public.ud_submit_run(jsonb) to anon, authenticated;
grant execute on function public.ud_enable_link(uuid, uuid) to anon, authenticated;
