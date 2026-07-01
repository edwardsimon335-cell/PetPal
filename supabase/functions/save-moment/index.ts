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
    const record = body?.record as Record<string, unknown> | undefined;
    const historyId = body?.historyId as string | undefined;
    if (!petId || !record) return errorResponse('petId and record are required.');

    const { authUser } = await requireUser(req);
    const profile = await getOrCreateProfile(authUser.id);
    const admin = serviceClient();
    await assertPetOwner(admin, petId, profile.id);

    const row = {
      moment_record_id: stringOrDefault(record.momentRecordId, crypto.randomUUID()),
      moment_id: stringOrDefault(record.momentId, 'unknown'),
      pet_id: petId,
      source_event_id: stringOrDefault(record.sourceEventId, 'unknown'),
      title_snapshot: stringOrDefault(record.titleSnapshot, 'Little Memory'),
      diary_text_snapshot: stringOrDefault(record.diaryTextSnapshot, ''),
      image_url_snapshot: stringOrDefault(record.imageUrlSnapshot, ''),
      moment_type_snapshot: stringOrDefault(record.momentTypeSnapshot, 'home'),
      created_at: timestampOrNow(record.createdAt),
      is_favorite: booleanOrDefault(record.isFavorite, false),
      deleted_at: null,
    };

    const { data, error } = await admin
      .from('user_moment_records')
      .upsert(row, { onConflict: 'moment_record_id' })
      .select('*')
      .single();
    if (error) throw error;

    if (historyId) {
      const { error: historyError } = await admin
        .from('offline_event_history')
        .update({
          moment_saved: true,
          moment_record_id: row.moment_record_id,
        })
        .eq('history_id', historyId)
        .eq('pet_id', petId);
      if (historyError) throw historyError;
    }

    return jsonResponse({ record: data });
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

function stringOrDefault(value: unknown, fallback: string) {
  return typeof value === 'string' && value.trim() ? value.trim() : fallback;
}

function booleanOrDefault(value: unknown, fallback: boolean) {
  return typeof value === 'boolean' ? value : fallback;
}

function timestampOrNow(value: unknown) {
  return typeof value === 'string' && value.trim() ? value : new Date().toISOString();
}
