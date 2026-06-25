// Supabase Edge Function — busca endereço de agência Santander pelo número
// Deploy: supabase functions deploy agencia-lookup
import { serve } from "https://deno.land/std@0.168.0/http/server.ts";

const CORS = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
};

serve(async (req) => {
  if (req.method === "OPTIONS") return new Response("ok", { headers: CORS });

  const url = new URL(req.url);
  const agNum = (url.searchParams.get("agencia") || "").replace(/\D/g, "").padStart(4, "0");

  if (!agNum || agNum === "0000") {
    return new Response(JSON.stringify({ error: "Informe o número da agência" }), {
      status: 400, headers: { ...CORS, "Content-Type": "application/json" },
    });
  }

  const pageUrl = `https://www.agenciadobanco.com.br/agencia-${agNum}-santander`;

  try {
    const res = await fetch(pageUrl, {
      headers: { "User-Agent": "Mozilla/5.0 (compatible; RAT-lookup/1.0)" },
    });

    if (!res.ok) {
      return new Response(JSON.stringify({ error: "Agência não encontrada", agencia: agNum }), {
        status: 404, headers: { ...CORS, "Content-Type": "application/json" },
      });
    }

    const html = await res.text();

    // Extrai o endereço — formato típico: "RUA X, 123 - BAIRRO, Cidade/UF - CEP: 00000-000"
    const addrMatch = html.match(
      /([A-ZÁÉÍÓÚÀÃÕÂÊÔÇ][A-ZÁÉÍÓÚÀÃÕÂÊÔÇ\s\.]+),\s*(\d+[^\-<]*?)\s*-\s*([^,<]+),\s*([^\/\n<]+)\/([A-Z]{2})\s*-\s*CEP:\s*([\d\-]+)/i
    );

    if (!addrMatch) {
      // Tenta padrão alternativo sem CEP
      const alt = html.match(
        /([A-ZÁÉÍÓÚÀÃÕÂÊÔÇ][A-ZÁÉÍÓÚÀÃÕÂÊÔÇ\s\.]+),\s*(\d+[^\-<]*?)\s*-\s*([^,<]+),\s*([^\/\n<]+)\/([A-Z]{2})/i
      );
      if (alt) {
        return new Response(JSON.stringify({
          agencia: agNum,
          endereco: alt[1].trim().toUpperCase(),
          numero:   alt[2].trim(),
          bairro:   alt[3].trim().toUpperCase(),
          cidade:   alt[4].trim().toUpperCase(),
          uf:       alt[5].trim().toUpperCase(),
          cep:      "",
        }), { headers: { ...CORS, "Content-Type": "application/json" } });
      }
      return new Response(JSON.stringify({ error: "Endereço não reconhecido", agencia: agNum }), {
        status: 422, headers: { ...CORS, "Content-Type": "application/json" },
      });
    }

    return new Response(JSON.stringify({
      agencia: agNum,
      endereco: addrMatch[1].trim().toUpperCase(),
      numero:   addrMatch[2].trim(),
      bairro:   addrMatch[3].trim().toUpperCase(),
      cidade:   addrMatch[4].trim().toUpperCase(),
      uf:       addrMatch[5].trim().toUpperCase(),
      cep:      addrMatch[6].trim(),
    }), { headers: { ...CORS, "Content-Type": "application/json" } });

  } catch (err) {
    return new Response(JSON.stringify({ error: String(err) }), {
      status: 500, headers: { ...CORS, "Content-Type": "application/json" },
    });
  }
});
