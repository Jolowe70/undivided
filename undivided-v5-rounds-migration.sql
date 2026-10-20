-- =====================================================================
-- UNDIVIDED v5 · Rounds (Day 0 / Day 50 / Day 100) for programme cohorts
-- Run ONCE, after v2, v3, v3b and v4.   Supabase → SQL Editor → New query → paste → Run.   Safe to re-run.
--  · Each group has a CURRENT ROUND that the leader switches (Day 0 → Day 50 → Day 100).
--  · Every finished play is stamped with the round that was open when it was submitted (set by the server).
--  · Results can be viewed per round, and Day 0 vs Day 100 compared. The 5-player minimum applies to EACH round.
-- =====================================================================

alter table public.ud_cohorts add column if not exists current_round int not null default 0;
alter table public.ud_cohorts drop constraint if exists ud_cohorts_round_check;
alter table public.ud_cohorts add constraint ud_cohorts_round_check check (current_round in (0, 50, 100));
alter table public.ud_runs add column if not exists round int;
alter table public.ud_runs drop constraint if exists ud_runs_round_check;
alter table public.ud_runs add constraint ud_runs_round_check check (round is null or round in (0, 50, 100));
-- plays already in a group count as Day 0
update public.ud_runs set round = 0 where cohort_id is not null and round is null;

-- 1 · players' check also returns the open round
drop function if exists public.ud_check_cohort(text);
create or replace function public.ud_check_cohort(p_code text)
returns table(name text, kind text, lens text, setting text, level int, industry text, country text, has_code boolean, current_round int)
language sql stable security definer set search_path = public as $$
  select c.name, c.kind, c.lens, c.setting, c.level, c.industry, c.country,
         (c.code_text is not null and c.code_text <> ''), c.current_round
  from ud_cohorts c where c.code = upper(trim(p_code))
$$;

