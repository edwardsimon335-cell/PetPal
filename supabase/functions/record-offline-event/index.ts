import { handleCors } from '../_shared/cors.ts';
import { errorMessage, errorResponse, jsonResponse, readJson } from '../_shared/http.ts';
import { getOrCreateProfile, requireUser, serviceClient } from '../_shared/supabase.ts';

Deno.serve(async (req) => {
  const cors = handleCors(req);
  if (cors) return cors;
  if (req.method !== 'POST') return errorResponse('Method not allowed.', 405);

  try {
    const body = await readJson(req);
    const petId = body?.petId as string | undefined;
    const history = body?.history as Record<string, unknown> | undefined;
    if (!petId || !history) return errorResponse('petId and history are required.');

    const { authUser } = await requireUser(req);
    const profile = await getOrCreateProfile(authUser.id);
    const admin = serviceClient();
    await assertPetOwner(admin, petId, profile.id);

    const row = {
      history_id: stringOrDefault(history.historyId, crypto.randomUUID()),
      pet_id: petId,
      event_id: stringOrDefault(history.eventId, 'unknown'),
      event_type: stringOrDefault(history.eventType, 'special'),
      triggered_at: timestampOrNow(history.triggeredAt),
      offline_duration_minutes: numberOrDefault(history.offlineDurationMinutes, 0),
      mood_before: numberOrDefault(history.moodBefore, 0),
      hunger_before: numberOrDefault(history.hungerBefore, 0),
      affinity_before: numberOrDefault(history.affinityBefore, 0),
      mood_after: numberOrDefault(history.moodAfter, 0),
      hunger_after: numberOrDefault(history.hungerAfter, 0),
      affinity_after: numberOrDefault(history.affinityAfter, 0),
      placed_item_ids_snapshot: stringArrayOrDefault(history.placedItemIdsSnapshot),
      moment_saved: booleanOrDefault(history.momentSaved, false),
      moment_record_id: nullableString(history.momentRecordId),
      created_at: timestampOrNow(history.createdAt),
    };

    const { data, error } = await admin
      .from('offline_event_history')
      .upsert(row, { onConflict: 'history_id' })
      .select('*')
      .single();
    if (error) throw error;

    return jsonResponse({ history: data });
  } catch (error) {
    return errorResponse(errorMessage(error), 500);
  }
});

async function assertPetOwner(
  admin: ReturnType<typeof serviceClient>,
  petId: string,
  profileId: string,
) {
  const { error } = await admin
    .from('pets')
    .select('id')
    .eq('id', petId)
    .eq('user_id', profileId)
    .single();
  if (error) throw new Error('Pet not found.');
}

function numberOrDefault(value: unknown, fallback: number) {
  return typeof value === 'number' ? value : fallback;
}

function booleanOrDefault(value: unknown, fallback: boolean) {
  return typeof value === 'boolean' ? value : fallback;
}

function stringOrDefault(value: unknown, fallback: string) {
  return typeof value === 'string' && value.trim() ? value.trim() : fallback;
}

function nullableString(value: unknown) {
  return typeof value === 'string' && value.trim() ? value.trim() : null;
}

function stringArrayOrDefault(value: unknown) {
  return Array.isArray(value) ? value.filter((item) => typeof item === 'string') : [];
}

function timestampOrNow(value: unknown) {
  return typeof value === 'string' && value.trim() ? value : new Date().toISOString();
}
