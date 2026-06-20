-- ============================================================
-- Migration 009 — Melhorias na tabela chamados
-- ============================================================
-- 1. UNIQUE constraint no número INC (campo chamado)
-- 2. Colunas created_at / updated_at com trigger automático
-- 3. Tabela historico_chamados para auditoria de edições
-- ============================================================

-- ── Função reutilizável de updated_at (idempotente) ─────────
CREATE OR REPLACE FUNCTION atualizar_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- ── UNIQUE no INC ────────────────────────────────────────────
-- Ignora a linha CONFIG_TECNICOS que é um registro interno.
-- Se houver INCss duplicados no banco, este índice falhará —
-- limpe os duplicados antes de executar.
ALTER TABLE chamados ADD COLUMN IF NOT EXISTS created_at timestamptz DEFAULT now();
ALTER TABLE chamados ADD COLUMN IF NOT EXISTS updated_at timestamptz DEFAULT now();

DROP TRIGGER IF EXISTS chamados_updated_at ON chamados;
CREATE TRIGGER chamados_updated_at
  BEFORE UPDATE ON chamados
  FOR EACH ROW EXECUTE FUNCTION atualizar_updated_at();

-- UNIQUE exclui a linha interna CONFIG_TECNICOS
CREATE UNIQUE INDEX IF NOT EXISTS chamados_inc_unico
  ON chamados (chamado)
  WHERE chamado <> 'CONFIG_TECNICOS';

-- ── Tabela de auditoria de chamados ──────────────────────────
CREATE TABLE IF NOT EXISTS historico_chamados (
  id          bigserial PRIMARY KEY,
  chamado_id  bigint,
  chamado_inc text,
  acao        text NOT NULL,  -- 'CRIAÇÃO', 'EDIÇÃO', 'EXCLUSÃO'
  usuario     text,
  dados_antes jsonb,
  dados_depois jsonb,
  created_at  timestamptz DEFAULT now()
);

ALTER TABLE historico_chamados ENABLE ROW LEVEL SECURITY;

CREATE POLICY "hc_select" ON historico_chamados FOR SELECT TO authenticated USING (true);
CREATE POLICY "hc_insert" ON historico_chamados FOR INSERT TO authenticated WITH CHECK (true);