-- 2 · submitting a play stamps the group's current round (the browser cannot choose it)
create or replace function public.ud_submit_run(p jsonb)
returns jsonb language plpgsql security definer set search_path = public, extensions as $$
declare v_cohort uuid; v_round int; v_link text; v_row ud_runs;
begin
  if p is null or pg_column_size(p) > 20000 then raise exception 'payload too large'; end if;
  if nullif(p->>'cohort_code','') is not null then
    select id, current_round into v_cohort, v_round from ud_cohorts where code = upper(trim(p->>'cohort_code'));
  end if;
  if coalesce((p->>'link_consent')::boolean, false) then
    loop
      v_link := ud_code(8);
      exit when not exists (select 1 from ud_runs where link_code = v_link);
    end loop;
  end if;
  insert into ud_runs(cohort_id, round, lens, setting, mode, exam, iq, choices, wholeness, discernment,
                      mirrors, elements, events, research_consent, link_code, link_consent, link_expires)
  values (v_cohort, case when v_cohort is not null then coalesce(v_round, 0) end,
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
  return jsonb_build_object('id', v_row.id, 'token', v_row.token, 'link_code', v_row.link_code, 'round', v_row.round);
end $$;

-- 3 · leader opens the next round
create or replace function public.ud_set_cohort_round(p_id uuid, p_round int)
returns boolean language plpgsql security definer set search_path = public as $$
begin
  if auth.uid() is null then raise exception 'sign in first'; end if;
  if p_round not in (0, 50, 100) then raise exception 'round must be 0, 50 or 100'; end if;
  update ud_cohorts set current_round = p_round where id = p_id and owner = auth.uid();
  if not found then raise exception 'not your group'; end if;
  return true;
end $$;

-- 4 · group summary, optionally for one round (5-player minimum applies to whatever is shown)
drop function if exists public.ud_cohort_summary(uuid);
drop function if exists public.ud_cohort_summary(uuid, int);
create or replace function public.ud_cohort_summary(p_id uuid, p_round int default null)
returns jsonb language plpgsql stable security definer set search_path = public as $$
declare c ud_cohorts; n int; v_out jsonb;
begin
  select * into c from ud_cohorts where id = p_id and owner = auth.uid();
  if not found then raise exception 'not your group'; end if;
  select count(*) into n from ud_runs where cohort_id = p_id and (p_round is null or round = p_round);
  if n < c.min_group then
    return jsonb_build_object('n', n, 'min_group', c.min_group, 'locked', true, 'round', p_round);
  end if;
  with r as (select * from ud_runs where cohort_id = p_id and (p_round is null or round = p_round))
  select jsonb_build_object(
    'n', n, 'min_group', c.min_group, 'locked', false, 'round', p_round,
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

-- 5 · round-by-round comparison (only rounds with 5+ players show scores)
create or replace function public.ud_cohort_rounds(p_id uuid)
returns jsonb language plpgsql stable security definer set search_path = public as $$
declare c ud_cohorts; v_out jsonb;
begin
  select * into c from ud_cohorts where id = p_id and owner = auth.uid();
  if not found then raise exception 'not your group'; end if;
  select coalesce(jsonb_agg(x order by x.rd), '[]'::jsonb) into v_out from (
    select rd.rd,
      (select count(*) from ud_runs r where r.cohort_id = p_id and r.round = rd.rd) as n
    from (values (0), (50), (100)) rd(rd)
  ) s, lateral (
    select s.rd, s.n, s.n >= c.min_group as open,
      case when s.n >= c.min_group then (
        select jsonb_build_object(
          'iq', round(avg(iq)), 'choices', round(avg(choices)), 'wholeness', round(avg(wholeness)), 'discernment', round(avg(discernment)),
          'mirrors', (select coalesce(jsonb_object_agg(k, av), '{}'::jsonb) from (
              select m.key k, round(avg((m.value)::text::numeric)) av
              from ud_runs r2, jsonb_each(r2.mirrors) m
              where r2.cohort_id = p_id and r2.round = s.rd and jsonb_typeof(m.value) = 'number' group by m.key) mm),
          'elements', (select coalesce(jsonb_object_agg(k, av), '{}'::jsonb) from (
              select e.key k, round(avg((e.value)::text::numeric)) av
              from ud_runs r3, jsonb_each(r3.elements) e
              where r3.cohort_id = p_id and r3.round = s.rd and jsonb_typeof(e.value) = 'number' group by e.key) ee))
        from ud_runs r where r.cohort_id = p_id and r.round = s.rd)
      end as scores
  ) x;
  return jsonb_build_object('current_round', c.current_round, 'min_group', c.min_group, 'rounds', v_out);
end $$;

-- 6 · leader's list shows the open round
drop function if exists public.ud_my_cohorts();
create or replace function public.ud_my_cohorts()
returns table(id uuid, code text, name text, kind text, lens text, setting text, level int, industry text, country text,
              has_code boolean, current_round int, min_group int, created_at timestamptz, players bigint)
language sql stable security definer set search_path = public as $$
  select c.id, c.code, c.name, c.kind, c.lens, c.setting, c.level, c.industry, c.country,
         (c.code_text is not null and c.code_text <> ''), c.current_round, c.min_group, c.created_at,
         (select count(*) from ud_runs r where r.cohort_id = c.id)
  from ud_cohorts c where c.owner = auth.uid()
  order by c.created_at desc
$$;

-- 7 · permissions
revoke execute on function public.ud_check_cohort(text), public.ud_submit_run(jsonb),
  public.ud_set_cohort_round(uuid, int), public.ud_cohort_summary(uuid, int),
  public.ud_cohort_rounds(uuid), public.ud_my_cohorts() from public, anon, authenticated;
grant execute on function public.ud_check_cohort(text) to anon, authenticated;
grant execute on function public.ud_submit_run(jsonb) to anon, authenticated;
grant execute on function public.ud_set_cohort_round(uuid, int) to authenticated;
grant execute on function public.ud_cohort_summary(uuid, int) to authenticated;
grant execute on function public.ud_cohort_rounds(uuid) to authenticated;
grant execute on function public.ud_my_cohorts() to authenticated;
