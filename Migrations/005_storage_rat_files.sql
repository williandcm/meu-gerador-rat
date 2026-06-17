-- ============================================================
-- Migration 005 — Storage bucket rat-files
-- ============================================================
-- Cria o bucket público onde o template RAT EM BRANCO.pdf
-- é armazenado. A aplicação faz fetch sem autenticação, por
-- isso o bucket deve ser público (leitura anônima permitida).
--
-- Após executar este SQL, faça upload manual do arquivo
-- "RAT EM BRANCO.pdf" no bucket rat-files pelo painel
-- Supabase (Storage → rat-files → Upload file).
-- ============================================================

-- Cria o bucket se ainda não existir
insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values (
  'rat-files',
  'rat-files',
  true,
  10485760,                                -- 10 MB
  array['application/pdf', 'image/png']
)
on conflict (id) do nothing;

-- ── Políticas do bucket ───────────────────────────────────────────────────────

-- Leitura pública (anônima) — necessária para que o template seja
-- carregado pelo navegador sem autenticação via fetch()
create policy "rat_files_public_read"
  on storage.objects
  for select
  using (bucket_id = 'rat-files');

-- Upload apenas por usuários autenticados (admin faz manutenção do template)
create policy "rat_files_auth_insert"
  on storage.objects
  for insert
  to authenticated
  with check (bucket_id = 'rat-files');

-- Substituição de arquivo apenas por usuários autenticados
create policy "rat_files_auth_update"
  on storage.objects
  for update
  to authenticated
  using  (bucket_id = 'rat-files')
  with check (bucket_id = 'rat-files');

-- Exclusão de arquivo apenas por usuários autenticados
create policy "rat_files_auth_delete"
  on storage.objects
  for delete
  to authenticated
  using (bucket_id = 'rat-files');
