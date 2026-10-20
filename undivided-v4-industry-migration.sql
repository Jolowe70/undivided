-- =====================================================================
-- UNDIVIDED v4 · Industry packs + Bring Your Own Code of Conduct
-- Run ONCE, after the v2 schema, v3 migration and v3b migration.
-- Supabase → SQL Editor → New query → paste → Run.   Safe to re-run.
--  1. A group can be tied to one of 13 industry packs and a country.
--  2. A leader can paste the organisation's own code of conduct (private to the group).
--     Players never see the text; the guide reads it server-side and grounds the scenes in it.
-- =====================================================================

-- 1 · new columns
alter table public.ud_cohorts add column if not exists industry     text;
alter table public.ud_cohorts add column if not exists country      text;
alter table public.ud_cohorts add column if not exists code_text    text;
alter table public.ud_cohorts add column if not exists code_digest  text;
alter table public.ud_cohorts add column if not exists code_updated timestamptz;

alter table public.ud_cohorts drop constraint if exists ud_cohorts_industry_check;
alter table public.ud_cohorts add constraint ud_cohorts_industry_check check (industry is null or industry in
  ('general','banking','police','military','sales','education','healthcare','ministry','government','legal','technology','construction','students','mit'));
alter table public.ud_cohorts drop constraint if exists ud_cohorts_country_check;
alter table public.ud_cohorts add constraint ud_cohorts_country_check check (country is null or char_length(country) <= 60);
alter table public.ud_cohorts drop constraint if exists ud_cohorts_code_len;
alter table public.ud_cohorts add constraint ud_cohorts_code_len check (code_text is null or char_length(code_text) <= 20000);
alter table public.ud_cohorts drop constraint if exists ud_cohorts_digest_len;
alter table public.ud_cohorts add constraint ud_cohorts_digest_len check (code_digest is null or char_length(code_digest) <= 4000);

-- 2 · players' check returns the pack (never the code text itself)
drop function if exists public.ud_check_cohort(text);
create or replace function public.ud_check_cohort(p_code text)
returns table(name text, kind text, lens text, setting text, level int, industry text, country text, has_code boolean)
language sql stable security definer set search_path = public as $$
  select c.name, c.kind, c.lens, c.setting, c.level, c.industry, c.country, (c.code_text is not null and c.code_text <> '')
  from ud_cohorts c where c.code = upper(trim(p_code))
$$;

-- 3 · create a group with an industry and country
drop function if exists public.ud_create_cohort(text, text, text, text, int);
drop function if exists public.ud_create_cohort(text, text, text, text, int, text, text);
create or replace function public.ud_create_cohort(p_name text, p_kind text, p_lens text, p_setting text,
                                                   p_level int default null, p_industry text default null, p_country text default null)
returns jsonb language plpgsql security definer set search_path = public, extensions as $$
declare v_code text; v_id uuid; v_ind text;
begin
  if auth.uid() is null then raise exception 'sign in first'; end if;
  v_ind := case when p_industry in ('general','banking','police','military','sales','education','healthcare','ministry',
                                    'government','legal','technology','construction','students','mit') then p_industry end;
  loop
    v_code := ud_code(6);
    exit when not exists (select 1 from ud_cohorts where code = v_code);
  end loop;
  insert into ud_cohorts(code, name, kind, lens, setting, level, industry, country, owner)
  values (v_code, left(trim(p_name), 80),
          case when p_kind in ('school','church','workplace','other') then p_kind else 'other' end,
          case when p_lens in ('f','c') then p_lens end,
          case when v_ind = 'students' then 'y' when p_setting in ('a','y') then p_setting end,
          case when p_level between 1 and 3 then p_level end,
          v_ind, nullif(left(trim(coalesce(p_country,'')), 60), ''),
          auth.uid())
  returning id into v_id;
  return jsonb_build_object('id', v_id, 'code', v_code);
end $$;

-- 4 · owner saves (or clears) the group's code of conduct. Clearing = empty text.
create or replace function public.ud_set_cohort_code(p_id uuid, p_text text)
returns boolean language plpgsql security definer set search_path = public as $$
declare v_txt text := nullif(trim(coalesce(p_text,'')), '');
begin
  if auth.uid() is null then raise exception 'sign in first'; end if;
  if v_txt is not null and char_length(v_txt) > 20000 then raise exception 'code of conduct is too long (20,000 characters max)'; end if;
  update ud_cohorts set code_text = v_txt, code_digest = null, code_updated = now()
   where id = p_id and owner = auth.uid();
  if not found then raise exception 'not your group'; end if;
  return true;
end $$;

-- 5 · owner can read back the code and the guide's digest
create or replace function public.ud_get_cohort_code(p_id uuid)
returns jsonb language plpgsql stable security definer set search_path = public as $$
declare c ud_cohorts;
begin
  select * into c from ud_cohorts where id = p_id and owner = auth.uid();
  if not found then raise exception 'not your group'; end if;
  return jsonb_build_object('text', c.code_text, 'digest', c.code_digest, 'updated', c.code_updated);
end $$;

-- 6 · the leader's list shows industry, country and whether a code is loaded
drop function if exists public.ud_my_cohorts();
create or replace function public.ud_my_cohorts()
returns table(id uuid, code text, name text, kind text, lens text, setting text, level int, industry text, country text,
              has_code boolean, min_group int, created_at timestamptz, players bigint)
language sql stable security definer set search_path = public as $$
  select c.id, c.code, c.name, c.kind, c.lens, c.setting, c.level, c.industry, c.country,
         (c.code_text is not null and c.code_text <> ''), c.min_group, c.created_at,
         (select count(*) from ud_runs r where r.cohort_id = c.id)
  from ud_cohorts c where c.owner = auth.uid()
  order by c.created_at desc
$$;

-- 7 · permissions
revoke execute on function public.ud_check_cohort(text),
  public.ud_create_cohort(text, text, text, text, int, text, text),
  public.ud_set_cohort_code(uuid, text), public.ud_get_cohort_code(uuid),
  public.ud_my_cohorts() from public, anon, authenticated;
grant execute on function public.ud_check_cohort(text) to anon, authenticated;
grant execute on function public.ud_create_cohort(text, text, text, text, int, text, text) to authenticated;
grant execute on function public.ud_set_cohort_code(uuid, text) to authenticated;
grant execute on function public.ud_get_cohort_code(uuid) to authenticated;
grant execute on function public.ud_my_cohorts() to authenticated;
-- The guide Edge Function reads code_text and writes code_digest with the service role (RLS is bypassed only there).
