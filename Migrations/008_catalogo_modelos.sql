-- ============================================================
-- Migration 008 — Catálogo de modelos de equipamentos
-- ============================================================
-- Resolve o problema de duplicatas semânticas no estoque:
-- "PINPAD INGENICO", "Pinpad Ingenico", "PIN PAD INGENICO"
-- sendo tratados como itens distintos.
--
-- O campo descricao em estoque passa a ser controlado por
-- esta tabela. Itens novos só podem usar descrições do catálogo.
-- Admin gerencia o catálogo; técnicos apenas consultam.
-- ============================================================

create table if not exists modelos_estoque (
  id          bigserial primary key,
  descricao   text not null,
  categoria   text,
  created_at  timestamptz default now(),
  constraint modelos_estoque_descricao_unica unique (descricao)
);

-- Índice para busca por categoria
create index if not exists idx_modelos_categoria
  on modelos_estoque (categoria);

-- ── RLS ──────────────────────────────────────────────────────

alter table modelos_estoque enable row level security;

-- Todos os autenticados podem consultar o catálogo
create policy "modelos_select"
  on modelos_estoque for select to authenticated
  using (true);

-- Somente admin pode incluir, alterar ou excluir
create policy "modelos_admin_write"
  on modelos_estoque for all to authenticated
  using  (lower(auth.email()) = 'williandcm@hotmail.com')
  with check (lower(auth.email()) = 'williandcm@hotmail.com');

-- ── FK no estoque ─────────────────────────────────────────────
-- Nullable para preservar itens já existentes
alter table estoque
  add column if not exists modelo_id bigint
    references modelos_estoque(id)
    on update cascade
    on delete set null;
