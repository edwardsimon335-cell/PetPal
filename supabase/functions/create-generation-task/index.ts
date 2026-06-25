import { handleCors } from '../_shared/cors.ts';
import { errorMessage, errorResponse, jsonResponse, readJson } from '../_shared/http.ts';
import { getOrCreateProfile, requireUser, serviceClient } from '../_shared/supabase.ts';

Deno.serve(async (req) => {
  const cors = handleCors(req);
  if (cors) return cors;
  if (req.method !== 'POST') return errorResponse('Method not allowed.', 405);

  try {
    const body = await readJson(req);
    const inputPhotoPath = body?.inputPhotoPath as string | undefined;
    if (!inputPhotoPath) return errorResponse('inputPhotoPath is required.');

    const { authUser } = await requireUser(req);
    if (!inputPhotoPath.startsWith(`${authUser.id}/`)) {
      return errorResponse('inputPhotoPath does not belong to the current user.', 403);
    }

    const profile = await getOrCreateProfile(authUser.id);
    const admin = serviceClient();

    const { data, error } = await admin
      .from('generation_tasks')
      .insert({
        user_id: profile.id,
        task_type: 'avatar_options',
        status: 'pending',
        input_photo_path: inputPhotoPath,
        retry_count: body?.retryCount ?? 0,
        max_retry_count: 2,
      })
      .select('*')
      .single();

    if (error) throw error;
    return jsonResponse({ task: data });
  } catch (error) {
    return errorResponse(errorMessage(error), 500);
  }
});
