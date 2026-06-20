-- ============================================================
-- Migration 011 — Tabela de configurações do sistema
-- ============================================================
-- Remove dados sensíveis do código-fonte (ADMIN_EMAIL, CPF,
-- URL do template PDF, chave de criptografia demo) e os
-- armazena no banco com controle de acesso adequado.
--
-- system_config: leitura pública (necessário para login),
--                escrita restrita ao admin.
-- tecnicos:      admin inserido com nome e CPF reais.
-- ============================================================

CREATE TABLE IF NOT EXISTS system_config (
  chave      text PRIMARY KEY,
  valor      text NOT NULL,
  created_at timestamptz DEFAULT now()
);

ALTER TABLE system_config ENABLE ROW LEVEL SECURITY;

-- Leitura pública (necessária antes do login para carregar admin_email)
CREATE POLICY "config_select_all" ON system_config
  FOR SELECT USING (true);

-- Somente admin pode criar/alterar/excluir entradas
CREATE POLICY "config_admin_write" ON system_config
  FOR ALL TO authenticated
  USING  (lower(auth.email()) = 'williandcm@hotmail.com')
  WITH CHECK (lower(auth.email()) = 'williandcm@hotmail.com');

-- ── Valores iniciais ─────────────────────────────────────────
INSERT INTO system_config (chave, valor) VALUES
  ('admin_email',
   'williandcm@hotmail.com'),
  ('url_modelo_pdf',
   'https://amqpouzfsykkahwgatmy.supabase.co/storage/v1/object/public/rat-files/RAT%20EM%20BRANCO.pdf'),
  ('demo_secret_key',
   'RATProDemo2024SecretKey!@#$%^&*()')
ON CONFLICT (chave) DO NOTHING;

-- ── Admin na tabela tecnicos (nome e CPF reais) ───────────────
-- Garante que o admin tenha perfil completo na tabela própria,
-- eliminando a necessidade do CPF_FIXO hardcoded no JS.
INSERT INTO tecnicos (email, nome, cpf, ativo, permissoes)
VALUES (
  'williandcm@hotmail.com',
  'WILLIAN DO CARMO MORAIS',
  '327.190.648-31',
  true,
  '{}'
)
ON CONFLICT (email) DO UPDATE SET
  nome = EXCLUDED.nome,
  cpf  = EXCLUDED.cpf;
