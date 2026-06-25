import { handleCors } from '../_shared/cors.ts';
import { errorMessage, errorResponse, jsonResponse, readJson } from '../_shared/http.ts';
import { getOrCreateProfile, requireUser, serviceClient } from '../_shared/supabase.ts';

Deno.serve(async (req) => {
  const cors = handleCors(req);
  if (cors) return cors;
  if (req.method !== 'POST') return errorResponse('Method not allowed.', 405);

  let taskId: string | undefined;
  let profileId: string | undefined;
  try {
    const body = await readJson(req);
    taskId = body?.taskId as string | undefined;
    if (!taskId) return errorResponse('taskId is required.');

    const { authUser } = await requireUser(req);
    const profile = await getOrCreateProfile(authUser.id);
    profileId = profile.id;
    const admin = serviceClient();

    const { data: task, error: taskError } = await admin
      .from('generation_tasks')
      .select('*')
      .eq('id', taskId)
      .eq('user_id', profile.id)
      .single();
    if (taskError) throw taskError;

    await admin
      .from('generation_tasks')
      .update({ status: 'processing' })
      .eq('id', taskId)
      .eq('user_id', profile.id);

    const imageUrls = await generateCandidates(task.input_photo_path, taskId);

    const { data: updated, error: updateError } = await admin
      .from('generation_tasks')
      .update({
        status: 'success',
        result_urls: imageUrls,
      })
      .eq('id', taskId)
      .eq('user_id', profile.id)
      .select('*')
      .single();

    if (updateError) throw updateError;
    return jsonResponse({ task: updated });
  } catch (error) {
    const message = errorMessage(error);
    if (taskId && profileId) {
      try {
        await serviceClient()
          .from('generation_tasks')
          .update({ status: 'failed', error_message: message })
          .eq('id', taskId)
          .eq('user_id', profileId);
      } catch {
        // Preserve the original generation error for the client.
      }
    }
    return errorResponse(message, 500);
  }
});

async function generateCandidates(inputPhotoPath: string | null, taskId: string) {
  const apiKey = Deno.env.get('GEMINI_API_KEY');
  if (!apiKey) throw new Error('GEMINI_API_KEY is not configured.');
  if (!inputPhotoPath) throw new Error('Task is missing input_photo_path.');

  const admin = serviceClient();
  const { data: downloaded, error: downloadError } = await admin.storage
    .from('pet-uploads')
    .download(inputPhotoPath);
  if (downloadError) throw downloadError;

  const sourceBytes = new Uint8Array(await downloaded.arrayBuffer());
  const sourceBase64 = toBase64(sourceBytes);
  const model = Deno.env.get('GEMINI_IMAGE_MODEL') ?? 'gemini-2.5-flash-image';
  const basePrompt = [
    'Create a PetPal virtual companion avatar from this real pet photo.',
    'The product direction is a cozy 16-bit pixel-art mobile pet, like a tiny living game sprite, not a generic sticker, plush toy, 3D render, emoji, or flat mascot icon.',
    'Preserve the actual pet identity: species, breed cues, fur length, fur color pattern, face shape, ears, muzzle, eye color impression, and any unique markings.',
    'Use crisp pixel clusters, limited warm palette, readable silhouette, small idle-game proportions, and expressive eyes that still match the source pet.',
    'Square composition, centered full body or bust, simple transparent or soft cream background, no text, no UI frame, no border, no watermark.',
    'Output a polished production asset that could sit naturally inside a cozy pixel pet room UI.',
  ].join(' ');

  const images = [];
  for (let index = 0; index < 4; index += 1) {
    const prompt = [
      basePrompt,
      `Create option ${index + 1} with a distinct pose and expression while keeping the same pet identity. Variant style: ${variantDirection(index)}.`,
    ].join(' ');
    images.push(await generateCandidateImage({
      apiKey,
      model,
      prompt,
      sourceBase64,
      mimeType: downloaded.type || 'image/jpeg',
    }));
  }

  const urls: string[] = [];
  for (const [index, image] of images.entries()) {
    const path = `${taskId}/candidate-${index + 1}.png`;
    const bytes = base64ToBytes(image.data);
    const { error: uploadError } = await admin.storage
      .from('pet-avatars')
      .upload(path, bytes, {
        contentType: image.mimeType,
        upsert: true,
      });
    if (uploadError) throw uploadError;

    const { data } = admin.storage.from('pet-avatars').getPublicUrl(path);
    urls.push(data.publicUrl);
  }

  return urls;
}

async function generateCandidateImage({
  apiKey,
  model,
  prompt,
  sourceBase64,
  mimeType,
}: {
  apiKey: string;
  model: string;
  prompt: string;
  sourceBase64: string;
  mimeType: string;
}) {
  const response = await fetch(
    `https://generativelanguage.googleapis.com/v1beta/models/${model}:generateContent?key=${apiKey}`,
    {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        contents: [
          {
            parts: [
              { text: prompt },
              {
                inline_data: {
                  mime_type: mimeType,
                  data: sourceBase64,
                },
              },
            ],
          },
        ],
        generationConfig: {
          responseModalities: ['IMAGE', 'TEXT'],
        },
      }),
    },
  );

  if (!response.ok) {
    const text = await response.text();
    throw new Error(`Gemini image request failed: ${response.status} ${text}`);
  }

  const payload = await response.json();
  const images = extractImages(payload);
  if (!images.length) throw new Error('Gemini returned no image candidates.');
  return images[0];
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

function variantDirection(index: number) {
  const directions = [
    'gentle front-facing companion, calm smile, cozy everyday look',
    'playful three-quarter pose, curious eyes, subtle motion in ears or tail',
    'sleepy affectionate pose, softer rounded silhouette, warm blush accents',
    'confident tiny hero pose, brighter accent color, clear collectible outline',
  ];
  return directions[index % directions.length];
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
