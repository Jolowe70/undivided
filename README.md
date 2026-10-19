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
