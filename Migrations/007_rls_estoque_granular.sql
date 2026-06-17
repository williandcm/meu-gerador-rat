-- ============================================================
-- Migration 007 — Estoque RLS granular + coluna criado_por
-- ============================================================
-- Problema anterior: a policy "estoque_authenticated_all"
-- permitia que qualquer técnico autenticado excluísse qualquer
-- item do estoque via API, sem passar pela interface.
--
-- Modelo de acesso corrigido:
--   SELECT → todos os autenticados
--   INSERT → todos os autenticados (criado_por deve ser o
--             próprio e-mail do usuário)
--   UPDATE → todos os autenticados (necessário para o fluxo
--             de "baixa" de equipamentos e registro de envio
--             no BAD feitos por técnicos)
--   DELETE → somente o administrador (ambos os botões de
--             exclusão na UI já são admin-only; agora o banco
--             reforça essa regra)
-- ============================================================

-- Adiciona coluna de rastreabilidade (nullable para itens antigos)
alter table estoque add column if not exists criado_por text;

-- Remove policies anteriores (permissiva e quaisquer tentativas parciais)
drop policy if exists "estoque_authenticated_all" on estoque;
drop policy if exists "estoque_select"            on estoque;
drop policy if exists "estoque_insert"            on estoque;
drop policy if exists "estoque_update"            on estoque;
drop policy if exists "estoque_delete"            on estoque;

-- ── SELECT: todos os autenticados ────────────────────────────
create policy "estoque_select"
  on estoque
  for select
  to authenticated
  using (auth.role() = 'authenticated');

-- ── INSERT: autenticados; criado_por deve ser o próprio email ─
create policy "estoque_insert"
  on estoque
  for insert
  to authenticated
  with check (
    auth.role() = 'authenticated'
    and (
      criado_por is null
      or lower(criado_por) = lower(auth.email())
      or lower(auth.email()) = 'williandcm@hotmail.com'
    )
  );

-- ── UPDATE: todos os autenticados (fluxo de baixa e BAD) ─────
create policy "estoque_update"
  on estoque
  for update
  to authenticated
  using  (auth.role() = 'authenticated')
  with check (auth.role() = 'authenticated');

-- ── DELETE: somente o administrador ──────────────────────────
create policy "estoque_delete"
  on estoque
  for delete
  to authenticated
  using (lower(auth.email()) = 'williandcm@hotmail.com');
