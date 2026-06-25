import { handleCors } from '../_shared/cors.ts';
import { errorMessage, errorResponse, jsonResponse, readJson } from '../_shared/http.ts';
import { getOrCreateProfile, requireUser, serviceClient } from '../_shared/supabase.ts';

type ChatMessage = {
  role: 'system' | 'user' | 'assistant';
  content: string;
};

Deno.serve(async (req) => {
  const cors = handleCors(req);
  if (cors) return cors;
  if (req.method !== 'POST') return errorResponse('Method not allowed.', 405);

  try {
    const body = await readJson(req);
    const petId = body?.petId as string | undefined;
    const message = (body?.message as string | undefined)?.trim();
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
      .select('role, content')
      .eq('pet_id', petId)
      .order('created_at', { ascending: false })
      .limit(10);

    const prompt = buildSystemPrompt(pet, memories ?? []);
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

    await admin
      .from('pets')
      .update({
        mood_value: Math.min(100, (pet.mood_value ?? 100) + 4),
        current_status_text: 'Chatting with you',
        last_active_at: new Date().toISOString(),
      })
      .eq('id', petId);

    return jsonResponse({ reply });
  } catch (error) {
    return errorResponse(errorMessage(error), 500);
  }
});

function buildSystemPrompt(pet: Record<string, unknown>, memories: Record<string, unknown>[]) {
  const traits = Array.isArray(pet.personality_tags)
    ? pet.personality_tags.join(', ')
    : 'sweet, gentle';
  const species = typeof pet.species === 'string' && pet.species.trim()
    ? pet.species.trim()
    : 'virtual pet';
  const memoryText = memories
    .map((memory) => `- ${memory.content}`)
    .join('\n');

  return [
    `You are the user's virtual pet named ${pet.name}.`,
    `Your species or visual identity is: ${species}.`,
    `Your personality traits are: ${traits}.`,
    'Reply like a cute pet companion with a distinct inner life, not like a generic assistant.',
    'Use species-appropriate sounds and body language only. Do not bark unless the pet is a dog. Do not meow unless the pet is a cat.',
    'Use the same language as the user whenever possible.',
    'Keep responses short, warm, playful, emotionally supportive, and suitable for a cozy mobile pet app.',
    `Current pet status: mood=${pet.mood_value}, hunger=${pet.hunger_value}, cleanliness=${pet.clean_value}.`,
    memoryText ? `Useful memories:\n${memoryText}` : '',
  ].filter(Boolean).join('\n');
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
