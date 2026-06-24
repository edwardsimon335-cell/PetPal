import { createClient } from 'https://esm.sh/@supabase/supabase-js@2';

function firstJsonSecret(name: string) {
  const raw = Deno.env.get(name);
  if (!raw) return null;
  try {
    const parsed = JSON.parse(raw) as Record<string, string>;
    return parsed.default ?? Object.values(parsed)[0] ?? null;
  } catch {
    return raw;
  }
}

export function serviceClient() {
  const url = Deno.env.get('SUPABASE_URL');
  const key =
    firstJsonSecret('SUPABASE_SECRET_KEYS') ??
    Deno.env.get('SUPABASE_SERVICE_ROLE_KEY');
  if (!url || !key) {
    throw new Error('Supabase service credentials are not configured.');
  }
  return createClient(url, key, {
    auth: { persistSession: false, autoRefreshToken: false },
  });
}

export function userClient(req: Request) {
  const url = Deno.env.get('SUPABASE_URL');
  const key =
    firstJsonSecret('SUPABASE_PUBLISHABLE_KEYS') ??
    Deno.env.get('SUPABASE_ANON_KEY');
  if (!url || !key) {
    throw new Error('Supabase publishable credentials are not configured.');
  }
  return createClient(url, key, {
    global: {
      headers: {
        Authorization: req.headers.get('Authorization') ?? '',
      },
    },
    auth: { persistSession: false, autoRefreshToken: false },
  });
}

export async function requireUser(req: Request) {
  const supabase = userClient(req);
  const { data, error } = await supabase.auth.getUser();
  if (error || !data.user) {
    throw new Error('Unauthorized.');
  }
  return { supabase, authUser: data.user };
}

export async function getOrCreateProfile(authUserId: string) {
  const admin = serviceClient();
  const { data: existing, error: existingError } = await admin
    .from('users')
    .select('*')
    .eq('auth_user_id', authUserId)
    .maybeSingle();
  if (existingError) throw existingError;
  if (existing) return existing;

  const { data, error } = await admin
    .from('users')
    .insert({
      auth_user_id: authUserId,
      nickname: 'PetPal Friend',
      onboarding_status: 'new',
    })
    .select('*')
    .single();
  if (error) throw error;
  return data;
}
