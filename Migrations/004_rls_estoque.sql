-- ============================================================
-- Migration 004 — Row Level Security para a tabela estoque
-- ============================================================
-- Modelo de acesso:
--   SELECT → todos os usuários autenticados (técnicos precisam
--            ver o estoque e o BAD).
--
--   INSERT → todos os autenticados (técnicos inserem itens no
--            BAD ao registrar uma troca via modal "Vincular").
--
--   UPDATE → todos os autenticados (técnicos registram "Envio"
--            de um item do BAD, atualizando data_envio).
--
--   DELETE → todos os autenticados (técnicos podem "Baixar"
--            equipamento do estoque ao vincular um chamado de
--            troca; admin pode excluir qualquer item pelo painel).
--
-- Nota: a restrição visual (quem vê qual botão) é aplicada no
-- front-end pelo campo `isAdmin`. O RLS garante apenas que
-- usuários não autenticados não acessem a tabela.
-- ============================================================

alter table estoque enable row level security;

create policy "estoque_authenticated_all"
  on estoque
  for all
  to authenticated
  using  (auth.role() = 'authenticated')
  with check (auth.role() = 'authenticated');
