import { handleCors } from '../_shared/cors.ts';
import { errorMessage, errorResponse, jsonResponse, readJson } from '../_shared/http.ts';
import { getOrCreateProfile, requireUser, serviceClient } from '../_shared/supabase.ts';

type ChatMessage = {
  role: 'system' | 'user' | 'assistant';
  content: string;
};

type ChatState = {
  mood_value: number;
  hunger_value: number;
  affinity_value: number;
  affinity_level: number;
  last_daily_reset_date: string;
  chat_mood_gain_today: number;
  valid_chat_count_today: number;
  affinity_gain_today: number;
  return_tip_show_count_today: number;
  feed_effective_count_today: number;
  caress_effective_count_today: number;
  daily_first_feed_done: boolean;
  daily_first_caress_done: boolean;
  daily_chat_affinity_done: boolean;
  daily_first_return_done: boolean;
};

Deno.serve(async (req) => {
  const cors = handleCors(req);
  if (cors) return cors;
  if (req.method !== 'POST') return errorResponse('Method not allowed.', 405);

  try {
    const body = await readJson(req);
    const petId = body?.petId as string | undefined;
    const message = (body?.message as string | undefined)?.trim();
    const localDate = typeof body?.localDate === 'string'
      ? body.localDate
      : new Date().toISOString().slice(0, 10);
    if (!petId) return errorResponse('petId is required.');
    if (!message) return errorResponse('message is required.');

    const { authUser } = await requireUser(req);
    const profile = await getOrCreateProfile(authUser.id);
    const admin = serviceClient();

    const { data: pet, error: petError } = await admin
      .from('pets')
      .select('*')
      .eq('id', petId)
      .eq('user_id', profile.id)
      .single();
    if (petError) throw petError;

    const { data: memories } = await admin
      .from('pet_memories')
      .select('memory_type, content, importance')
      .eq('pet_id', petId)
      .order('importance', { ascending: false })
      .limit(5);

    const { data: recentMessages } = await admin
      .from('messages')
      .select('role, content, created_at')
      .eq('pet_id', petId)
      .order('created_at', { ascending: false })
      .limit(10);

    const prompt = buildSystemPrompt(pet, memories ?? [], body ?? {});
    const chatMessages: ChatMessage[] = [
      { role: 'system', content: prompt },
      ...(recentMessages ?? [])
        .reverse()
        .filter((item) => item.role !== 'system')
        .map((item) => ({
          role: item.role === 'pet' ? 'assistant' : 'user',
          content: item.content,
        }) as ChatMessage),
      { role: 'user', content: message },
    ];

    const reply = await callDeepSeek(chatMessages);

    await admin.from('messages').insert([
      { pet_id: petId, role: 'user', content: message },
      { pet_id: petId, role: 'pet', content: reply },
    ]);

    const updates = chatStateUpdates(
      pet,
      message,
      recentMessages ?? [],
      localDate,
    );

    await admin
      .from('pets')
      .update(updates)
      .eq('id', petId);

    return jsonResponse({ reply, state: updates });
  } catch (error) {
    return errorResponse(errorMessage(error), 500);
  }
});

function buildSystemPrompt(
  pet: Record<string, unknown>,
  memories: Record<string, unknown>[],
  requestState: Record<string, unknown>,
) {
  const traits = Array.isArray(pet.personality_tags)
    ? pet.personality_tags.join(', ')
    : 'sweet, gentle';
  const species = typeof pet.species === 'string' && pet.species.trim()
    ? pet.species.trim()
    : 'virtual pet';
  const memoryText = memories
    .map((memory) => `- ${memory.content}`)
    .join('\n');

  const moodValue = numberOrDefault(requestState.mood, numberOrDefault(pet.mood_value, 100));
  const hungerValue = numberOrDefault(requestState.hunger, numberOrDefault(pet.hunger_value, 100));
  const affinityLevel = numberOrDefault(
    requestState.affinityLevel,
    numberOrDefault(pet.affinity_level, 1),
  );
  const moodLevel = stringOrDefault(requestState.moodLevel, moodLevelFor(moodValue));
  const hungerLevel = stringOrDefault(requestState.hungerLevel, hungerLevelFor(hungerValue));

  return [
    `You are the user's virtual pet named ${pet.name}.`,
    `Your species or visual identity is: ${species}.`,
    `Your personality traits are: ${traits}.`,
    'Reply like a cute pet companion with a distinct inner life, not like a generic assistant.',
    'Use species-appropriate sounds and body language only. Do not bark unless the pet is a dog. Do not meow unless the pet is a cat.',
    'Use the same language as the user whenever possible.',
    'Keep responses short, warm, playful, emotionally supportive, and suitable for a cozy mobile pet app.',
    `Current pet status: mood=${moodValue} (${moodLevel}), hunger=${hungerValue} (${hungerLevel}), affinity=Lv.${affinityLevel}, cleanliness=${pet.clean_value}.`,
    memoryText ? `Useful memories:\n${memoryText}` : '',
  ].filter(Boolean).join('\n');
}

