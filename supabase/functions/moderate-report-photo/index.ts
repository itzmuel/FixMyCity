import { serve } from 'https://deno.land/std@0.224.0/http/server.ts';

type ModerationInput = {
  category?: string;
  description?: string;
  address?: string;
  latitude?: number;
  longitude?: number;
  mimeType?: string;
  imageBase64?: string;
  photoUrl?: string;
  threshold?: number;
};

type ModerationOutput = {
  allow: boolean;
  score: number;
  reason?: string;
  reasonCode?: string;
  blocked?: boolean;
};

const providerUrl = Deno.env.get('MODERATION_PROVIDER_URL')?.trim();
const providerApiKey = Deno.env.get('MODERATION_PROVIDER_API_KEY')?.trim();

serve(async (req: Request): Promise<Response> => {
  if (req.method !== 'POST') {
    return json({ error: 'Method not allowed' }, 405);
  }

  let input: ModerationInput;
  try {
    input = (await req.json()) as ModerationInput;
  } catch {
    return json({ error: 'Invalid JSON payload' }, 400);
  }

  const threshold = normalizeThreshold(input.threshold);

  // Optional external moderation provider hook.
  if (providerUrl) {
    try {
      const providerResult = await invokeProvider(input, threshold);
      return json(providerResult, 200);
    } catch {
      // Keep fail-open behavior so reports are not blocked by provider outages.
    }
  }

  const fallback = localHeuristicModeration(input, threshold);
  return json(fallback, 200);
});

function normalizeThreshold(value: number | undefined): number {
  if (typeof value !== 'number' || Number.isNaN(value)) return 0.65;
  if (value < 0) return 0;
  if (value > 1) return 1;
  return value;
}

async function invokeProvider(
  input: ModerationInput,
  threshold: number,
): Promise<ModerationOutput> {
  const headers: Record<string, string> = {
    'content-type': 'application/json',
  };
  if (providerApiKey) {
    headers.authorization = `Bearer ${providerApiKey}`;
  }

  const response = await fetch(providerUrl!, {
    method: 'POST',
    headers,
    body: JSON.stringify({ ...input, threshold }),
  });

  if (!response.ok) {
    throw new Error(`Provider failed with ${response.status}`);
  }

  const data = (await response.json()) as Record<string, unknown>;
  const score = toScore(data.score);
  const allow = toAllow(data.allow, score, threshold);
  const reason = asNonEmptyString(data.reason);
  const reasonCode = asNonEmptyString(data.reasonCode);

  return {
    allow,
    blocked: !allow,
    score,
    reason,
    reasonCode,
  };
}

function localHeuristicModeration(
  input: ModerationInput,
  threshold: number,
): ModerationOutput {
  const text = `${input.category ?? ''} ${input.description ?? ''} ${input.address ?? ''}`
    .toLowerCase()
    .trim();

  const bannedTerms = [
    'selfie',
    'my face',
    'his face',
    'her face',
    'person',
    'people',
    'portrait',
  ];

  if (bannedTerms.some((term) => text.includes(term))) {
    return {
      allow: false,
      blocked: true,
      score: 0.95,
      reason: 'Photo or description appears to target people instead of a civic issue.',
      reasonCode: 'people_content',
    };
  }

  // This fallback score is intentionally conservative: if local client checks passed,
  // keep the default as allow and only block very suspicious text-only payloads.
  let score = 0.2;

  if (!input.imageBase64 && !input.photoUrl) {
    score += 0.4;
  }
  if ((input.description ?? '').trim().length < 12) {
    score += 0.25;
  }
  if ((input.category ?? '').toLowerCase() === 'other') {
    score += 0.1;
  }

  score = Math.min(1, Math.max(0, score));
  const allow = score < threshold;

  return {
    allow,
    blocked: !allow,
    score,
    reason: allow
      ? undefined
      : 'Server moderation could not confirm this report as a civic issue.',
    reasonCode: allow ? undefined : 'low_confidence',
  };
}

function toScore(value: unknown): number {
  if (typeof value !== 'number' || Number.isNaN(value)) return 0;
  return Math.min(1, Math.max(0, value));
}

function toAllow(value: unknown, score: number, threshold: number): boolean {
  if (typeof value === 'boolean') return value;
  return score < threshold;
}

function asNonEmptyString(value: unknown): string | undefined {
  if (typeof value !== 'string') return undefined;
  const trimmed = value.trim();
  return trimmed.length === 0 ? undefined : trimmed;
}

function json(body: unknown, status = 200): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: {
      'content-type': 'application/json; charset=utf-8',
      'cache-control': 'no-store',
    },
  });
}
