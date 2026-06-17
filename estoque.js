/* ── MÓDULO ESTOQUE — RAT Pro Editor ──
 * Campos: SÉRIE FAB · DESCRIÇÃO · DESCRIÇÃO FIELD · Estado ·
 *         Nome Técnico · Operação · OSE · Patrimônio · UF
 * Depende de globals em index.html: supabaseClient, ADMIN_EMAIL, loggedInUser
 */

let estoqueCache   = [];
let estoqueIdAtual = null;

// ── utils ────────────────────────────────────────────────────────────────────

function v(val) { return val && String(val).trim() ? String(val).trim() : '—'; }

function estadoBadge(e) {
    if (!e) return '<span style="color:#cbd5e1;">—</span>';
    const mapa = {
        'bom':        { bg:'#dcfce7', color:'#166534' },
        'regular':    { bg:'#fef3c7', color:'#92400e' },
        'defeituoso': { bg:'#fee2e2', color:'#991b1b' },
        'novo':       { bg:'#dbeafe', color:'#1d4ed8' },
    };
    const key = e.toLowerCase().normalize('NFD').replace(/[̀-ͯ]/g,'');
    const info = mapa[key] || { bg:'#f1f5f9', color:'#475569' };
    return `<span style="display:inline-block;padding:2px 8px;border-radius:12px;font-size:11px;font-weight:700;background:${info.bg};color:${info.color};">${e}</span>`;
}

// ── carregar ─────────────────────────────────────────────────────────────────

async function carregarEstoque() {
    const btn   = document.getElementById('btnAtualizarEstoque');
    const status= document.getElementById('statusEstoque');
    const aviso = document.getElementById('avisoEstoqueSQL');
    if (!btn || !status) return;

    btn.innerHTML = '⏳ Carregando...'; btn.disabled = true;
    if (aviso) aviso.style.display = 'none';

    try {
        const { data, error } = await supabaseClient
            .from('estoque')
            .select('*')
            .order('id', { ascending: false });

        if (error) {
            if (error.code === '42P01' || error.message?.includes('does not exist')) {
                if (aviso) aviso.style.display = 'block';
                status.textContent = 'Tabela não encontrada. Veja as instruções acima.';
            } else throw error;
            return;
        }

        estoqueCache = data || [];
        atualizarTabelaEstoque(estoqueCache);
        atualizarStatsEstoque(estoqueCache);
        popularFiltros(estoqueCache);

        const container = document.getElementById('containerEstoque');
        if (container) container.style.display = estoqueCache.length ? 'block' : 'none';
        status.textContent = `${estoqueCache.length} equipamento(s) cadastrado(s).`;

    } catch (e) {
        if (status) status.textContent = 'Erro ao carregar estoque: ' + e.message;
        console.error('[estoque] carregarEstoque:', e);
    } finally {
        btn.innerHTML = '🔄 Atualizar'; btn.disabled = false;
    }
}

// ── stats ────────────────────────────────────────────────────────────────────

function atualizarStatsEstoque(lista) {
    const set = (id, val) => { const el = document.getElementById(id); if (el) el.textContent = val; };
    set('stTotal', lista.length);
    set('stUFs',  new Set(lista.map(x => x.uf).filter(Boolean)).size);
    set('stOps',  new Set(lista.map(x => x.operacao).filter(Boolean)).size);
    set('stTecs', new Set(lista.map(x => x.nome_tecnico).filter(Boolean)).size);
}

// ── filtros dinâmicos ────────────────────────────────────────────────────────

function popularFiltros(lista) {
    const ufs     = [...new Set(lista.map(x => x.uf).filter(Boolean))].sort();
    const estados = [...new Set(lista.map(x => x.estado).filter(Boolean))].sort();

    const selUF = document.getElementById('filtroEstoqueUF');
    if (selUF) {
        selUF.innerHTML = '<option value="">Todas as UFs</option>' +
            ufs.map(u => `<option value="${u}">${u}</option>`).join('');
    }
    const selEst = document.getElementById('filtroEstoqueEstado');
    if (selEst) {
        selEst.innerHTML = '<option value="">Todos os estados</option>' +
            estados.map(e => `<option value="${e}">${e}</option>`).join('');
    }
}

