-- ============================================================
-- Migration 006 — Seed da linha CONFIG_TECNICOS
-- ============================================================
-- Insere a linha especial que armazena os perfis dos técnicos.
-- O campo `solucao` contém um JSON array; o admin é incluído
-- automaticamente com acesso total (sem necessidade de entrada
-- aqui, pois é verificado pelo ADMIN_EMAIL no código).
--
-- Execute este seed apenas uma vez, após criar a tabela e
-- configurar a autenticação no Supabase.
-- ============================================================

insert into chamados (chamado, tecnico, solucao)
select 'CONFIG_TECNICOS', 'SISTEMA_ADMIN', '[]'
where not exists (
  select 1 from chamados where chamado = 'CONFIG_TECNICOS'
);
