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
      mood_value: numberOrDefault(body?.mood, 100),
      hunger_value: numberOrDefault(body?.hunger, 100),
      clean_value: numberOrDefault(body?.cleanliness, 100),
      affinity_value: numberOrDefault(body?.affinity, 0),
      affinity_level: affinityLevelFor(
        numberOrDefault(body?.affinity, 0),
        body?.affinityLevel,
      ),
      current_status_text: body?.statusText ?? 'Feeling cozy',
      generation_status: body?.generationStatus ?? 'none',
      last_settlement_at: timestampOrNow(body?.lastSettlementAt),
      last_daily_reset_date: stringOrDefault(body?.lastDailyResetDate, localDateKey()),
      feed_last_at: nullableTimestamp(body?.feedLastAt),
      caress_last_at: nullableTimestamp(body?.caressLastAt),
      feed_effective_count_today: numberOrDefault(body?.feedEffectiveCountToday, 0),
      caress_effective_count_today: numberOrDefault(body?.caressEffectiveCountToday, 0),
      chat_mood_gain_today: numberOrDefault(body?.chatMoodGainToday, 0),
      valid_chat_count_today: numberOrDefault(body?.validChatCountToday, 0),
      affinity_gain_today: numberOrDefault(body?.affinityGainToday, 0),
      return_tip_show_count_today: numberOrDefault(body?.returnTipShowCountToday, 0),
      offline_event_show_count_today: numberOrDefault(body?.offlineEventShowCountToday, 0),
      shown_event_ids_today: stringArrayOrDefault(body?.shownEventIdsToday),
      placed_item_ids: stringArrayOrDefault(body?.placedItemIds),
      daily_first_feed_done: booleanOrDefault(body?.dailyFirstFeedDone, false),
      daily_first_caress_done: booleanOrDefault(body?.dailyFirstCaressDone, false),
      daily_chat_affinity_done: booleanOrDefault(body?.dailyChatAffinityDone, false),
      daily_first_return_done: booleanOrDefault(body?.dailyFirstReturnDone, false),
      last_offline_event_at: nullableTimestamp(body?.lastOfflineEventAt),
      last_room_item_update_at: nullableTimestamp(body?.lastRoomItemUpdateAt),
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

    try {
      await syncPetProfileMemory(admin, data);
    } catch (memoryError) {
      console.warn('Failed to sync pet profile memory:', errorMessage(memoryError));
    }

    return jsonResponse({ pet: data });
  } catch (error) {
    return errorResponse(errorMessage(error), 500);
  }
});

function numberOrDefault(value: unknown, fallback: number) {
  return typeof value === 'number' ? value : fallback;
}

function booleanOrDefault(value: unknown, fallback: boolean) {
  return typeof value === 'boolean' ? value : fallback;
}

function stringOrDefault(value: unknown, fallback: string) {
  return typeof value === 'string' && value.trim() ? value.trim() : fallback;
}

function stringArrayOrDefault(value: unknown) {
  return Array.isArray(value) ? value.filter((item) => typeof item === 'string') : [];
}

function nullableTimestamp(value: unknown) {
  return typeof value === 'string' && value.trim() ? value : null;
}

function timestampOrNow(value: unknown) {
  return nullableTimestamp(value) ?? new Date().toISOString();
}

function localDateKey() {
  return new Date().toISOString().slice(0, 10);
}

function affinityLevelFor(affinity: number, explicit: unknown) {
  if (typeof explicit === 'number' && explicit >= 1 && explicit <= 5) {
    return Math.floor(explicit);
  }
  if (affinity >= 30) return 5;
  if (affinity >= 14) return 4;
  if (affinity >= 7) return 3;
  if (affinity >= 3) return 2;
  return 1;
}

async function syncPetProfileMemory(admin: ReturnType<typeof serviceClient>, pet: Record<string, unknown>) {
  const petId = pet.id;
  if (typeof petId !== 'string') return;

  const traits = Array.isArray(pet.personality_tags)
    ? pet.personality_tags.filter((trait) => typeof trait === 'string').join(', ')
    : '';
  const detail =
    typeof pet.special_personality_detail === 'string' && pet.special_personality_detail.trim()
      ? `Special detail: ${pet.special_personality_detail.trim()}.`
      : '';
  const species =
    typeof pet.species === 'string' && pet.species.trim()
      ? pet.species.trim()
      : 'virtual pet';
  const content = [
    `The pet is named ${pet.name}.`,
    `Species or visual identity: ${species}.`,
    traits ? `Personality traits: ${traits}.` : '',
    detail,
  ].filter(Boolean).join(' ');

  const { data: existing, error: existingError } = await admin
    .from('pet_memories')
    .select('id')
    .eq('pet_id', petId)
    .eq('memory_type', 'pet_profile')
    .limit(1)
    .maybeSingle();
  if (existingError) throw existingError;

  if (existing?.id) {
    const { error } = await admin
      .from('pet_memories')
      .update({ content, importance: 4 })
      .eq('id', existing.id);
    if (error) throw error;
    return;
  }

  const { error } = await admin.from('pet_memories').insert({
    pet_id: petId,
    memory_type: 'pet_profile',
    content,
    importance: 4,
  });
  if (error) throw error;
}
