// Exclusao de conta (LGPD e politica do Google Play). Apagar o login exige a
// chave de servico, por isso fica na API e nao no app.

export class AccountDeletionError extends Error {
  constructor(message, statusCode = 400, code = undefined) {
    super(message);
    this.name = "AccountDeletionError";
    this.statusCode = statusCode;
    this.code = code;
  }
}

async function removeFolder(supabase, prefix) {
  const bucket = supabase.storage.from("attachments");
  const { data, error } = await bucket.list(prefix, { limit: 1000 });
  if (error || !data?.length) return 0;
  let removed = 0;
  const files = [];
  for (const entry of data) {
    const path = `${prefix}/${entry.name}`;
    if (entry.id === null) {
      removed += await removeFolder(supabase, path);
    } else {
      files.push(path);
    }
  }
  if (files.length) {
    await bucket.remove(files);
    removed += files.length;
  }
  return removed;
}

/**
 * Exclui a conta e tudo ligado a ela (em cascata no banco): perfil, agenda e
 * grades pessoais, notas, turmas, participacao na Familia, assinaturas e
 * tokens. Eventos que a pessoa criou na Familia continuam com a Familia,
 * sem autoria. O dono precisa excluir a Familia antes.
 */
export async function deleteAccount({ supabase, userId, log }) {
  const { data: owned, error: ownedError } = await supabase
    .from("families")
    .select("name")
    .eq("owner_id", userId)
    .maybeSingle();
  if (ownedError) throw new AccountDeletionError("Could not check family", 500);
  if (owned) {
    throw new AccountDeletionError(
      `Voce e dono da ${owned.name}. Exclua a Familia antes de excluir a conta.`,
      409,
      "family_owner"
    );
  }

  const files =
    (await removeFolder(supabase, `user/${userId}`)) +
    (await removeFolder(supabase, userId)); // pasta do formato antigo

  const { error } = await supabase.auth.admin.deleteUser(userId);
  if (error) throw new AccountDeletionError("Could not delete account", 500);
  log.info({ files }, "[account_deleted]");
}
