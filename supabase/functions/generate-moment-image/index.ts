import { handleCors } from '../_shared/cors.ts';
import { errorMessage, errorResponse, jsonResponse, readJson } from '../_shared/http.ts';
import { getOrCreateProfile, requireUser, serviceClient } from '../_shared/supabase.ts';

Deno.serve(async (req) => {
  const cors = handleCors(req);
  if (cors) return cors;
  if (req.method !== 'POST') return errorResponse('Method not allowed.', 405);

  let taskId: string | undefined;
  try {
    const body = await readJson(req);
    const petId = body?.petId as string | undefined;
    const momentId = body?.momentId as string | undefined;
    const eventId = body?.eventId as string | undefined;
    if (!petId || !momentId || !eventId) {
      return errorResponse('petId, momentId, and eventId are required.');
    }

    const { authUser } = await requireUser(req);
    const profile = await getOrCreateProfile(authUser.id);
    const admin = serviceClient();
    const pet = await assertPetOwner(admin, petId, profile.id);

    const existing = await findReadyAsset(admin, petId, momentId);
    if (existing) {
      return jsonResponse({ asset: toClientAsset(existing), taskId: null });
    }

    const prompt = buildMomentPrompt({
      imageKey: stringOrDefault(body?.imageKey, eventId),
      eventType: stringOrDefault(body?.eventType, 'special'),
      title: stringOrDefault(body?.title, 'Little Memory'),
      body: stringOrDefault(body?.body, ''),
      diaryText: stringOrDefault(body?.diaryText, ''),
      petName: stringOrDefault(body?.petName, pet.name ?? 'the pet'),
      species: stringOrDefault(body?.species, pet.species ?? 'virtual pet'),
      personalityTags: stringArrayOrDefault(body?.personalityTags),
      placedItemIds: stringArrayOrDefault(body?.placedItemIds),
      specialPersonalityDetail: stringOrDefault(body?.specialPersonalityDetail, ''),
    });

    const { data: task, error: taskError } = await admin
      .from('moment_generation_tasks')
      .insert({
        pet_id: petId,
        moment_id: momentId,
        event_id: eventId,
        pending_id: body?.pendingId ?? null,
        status: 'processing',
        prompt,
      })
      .select('*')
      .single();
    if (taskError) throw taskError;
    taskId = task.task_id;

    const reference = await referenceImageFor(admin, {
      avatarUrl: body?.avatarUrl as string | undefined,
      sourcePhotoPath: body?.sourcePhotoPath as string | undefined,
    });
    const image = await generateMomentImage({
      prompt,
      reference,
    });

    const path = `${petId}/${momentId}/${taskId}.png`;
    const bytes = base64ToBytes(image.data);
    const { error: uploadError } = await admin.storage
      .from('pet-moments')
      .upload(path, bytes, {
        contentType: image.mimeType,
        upsert: true,
      });
    if (uploadError) throw uploadError;
    const { data: publicUrl } = admin.storage.from('pet-moments').getPublicUrl(path);

    const { data: asset, error: assetError } = await admin
      .from('moment_assets')
      .upsert({
        pet_id: petId,
        role_id: body?.roleId ?? null,
        moment_id: momentId,
        event_id: eventId,
        image_key: body?.imageKey ?? eventId,
        source_type: 'ai',
        image_url: publicUrl.publicUrl,
        thumbnail_url: publicUrl.publicUrl,
        status: 'ready',
        prompt,
      }, { onConflict: 'pet_id,moment_id' })
      .select('*')
      .single();
    if (assetError) throw assetError;

    await admin
      .from('moment_generation_tasks')
      .update({
        status: 'success',
        result_asset_id: asset.asset_id,
        result_url: publicUrl.publicUrl,
      })
      .eq('task_id', taskId);

    return jsonResponse({ asset: toClientAsset(asset), taskId });
  } catch (error) {
    const message = errorMessage(error);
    if (taskId) {
      try {
        await serviceClient()
          .from('moment_generation_tasks')
          .update({ status: 'failed', error_message: message })
          .eq('task_id', taskId);
      } catch {
        // Preserve original generation error.
      }
    }
    return errorResponse(message, 500);
  }
});

async function assertPetOwner(
  admin: ReturnType<typeof serviceClient>,
  petId: string,
  profileId: string,
) {
  const { data, error } = await admin
    .from('pets')
    .select('*')
    .eq('id', petId)
    .eq('user_id', profileId)
    .single();
  if (error) throw new Error('Pet not found.');
  return data;
}

