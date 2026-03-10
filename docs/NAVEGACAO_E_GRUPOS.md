# Navegacao Reorganizada e Feature Grupos

## Resumo da Solucao de Navegacao

**Escolha: Aba "Mais" como tela central de modulos**

O rodape mantem 5 itens focados no uso diario:
- **Home** - Dashboard
- **Agenda** - Calendario de eventos
- **Materias** - Grade horaria
- **Mais** - Acesso a todas as demais funcionalidades
- **Config** - Configuracoes

A aba **Mais** exibe um grid de modulos/cards. Cada card leva a uma funcionalidade especifica. Isso permite:
- Rodape enxuto e focado
- Crescimento futuro sem poluir a navegacao principal
- Organizacao por contexto
- Experiencia familiar em apps mobile

**Alternativas consideradas:**
- **Drawer**: Bom para muitos itens, mas menos descobertavel em mobile
- **Menu lateral**: Similar ao drawer
- **Aba Mais**: Escolhida por ser escalavel, visivel e manter o padrao de tabs

---

## Estrutura das Telas Criadas

### Feature: Grupos (Turmas/Salas com Alunos)

| Tela | Rota | Descricao |
|------|------|-----------|
| ClassGroupListPage | /class-groups | Listagem de grupos |
| ClassGroupDetailPage | /class-group-detail | Detalhe do grupo + lista de alunos |

### Navegacao

| Tela | Rota | Descricao |
|------|------|-----------|
| MorePage | (tab 3) | Grid de modulos |

### Modulos no "Mais"

- **Grupos** - Turmas, salas, alunos (nova feature)
- **Grupos da Agenda** - Categorias para eventos (existente)
- **Notificacoes** - Preferencias de push
- **Compartilhar** - Compartilhamento de agenda (se Supabase configurado)

---

## Fluxo de Navegacao do Usuario

```
Home (tab 0)
  |
Agenda (tab 1)
  |
Materias (tab 2)
  |
Mais (tab 3) --> Grid de modulos
  |              |
  |              +--> Grupos --> Lista de grupos
  |              |                  |
  |              |                  +--> Detalhe do grupo
  |              |                           |
  |              |                           +--> Adicionar/editar aluno
  |              |                           +--> Editar grupo
  |              |
  |              +--> Grupos da Agenda
  |              +--> Notificacoes
  |              +--> Compartilhar
  |
Config (tab 4)
```

---

## Modelos de Dados

### ClassGroup
- id, name (obrigatorio), description (opcional), createdAt, updatedAt

### Student
- id, groupId, name (obrigatorio)
- email, phone (opcionais)
- guardianName, guardianEmail, guardianPhone (opcionais)
- createdAt, updatedAt

---

## Persistencia

- **Drift** (SQLite local): tabelas `class_groups` e `students`
- Migration schema version 5
- Sem sync Supabase por ora (pode ser adicionado depois)
