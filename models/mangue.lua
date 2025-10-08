-- ===============================================================
-- FUNÇÃO GERAL DE MIGRAÇÃO DE SOLOS 
-- ===============================================================
-- Atualiza o tipo de solo das células vizinhas com base em regras fixas e simples
-- de migração, sem uso de parâmetros ou tabelas auxiliares.
function migrarSolos(celula, nomes_atributos, tabela_solos, zonaInfluencia)
    -- Campos do shapefile
    local attrSolo = nomes_atributos.solo
    local attrUso  = nomes_atributos.uso
    local attrAlt  = nomes_atributos.alt

    local soloAtual = celula.past[attrSolo]

    -- Verifica se o solo atual pode iniciar a migração (solos de origem)
    if soloAtual == tabela_solos.MANGUE.valor
        or soloAtual == tabela_solos.MANGUE_MIGRADO.valor
        or soloAtual == tabela_solos.CANAL_FLUVIAL.valor then

        -- Percorre os vizinhos da célula atual
        forEachNeighbor(celula, function(vizinho)
            local usoVizinho  = vizinho.past[attrUso]
            local soloVizinho = vizinho.past[attrSolo]
            local altVizinho  = vizinho.past[attrAlt]

            -- Condições diretas para permitir a migração do solo
            if (usoVizinho == tabela_usos.VEGETACAO_TERRESTRE.valor
                or usoVizinho == tabela_usos.SOLO_DESCOBERTO.valor)
                and soloVizinho ~= tabela_solos.MANGUE_MIGRADO.valor
                and altVizinho <= zonaInfluencia then

                -- Atualiza o tipo de solo do vizinho para "Mangue Migrado"
                vizinho[attrSolo] = tabela_solos.MANGUE_MIGRADO.valor
            end
        end)
    end
end



-- ===============================================================
-- FUNÇÃO GERAL DE MIGRAÇÃO DE USOS
-- ===============================================================
-- Atualiza o uso do solo das células vizinhas conforme regras fixas,
-- sem uso de parâmetros externos ou tabelas auxiliares.
function migrarUsos(celula, nomes_atributos, tabela_usos, tabela_solos, zonaInfluencia)
    -- Campos do shapefile
    local attrSolo = nomes_atributos.solo
    local attrUso  = nomes_atributos.uso
    local attrAlt  = nomes_atributos.alt

    local usoAtual = celula.past[attrUso]

    -- Verifica se o uso atual é elegível para iniciar a migração
    if usoAtual == tabela_usos.MANGUE.valor
        or usoAtual == tabela_usos.MANGUE_MIGRADO.valor then

        -- Percorre vizinhos e aplica as condições de migração
        forEachNeighbor(celula, function(vizinho)
            local usoVizinho  = vizinho.past[attrUso]
            local soloVizinho = vizinho.past[attrSolo]
            local altVizinho  = vizinho.past[attrAlt]

            -- Condições diretas de migração do uso
            if (usoVizinho == tabela_usos.VEGETACAO_TERRESTRE.valor
                or usoVizinho == tabela_usos.SOLO_DESCOBERTO.valor)
                and (soloVizinho == tabela_solos.MANGUE.valor
                     or soloVizinho == tabela_solos.MANGUE_MIGRADO.valor)
                and altVizinho <= zonaInfluencia then

                -- Atualiza o uso do vizinho para "Mangue Migrado"
                vizinho[attrUso] = tabela_usos.MANGUE_MIGRADO.valor
            end
        end)
    end
end



-- ===============================================================
-- FUNÇÃO DE ACREÇÃO VERTICAL DA LAMA
-- ===============================================================
-- Simula o acúmulo vertical de sedimentos (acréção) nas células de mangue.
-- A elevação ocorre apenas em solos e usos adequados.
function aplicarAcrecao(celula, nomes_atributos, tabela_usos, tabela_solos, taxaAcrecao_m)
    -- Campos do shapefile
    local attrSolo = nomes_atributos.solo
    local attrUso  = nomes_atributos.uso
    local attrAlt  = nomes_atributos.alt

    local soloAtual = celula.past[attrSolo]
    local usoAtual  = celula.past[attrUso]

    -- Verifica se o solo é permitido para acréção (somente mangue e mangue migrado)
    local soloPermitido = (
        soloAtual == tabela_solos.MANGUE.valor or
        soloAtual == tabela_solos.MANGUE_MIGRADO.valor
    )

    -- Verifica se o uso é proibido para acréção
    local usoProibido = (
        usoAtual == tabela_usos.MAR.valor or
        usoAtual == tabela_usos.SOLO_INUNDADO.valor or
        usoAtual == tabela_usos.AREA_ANTROPIZADA_INUNDADA.valor or
        usoAtual == tabela_usos.MANGUE_INUNDADO.valor or
        usoAtual == tabela_usos.VEGETACAO_TERRESTRE_INUNDADA.valor
    )

    -- Executa a acréção vertical apenas quando o solo é permitido e o uso não é proibido
    if soloPermitido and not usoProibido then
        celula[attrAlt] = celula[attrAlt] + taxaAcrecao_m
    end
end



-- ===============================================================
-- MODELO DE DINÂMICA DE MANGUE
-- ===============================================================
-- Este modelo integra as funções de migração de solo, migração de uso
-- e acréção vertical para simular a resposta do mangue à elevação do mar.
function Mangue(espacoCelular, tabela_solos, tabela_usos, nomes_atributos)
    return Model {
        -- Tempo de simulação
        start = 1,
        finalTime = 100,

        -- Parâmetros gerais do modelo
        areaCelula = 0.09,          -- área da célula (hectares)
        alturaMare = 6,             -- altura média da maré (m)
        taxaElevacaoMar = 0.5,      -- taxa de elevação do nível do mar (m/ano)

        -- Coeficientes da equação de Alongi (2008)
        coeficienteA = 1.693,       -- intercepto
        coeficienteB = 0.939,       -- inclinação

        -- Função de execução por passo temporal
        execute = function(modelo, event)
            local tempo = event:getTime()

            -- Calcula o nível do mar e a taxa de acréção (em metros)
            local nivelMar = tempo * modelo.taxaElevacaoMar
            local taxaAcrecao_m = modelo.coeficienteA / 1000 + (modelo.coeficienteB * nivelMar)

            -- Define a zona de influência da maré considerando a elevação
            local zonaInfluencia = modelo.alturaMare + nivelMar

            -- Aplica os processos em cada célula do espaço
            forEachCell(espacoCelular, function(celula)
                migrarSolos(celula, nomes_atributos, tabela_solos, zonaInfluencia)
                migrarUsos(celula, nomes_atributos, tabela_usos, tabela_solos, zonaInfluencia)
                --aplicarAcrecao(celula, nomes_atributos, tabela_usos, tabela_solos, taxaAcrecao_m)
            end)
        end,

        -- Inicialização do modelo
        init = function(model)
            model.timer = Timer { Event { action = model } }
        end
    }
end
