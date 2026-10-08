# Smart Agenda (MVP+)

Aplicativo de agenda construído com Flutter + GetX + Drift, em arquitetura em camadas e preparado para evolução de funcionalidades premium/cloud.

## Arquitetura

- `presentation/`: páginas, widgets e controllers GetX.
- `domain/`: entidades, contratos de repositório/serviços e casos de uso.
- `data/`: schema Drift, data sources locais/remotos e implementações concretas.
- `core/`: utilitários, constantes, rotas, DI e `Result`.

Fluxo de dependência:

`UI -> Controller -> UseCase -> Repository (abstrato) -> RepositoryImpl -> DataSource`

## Funcionalidades MVP+

- CRUD de eventos (`AgendaItem`) com soft delete.
- CRUD de grupos (`AgendaGroup`).
- Visões: Hoje, Semana, Mês (com marcadores no calendário), Buscar e Config.
- Busca com filtros por período, grupo e status.
- Status do evento (`pending`, `done`, `canceled`).
- Anexos de imagem por path (sem bytes no banco).
- Lembretes locais com `flutter_local_notifications`.
- Botão de duplicar evento.
- Ads placeholder e contratos stubs para premium/cloud:
  - `IAdsService`
  - `IAuthService`
  - `ISyncService`
  - `IAgendaRemoteDataSource`

## Banco local (Drift)

Schema versionado (`schemaVersion = 2`) com tabelas:

- `agenda_items`
- `agenda_groups`
- `attachments`
- `class_schedule_slots`

Campos de reminder/recorrência são persistidos como JSON em colunas text, facilitando compatibilidade futura de migrações.

## Execução

```bash
flutter pub get
flutter pub run build_runner build --delete-conflicting-outputs
flutter run
```

## Autenticação (Supabase)

Login, cadastro e recuperação de senha usam Supabase Auth. O app permite uso sem conta (modo local), mas para sincronização online é necessário autenticar.

1. Crie um projeto em [supabase.com](https://supabase.com) e obtenha a URL e a chave anônima (anon key).
2. Execute o app passando as variáveis:

   ```bash
   flutter run --dart-define=SUPABASE_URL=https://seu-projeto.supabase.co --dart-define=SUPABASE_ANON_KEY=eyJ...
   ```

3. Para build de release, inclua as mesmas `--dart-define` no comando de build.

## Planos e Família

O produto é "uma agenda para organizar a rotina da família".

- **Free**: uso individual. Agenda, tarefas e lembretes ficam **só no aparelho** (com ou sem conta). Tem anúncios. A conta serve para aceitar convites de Família e assinar o Pro.
- **Pro**: cria uma **Família**, convida pessoas, cadastra vários filhos, sincroniza a agenda pessoal entre aparelhos, envia imagens e não vê anúncios.
- **Membros convidados não precisam assinar.** A assinatura é do dono da Família; os membros (Free) continuam vendo anúncios.

### Regras da Família
- Até 5 pessoas por Família, **dono incluso** (`families.max_members`). Filhos não contam no limite.
- V1: cada pessoa participa de no máximo 1 Família (índice `family_members_one_family_v1`).
- Papéis: **administrador** (gerencia pessoas, filhos e convites), **editor** (cria, edita e conclui eventos e tarefas) e **visualizador** (só leitura). O dono é sempre administrador.
- Cada item da Família tem *para quem* (família toda, um filho ou um membro), *responsável* (ninguém, todos ou um membro) e *criado por* (preenchido pelo servidor).
- Convite por e-mail: aparece para a pessoa ao entrar no app com aquele e-mail; vale 7 dias.
- **Pro do dono expirou**: a Família fica somente leitura para todos. Nada é apagado; volta a editar ao renovar.

As regras ficam no banco (RLS + RPCs em `supabase/migrations/016`–`019`), não só no app.

### Sincronização
- A UI lê sempre do banco local (Drift).
- Agenda da Família: a nuvem é a fonte da verdade; o aparelho guarda um cache e recebe alterações dos outros membros via Supabase Realtime.
- Agenda pessoal: só local no Free; no Pro, envia e baixa alterações incrementais (`updated_at` do servidor).

### Supabase (self-hosted no Easypanel)
- Rode as migrations como `supabase_admin` (dono das tabelas) e depois `NOTIFY pgrst, 'reload schema';`.
- `premium_allowlist` continua como override de Pro para desenvolvimento/testes:
  ```sql
  INSERT INTO premium_allowlist (email, is_active) VALUES ('seu@email.com', true);
  ```

## Testes

```bash
flutter test
```

Inclui testes unitários para:

- utilitários de data (day/week/month)
- validação de `ReminderConfig`
- duplicação de item com novo id

## Roadmap

Preparado no modelo, ainda não implementado: histórico de alterações (`updated_by`/`deleted_at` já existem), comentários e anexos por evento, notificações para a Família, calendário escolar por filho, recorrência, integração com calendários, filho com conta própria (`family_children.linked_user_id`), mais de uma Família por pessoa (V2) e planos com mais membros (`max_members`).

## Pronto para Play Store (Android)

- Configuração de release/signing em `android/app/build.gradle.kts`.
- Template de keystore em `android/key.properties.template`.
- Checklist de QA/publicação em `docs/store/qa_release_checklist.md`.
- Materiais de privacidade e Data Safety em `docs/store/`.

### Build assinado para release

1. **Criar o keystore** (apenas na primeira vez):

   ```bash
   keytool -genkey -v -keystore upload-keystore.jks -keyalg RSA -keysize 2048 -validity 10000 -alias upload
   ```

   Defina uma senha e preencha os dados do certificado. Guarde o arquivo `.jks` e a senha em local seguro.

2. **Configurar `key.properties`**:

   ```bash
   cp android/key.properties.template android/key.properties
   ```

   Edite `android/key.properties` com suas credenciais reais (senhas e caminho absoluto do `.jks`).

3. **Gerar o App Bundle**:

   ```bash
   bash scripts/build_release.sh
   ```

   O script executa `pub get`, `analyze`, `test` e `flutter build appbundle --release`. O AAB é gerado em:

   ```
   build/app/outputs/bundle/release/app-release.aab
   ```

4. **Upload no Play Console**: Testar → Teste interno → Criar nova versão → enviar o arquivo `.aab`.

> Os arquivos `key.properties` e `*.jks` estão no `.gitignore` e não devem ser commitados.
