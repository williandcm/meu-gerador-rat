-- ============================================================
-- Migration 012 — Normalizar campos de texto para maiúsculas
-- ============================================================
-- Padroniza todos os registros existentes na tabela chamados
-- para letras maiúsculas, igualando o comportamento do app
-- após a correção aplicada no front-end (commit 36655c1).
--
-- Campos excluídos da conversão:
--   chamado         — já foi sempre maiúsculo (INC..., SCT...)
--   uniorg          — código numérico
--   tecnico         — e-mail, case-sensitive
--   data_atendimento, hora_* — datas e horas
--   pdf_base64      — binário codificado em base64
--   id, created_at, updated_at — metadados
-- ============================================================

UPDATE chamados SET
    endereco                 = UPPER(endereco),
    numero                   = UPPER(numero),
    bairro                   = UPPER(bairro),
    cidade                   = UPPER(cidade),
    uf                       = UPPER(uf),
    responsavel              = UPPER(responsavel),
    matricula                = UPPER(matricula),
    patri_ret                = UPPER(patri_ret),
    sn_ret                   = UPPER(sn_ret),
    modelo_ret               = UPPER(modelo_ret),
    host_ret                 = UPPER(host_ret),
    mac_ret                  = UPPER(mac_ret),
    patri_inst               = UPPER(patri_inst),
    sn_inst                  = UPPER(sn_inst),
    modelo_inst              = UPPER(modelo_inst),
    host_inst                = UPPER(host_inst),
    mac_inst                 = UPPER(mac_inst),
    descritivo_defeito_causa = UPPER(descritivo_defeito_causa),
    solucao                  = UPPER(solucao),
    observacoes              = UPPER(observacoes),
    chamado_cerb             = UPPER(chamado_cerb)
WHERE chamado <> 'CONFIG_TECNICOS';