// ── tabela ───────────────────────────────────────────────────────────────────

function atualizarTabelaEstoque(lista) {
    const tbody = document.getElementById('corpoTabelaEstoque');
    if (!tbody) return;
    tbody.innerHTML = '';

    const isAdmin = loggedInUser?.email?.toLowerCase() === ADMIN_EMAIL;

    if (!lista.length) {
        tbody.innerHTML = '<tr><td colspan="9" style="text-align:center;color:#94a3b8;">Nenhum equipamento encontrado.</td></tr>';
        return;
    }

    lista.forEach(eq => {
        const tr = document.createElement('tr');
        tr.style.cursor = 'pointer';
        tr.innerHTML = `
            <td onclick="event.stopPropagation()">
                <div style="display:flex;gap:5px;">
                    <button class="btn-edit-table" style="background:#64748b;" onclick="verDetalheEquip(${eq.id})">Ver</button>
                    ${isAdmin ? `<button class="btn-edit-table" onclick="abrirModalEquip(${eq.id})">Editar</button>` : ''}
                    ${isAdmin ? `<button class="btn-danger-table" onclick="excluirEquipamento(${eq.id})">🗑</button>` : ''}
                </div>
            </td>
            <td style="font-weight:bold;">${v(eq.patrimonio)}</td>
            <td>${v(eq.serie_fab)}</td>
            <td style="max-width:200px;overflow:hidden;text-overflow:ellipsis;white-space:nowrap;" title="${eq.descricao||''}">${v(eq.descricao)}</td>
            <td>${v(eq.ose)}</td>
            <td>${estadoBadge(eq.estado)}</td>
            <td><strong>${v(eq.uf)}</strong></td>
            <td>${v(eq.operacao)}</td>
            <td>${v(eq.nome_tecnico)}</td>`;
        tr.addEventListener('click', () => verDetalheEquip(eq.id));
        tbody.appendChild(tr);
    });

    const container = document.getElementById('containerEstoque');
    if (container) container.style.display = 'block';
}

// ── filtro local ─────────────────────────────────────────────────────────────

function filtrarEstoqueLocal() {
    const texto  = (document.getElementById('filtroEstoqueTexto')?.value || '').toUpperCase().trim();
    const uf     = document.getElementById('filtroEstoqueUF')?.value || '';
    const estado = document.getElementById('filtroEstoqueEstado')?.value || '';

    const filtrado = estoqueCache.filter(eq =>
        (!uf     || eq.uf === uf) &&
        (!estado || eq.estado === estado) &&
        (!texto  || [eq.patrimonio, eq.serie_fab, eq.descricao, eq.descricao_field,
                     eq.ose, eq.nome_tecnico, eq.operacao]
            .some(c => c && c.toUpperCase().includes(texto)))
    );

    atualizarTabelaEstoque(filtrado);
    const st = document.getElementById('statusEstoque');
    if (st) st.textContent = (texto || uf || estado)
        ? `${filtrado.length} resultado(s) filtrado(s).`
        : `${estoqueCache.length} equipamento(s).`;
}

// ── modal abrir / fechar ─────────────────────────────────────────────────────

function abrirModalEquip(id = null) {
    estoqueIdAtual = id;

    const titulo = document.getElementById('modalEquipTitulo');
    if (titulo) titulo.textContent = id ? 'Editar Equipamento' : 'Novo Equipamento';

    const ids = ['eq_descricao','eq_descricao_field','eq_patrimonio','eq_serie_fab',
                 'eq_ose','eq_estado','eq_operacao','eq_nome_tecnico','eq_uf'];
    ids.forEach(elId => { const el = document.getElementById(elId); if (el) el.value = ''; });

    if (id) {
        const eq = estoqueCache.find(x => x.id === id);
        if (!eq) return;
        const set = (elId, val) => { const el = document.getElementById(elId); if (el) el.value = val || ''; };
        set('eq_descricao',       eq.descricao);
        set('eq_descricao_field', eq.descricao_field);
        set('eq_patrimonio',      eq.patrimonio);
        set('eq_serie_fab',       eq.serie_fab);
        set('eq_ose',             eq.ose);
        set('eq_estado',          eq.estado);
        set('eq_operacao',        eq.operacao);
        set('eq_nome_tecnico',    eq.nome_tecnico);
        set('eq_uf',              eq.uf);
    }

    const modal = document.getElementById('modalEquip');
    if (modal) { modal.classList.add('open'); document.body.style.overflow = 'hidden'; }
}

