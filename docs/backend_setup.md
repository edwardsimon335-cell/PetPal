# PetPal Backend Setup

This backend follows the V1 product plan:

- Supabase Auth, Postgres, Storage, and Edge Functions.
- DeepSeek for pet chat.
- Gemini image generation for upload-to-pixel-avatar candidates.
- Firebase is kept for mobile analytics, crash reporting, and push notification work.

## 1. Required Supabase dashboard settings

Open the Supabase project and enable:

- Authentication -> Providers -> Anonymous sign-ins.
- Storage buckets are created by the migration:
  - `pet-uploads`, private.
  - `pet-avatars`, public.

## 2. Apply database schema

The schema lives at:

```text
supabase/migrations/202606240001_petpal_v1_schema.sql
```

If the Supabase CLI is installed:

```powershell
supabase link --project-ref obzxhnwcdbbkhvpajwcw
supabase db push
```

If direct database access to `db.obzxhnwcdbbkhvpajwcw.supabase.co:5432`
times out in the current network, use the Supabase pooler URL from Dashboard
Project Settings -> Database -> Connection string. For this project, the CLI
deployment succeeded through the `aws-1-ap-southeast-1` pooler host.

Without the CLI, open Supabase Dashboard -> SQL Editor and run the migration SQL once.

## 3. Configure Edge Function secrets

Do not commit real secrets. Set them in Supabase Dashboard -> Edge Functions -> Secrets, or use the CLI:

```powershell
supabase secrets set DEEPSEEK_API_KEY=...
supabase secrets set DEEPSEEK_CHAT_MODEL=deepseek-chat
supabase secrets set GEMINI_API_KEY=...
supabase secrets set GEMINI_IMAGE_MODEL=gemini-2.5-flash-image
```

## 4. Deploy functions

```powershell
supabase functions deploy create-generation-task
supabase functions deploy generate-pet-avatar
supabase functions deploy chat-with-pet
supabase functions deploy update-pet-status
```

## 5. Run Flutter with Supabase enabled

The app uses compile-time values so no API keys are stored in Git:

```powershell
flutter run `
  --dart-define=SUPABASE_URL=https://your-project-ref.supabase.co `
  --dart-define=SUPABASE_ANON_KEY=your-publishable-key
```

If these values are omitted, the app stays in local demo mode.

## 6. Current backend surface

- `create-generation-task`: creates an avatar generation task.
- `generate-pet-avatar`: downloads the uploaded pet photo, calls Gemini, stores candidate avatars, and updates the task.
- `chat-with-pet`: loads pet profile, memories, recent messages, calls DeepSeek, stores conversation.
- `update-pet-status`: updates mood, hunger, cleanliness, and status text.