async function findReadyAsset(
  admin: ReturnType<typeof serviceClient>,
  petId: string,
  momentId: string,
) {
  const { data, error } = await admin
    .from('moment_assets')
    .select('*')
    .eq('pet_id', petId)
    .eq('moment_id', momentId)
    .eq('status', 'ready')
    .maybeSingle();
  if (error) throw error;
  return data;
}

async function referenceImageFor(
  admin: ReturnType<typeof serviceClient>,
  input: { avatarUrl?: string; sourcePhotoPath?: string },
) {
  if (input.avatarUrl?.startsWith('http')) {
    try {
      const response = await fetch(input.avatarUrl);
      if (response.ok) {
        return {
          mimeType: response.headers.get('content-type') ?? 'image/png',
          base64: toBase64(new Uint8Array(await response.arrayBuffer())),
        };
      }
    } catch {
      // Fall back to the original source photo below.
    }
  }
  if (input.sourcePhotoPath) {
    const { data, error } = await admin.storage
      .from('pet-uploads')
      .download(input.sourcePhotoPath);
    if (!error && data) {
      return {
        mimeType: data.type || 'image/jpeg',
        base64: toBase64(new Uint8Array(await data.arrayBuffer())),
      };
    }
  }
  return null;
}

async function generateMomentImage({
  prompt,
  reference,
}: {
  prompt: string;
  reference: { mimeType: string; base64: string } | null;
}) {
  const apiKey = Deno.env.get('GEMINI_API_KEY');
  if (!apiKey) throw new Error('GEMINI_API_KEY is not configured.');
  const model = Deno.env.get('GEMINI_IMAGE_MODEL') ?? 'gemini-2.5-flash-image';
  const parts: Array<Record<string, unknown>> = [{ text: prompt }];
  if (reference) {
    parts.push({
      inline_data: {
        mime_type: reference.mimeType,
        data: reference.base64,
      },
    });
  }

  const response = await fetch(
    `https://generativelanguage.googleapis.com/v1beta/models/${model}:generateContent?key=${apiKey}`,
    {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        contents: [{ parts }],
        generationConfig: { responseModalities: ['IMAGE', 'TEXT'] },
      }),
    },
  );
  if (!response.ok) {
    const text = await response.text();
    throw new Error(`Gemini image request failed: ${response.status} ${text}`);
  }
  const payload = await response.json();
  const images = extractImages(payload);
  if (!images.length) throw new Error('Gemini returned no Moment image.');
  return images[0];
}

function buildMomentPrompt(input: {
  imageKey: string;
  eventType: string;
  title: string;
  body: string;
  diaryText: string;
  petName: string;
  species: string;
  personalityTags: string[];
  placedItemIds: string[];
  specialPersonalityDetail: string;
}) {
  const scene = scenePromptFor(input.imageKey, input.eventType);
  const traits = input.personalityTags.length
    ? input.personalityTags.join(', ')
    : 'gentle companion';
  const items = input.placedItemIds.length
    ? input.placedItemIds.join(', ')
    : 'cozy room details';
  return [
    'Create one finished PetPal Moment illustration for a mobile virtual pet app.',
    'Style: cozy 16-bit pixel-art diary scene, warm bedroom lighting, crisp pixel clusters, readable silhouette, polished production asset.',
    'The pet can be any role or species such as cat, dog, rabbit, or fantasy pet. Adapt the pose, ears, tail, body shape, and expression to the pet naturally.',
    'If a reference image is provided, preserve the pet identity, fur color, markings, face shape, and eye impression. If no reference is provided, use the supplied species and traits.',
    `Pet name: ${input.petName}. Species or role: ${input.species}. Personality: ${traits}. ${input.specialPersonalityDetail}`,
    `Moment title: ${input.title}. Event copy: ${input.body}. Diary: ${input.diaryText}.`,
    `Scene direction: ${scene}`,
    `Room item context: ${items}.`,
    'Composition: one pet as the clear subject, cozy room environment, no UI, no text, no speech bubble, no border, no watermark, no extra animals, no humans.',
    'Mood: warm, safe, affectionate, never sad, sick, injured, abandoned, or scary.',
    'Output a landscape image suitable for a Moment card and detail page.',
  ].join(' ');
}