function fecharModalEquip() {
    const modal = document.getElementById('modalEquip');
    if (modal) modal.classList.remove('open');
    document.body.style.overflow = '';
}

function fecharModalEquipFora(e) {
    if (e.target === document.getElementById('modalEquip')) fecharModalEquip();
}

// ── salvar ───────────────────────────────────────────────────────────────────

async function salvarEquipamento() {
    const g    = id => (document.getElementById(id)?.value || '').trim();
    const gUP  = id => g(id).toUpperCase();

    const payload = {
        descricao:       gUP('eq_descricao'),
        descricao_field: gUP('eq_descricao_field'),
        patrimonio:      gUP('eq_patrimonio'),
        serie_fab:       gUP('eq_serie_fab'),
        ose:             gUP('eq_ose'),
        estado:          g('eq_estado'),
        operacao:        gUP('eq_operacao'),
        nome_tecnico:    gUP('eq_nome_tecnico'),
        uf:              gUP('eq_uf'),
    };

    try {
        let error;
        if (estoqueIdAtual) {
            ({ error } = await supabaseClient.from('estoque').update(payload).eq('id', estoqueIdAtual));
        } else {
            ({ error } = await supabaseClient.from('estoque').insert([payload]));
        }
        if (error) throw error;
        fecharModalEquip();
        await carregarEstoque();
    } catch (e) {
        alert('Erro ao salvar equipamento: ' + e.message);
        console.error('[estoque] salvarEquipamento:', e);
    }
}

// ── excluir ──────────────────────────────────────────────────────────────────

async function excluirEquipamento(id) {
    const eq   = estoqueCache.find(x => x.id === id);
    const desc = [eq?.patrimonio, eq?.serie_fab, eq?.descricao].filter(Boolean).join(' / ') || '#' + id;
    if (!confirm(`Excluir definitivamente:\n${desc}\n\nEsta ação não pode ser desfeita.`)) return;

    try {
        const { error } = await supabaseClient.from('estoque').delete().eq('id', id);
        if (error) throw error;
        estoqueCache = estoqueCache.filter(x => x.id !== id);
        atualizarTabelaEstoque(estoqueCache);
        atualizarStatsEstoque(estoqueCache);
        popularFiltros(estoqueCache);
        const st = document.getElementById('statusEstoque');
        if (st) st.textContent = `${estoqueCache.length} equipamento(s).`;
        if (!estoqueCache.length) {
            const c = document.getElementById('containerEstoque');
            if (c) c.style.display = 'none';
        }
    } catch (e) {
        alert('Erro ao excluir: ' + e.message);
        console.error('[estoque] excluirEquipamento:', e);
    }
}

// ── detalhe ──────────────────────────────────────────────────────────────────

function verDetalheEquip(id) {
    const eq = estoqueCache.find(x => x.id === id);
    if (!eq) return;

    const linhas = [
        ['Patrimônio',      eq.patrimonio],
        ['Série Fab',       eq.serie_fab],
        ['Descrição',       eq.descricao],
        ['Descrição Field', eq.descricao_field],
        ['OSE',             eq.ose],
        ['Estado',          eq.estado],
        ['Operação',        eq.operacao],
        ['Nome Técnico',    eq.nome_tecnico],
        ['UF',              eq.uf],
    ].filter(([, val]) => val && String(val).trim());

    const resumo = linhas.map(([l, val]) => `${l}: ${val}`).join('\n');
    alert(`📦 Equipamento\n${'─'.repeat(40)}\n${resumo}`);
}

console.info('[estoque] módulo carregado com sucesso.');
