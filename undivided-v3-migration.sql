-- =====================================================================
-- UNDIVIDED v3 · migration (run ONCE, after undivided-v2-schema.sql)
-- Supabase → SQL Editor → New query → paste → Run.
-- Adds a difficulty level that a leader can set for a group.
-- Safe to re-run.
-- =====================================================================

alter table public.ud_cohorts add column if not exists level int check (level between 1 and 3);

-- ud_check_cohort now also returns the group's level
drop function if exists public.ud_check_cohort(text);
create or replace function public.ud_check_cohort(p_code text)
returns table(name text, kind text, lens text, setting text, level int)
language sql stable security definer set search_path = public as $$
  select c.name, c.kind, c.lens, c.setting, c.level from ud_cohorts c where c.code = upper(trim(p_code))
$$;

-- ud_create_cohort gains an optional level
drop function if exists public.ud_create_cohort(text, text, text, text);
create or replace function public.ud_create_cohort(p_name text, p_kind text, p_lens text, p_setting text, p_level int default null)
returns jsonb language plpgsql security definer set search_path = public, extensions as $$
declare v_code text; v_id uuid;
begin
  if auth.uid() is null then raise exception 'sign in first'; end if;
  loop
    v_code := ud_code(6);
    exit when not exists (select 1 from ud_cohorts where code = v_code);
  end loop;
  insert into ud_cohorts(code, name, kind, lens, setting, level, owner)
  values (v_code, trim(p_name),
          case when p_kind in ('school','church','workplace','other') then p_kind else 'other' end,
          case when p_lens in ('f','c') then p_lens end,
          case when p_setting in ('a','y') then p_setting end,
          case when p_level between 1 and 3 then p_level end,
          auth.uid())
  returning id into v_id;
  return jsonb_build_object('id', v_id, 'code', v_code);
end $$;

-- ud_my_cohorts now lists the level
drop function if exists public.ud_my_cohorts();
create or replace function public.ud_my_cohorts()
returns table(id uuid, code text, name text, kind text, lens text, setting text, level int, min_group int, created_at timestamptz, players bigint)
language sql stable security definer set search_path = public as $$
  select c.id, c.code, c.name, c.kind, c.lens, c.setting, c.level, c.min_group, c.created_at,
         (select count(*) from ud_runs r where r.cohort_id = c.id)
  from ud_cohorts c where c.owner = auth.uid()
  order by c.created_at desc
$$;

-- Permissions for the replaced functions (others are unchanged)
revoke execute on function public.ud_check_cohort(text), public.ud_create_cohort(text, text, text, text, int), public.ud_my_cohorts() from public, anon, authenticated;
grant execute on function public.ud_check_cohort(text) to anon, authenticated;
grant execute on function public.ud_create_cohort(text, text, text, text, int) to authenticated;
grant execute on function public.ud_my_cohorts() to authenticated;
