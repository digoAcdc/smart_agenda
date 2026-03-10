import { jwtVerify } from "jose";

const encoder = new TextEncoder();

export class AuthError extends Error {
  constructor(message, statusCode = 401) {
    super(message);
    this.name = "AuthError";
    this.statusCode = statusCode;
  }
}

export async function verifySupabaseJwt(authHeader, jwtSecret, options = {}) {
  if (!authHeader || !authHeader.startsWith("Bearer ")) {
    throw new AuthError("Missing or invalid Authorization header", 401);
  }

  const token = authHeader.slice("Bearer ".length).trim();
  if (!token) {
    throw new AuthError("Missing bearer token", 401);
  }

  try {
    const verifyOptions = {
      algorithms: ["HS256"],
    };
    if (options.issuer) verifyOptions.issuer = options.issuer;
    if (options.audience) verifyOptions.audience = options.audience;

    const { payload } = await jwtVerify(
      token,
      encoder.encode(jwtSecret),
      verifyOptions
    );

    const userId = payload?.sub;
    if (!userId || typeof userId !== "string") {
      throw new AuthError("Invalid token payload", 401);
    }

    return { userId, payload };
  } catch (_) {
    throw new AuthError("Invalid or expired token", 401);
  }
}
