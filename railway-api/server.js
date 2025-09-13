const express = require("express");
const cors = require("cors");
const fetch = require("node-fetch");
const jwt = require("jsonwebtoken");
const crypto = require("crypto");

const app = express();
const PORT = process.env.PORT || 3000;

// CORS 설정
// CORS 설정 - 보안 강화
app.use(
  cors({
    origin: process.env.ALLOWED_ORIGINS
      ? process.env.ALLOWED_ORIGINS.split(",")
      : "*",
    credentials: true,
    methods: ["GET", "POST", "OPTIONS"],
    allowedHeaders: ["Content-Type", "Authorization", "x-app-token"],
  })
);

app.use(express.json({ limit: "10mb" })); // 요청 크기 제한

// Rate limiting (간단한 메모리 기반)
const rateLimitMap = new Map();
const RATE_LIMIT_WINDOW = 15 * 60 * 1000; // 15분
const RATE_LIMIT_MAX_REQUESTS = 100; // 15분당 최대 100회

// Rate limiting 미들웨어
const rateLimit = (req, res, next) => {
  const clientId = req.ip || req.connection.remoteAddress;
  const now = Date.now();

  if (!rateLimitMap.has(clientId)) {
    rateLimitMap.set(clientId, {
      count: 1,
      resetTime: now + RATE_LIMIT_WINDOW,
    });
    return next();
  }

  const clientData = rateLimitMap.get(clientId);

  if (now > clientData.resetTime) {
    clientData.count = 1;
    clientData.resetTime = now + RATE_LIMIT_WINDOW;
    return next();
  }

  if (clientData.count >= RATE_LIMIT_MAX_REQUESTS) {
    return res.status(429).json({
      error: "Too many requests",
      message: "Rate limit exceeded. Please try again later.",
    });
  }

  clientData.count++;
  next();
};

app.use(rateLimit);

// JWT 설정
const JWT_SECRET =
  process.env.JWT_SECRET || crypto.randomBytes(64).toString("hex");
const JWT_EXPIRES_IN = "1h"; // 1시간
const REFRESH_TOKEN_EXPIRES_IN = "7d"; // 7일

// 토큰 발급 엔드포인트 (최고 수준 보안)
app.post("/api/auth/token", async (req, res) => {
  try {
    const { deviceId, appVersion, deviceInfo } = req.body;

    // 필수 필드 검증
    if (!deviceId || !appVersion) {
      return res.status(400).json({
        error: "Missing required fields",
        message: "deviceId and appVersion are required",
      });
    }

    // 앱 버전 검증 (선택적)
    const minAppVersion = process.env.MIN_APP_VERSION || "1.0.0";
    if (appVersion < minAppVersion) {
      return res.status(400).json({
        error: "App version too old",
        message: `Minimum app version required: ${minAppVersion}`,
      });
    }

    // 디바이스 정보 해시 생성 (추가 보안)
    const deviceHash = crypto
      .createHash("sha256")
      .update(`${deviceId}-${appVersion}-${deviceInfo || ""}`)
      .digest("hex");

    // JWT 페이로드 생성
    const payload = {
      deviceId: deviceId,
      appVersion: appVersion,
      deviceHash: deviceHash,
      iat: Math.floor(Date.now() / 1000),
      jti: crypto.randomUUID(), // JWT ID (중복 방지)
    };

    // JWT 토큰 생성
    const accessToken = jwt.sign(payload, JWT_SECRET, {
      expiresIn: JWT_EXPIRES_IN,
      issuer: "reviewai-api",
      audience: "reviewai-app",
    });

    // 리프레시 토큰 생성
    const refreshToken = jwt.sign(
      { deviceId, deviceHash, type: "refresh" },
      JWT_SECRET,
      { expiresIn: REFRESH_TOKEN_EXPIRES_IN }
    );

    res.json({
      accessToken: accessToken,
      refreshToken: refreshToken,
      expiresIn: 3600, // 1시간
      tokenType: "Bearer",
    });
  } catch (error) {
    console.error("Token generation error:", error);
    res.status(500).json({
      error: "Internal server error",
      message: "Failed to generate authentication token",
    });
  }
});

