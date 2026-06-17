-- ============================================================
-- Migration 002 — Tabela de estoque de equipamentos
-- ============================================================
-- A mesma tabela serve tanto para o estoque ativo quanto
-- para o BAD (Banco de Ativos Defeituosos), diferenciados
-- pela coluna `categoria`:
--   NULL ou 'estoque' → item disponível no estoque
--   'bad'             → item com defeito aguardando envio
-- ============================================================

create table if not exists estoque (
  id               bigserial primary key,

  -- Identificação do equipamento
  descricao        text,
  patrimonio       text,          -- SGPI
  numero_serie     text,
  modelo           text,
  mac              text,
  ean              text,          -- código de barras EAN

  -- Controle de quantidade (apenas para estoque normal)
  quantidade       integer default 1,

  -- Categoria: NULL/'estoque' = ativo | 'bad' = defeituoso
  categoria        text,

  -- Campos exclusivos do BAD
  chamado_ref      text,          -- número do chamado que originou a entrada no BAD
  data_entrada_bad date,          -- data de entrada no BAD
  data_envio       date,          -- data de envio para reparo/descarte (null = pendente)

  created_at       timestamptz default now()
);

-- Filtro por categoria (estoque vs bad) — uso frequente
create index if not exists idx_estoque_categoria
  on estoque (categoria);

-- Busca por número de série (vincular ao chamado)
create index if not exists idx_estoque_numero_serie
  on estoque (numero_serie);

-- Busca por patrimônio (SGPI)
create index if not exists idx_estoque_patrimonio
  on estoque (patrimonio);
