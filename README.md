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

Schema versionado (`schemaVersion = 1`) com tabelas:

- `agenda_items`
- `agenda_groups`
- `attachments`

Campos de reminder/recorrência são persistidos como JSON em colunas text, facilitando compatibilidade futura de migrações.

## Execução

```bash
flutter pub get
flutter pub run build_runner build --delete-conflicting-outputs
flutter run
```

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
# smart_agenda
