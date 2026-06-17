-- ============================================================
-- Migration 001 — Tabela principal de chamados (atendimentos)
-- ============================================================
-- A tabela também armazena uma linha especial com
-- chamado = 'CONFIG_TECNICOS' cujo campo `solucao` contém
-- um JSON array com os perfis/permissões dos técnicos.
-- ============================================================

create table if not exists chamados (
  id                       bigserial primary key,

  -- Identificação
  chamado                  text,          -- número do chamado (INCxxxxxxx) ou 'CONFIG_TECNICOS'
  tecnico                  text,          -- e-mail do técnico responsável

  -- Horários (armazenados como "HH:MM")
  hora_partida             text,
  hora_chegada             text,
  hora_inicio_ate          text,
  hora_termino_ate         text,

  -- Localização
  uniorg                   text,
  endereco                 text,
  numero                   text,
  bairro                   text,
  cidade                   text,
  uf                       text,

  -- Equipamento retirado / reconfigurado
  patri_ret                text,          -- patrimônio (SGPI)
  sn_ret                   text,          -- número de série
  modelo_ret               text,
  host_ret                 text,          -- hostname
  mac_ret                  text,

  -- Equipamento instalado / novo (em caso de troca)
  patri_inst               text,
  sn_inst                  text,
  modelo_inst              text,
  host_inst                text,
  mac_inst                 text,

  -- Defeito e solução
  descritivo_defeito_causa text,
  solucao                  text,

  -- Responsável pela abertura
  responsavel              text,
  matricula                text,

  -- Data (formato "dd/mm/yyyy" — mantido como texto para compatibilidade)
  data_atendimento         text,

  -- Texto bruto colado no campo "Cole o chamado"
  chamado_cerb             text,

  -- PDF gerado/assinado (base64) — pode ser null se ainda não gerado
  pdf_base64               text,

  created_at               timestamptz default now()
);

-- Busca por número de chamado (INC…)
create index if not exists idx_chamados_chamado
  on chamados (chamado);

-- Filtro por técnico (usado na listagem de cada técnico)
create index if not exists idx_chamados_tecnico
  on chamados (tecnico);
