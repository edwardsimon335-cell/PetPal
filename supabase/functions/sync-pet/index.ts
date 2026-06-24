import { handleCors } from '../_shared/cors.ts';
import { errorMessage, errorResponse, jsonResponse, readJson } from '../_shared/http.ts';
import { getOrCreateProfile, requireUser, serviceClient } from '../_shared/supabase.ts';

Deno.serve(async (req) => {
  const cors = handleCors(req);
  if (cors) return cors;
  if (req.method !== 'POST') return errorResponse('Method not allowed.', 405);

  try {
    const body = await readJson(req);
    const { authUser } = await requireUser(req);
    const profile = await getOrCreateProfile(authUser.id);
    const admin = serviceClient();

    const petId = body?.petId as string | undefined;
    const sourceType = body?.sourceType === 'preset_role' ? 'preset_role' : 'uploaded_photo';
    const name = (body?.name as string | undefined)?.trim() || 'Mochi';
    const payload = {
      user_id: profile.id,
      source_type: sourceType,
      preset_role_id: sourceType === 'preset_role' ? body?.presetRoleId ?? null : null,
      name,
      species: body?.species ?? null,
      avatar_url: body?.avatarUrl ?? null,
      final_avatar_url: body?.avatarUrl ?? null,
      source_photo_path: body?.sourcePhotoPath ?? null,
      personality_tags: Array.isArray(body?.personalityTags) ? body.personalityTags : [],
      special_personality_detail: body?.specialPersonalityDetail ?? '',
      mood_value: numberOrDefault(body?.mood, 72),
      hunger_value: numberOrDefault(body?.hunger, 95),
      clean_value: numberOrDefault(body?.cleanliness, 92),
      current_status_text: body?.statusText ?? 'Feeling cozy',
      generation_status: body?.generationStatus ?? 'none',
      last_active_at: new Date().toISOString(),
    };

    const query = petId
      ? admin
        .from('pets')
        .update(payload)
        .eq('id', petId)
        .eq('user_id', profile.id)
        .select('*')
        .single()
      : admin
        .from('pets')
        .insert(payload)
        .select('*')
        .single();

    const { data, error } = await query;
    if (error) throw error;
    return jsonResponse({ pet: data });
  } catch (error) {
    return errorResponse(errorMessage(error), 500);
  }
});

function numberOrDefault(value: unknown, fallback: number) {
  return typeof value === 'number' ? value : fallback;
}
