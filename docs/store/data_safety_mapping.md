# Data Safety Mapping (Google Play)

## Resumo recomendado para formulario

- **Coleta de dados**: Nao.
- **Compartilhamento de dados**: Nao.
- **Dados processados localmente**: Sim (agenda, grupos, grade e anexos locais).
- **Criptografia em transito**: Nao aplicavel para dados locais nesta versao.
- **Solicitacao de exclusao**: Nao aplicavel para conta remota (sem backend/login nesta versao).

## Justificativas por funcionalidade

- **Notificacoes locais**: usa dados de evento apenas no proprio dispositivo para disparar lembrete.
- **Anexos de imagem**: usuario escolhe imagem; app guarda referencia local para exibicao.
- **Busca e filtros**: operacao local, sem envio para servidor.

## Revisao antes de enviar

1. Conferir se nenhum SDK de analytics/ads real foi integrado.
2. Validar permissoes no `AndroidManifest.xml`.
3. Sincronizar texto com a `privacy_policy.md`.
