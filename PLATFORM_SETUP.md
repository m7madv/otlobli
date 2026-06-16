# طلبية Platform Setup

## Vercel

Vercel CLI is already available on this machine and logged in.

Current account:

```txt
mhm1981x-4333
```

Project:

```txt
mhm1981x-4333s-projects/talabieh
```

Production URL:

```txt
https://talabieh.vercel.app
```

Admin URL:

```txt
https://talabieh-admin.vercel.app
```

Production Supabase environment variables were added on Vercel:

```txt
VITE_SUPABASE_URL
VITE_SUPABASE_ANON_KEY
```

Admin API routes also need server-side-only variables:

```txt
SUPABASE_SERVICE_ROLE_KEY
ADMIN_PIN
```

Never expose `SUPABASE_SERVICE_ROLE_KEY` in Vite client code.

`ADMIN_PIN` is configured on the admin Vercel project. `SUPABASE_SERVICE_ROLE_KEY` must also be added to `talabieh-admin` before the admin panel can read and update orders.

Project metadata:

```txt
projectId: prj_NRVuRFkc1fkabh37diFxqr48qQEf
orgId: team_GBTpBuDRNWvtSU1mHN18ejeH
```

## Supabase

Create a free Supabase project, then run the SQL in:

```txt
supabase/schema.sql
```

Current project URL:

```txt
https://dcicqdprtyhwmhegabay.supabase.co
```

After that, create a local `.env` file:

```txt
VITE_SUPABASE_URL=your-project-url
VITE_SUPABASE_ANON_KEY=your-anon-key
```

For production on Vercel, add the same variables:

```bash
vercel env add VITE_SUPABASE_URL
vercel env add VITE_SUPABASE_ANON_KEY
vercel env add SUPABASE_SERVICE_ROLE_KEY
vercel env add ADMIN_PIN
```

Then redeploy:

```bash
vercel deploy --prod --scope mhm1981x-4333s-projects
```

Do not put `SUPABASE_SERVICE_ROLE_KEY` in client code. Use it only in server-side routes.
