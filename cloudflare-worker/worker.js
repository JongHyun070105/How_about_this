// Cloudflare Workers API Proxy for ReviewAI
// JWT 기반 동적 토큰 인증 + Rate Limiting

// Rate limiting 설정
const RATE_LIMIT_WINDOW = 15 * 60 * 1000; // 15분
const RATE_LIMIT_MAX_REQUESTS = 100; // 15분당 최대 100회

// JWT 설정
const JWT_EXPIRES_IN = 3600; // 1시간 (초)
const REFRESH_TOKEN_EXPIRES_IN = 7 * 24 * 3600; // 7일 (초)

// CORS 헤더
const CORS_HEADERS = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Methods": "GET, POST, OPTIONS",
  "Access-Control-Allow-Headers": "Content-Type, Authorization, x-app-token",
  "Access-Control-Max-Age": "86400",
};

// JWT 헬퍼 함수들 (Web Crypto API 사용)
async function generateJWT(payload, secret, expiresIn) {
  const header = { alg: "HS256", typ: "JWT" };
  const now = Math.floor(Date.now() / 1000);

  const jwtPayload = {
    ...payload,
    iat: now,
    exp: now + expiresIn,
    iss: "reviewai-api",
    aud: "reviewai-app",
  };

  const encodedHeader = base64urlEncode(JSON.stringify(header));
  const encodedPayload = base64urlEncode(JSON.stringify(jwtPayload));
  const message = `${encodedHeader}.${encodedPayload}`;

  const signature = await sign(message, secret);
  return `${message}.${signature}`;
}

async function verifyJWT(token, secret) {
  const parts = token.split(".");
  if (parts.length !== 3) {
    throw new Error("Invalid token format");
  }

  const [encodedHeader, encodedPayload, signature] = parts;
  const message = `${encodedHeader}.${encodedPayload}`;

  const expectedSignature = await sign(message, secret);
  if (signature !== expectedSignature) {
    throw new Error("Invalid signature");
  }

  const payload = JSON.parse(base64urlDecode(encodedPayload));

  const now = Math.floor(Date.now() / 1000);
  if (payload.exp && payload.exp < now) {
    throw new Error("Token expired");
  }

  return payload;
}

async function sign(message, secret) {
  const encoder = new TextEncoder();
  const key = await crypto.subtle.importKey(
    "raw",
    encoder.encode(secret),
    { name: "HMAC", hash: "SHA-256" },
    false,
    ["sign"]
  );

  const signature = await crypto.subtle.sign(
    "HMAC",
    key,
    encoder.encode(message)
  );

  return base64urlEncode(new Uint8Array(signature));
}

