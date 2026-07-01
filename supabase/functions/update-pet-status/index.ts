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
    if (typeof body?.affinity === 'number') updates.affinity_value = body.affinity;
    if (typeof body?.affinityLevel === 'number') updates.affinity_level = body.affinityLevel;
    if (typeof body?.lastSettlementAt === 'string') updates.last_settlement_at = body.lastSettlementAt;
    if (typeof body?.lastDailyResetDate === 'string') updates.last_daily_reset_date = body.lastDailyResetDate;
    if (typeof body?.feedLastAt === 'string') updates.feed_last_at = body.feedLastAt;
    if (typeof body?.caressLastAt === 'string') updates.caress_last_at = body.caressLastAt;
    if (typeof body?.feedEffectiveCountToday === 'number') {
      updates.feed_effective_count_today = body.feedEffectiveCountToday;
    }
    if (typeof body?.caressEffectiveCountToday === 'number') {
      updates.caress_effective_count_today = body.caressEffectiveCountToday;
    }
    if (typeof body?.chatMoodGainToday === 'number') updates.chat_mood_gain_today = body.chatMoodGainToday;
    if (typeof body?.validChatCountToday === 'number') updates.valid_chat_count_today = body.validChatCountToday;
    if (typeof body?.affinityGainToday === 'number') updates.affinity_gain_today = body.affinityGainToday;
    if (typeof body?.returnTipShowCountToday === 'number') {
      updates.return_tip_show_count_today = body.returnTipShowCountToday;
    }
    if (typeof body?.offlineEventShowCountToday === 'number') {
      updates.offline_event_show_count_today = body.offlineEventShowCountToday;
    }
    if (Array.isArray(body?.shownEventIdsToday)) {
      updates.shown_event_ids_today = body.shownEventIdsToday.filter((item: unknown) => typeof item === 'string');
    }
    if (Array.isArray(body?.placedItemIds)) {
      updates.placed_item_ids = body.placedItemIds.filter((item: unknown) => typeof item === 'string');
    }
    if (typeof body?.dailyFirstFeedDone === 'boolean') updates.daily_first_feed_done = body.dailyFirstFeedDone;
    if (typeof body?.dailyFirstCaressDone === 'boolean') {
      updates.daily_first_caress_done = body.dailyFirstCaressDone;
    }
    if (typeof body?.dailyChatAffinityDone === 'boolean') {
      updates.daily_chat_affinity_done = body.dailyChatAffinityDone;
    }
    if (typeof body?.dailyFirstReturnDone === 'boolean') {
      updates.daily_first_return_done = body.dailyFirstReturnDone;
    }
    if (typeof body?.lastOfflineEventAt === 'string') updates.last_offline_event_at = body.lastOfflineEventAt;
    if (typeof body?.lastRoomItemUpdateAt === 'string') {
      updates.last_room_item_update_at = body.lastRoomItemUpdateAt;
    }

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
