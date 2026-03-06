# Compartilhamento de Agenda - Fase 2 (Anexos em ZIP)

## Objetivo
Suportar compartilhamento opcional de anexos entre dispositivos junto com os dados da agenda, sem quebrar o fluxo MVP de JSON puro.

## Formato proposto
- Arquivo final: `smart_agenda_bundle_<timestamp>.zip`.
- Estrutura:
  - `manifest.json` (metadados + schema transfer v2).
  - `agenda.json` (mesmo payload da fase 1).
  - `attachments/` (arquivos binarios referenciados no `manifest.json`).

## Manifest (v2)
Campos obrigatorios:
- `schemaVersion`: inteiro (2 para ZIP com anexos).
- `exportedAt`: ISO8601.
- `appName`: string.
- `attachments`: lista com:
  - `attachmentId`
  - `itemId`
  - `relativePath` (ex: `attachments/abc123.jpg`)
  - `sha256`
  - `sizeBytes`
  - `mimeType`

## Regras de validacao
- Rejeitar arquivo sem `manifest.json` ou `agenda.json`.
- Rejeitar se `schemaVersion` for maior que o suportado no app.
- Validar hash SHA-256 de cada anexo antes de importar.
- Ignorar anexos faltantes e registrar no relatorio final.
- Limitar tamanho por arquivo e tamanho total do ZIP.

## Limites recomendados
- Maximo por arquivo: 15 MB.
- Maximo total do pacote: 80 MB.
- Maximo de anexos por importacao: 200.
- Timeout de descompactacao: 20 segundos (falha segura ao exceder).

## Tratamento de erros
- Arquivo corrompido: abortar importacao e exibir motivo.
- Anexo invalido (hash divergente): importar agenda sem esse anexo.
- Espaco insuficiente em disco: abortar com orientacao ao usuario.
- Tipo de arquivo bloqueado: descartar anexo e registrar aviso.

## UX sugerida
- Toggle no export: `Incluir anexos (beta)`.
- Tela de import com preview:
  - quantidade de eventos/grupos
  - quantidade e tamanho dos anexos
  - estimativa de tempo
- Relatorio final:
  - itens importados/atualizados/ignorados
  - anexos importados/ignorados/falhos

## Dependencias tecnicas
- `archive` para zip/unzip.
- `crypto` para SHA-256.
- Reuso de `IFileStorageService` para copiar anexos para pasta interna.

## Compatibilidade
- v1 (JSON sem anexos) continua suportado.
- v2 (ZIP) deve cair para comportamento de v1 quando nao houver pasta `attachments/`.