function base64urlEncode(data) {
  let str = typeof data === "string" ? data : String.fromCharCode(...data);
  return btoa(str).replace(/\+/g, "-").replace(/\//g, "_").replace(/=/g, "");
}

function base64urlDecode(str) {
  str = str.replace(/-/g, "+").replace(/_/g, "/");
  while (str.length % 4) str += "=";
  return atob(str);
}

async function sha256Hash(text) {
  const encoder = new TextEncoder();
  const data = encoder.encode(text);
  const hash = await crypto.subtle.digest("SHA-256", data);
  return Array.from(new Uint8Array(hash))
    .map((b) => b.toString(16).padStart(2, "0"))
    .join("");
}

function generateUUID() {
  return crypto.randomUUID();
}

// Rate limiting 함수
async function checkRateLimit(env, clientId) {
  const key = `rate_limit:${clientId}`;
  const now = Date.now();

  const data = await env.RATE_LIMIT.get(key, { type: "json" });

  if (!data) {
    await env.RATE_LIMIT.put(
      key,
      JSON.stringify({ count: 1, resetTime: now + RATE_LIMIT_WINDOW }),
      { expirationTtl: 900 } // 15분
    );
    return true;
  }

  if (now > data.resetTime) {
    await env.RATE_LIMIT.put(
      key,
      JSON.stringify({ count: 1, resetTime: now + RATE_LIMIT_WINDOW }),
      { expirationTtl: 900 }
    );
    return true;
  }

  if (data.count >= RATE_LIMIT_MAX_REQUESTS) {
    return false;
  }

  data.count++;
  await env.RATE_LIMIT.put(key, JSON.stringify(data), {
    expirationTtl: Math.ceil((data.resetTime - now) / 1000),
  });
  return true;
}

// 메인 핸들러
export default {
  async fetch(request, env, ctx) {
    // CORS preflight 처리
    if (request.method === "OPTIONS") {
      return new Response(null, { headers: CORS_HEADERS });
    }

    const url = new URL(request.url);
    const path = url.pathname;

    // Rate limiting (모든 요청에 적용)
    const clientId = request.headers.get("CF-Connecting-IP") || "unknown";
    const rateLimitOk = await checkRateLimit(env, clientId);

    if (!rateLimitOk) {
      return jsonResponse(
        {
          error: "Too many requests",
          message: "Rate limit exceeded. Please try again later.",
        },
        429,
        CORS_HEADERS
      );
    }

    try {
      // 헬스 체크
      if (path === "/health" && request.method === "GET") {
        return jsonResponse(
          { status: "OK", message: "ReviewAI API Proxy Server is running" },
          200,
          CORS_HEADERS
        );
      }

      // 토큰 발급
      if (path === "/api/auth/token" && request.method === "POST") {
        return handleTokenGeneration(request, env);
      }

      // 토큰 갱신
      if (path === "/api/auth/refresh" && request.method === "POST") {
        return handleTokenRefresh(request, env);
      }

      // Gemini API 프록시
      if (path === "/api/gemini-proxy" && request.method === "POST") {
        return handleGeminiProxy(request, env);
      }

      // 카카오 로컬 API 프록시
      if (path === "/api/kakao-local" && request.method === "GET") {
        return handleKakaoLocalProxy(request, env);
      }

      // 동적 설정 API
      if (path === "/api/config" && request.method === "GET") {
        return handleConfig(env);
      }

      // 서버 시간 API (시스템 시간 조작 방지)
      if (path === "/api/server-time" && request.method === "GET") {
        return handleServerTime(request, env);
      }

      // 날씨 API 프록시
      if (path === "/weather" && request.method === "GET") {
        return handleWeatherProxy(request, env);
      }

      // AI 식습관 인사이트 API
      if (path === "/api/food-insight" && request.method === "POST") {
        return handleFoodInsight(request, env);
      }

      return jsonResponse({ error: "Not Found" }, 404, CORS_HEADERS);
    } catch (error) {
      console.error("Worker error:", error);
      return jsonResponse(
        { error: "Internal server error", details: error.message },
        500,
        CORS_HEADERS
      );
    }
  },
};

// 토큰 발급 핸들러
async function handleTokenGeneration(request, env) {
  const body = await request.json();
  const { deviceId, appVersion, deviceInfo } = body;

  if (!deviceId || !appVersion) {
    return jsonResponse(
      {
        error: "Missing required fields",
        message: "deviceId and appVersion are required",
      },
      400,
      CORS_HEADERS
    );
  }

  // 앱 버전 검증
  const minAppVersion = env.MIN_APP_VERSION || "1.0.0";
  if (appVersion < minAppVersion) {
    return jsonResponse(
      {
        error: "App version too old",
        message: `Minimum app version required: ${minAppVersion}`,
      },
      400,
      CORS_HEADERS
    );
  }

  // 디바이스 해시 생성
  const deviceHash = await sha256Hash(
    `${deviceId}-${appVersion}-${deviceInfo || ""}`
  );

  // JWT 페이로드
  const payload = {
    deviceId: deviceId,
    appVersion: appVersion,
    deviceHash: deviceHash,
    jti: generateUUID(),
  };

  // JWT 토큰 생성
  const accessToken = await generateJWT(
    payload,
    env.JWT_SECRET,
    JWT_EXPIRES_IN
  );
  const refreshToken = await generateJWT(
    { deviceId, deviceHash, type: "refresh" },
    env.JWT_SECRET,
    REFRESH_TOKEN_EXPIRES_IN
  );

  return jsonResponse(
    {
      accessToken: accessToken,
      refreshToken: refreshToken,
      expiresIn: JWT_EXPIRES_IN,
      tokenType: "Bearer",
    },
    200,
    CORS_HEADERS
  );
}

// 토큰 갱신 핸들러
async function handleTokenRefresh(request, env) {
  const body = await request.json();
  const { refreshToken } = body;

  if (!refreshToken) {
    return jsonResponse(
      { error: "Refresh token is required" },
      400,
      CORS_HEADERS
    );
  }

  try {
    const decoded = await verifyJWT(refreshToken, env.JWT_SECRET);

    if (decoded.type !== "refresh") {
      return jsonResponse({ error: "Invalid token type" }, 400, CORS_HEADERS);
    }

    // 새 액세스 토큰 생성
    const payload = {
      deviceId: decoded.deviceId,
      deviceHash: decoded.deviceHash,
      jti: generateUUID(),
    };

    const newAccessToken = await generateJWT(
      payload,
      env.JWT_SECRET,
      JWT_EXPIRES_IN
    );

    return jsonResponse(
      {
        accessToken: newAccessToken,
        expiresIn: JWT_EXPIRES_IN,
        tokenType: "Bearer",
      },
      200,
      CORS_HEADERS
    );
  } catch (error) {
    return jsonResponse(
      { error: "Invalid refresh token", message: "Please re-authenticate" },
      401,
      CORS_HEADERS
    );
  }
}

// Gemini API 프록시 핸들러 (Durable Object 사용)
async function handleGeminiProxy(request, env) {
  // JWT 검증
  const authHeader = request.headers.get("Authorization");
  if (!authHeader || !authHeader.startsWith("Bearer ")) {
    return jsonResponse(
      {
        error: "No valid token provided",
        message: "Authorization header with Bearer token is required",
      },
      401,
      CORS_HEADERS
    );
  }

  const token = authHeader.substring(7);
  try {
    await verifyJWT(token, env.JWT_SECRET);
  } catch (error) {
    if (error.message === "Token expired") {
      return jsonResponse(
        { error: "Token expired", message: "Please refresh your token" },
        401,
        CORS_HEADERS
      );
    }
    return jsonResponse(
      { error: "Invalid token", message: "Authentication failed" },
      401,
      CORS_HEADERS
    );
  }

  // Durable Object를 통해 Gemini API 호출 (미국 리전 강제)
  // "US_PROXY"라는 이름으로 고정된 DO ID 생성
  const id = env.GEMINI_PROXY.idFromName("US_PROXY");
  
  // locationHint를 'wnam' (Western North America)로 설정하여 미국에 생성 유도
  const stub = env.GEMINI_PROXY.get(id, { locationHint: "wnam" });
  
  // DO에 요청 전달
  return stub.fetch(request);
}

// 카카오 로컬 API 프록시 핸들러
async function handleKakaoLocalProxy(request, env) {
  // JWT 검증
  const authHeader = request.headers.get("Authorization");
  if (!authHeader || !authHeader.startsWith("Bearer ")) {
    return jsonResponse(
      {
        error: "No valid token provided",
        message: "Authorization header with Bearer token is required",
      },
      401,
      CORS_HEADERS
    );
  }

  const token = authHeader.substring(7);
  let user;

  try {
    user = await verifyJWT(token, env.JWT_SECRET);
  } catch (error) {
    if (error.message === "Token expired") {
      return jsonResponse(
        { error: "Token expired", message: "Please refresh your token" },
        401,
        CORS_HEADERS
      );
    }
    return jsonResponse(
      { error: "Invalid token", message: "Token verification failed" },
      401,
      CORS_HEADERS
    );
  }

  // 추가 보안 검증
  if (!user.deviceId || !user.deviceHash) {
    return jsonResponse(
      {
        error: "Invalid token payload",
        message: "Token missing required information",
      },
      401,
      CORS_HEADERS
    );
  }

  // URL 파라미터 파싱
  const url = new URL(request.url);
  const query = url.searchParams.get("query");
  const x = url.searchParams.get("x"); // 경도
  const y = url.searchParams.get("y"); // 위도
  const radius = url.searchParams.get("radius") || "1000";
  const page = url.searchParams.get("page") || "1";
  const size = url.searchParams.get("size") || "15";
  const categoryGroupCode = url.searchParams.get("category_group_code"); // 카테고리 그룹 코드

  try {
    // 필수 파라미터 검증
    if (!query || !x || !y) {
      return jsonResponse(
        {
          error: "Missing required parameters",
          message: "query, x (longitude), and y (latitude) are required",
        },
        400,
        CORS_HEADERS
      );
    }

    // 카카오 API 키 가져오기
    const apiKey = env.KAKAO_API_KEY;
    if (!apiKey) {
      console.error("KAKAO_API_KEY not found in environment variables");
      return jsonResponse({ error: "API key not configured" }, 500, CORS_HEADERS);
    }

    // 카카오 로컬 API 호출
    const kakaoUrl = "https://dapi.kakao.com/v2/local/search/keyword.json";
    const kakaoParams = new URLSearchParams({
      query: query,
      x: x,
      y: y,
      radius: radius,
      page: page,
      size: size,
      sort: "distance",
    });

    // 카테고리 그룹 코드가 있으면 추가
    if (categoryGroupCode) {
      kakaoParams.append("category_group_code", categoryGroupCode);
    }

    console.log(`Calling Kakao API: ${kakaoUrl}?${kakaoParams}`);

    const response = await fetch(`${kakaoUrl}?${kakaoParams}`, {
      method: "GET",
      headers: {
        Authorization: `KakaoAK ${apiKey}`,
        "Content-Type": "application/json",
      },
    });

    if (!response.ok) {
      const errorText = await response.text();
      console.error("Kakao API error:", response.status, errorText);
      return jsonResponse(
        { error: "Kakao API error", status: response.status, details: errorText },
        response.status,
        CORS_HEADERS
      );
    }

    const data = await response.json();
    return jsonResponse(data, 200, CORS_HEADERS);
  } catch (error) {
    console.error("Worker Error in handleKakaoLocalProxy:", error);
    return jsonResponse(
      {
        error: "Internal Server Error",
        message: "An unexpected error occurred",
      },
      500,
      CORS_HEADERS
    );
  }
}

// 날씨 API 프록시 핸들러
async function handleWeatherProxy(request, env) {
  // JWT 검증
  const authHeader = request.headers.get("Authorization");
  if (!authHeader || !authHeader.startsWith("Bearer ")) {
     return jsonResponse(
      {
        error: "No valid token provided",
        message: "Authorization header with Bearer token is required",
      },
      401,
      CORS_HEADERS
    );
  }

  const token = authHeader.substring(7);
  try {
    await verifyJWT(token, env.JWT_SECRET);
  } catch (error) {
    if (error.message === "Token expired") {
      return jsonResponse(
        { error: "Token expired", message: "Please refresh your token" },
        401,
        CORS_HEADERS
      );
    }
    return jsonResponse(
      { error: "Invalid token", message: "Token verification failed" },
      401,
      CORS_HEADERS
    );
  }

  const url = new URL(request.url);
  const lat = url.searchParams.get("lat");
  const lon = url.searchParams.get("lon");

  if (!lat || !lon) {
    return jsonResponse(
      { error: "Missing parameters", message: "lat and lon are required" },
      400,
      CORS_HEADERS
    );
  }

  const apiKey = env.OPEN_WEATHER_MAP_API_KEY;
  if (!apiKey) {
    console.error("OPEN_WEATHER_MAP_API_KEY not found in environment variables");
    return jsonResponse({ error: "API key not configured" }, 500, CORS_HEADERS);
  }

  const weatherUrl = `https://api.openweathermap.org/data/2.5/weather?lat=${lat}&lon=${lon}&appid=${apiKey}&units=metric&lang=kr`;

  try {
    const response = await fetch(weatherUrl);
    if (!response.ok) {
      const errorText = await response.text();
      console.error("OpenWeatherMap API error:", response.status, errorText);
      return jsonResponse(
        { error: "Weather API error", details: errorText },
        response.status,
        CORS_HEADERS
      );
    }

    const data = await response.json();
    return jsonResponse(data, 200, CORS_HEADERS);
  } catch (error) {
    console.error("Worker Error in handleWeatherProxy:", error);
    return jsonResponse(
      {
        error: "Internal Server Error",
        message: error.message,
      },
      500,
      CORS_HEADERS
    );
  }
}

// 동적 설정 핸들러
function handleConfig(env) {
  return jsonResponse(
    {
      adMob: {
        ios: {
          rewarded: env.ADMOB_IOS_REWARDED || "",
          banner: env.ADMOB_IOS_BANNER || "",
        },
        android: {
          rewarded: env.ADMOB_ANDROID_REWARDED || "",
          banner: env.ADMOB_ANDROID_BANNER || "",
        },
      },
    },
    200,
    CORS_HEADERS
  );
}

// 서버 시간 핸들러 (시스템 시간 조작 방지)
async function handleServerTime(request, env) {
  // JWT 검증
  const authHeader = request.headers.get("Authorization");
  if (!authHeader || !authHeader.startsWith("Bearer ")) {
    return jsonResponse(
      {
        error: "No valid token provided",
        message: "Authorization header with Bearer token is required",
      },
      401,
      CORS_HEADERS
    );
  }

  const token = authHeader.substring(7);
  
  try {
    // JWT 검증
    await verifyJWT(token, env.JWT_SECRET);
    
    // 현재 서버 시간 (UTC)
    const now = new Date();
    
    return jsonResponse(
      {
        serverTime: now.toISOString(),
        timestamp: now.getTime(),
        timezone: "UTC",
      },
      200,
      CORS_HEADERS
    );
  } catch (error) {
    if (error.message === "Token expired") {
      return jsonResponse(
        { error: "Token expired", message: "Please refresh your token" },
        401,
        CORS_HEADERS
      );
    }
    return jsonResponse(
      { error: "Invalid token", message: "Authentication failed" },
      401,
      CORS_HEADERS
    );
  }
}

// AI 식습관 인사이트 핸들러 (KV 캐싱 + Gemini API)
async function handleFoodInsight(request, env) {
  // JWT 검증
  const authHeader = request.headers.get("Authorization");
  if (!authHeader || !authHeader.startsWith("Bearer ")) {
    return jsonResponse(
      { error: "No valid token provided" },
      401,
      CORS_HEADERS
    );
  }

  const token = authHeader.substring(7);
  let user;
  try {
    user = await verifyJWT(token, env.JWT_SECRET);
  } catch (error) {
    if (error.message === "Token expired") {
      return jsonResponse(
        { error: "Token expired", message: "Please refresh your token" },
        401,
        CORS_HEADERS
      );
    }
    return jsonResponse(
      { error: "Invalid token" },
      401,
      CORS_HEADERS
    );
  }

  try {
    const body = await request.json();
    const { categoryFrequency, topFoods, totalReviews, weeklyCount, streak } = body;

    if (!categoryFrequency || !topFoods) {
      return jsonResponse(
        { error: "Missing required fields: categoryFrequency, topFoods" },
        400,
        CORS_HEADERS
      );
    }

    // KV 캐시 키: deviceHash + 날짜 기반 (하루 단위)
    const today = new Date().toISOString().split("T")[0];
    const cacheKey = `insight:${user.deviceHash}:${today}`;

    // 캐시 확인
    const cached = await env.FOOD_INSIGHT.get(cacheKey, { type: "json" });
    if (cached) {
      console.log(`Food insight cache hit: ${cacheKey}`);
      return jsonResponse(
        { ...cached, cached: true },
        200,
        CORS_HEADERS
      );
    }

    // Gemini API로 인사이트 생성
    const prompt = buildInsightPrompt({ categoryFrequency, topFoods, totalReviews, weeklyCount, streak });

    const id = env.GEMINI_PROXY.idFromName("US_PROXY");
    const stub = env.GEMINI_PROXY.get(id, { locationHint: "wnam" });

    const geminiRequest = new Request(request.url, {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({
        endpoint: "generateContent",
        requestBody: {
          contents: [{ parts: [{ text: prompt }] }],
          generationConfig: {
            temperature: 0.8,
            maxOutputTokens: 300,
          },
        },
      }),
    });

    const geminiResponse = await stub.fetch(geminiRequest);

    if (!geminiResponse.ok) {
      console.error("Gemini insight error:", geminiResponse.status);
      return jsonResponse(
        { error: "AI insight generation failed" },
        502,
        CORS_HEADERS
      );
    }

    const geminiData = await geminiResponse.json();
    const insightText = geminiData?.candidates?.[0]?.content?.parts?.[0]?.text || null;

    if (!insightText) {
      return jsonResponse(
        { error: "Empty AI response" },
        502,
        CORS_HEADERS
      );
    }

    const result = {
      insight: insightText.trim(),
      generatedAt: new Date().toISOString(),
    };

    // KV에 캐싱 (12시간 TTL)
    await env.FOOD_INSIGHT.put(cacheKey, JSON.stringify(result), {
      expirationTtl: 43200,
    });

    return jsonResponse(
      { ...result, cached: false },
      200,
      CORS_HEADERS
    );
  } catch (error) {
    console.error("Food insight error:", error);
    return jsonResponse(
      { error: "Internal server error", details: error.message },
      500,
      CORS_HEADERS
    );
  }
}

// 인사이트 생성용 프롬프트 빌더
function buildInsightPrompt({ categoryFrequency, topFoods, totalReviews, weeklyCount, streak }) {
  let context = `사용자의 식습관 데이터:\n`;
  context += `- 총 리뷰 수: ${totalReviews || 0}개\n`;
  context += `- 이번 주 리뷰: ${weeklyCount || 0}개\n`;

  if (categoryFrequency && Object.keys(categoryFrequency).length > 0) {
    context += `- 카테고리별 빈도: ${Object.entries(categoryFrequency).map(([k, v]) => `${k}(${v}회)`).join(", ")}\n`;
  }

  if (topFoods && topFoods.length > 0) {
    context += `- 자주 먹는 음식: ${topFoods.map(f => `${f.foodName}(${f.count}회)`).join(", ")}\n`;
  }

  if (streak) {
    context += `- 최근 연속: ${streak.category}를 ${streak.count}번 연속\n`;
  }

  return `${context}\n위 데이터를 분석해서 친근하고 재치있는 한국어 식습관 인사이트 메시지를 1개만 생성해주세요.\n규칙:\n- 2~3문장, 이모지 1~2개 포함\n- 건강/다양성/재미 관점에서 자연스러운 제안\n- 반말(~해요체) 사용\n- 음식 추천은 구체적으로 (예: "닭가슴살 샐러드" 말고 그냥 "샐러드")\n- 메시지만 출력, 다른 설명 없음`;
}

// JSON 응답 헬퍼
function jsonResponse(data, status = 200, headers = {}) {
  return new Response(JSON.stringify(data), {
    status,
    headers: {
      "Content-Type": "application/json",
      ...headers,
    },
  });
}

// Durable Object 클래스 정의
export class GeminiProxyV2 {
  constructor(state, env) {
    this.state = state;
    this.env = env;
  }

  async fetch(request) {
    try {
      const body = await request.json();
      const { endpoint, requestBody } = body;

      // 유효한 엔드포인트만 허용
      const allowedEndpoints = [
        "generateContent",
        "generateReviews",
        "validateImage",
        "buildPersonalizedRecommendationPrompt",
        "buildGenericRecommendationPrompt",
        "generateFoodInsight",
      ];

      if (!endpoint || !allowedEndpoints.includes(endpoint)) {
        return jsonResponse({ error: "Invalid endpoint" }, 400, CORS_HEADERS);
      }

      // Gemini API 키 가져오기
      const apiKey = this.env.GEMINI_API_KEY;
      if (!apiKey) {
        console.error("GEMINI_API_KEY not found in environment variables");
        return jsonResponse({ error: "API key not configured" }, 500, CORS_HEADERS);
      }

      // Gemini API 호출 (API 키는 절대 로깅하지 않음)
      const geminiUrl = `https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash-lite:${endpoint}?key=${apiKey}`;
      console.log(`Calling Gemini API endpoint: ${endpoint}`);

      const response = await fetch(geminiUrl, {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
        },
        body: JSON.stringify(requestBody),
      });

      if (!response.ok) {
        const errorText = await response.text();
        console.error("Gemini API error:", response.status, errorText);
        return jsonResponse(
          { error: "Gemini API error", details: errorText },
          response.status,
          CORS_HEADERS
        );
      }

      const data = await response.json();
      return jsonResponse(data, 200, CORS_HEADERS);
    } catch (error) {
      console.error("Durable Object error:", error);
      return jsonResponse(
        { error: "Internal server error in DO", details: error.message },
        500,
        CORS_HEADERS
      );
    }
  }
}
