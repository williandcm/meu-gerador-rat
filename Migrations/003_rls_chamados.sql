-- ============================================================
-- Migration 003 — Row Level Security para a tabela chamados
-- ============================================================
-- Modelo de acesso:
--   Admin (williandcm@hotmail.com): acesso total a todos os registros.
--   Técnicos autenticados:
--     SELECT  → chamados onde tecnico = seu e-mail
--               + linha CONFIG_TECNICOS (perfis e permissões)
--     INSERT  → somente com tecnico = seu e-mail
--     UPDATE  → somente seus próprios chamados
--     DELETE  → somente seus próprios chamados
-- ============================================================

alter table chamados enable row level security;

-- ── ADMIN: acesso irrestrito ──────────────────────────────────────────────────

create policy "chamados_admin_all"
  on chamados
  for all
  to authenticated
  using  (lower(auth.email()) = 'williandcm@hotmail.com')
  with check (lower(auth.email()) = 'williandcm@hotmail.com');

-- ── TÉCNICO: leitura dos próprios chamados + CONFIG_TECNICOS ─────────────────

create policy "chamados_tech_select"
  on chamados
  for select
  to authenticated
  using (
    lower(tecnico) = lower(auth.email())
    or chamado = 'CONFIG_TECNICOS'
  );

-- ── TÉCNICO: inserir apenas com seu próprio e-mail como técnico ──────────────

create policy "chamados_tech_insert"
  on chamados
  for insert
  to authenticated
  with check (
    lower(tecnico) = lower(auth.email())
  );

-- ── TÉCNICO: atualizar apenas seus próprios chamados ─────────────────────────

create policy "chamados_tech_update"
  on chamados
  for update
  to authenticated
  using (
    lower(tecnico) = lower(auth.email())
  )
  with check (
    lower(tecnico) = lower(auth.email())
  );

-- ── TÉCNICO: excluir apenas seus próprios chamados ───────────────────────────

create policy "chamados_tech_delete"
  on chamados
  for delete
  to authenticated
  using (
    lower(tecnico) = lower(auth.email())
  );
