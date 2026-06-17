# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

**RAT Pro Editor** — a single-file web app for managing and generating technical service reports (RAT = Relatório de Atendimento Técnico) for field technicians. The entire application lives in `index.html` with no build step.

## Running the App

Open `index.html` directly in a browser (file://) or serve it with any static file server:

```
npx serve .
# or
python -m http.server
```

No install, no build, no package manager.

## Architecture

### Single-file structure
All HTML, CSS, and JavaScript is in [index.html](index.html). There are no separate modules, components, or build artifacts.

### External dependencies (CDN only)
- **Supabase JS v2** — database and authentication
- **pdf-lib v1.17.1** — modifies the blank PDF template at runtime
- **pdf.js v3.4.120** — renders the modified PDF to a canvas for live preview

### Backend: Supabase
- **Auth**: Supabase email/password authentication. Two clients are instantiated:
  - `supabaseClient` — main session-aware client
  - `authRegistrationClient` — session-less client used only by admin to register new users without disrupting their own session
- **Database**: A single `chamados` table stores all service records. Fields map to PDF positions defined in the `POS` object.
- **Tech profiles hack**: Technician user profiles are not in a separate table — they are stored as a JSON blob in the `solucao` column of a special row where `chamado = 'CONFIG_TECNICOS'`. This is loaded into `perfisTecnicosCache` on login.

### PDF generation
The `POS` object (line ~489) maps every form field to absolute `{x, y}` pixel coordinates on the PDF template. `aplicarDadosNoPdf()` fetches the blank template from Supabase Storage and writes text at those coordinates using pdf-lib. `gerarERenderizar()` calls this and renders the result to a canvas via pdf.js (debounced 500ms after any form input).

The blank template URL is: `URL_MODELO_PDF` constant at the top of the script section.

### Access control
- `ADMIN_EMAIL = 'williandcm@hotmail.com'` — hardcoded admin identity
- Admin sees all records; regular technicians see only records where `tecnico = their email`
- On each save/load, `checarStatusAtivo()` re-reads CONFIG_TECNICOS from the DB to check if the technician has been deactivated mid-session

### Data extraction
`extrairDados()` uses regex to parse raw ticket text pasted into the textarea, auto-filling form fields. It recognizes patterns like `INC\d+`, `SGPI: \d+`, `HOSTNAME: \S+`, `UNIORG: \d+`, and address formats. It also handles special cases: PIN PAD vs. computer swap vs. image reset (`BAIXA DE IMAGEM`).

## Key constants to know before editing

| Constant | Purpose |
|---|---|
| `ADMIN_EMAIL` | Email that receives admin privileges |
| `SUPABASE_URL` / `SUPABASE_KEY` | Supabase project credentials |
| `URL_MODELO_PDF` | Blank RAT template in Supabase Storage |
| `CPF_FIXO` | Default CPF for the admin user |
| `POS` | x/y coordinates for every field on the PDF template |

## Editing PDF field positions

If the PDF template changes, update the `POS` object coordinates. Each entry is `{ x, y }` in PDF points from the bottom-left corner, with an optional `s` for font size (defaults to 11). Time fields use paired hour/minute entries (e.g., `h_partida` / `m_partida`).
