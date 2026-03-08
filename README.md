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

Login, cadastro e recuperação de senha usam Supabase Auth. Sem as variáveis configuradas, o app usa um stub local e não inicializa o Supabase.

1. Crie um projeto em [supabase.com](https://supabase.com) e obtenha a URL e a chave anônima (anon key).
2. Execute o app passando as variáveis:

   ```bash
   flutter run --dart-define=SUPABASE_URL=https://seu-projeto.supabase.co --dart-define=SUPABASE_ANON_KEY=eyJ...
   ```

3. Para build de release, inclua as mesmas `--dart-define` no comando de build.

## Plano Premium (allow list temporaria)

O app alterna entre persistencia local (free) e Supabase (premium) conforme o plano do usuario. Premium = autenticado + email na allow list.

### Configuracao no Supabase

1. Execute as migracoes em `supabase/migrations/`:
   - `001_premium_allowlist.sql` - tabela de e-mails autorizados
   - `002_premium_data_tables.sql` - tabelas agenda_items, agenda_groups, attachments, class_schedule_slots
   - `003_storage_bucket.sql` - bucket para imagens

2. Adicione e-mails na allow list:
   ```sql
   INSERT INTO premium_allowlist (email, is_active) VALUES ('seu@email.com', true);
   ```

3. O usuario logado com e-mail na allow list passa a usar dados na nuvem e imagens no Storage.

### Substituir por in-app purchase

Criar `IPremiumEligibilityService` com `isEligible()`. O `PlanServiceImpl` passa a usar essa interface em vez da allow list. Implementar `InAppPurchaseEligibilityService` que verifica assinatura ativa.

## Testes

```bash
flutter test
```

Inclui testes unitários para:

- utilitários de data (day/week/month)
- validação de `ReminderConfig`
- duplicação de item com novo id

## Roadmap (Free vs Premium)

### Free (atual)
- Agenda local completa
- Grupos, busca e marcadores de calendário
- Lembretes locais
- Anexos locais (imagens)

### Premium (planejado)
- Engine completa de recorrência avançada
- Sync multi-device com resolução de conflitos
- Login e conta cloud
- Exportação avançada e backup cloud
- Remoção de ads

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