function chatStateUpdates(
  pet: Record<string, unknown>,
  message: string,
  recentMessages: Record<string, unknown>[],
  localDate: string,
) {
  const now = new Date();
  const nowIso = now.toISOString();
  const state = resetDailyIfNeeded({
    mood_value: numberOrDefault(pet.mood_value, 100),
    hunger_value: numberOrDefault(pet.hunger_value, 100),
    affinity_value: numberOrDefault(pet.affinity_value, 0),
    affinity_level: numberOrDefault(pet.affinity_level, 1),
    last_daily_reset_date: stringOrDefault(pet.last_daily_reset_date, localDate),
    chat_mood_gain_today: numberOrDefault(pet.chat_mood_gain_today, 0),
    valid_chat_count_today: numberOrDefault(pet.valid_chat_count_today, 0),
    affinity_gain_today: numberOrDefault(pet.affinity_gain_today, 0),
    return_tip_show_count_today: numberOrDefault(pet.return_tip_show_count_today, 0),
    feed_effective_count_today: numberOrDefault(pet.feed_effective_count_today, 0),
    caress_effective_count_today: numberOrDefault(pet.caress_effective_count_today, 0),
    daily_first_feed_done: Boolean(pet.daily_first_feed_done),
    daily_first_caress_done: Boolean(pet.daily_first_caress_done),
    daily_chat_affinity_done: Boolean(pet.daily_chat_affinity_done),
    daily_first_return_done: Boolean(pet.daily_first_return_done),
  }, localDate);

  if (isValidChat(message, recentMessages, now)) {
    if (state.chat_mood_gain_today < 30) {
      const gain = Math.min(4, 30 - state.chat_mood_gain_today);
      state.mood_value = Math.min(100, state.mood_value + gain);
      state.chat_mood_gain_today += gain;
    }
    state.valid_chat_count_today += 1;
    if (
      state.valid_chat_count_today >= 3 &&
      !state.daily_chat_affinity_done &&
      state.affinity_gain_today < 3
    ) {
      state.affinity_value += 1;
      state.affinity_gain_today += 1;
      state.daily_chat_affinity_done = true;
    }
  }

  state.affinity_level = affinityLevelFor(state.affinity_value);

  return {
    mood_value: state.mood_value,
    affinity_value: state.affinity_value,
    affinity_level: state.affinity_level,
    last_daily_reset_date: state.last_daily_reset_date,
    chat_mood_gain_today: state.chat_mood_gain_today,
    valid_chat_count_today: state.valid_chat_count_today,
    affinity_gain_today: state.affinity_gain_today,
    return_tip_show_count_today: state.return_tip_show_count_today,
    feed_effective_count_today: state.feed_effective_count_today,
    caress_effective_count_today: state.caress_effective_count_today,
    daily_first_feed_done: state.daily_first_feed_done,
    daily_first_caress_done: state.daily_first_caress_done,
    daily_chat_affinity_done: state.daily_chat_affinity_done,
    daily_first_return_done: state.daily_first_return_done,
    current_status_text: 'Chatting with you',
    last_active_at: nowIso,
  };
}

function resetDailyIfNeeded(
  state: ChatState,
  localDate: string,
) {
  if (state.last_daily_reset_date === localDate) return state;
  return {
    ...state,
    last_daily_reset_date: localDate,
    feed_effective_count_today: 0,
    caress_effective_count_today: 0,
    chat_mood_gain_today: 0,
    valid_chat_count_today: 0,
    affinity_gain_today: 0,
    return_tip_show_count_today: 0,
    daily_first_feed_done: false,
    daily_first_caress_done: false,
    daily_chat_affinity_done: false,
    daily_first_return_done: false,
  };
}

function isValidChat(
  message: string,
  recentMessages: Record<string, unknown>[],
  now: Date,
) {
  if (message.length < 2) return false;
  if (!/[A-Za-z0-9\u4e00-\u9fff]/.test(message)) return false;
  const lower = message.toLowerCase();
  return !recentMessages.some((item) => {
    if (item.role !== 'user') return false;
    if (typeof item.content !== 'string') return false;
    if (item.content.toLowerCase() !== lower) return false;
    if (typeof item.created_at !== 'string') return false;
    const createdAt = new Date(item.created_at);
    return now.getTime() - createdAt.getTime() < 30_000;
  });
}

function numberOrDefault(value: unknown, fallback: number) {
  return typeof value === 'number' ? value : fallback;
}

function stringOrDefault(value: unknown, fallback: string) {
  return typeof value === 'string' && value.trim() ? value.trim() : fallback;
}

function moodLevelFor(value: number) {
  if (value >= 80) return 'happy';
  if (value >= 60) return 'calm';
  if (value >= 30) return 'lonely';
  return 'low';
}

function hungerLevelFor(value: number) {
  if (value >= 80) return 'full';
  if (value >= 60) return 'okay';
  if (value >= 30) return 'hungry';
  return 'very_hungry';
}

function affinityLevelFor(affinity: number) {
  if (affinity >= 30) return 5;
  if (affinity >= 14) return 4;
  if (affinity >= 7) return 3;
  if (affinity >= 3) return 2;
  return 1;
}

async function callDeepSeek(messages: ChatMessage[]) {
  const apiKey = Deno.env.get('DEEPSEEK_API_KEY');
  if (!apiKey) throw new Error('DEEPSEEK_API_KEY is not configured.');

  const response = await fetch('https://api.deepseek.com/chat/completions', {
    method: 'POST',
    headers: {
      Authorization: `Bearer ${apiKey}`,
      'Content-Type': 'application/json',
    },
    body: JSON.stringify({
      model: Deno.env.get('DEEPSEEK_CHAT_MODEL') ?? 'deepseek-chat',
      messages,
      temperature: 0.8,
      max_tokens: 180,
    }),
  });

  if (!response.ok) {
    const text = await response.text();
    throw new Error(`DeepSeek request failed: ${response.status} ${text}`);
  }

  const data = await response.json();
  return data.choices?.[0]?.message?.content?.trim() ?? 'I am here with you.';
}
