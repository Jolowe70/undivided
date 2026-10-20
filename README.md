# UNDIVIDED v2 · The Integrity Quest

The game (`index.html`), a leader dashboard (`leader.html`), a Supabase backend, and a bridge to the two Firebase sites.

```
index.html                         the game
leader.html                        leader dashboard: create groups, see group totals
config.js                          the ONLY file you edit (Supabase URL + public key + site links)
netlify.toml                       static site, no build step
supabase/functions/guide/index.ts  the AI guide (Elihu / The Witness); holds your Anthropic key
bridge/undivided-bridge.js         copy into The Integrity Commons and The Three Fires (Firebase)
undivided-v2-schema.sql            also delivered separately; run once in Supabase
```

## 1 · Supabase (about 10 minutes)

1. Create a project named **integrity-suite**, region **US East** (or reuse one you already pay for; every object here starts with `ud_`, so nothing collides).
2. **SQL Editor → New query** → paste `undivided-v2-schema.sql` → **Run**.
3. **Edge Functions → Deploy a new function → Via editor** → name it `guide` → paste `supabase/functions/guide/index.ts` → **Deploy**.
   Then open the function's **Details** and turn **Verify JWT OFF**. (The game sends only the public key; the function limits each IP to 80 calls an hour.)
4. **Edge Functions → Secrets** → add `ANTHROPIC_API_KEY`. Optional: `ANTHROPIC_MODEL` (default `claude-sonnet-5-5`), `GUIDE_HOURLY_LIMIT`.
5. Check it: open `https://YOUR-PROJECT-REF.supabase.co/functions/v1/guide` in a browser. You should see `{"ok":true,...,"hasKey":true}`.
6. **Authentication → URL Configuration**: set **Site URL** to your live address and add `https://YOUR-SITE/leader.html` under **Redirect URLs** (leaders sign in by email link).
   Recommended: **Authentication → SMTP** with your Resend account, so sign-in emails aren't rate-limited.
7. **Project Settings → API**: copy the **Project URL** and the **anon / publishable** key into `config.js`.

## 2 · GitHub + Netlify

```powershell
cd C:\dev
git clone https://github.com/Jolowe70/undivided.git     # after creating the empty repo on GitHub
# unzip this package INTO C:\dev\undivided so index.html sits at the repo root
cd C:\dev\undivided
git add -A
git commit -m "Undivided v2: Supabase backend, groups, portfolio bridge"
git push
```

Netlify → **Add new site → Import from GitHub** → `undivided` → no build command, publish directory `.` → Deploy.
Open `/leader.html`, sign in, create a test group, and play once with its code.

## 3 · Link the Firebase sites

Copy `bridge/undivided-bridge.js` into The Integrity Commons and The Three Fires, put the same Supabase URL and public key at its top, and follow the example at the bottom of the file. Neither site moves off Firebase.

## Privacy, in one paragraph

Players never sign in and are never asked for an email. Their name stays on their device. Results are stored only if they join a group, tick research consent, or choose to carry their scores to another site. Nothing they write is stored. Leaders see totals only once 5 or more people have played. All tables are locked; the browser can only call the `ud_*` functions. This is a reflection tool, not a validated test: not for hiring, grading, discipline or appointments.

## v3 · Dynamic scenes and levels (upgrade from v2)

Every play is now new. Each of the 13 scenes, the two watched/alone pairs, the two judgment pairs and the two discernment cases are rewritten by the guide around a fixed blueprint (same principle, same moral structure, same scoring). Options are shuffled. The quiz draws 3 of 12 questions with shuffled answers. The promise character and the two roads change. The truth in each discernment case (innocent or guilty) is random.

Levels: 1 Seeker (clear), 2 Steward (two goods collide; every option sounds reasonable; doing right costs something; asking the guide costs 10 talents, players start with 30), 3 Sage (scenes written for the player's real role; grey areas; Examiner mode on).

Upgrade steps:
1. Supabase SQL Editor → run `undivided-v3-migration.sql`, then `undivided-v3b-diligence-migration.sql` (once each, in that order).
2. Redeploy the `guide` function with the new `supabase/functions/guide/index.ts` (dashboard: open guide → paste → Deploy; or `npx supabase functions deploy guide --no-verify-jwt --project-ref aavwbyrudkqqzjkdlflx`). Keep Verify JWT OFF.
3. Copy the files into C:\dev\undivided, then `git add -A`, `git commit`, `git push`.

If the guide can't be reached, the classic scenes are used (still shuffled), so the game never breaks.

## v3b · The Diligence link (the 100-Day Plumb Line)
Results now end with "Your next 100 days": Days 1–7 practise, Day 8 the Diligence Profile, Days 8–97 the 90-day journey, Day 100 replay Undivided. Link codes last 120 days. The Diligence site's side of the link is in its own update zip (undivided-link.js).

## v3c · Pathfinder
Results open with one recommended next step, chosen from the weakest mirror first (seen/unseen gap or a broken promise → Diligence; say/do gap → IPI; judging others harshly → Three Fires; low discernment → Sage replay; strong across the board → lead a Council), then from the weakest elements. Elihu adds a one-line personal note. The leader dashboard shows up to three programme suggestions per group, worded for churches, workplaces or schools, from group totals only. No new SQL beyond v3 and v3b.

## v4 · Industry packs + Bring Your Own Code of Conduct
**13 packs** (plus General): Banking & finance · Law enforcement · Military · Sales · Education · Healthcare · Church & ministry · Government & public service · Legal · Technology & AI · Construction & engineering · Students (school) · **Manufacturing Identity Track (Rebuilt Workplace)**.

- Same 11 elements, same four mirrors, same scoring in every pack. A pack changes *whose world* the scenes are written for: its workplaces, pressure points, vocabulary, professional standards, and how "watched vs alone" looks in that job.
- Each pack has three role levels (frontline / manager / executive) and an optional country.
- **Field focus** on the results page shows the 3–4 elements that matter most in that field (display and Pathfinder only; the IQ is unchanged).
- Group Pathfinder on the leader dashboard adds the field's weakest focus element and a field-specific programme. For the MIT pack: Undivided at Day 0 and Day 100 as the behavioural measure, then the Integrity Track and the Culture Track.
- Packs are plain data in `industries.js`. Edit the wording there freely.

**Bring your own code:** in `leader.html`, each group has a *Code of conduct* button. Paste up to 20,000 characters. The text stays in Supabase (owner-only); players never see it. The first time a player in that group plays, the guide writes a short summary (shown back to the leader for checking) and grounds the scenes in the organisation's real rules.

Upgrade steps: run `undivided-v4-industry-migration.sql` once, redeploy the `guide` function, push the site (now includes `industries.js`).
