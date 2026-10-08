import { readFile } from "node:fs/promises";
import nodemailer from "nodemailer";

// Envio do e-mail de recuperacao de senha em portugues, so com o codigo.
// O Supabase self-hosted (compose do Easypanel) nao permite trocar o template
// do Auth sem editar o compose, entao a API gera o codigo pelo admin do
// Supabase (que nao envia e-mail) e envia pelo mesmo SMTP.

const EMAIL_PATTERN = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
const PER_EMAIL_COOLDOWN_MS = 60_000;

const lastSentAt = new Map();

export class RecoveryConfigError extends Error {
  constructor(message) {
    super(message);
    this.name = "RecoveryConfigError";
  }
}

export function isValidEmail(value) {
  return typeof value === "string" && value.length <= 254 && EMAIL_PATTERN.test(value);
}

/** Mesmos nomes de variaveis do .env do Supabase. Retorna null se faltar algo. */
export function createMailerFromEnv(env) {
  const { SMTP_HOST, SMTP_PORT, SMTP_USER, SMTP_PASS, SMTP_ADMIN_EMAIL } = env;
  if (!SMTP_HOST || !SMTP_PORT || !SMTP_USER || !SMTP_PASS || !SMTP_ADMIN_EMAIL) {
    return null;
  }
  const port = Number(SMTP_PORT);
  const transport = nodemailer.createTransport({
    host: SMTP_HOST,
    port,
    secure: port === 465,
    auth: { user: SMTP_USER, pass: SMTP_PASS },
  });
  const senderName = env.SMTP_SENDER_NAME || "Smart Agenda";
  return {
    from: `"${senderName}" <${SMTP_ADMIN_EMAIL}>`,
    send: (message) => transport.sendMail(message),
  };
}

let templateCache;
async function loadTemplate() {
  templateCache ??= await readFile(new URL("./emails/recovery.html", import.meta.url), "utf8");
  return templateCache;
}

/**
 * Gera o codigo e envia o e-mail. Nunca revela se o e-mail tem conta:
 * retorna "sent" ou "skipped" (sem conta / aguardando intervalo).
 */
export async function sendRecoveryCode({ supabase, mailer, email, log }) {
  const normalized = email.trim().toLowerCase();

  const last = lastSentAt.get(normalized);
  if (last && Date.now() - last < PER_EMAIL_COOLDOWN_MS) {
    return "skipped";
  }

  const { data, error } = await supabase.auth.admin.generateLink({
    type: "recovery",
    email: normalized,
  });
  if (error && (error.status === 401 || error.status === 403)) {
    // Chave de servico invalida: e problema de configuracao, nao do usuario.
    throw new RecoveryConfigError(error.message);
  }
  if (error || !data?.properties?.email_otp) {
    // Sem conta com este e-mail (ou falha do Auth): responde igual para nao vazar.
    log.info({ reason: error?.message ?? "no_otp" }, "[recovery_skipped]");
    return "skipped";
  }

  const html = (await loadTemplate()).replaceAll("{{ .Token }}", data.properties.email_otp);
  await mailer.send({
    from: mailer.from,
    to: normalized,
    subject: "Seu código para redefinir a senha - Smart Agenda",
    text:
      `Seu código para redefinir a senha do Smart Agenda: ${data.properties.email_otp}\n\n` +
      "Abra o app Smart Agenda no celular e digite este código na tela Esqueci minha senha.\n" +
      "O código vale por 1 hora. Se não foi você, ignore este e-mail.",
    html,
  });
  if (lastSentAt.size > 5_000) lastSentAt.clear();
  lastSentAt.set(normalized, Date.now());
  log.info("[recovery_sent]");
  return "sent";
}
