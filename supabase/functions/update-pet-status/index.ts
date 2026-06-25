import { handleCors } from '../_shared/cors.ts';
import { errorResponse, jsonResponse, readJson } from '../_shared/http.ts';
import { getOrCreateProfile, requireUser, serviceClient } from '../_shared/supabase.ts';

Deno.serve(async (req) => {
  const cors = handleCors(req);
  if (cors) return cors;
  if (req.method !== 'POST') return errorResponse('Method not allowed.', 405);

  try {
    const body = await readJson(req);
    const petId = body?.petId as string | undefined;
    if (!petId) return errorResponse('petId is required.');

    const { authUser } = await requireUser(req);
    const profile = await getOrCreateProfile(authUser.id);
    const admin = serviceClient();
    const updates: Record<string, unknown> = {
      last_active_at: new Date().toISOString(),
    };

    if (typeof body?.mood === 'number') updates.mood_value = body.mood;
    if (typeof body?.hunger === 'number') updates.hunger_value = body.hunger;
    if (typeof body?.cleanliness === 'number') updates.clean_value = body.cleanliness;
    if (typeof body?.statusText === 'string') updates.current_status_text = body.statusText;

    const { data, error } = await admin
      .from('pets')
      .update(updates)
      .eq('id', petId)
      .eq('user_id', profile.id)
      .select('*')
      .single();

    if (error) throw error;
    return jsonResponse({ pet: data });
  } catch (error) {
    return errorResponse(error instanceof Error ? error.message : String(error), 500);
  }
});