// 토큰 갱신 엔드포인트
app.post("/api/auth/refresh", async (req, res) => {
  try {
    const { refreshToken } = req.body;

    if (!refreshToken) {
      return res.status(400).json({ error: "Refresh token is required" });
    }

    const decoded = jwt.verify(refreshToken, JWT_SECRET);

    if (decoded.type !== "refresh") {
      return res.status(400).json({ error: "Invalid token type" });
    }

    // 새 액세스 토큰 생성
    const payload = {
      deviceId: decoded.deviceId,
      deviceHash: decoded.deviceHash,
      iat: Math.floor(Date.now() / 1000),
      jti: crypto.randomUUID(),
    };

    const newAccessToken = jwt.sign(payload, JWT_SECRET, {
      expiresIn: JWT_EXPIRES_IN,
      issuer: "reviewai-api",
      audience: "reviewai-app",
    });

    res.json({
      accessToken: newAccessToken,
      expiresIn: 3600,
      tokenType: "Bearer",
    });
  } catch (error) {
    console.error("Token refresh error:", error);
    res.status(401).json({
      error: "Invalid refresh token",
      message: "Please re-authenticate",
    });
  }
});

// JWT 토큰 검증 미들웨어
const verifyJWT = (req, res, next) => {
  try {
    const authHeader = req.headers["authorization"];

    if (!authHeader || !authHeader.startsWith("Bearer ")) {
      return res.status(401).json({
        error: "No valid token provided",
        message: "Authorization header with Bearer token is required",
      });
    }

    const token = authHeader.substring(7);
    const decoded = jwt.verify(token, JWT_SECRET, {
      issuer: "reviewai-api",
      audience: "reviewai-app",
    });

    // 토큰이 유효하면 요청 객체에 추가
    req.user = decoded;
    next();
  } catch (error) {
    if (error.name === "TokenExpiredError") {
      return res.status(401).json({
        error: "Token expired",
        message: "Please refresh your token",
      });
    } else if (error.name === "JsonWebTokenError") {
      return res.status(401).json({
        error: "Invalid token",
        message: "Token verification failed",
      });
    }

    console.error("JWT verification error:", error);
    res.status(401).json({
      error: "Authentication failed",
      message: "Token verification error",
    });
  }
};

// Gemini API 프록시 엔드포인트 (JWT 인증 사용)
app.post("/api/gemini-proxy", verifyJWT, async (req, res) => {
  try {
    // JWT 토큰에서 사용자 정보 추출
    const { deviceId, deviceHash, appVersion } = req.user;

    // 추가 보안 검증
    if (!deviceId || !deviceHash) {
      return res.status(401).json({
        error: "Invalid token payload",
        message: "Token missing required information",
      });
    }

    const { endpoint, requestBody } = req.body;

    // 유효한 엔드포인트만 허용
    const allowedEndpoints = [
      "generateContent",
      "generateReviews",
      "validateImage",
      "buildPersonalizedRecommendationPrompt",
      "buildGenericRecommendationPrompt",
    ];

    if (!endpoint || !allowedEndpoints.includes(endpoint)) {
      return res.status(400).json({ error: "Invalid endpoint" });
    }

    // Gemini API 키 가져오기
    const apiKey = process.env.GEMINI_API_KEY;
    if (!apiKey) {
      console.error("GEMINI_API_KEY not found in environment variables");
      return res.status(500).json({ error: "API key not configured" });
    }

    // Gemini API 호출
    const geminiUrl = `https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash-lite:${endpoint}?key=${apiKey}`;

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
      return res.status(response.status).json({
        error: "Gemini API error",
        details: errorText,
      });
    }

    const data = await response.json();
    return res.status(200).json(data);
  } catch (error) {
    console.error("Proxy error:", error);
    return res.status(500).json({
      error: "Internal server error",
      details: error.message,
    });
  }
});

// 헬스 체크 엔드포인트
app.get("/health", (req, res) => {
  res.json({ status: "OK", message: "ReviewAI API Proxy Server is running" });
});

app.listen(PORT, () => {
  console.log(`Server is running on port ${PORT}`);
});
