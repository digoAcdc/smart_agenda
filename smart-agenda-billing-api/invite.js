// Pagina do convite por link (rbarbosa.tech/convite/<codigo>) e o arquivo de
// verificacao do Android App Links. Com o app instalado e o dominio
// verificado, o Android abre o app direto e esta pagina nem aparece.

const PACKAGE = "com.digo.smartagenda";

// Digitais SHA-256 (publicas) dos certificados do app: chave de upload e chave
// de assinatura do Google Play (Play Console > Integridade do app).
const APP_CERT_SHA256 = [
  // Assinatura do Google Play (apps instalados pela loja).
  "6B:0B:ED:78:D8:66:79:D8:CE:D8:DF:8C:B7:2A:E3:80:87:1B:70:8B:30:32:0A:86:18:79:91:28:39:99:7F:DF",
  // Chave de upload (builds instalados direto, ex.: testes).
  "4B:75:58:24:8C:D3:5C:AD:2C:D4:42:A6:73:2E:E7:C0:F0:09:33:CC:1C:95:22:59:1C:B1:91:BA:DC:F8:0C:0F",
];
const TOKEN_RE = /^[a-z2-9]{8,64}$/;

const ROLE_LABEL = { editor: "editor", viewer: "visualizador", admin: "administrador" };

function escapeHtml(value) {
  return String(value ?? "").replace(/[&<>"']/g, (c) => ({
    "&": "&amp;", "<": "&lt;", ">": "&gt;", '"': "&quot;", "'": "&#39;",
  })[c]);
}

export function isValidInviteToken(token) {
  return typeof token === "string" && TOKEN_RE.test(token);
}

export async function fetchInvite(supabase, token) {
  const { data, error } = await supabase.rpc("get_family_invite_by_token", { p_token: token });
  if (error) throw new Error(error.message);
  return Array.isArray(data) && data.length ? data[0] : null;
}

/** App Links: fingerprints SHA-256 (chave de assinatura do Play e de upload). */
export function assetLinks(extra = "") {
  const list = [
    ...new Set([
      ...APP_CERT_SHA256,
      ...extra.split(",").map((f) => f.trim().toUpperCase()).filter(Boolean),
    ]),
  ];
  return [{
    relation: ["delegate_permission/common.handle_all_urls"],
    target: { namespace: "android_app", package_name: PACKAGE, sha256_cert_fingerprints: list },
  }];
}

export function renderInvitePage(token, invite) {
  const playUrl =
    `https://play.google.com/store/apps/details?id=${PACKAGE}` +
    `&referrer=${encodeURIComponent(`convite=${token}`)}`;
  const appUrl = `smartagenda://convite/${token}`;
  const valid = invite?.is_valid === true;
  const title = valid
    ? `${escapeHtml(invite.invited_by_name || "Alguém")} convidou você para a Família ${escapeHtml(invite.family_name)}`
    : "Este convite não está mais valendo";
  const text = valid
    ? `Você vai participar como <strong>${escapeHtml(ROLE_LABEL[invite.role] || invite.role)}</strong> e ver a agenda da família: compromissos, provas e a rotina das crianças.`
    : "O link já foi usado, venceu (vale por 7 dias) ou a Família não está mais ativa. Peça um convite novo para quem te chamou.";
  return `<!doctype html>
<html lang="pt-BR">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<meta name="robots" content="noindex">
<title>Convite — Smart Agenda</title>
<style>
  body { margin: 0; font-family: system-ui, -apple-system, Segoe UI, Roboto, Arial, sans-serif; background: #f4f6ef; color: #1f2a1a; }
  main { max-width: 520px; margin: 0 auto; padding: 40px 20px; }
  .card { background: #fff; border-radius: 20px; padding: 28px 24px; }
  h1 { font-size: 22px; line-height: 1.3; margin: 0 0 12px; }
  p { line-height: 1.5; color: #4a5544; }
  .btn { display: block; text-align: center; text-decoration: none; font-weight: 700; border-radius: 14px; padding: 15px; margin-top: 14px; }
  .primary { background: #8bc34a; color: #fff; }
  .secondary { border: 1.5px solid #8bc34a; color: #4f7a1f; }
  .muted { font-size: 14px; }
  .brand { font-weight: 800; color: #6a9f2f; margin-bottom: 18px; }
</style>
</head>
<body>
<main>
  <div class="card">
    <div class="brand">📅 Smart Agenda</div>
    <h1>${title}</h1>
    <p>${text}</p>
    ${valid ? `
    <a class="btn primary" href="${appUrl}">Abrir no Smart Agenda</a>
    <a class="btn secondary" href="${playUrl}">Instalar pelo Google Play</a>
    <p class="muted">Ainda não tem o app? Instale, abra e entre com sua conta (ou crie uma grátis): o convite aparece na tela inicial.</p>` : `
    <a class="btn secondary" href="${playUrl}">Conhecer o Smart Agenda</a>`}
  </div>
</main>
</body>
</html>`;
}
