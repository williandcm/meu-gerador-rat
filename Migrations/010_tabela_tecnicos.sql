-- ============================================================
-- Migration 010 — Tabela própria para perfis de técnicos
-- ============================================================
-- Substitui o hack CONFIG_TECNICOS (JSON blob na tabela
-- chamados) por uma tabela relacional normalizada.
-- Inclui campo expira_em para expiração automática de demos.
-- ============================================================

CREATE TABLE IF NOT EXISTS tecnicos (
  id          bigserial PRIMARY KEY,
  email       text NOT NULL UNIQUE,
  nome        text,
  cpf         text,
  ativo       boolean NOT NULL DEFAULT true,
  permissoes  jsonb NOT NULL DEFAULT '{}',
  is_demo     boolean NOT NULL DEFAULT false,
  expira_em   timestamptz,
  created_at  timestamptz DEFAULT now(),
  updated_at  timestamptz DEFAULT now()
);

DROP TRIGGER IF EXISTS tecnicos_updated_at ON tecnicos;
CREATE TRIGGER tecnicos_updated_at
  BEFORE UPDATE ON tecnicos
  FOR EACH ROW EXECUTE FUNCTION atualizar_updated_at();

ALTER TABLE tecnicos ENABLE ROW LEVEL SECURITY;

-- Admin tem controle total
CREATE POLICY "tecnicos_admin_all" ON tecnicos FOR ALL TO authenticated
  USING  (lower(auth.email()) = 'williandcm@hotmail.com')
  WITH CHECK (lower(auth.email()) = 'williandcm@hotmail.com');

-- Cada técnico lê apenas o próprio perfil
CREATE POLICY "tecnicos_self_select" ON tecnicos FOR SELECT TO authenticated
  USING (lower(auth.email()) = lower(email));

-- ── Migração de dados: CONFIG_TECNICOS → tecnicos ───────────
-- Lê o JSON blob armazenado em chamados.solucao onde
-- chamado = 'CONFIG_TECNICOS' e insere cada entrada na
-- nova tabela. Seguro de executar múltiplas vezes (ON CONFLICT).
DO $$
DECLARE
  v_solucao text;
  v_perfis  jsonb;
  v_perfil  jsonb;
BEGIN
  SELECT solucao INTO v_solucao
    FROM chamados
   WHERE chamado = 'CONFIG_TECNICOS'
   LIMIT 1;

  IF v_solucao IS NOT NULL THEN
    v_perfis := v_solucao::jsonb;
    FOR v_perfil IN SELECT * FROM jsonb_array_elements(v_perfis)
    LOOP
      INSERT INTO tecnicos (email, nome, cpf, ativo, is_demo, permissoes)
      VALUES (
        lower(v_perfil->>'email'),
        v_perfil->>'nome',
        v_perfil->>'cpf',
        COALESCE((v_perfil->>'ativo')::boolean, true),
        COALESCE((v_perfil->>'isDemo')::boolean, false),
        COALESCE(v_perfil->'permissoes', '{}')::jsonb
      )
      ON CONFLICT (email) DO UPDATE SET
        nome       = EXCLUDED.nome,
        cpf        = EXCLUDED.cpf,
        ativo      = EXCLUDED.ativo,
        is_demo    = EXCLUDED.is_demo,
        permissoes = EXCLUDED.permissoes;
    END LOOP;
  END IF;
END $$;
