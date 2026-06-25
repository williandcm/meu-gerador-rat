-- ============================================================
-- Migration 013 — Tabela de agências Santander (UNIORG → endereço)
-- Fonte: agenciadobanco.com.br · 413 agências SP · 2026-06-25
-- Execute no SQL Editor do Supabase
-- ============================================================

DROP TABLE IF EXISTS agencias_santander;

CREATE TABLE agencias_santander (
    uniorg       TEXT PRIMARY KEY,
    endereco     TEXT,
    numero       TEXT,
    complemento  TEXT,
    bairro       TEXT,
    cidade       TEXT,
    uf           TEXT,
    cep          TEXT
);

ALTER TABLE agencias_santander ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS agencias_read_all ON agencias_santander;
CREATE POLICY agencias_read_all ON agencias_santander FOR SELECT USING (true);

INSERT INTO agencias_santander (uniorg, endereco, numero, complemento, bairro, cidade, uf, cep)
VALUES
  ('1619', 'R EMILIA MARENGO', '312', '', 'VL REGENTE FEIJO', 'SAO PAULO', 'SP', '')
ON CONFLICT (uniorg) DO NOTHING;

CREATE INDEX IF NOT EXISTS idx_agencias_bairro ON agencias_santander(bairro);
