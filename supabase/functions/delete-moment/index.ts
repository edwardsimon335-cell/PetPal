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
    const momentRecordId = body?.momentRecordId as string | undefined;
    const deletedAt = body?.deletedAt as string | undefined;
    if (!petId || !momentRecordId) {
      return errorResponse('petId and momentRecordId are required.');
    }

    const { authUser } = await requireUser(req);
    const profile = await getOrCreateProfile(authUser.id);
    const admin = serviceClient();
    await assertPetOwner(admin, petId, profile.id);

    const { data, error } = await admin
      .from('user_moment_records')
      .update({ deleted_at: deletedAt ?? new Date().toISOString() })
      .eq('moment_record_id', momentRecordId)
      .eq('pet_id', petId)
      .select('*')
      .single();
    if (error) throw error;

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