function scenePromptFor(imageKey: string, eventType: string) {
  const scenes: Record<string, string> = {
    blanket_nap: 'The pet is curled on or beside a soft blanket, peaceful and warm, with soft folds and a sleepy cozy pose.',
    window_nap: 'The pet dozes near a window cushion with gentle sunlight, curtain glow, and a quiet afternoon atmosphere.',
    door_waiting: 'The pet rests near the room door in a calm, patient pose, with the room still feeling safe and lived-in.',
    pillow_curl: 'Nighttime room scene with the pet curled like a small comma near a pillow or cushion, soft moonlit warmth.',
    tiny_dream: 'Dreamy cozy room moment with subtle star-like sparkles around the sleeping pet, still grounded in the bedroom.',
    food_bowl_watch: 'The pet sits near a small food bowl with curious eyes, patient and cute rather than hungry or distressed.',
    after_meal_nap: 'The pet takes a content after-meal nap near the bowl or blanket, calm full-belly comfort.',
    quiet_corner: 'The pet has chosen a quiet cozy corner, relaxed and soothed, with warm shadows and soft room details.',
    happy_roll: 'The pet rolls or wiggles happily on a rug, energetic but still readable in a cozy indoor composition.',
    toy_chase: 'The pet plays with a small toy ball, mid-chase or proud pause, playful movement in the room.',
    ball_under_bed: 'The toy ball has rolled partly under the bed or furniture while the pet investigates it with curious focus.',
    welcome_wiggle: 'The pet is excited in a gentle welcome pose, bright eyes, small movement, warm room background.',
    box_hideout: 'The pet peeks from a simple box hideout, cozy and playful, with eyes or face visible.',
    tail_peek: 'The pet is partly hidden in a box or behind soft room objects, with tail or tiny detail peeking out playfully.',
    sunbeam_stretch: 'The pet stretches in a sunbeam on the floor or cushion, warm sunlight and peaceful morning energy.',
    goodnight_purr: 'Nighttime quiet scene with the pet resting peacefully, soft blanket or cushion nearby, gentle goodnight mood.',
    curtain_watch: 'The pet watches curtains or window light with curious attention, calm mystery and cozy room atmosphere.',
    tiny_troublemaker: 'A harmless tiny room mystery: one small object slightly moved, pet looking innocent and playful.',
    missed_you: 'The pet keeps the room company in a warm waiting pose, affectionate but not lonely or sad.',
    first_little_memory: 'A special first home memory: pet centered in a cozy room, warm glow, small magical diary feeling.',
  };
  return scenes[imageKey] ?? `A cozy ${eventType} Moment in the pet room, warm and affectionate.`;
}

function extractImages(payload: Record<string, unknown>) {
  const candidates = (payload.candidates as Array<Record<string, unknown>> | undefined) ?? [];
  return candidates.flatMap((candidate) => {
    const content = candidate.content as Record<string, unknown> | undefined;
    const parts = (content?.parts as Array<Record<string, unknown>> | undefined) ?? [];
    return parts.flatMap((part) => {
      const data = part.inlineData ?? part.inline_data;
      if (!data || typeof data !== 'object') return [];
      const inlineData = data as Record<string, string>;
      if (!inlineData.data) return [];
      return [{
        data: inlineData.data,
        mimeType: inlineData.mimeType ?? inlineData.mime_type ?? 'image/png',
      }];
    });
  });
}

function toClientAsset(row: Record<string, unknown>) {
  return {
    assetId: row.asset_id,
    momentId: row.moment_id,
    imageUrl: row.image_url,
    sourceType: row.source_type,
    petId: row.pet_id,
    roleId: row.role_id,
    thumbnailUrl: row.thumbnail_url,
    status: row.status,
    createdAt: row.created_at,
  };
}

function stringOrDefault(value: unknown, fallback: string) {
  return typeof value === 'string' && value.trim() ? value.trim() : fallback;
}

function stringArrayOrDefault(value: unknown) {
  return Array.isArray(value) ? value.filter((item) => typeof item === 'string') : [];
}

function toBase64(bytes: Uint8Array) {
  let binary = '';
  for (const byte of bytes) binary += String.fromCharCode(byte);
  return btoa(binary);
}

function base64ToBytes(base64: string) {
  const binary = atob(base64);
  const bytes = new Uint8Array(binary.length);
  for (let i = 0; i < binary.length; i += 1) {
    bytes[i] = binary.charCodeAt(i);
  }
  return bytes;
}
