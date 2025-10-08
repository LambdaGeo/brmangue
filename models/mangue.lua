-- ===============================================================
-- FUNÇÃO GERAL DE MIGRAÇÃO DE SOLOS
-- ===============================================================
function migrarSolos(celula, nomes_atributos, params, zonaInfluencia)
    local attrSolo = nomes_atributos.solo
    local attrUso  = nomes_atributos.uso
    local attrAlt  = nomes_atributos.alt

    if params.origens[celula.past[attrSolo]] then
        forEachNeighbor(celula, function(vizinho)
            if params.alvos[vizinho.past[attrUso]]
                and vizinho.past[attrSolo] ~= params.soloDestino
                and vizinho.past[attrAlt] <= zonaInfluencia then
                vizinho[attrSolo] = params.soloDestino
            end
        end)
    end
end


-- ===============================================================
-- FUNÇÃO GERAL DE MIGRAÇÃO DE USOS
-- ===============================================================
function migrarUsos(celula, nomes_atributos, params, zonaInfluencia)
    local attrSolo = nomes_atributos.solo
    local attrUso  = nomes_atributos.uso
    local attrAlt  = nomes_atributos.alt

    if params.origens[celula.past[attrUso]] then
        forEachNeighbor(celula, function(vizinho)
            if params.alvos[vizinho.past[attrUso]]
                and vizinho.past[attrAlt] <= zonaInfluencia
                and params.condSolos[vizinho.past[attrSolo]] then
                vizinho[attrUso] = params.usoDestino
            end
        end)
    end
end


-- ===============================================================
-- FUNÇÃO DE ACREÇÃO VERTICAL DA LAMA
-- ===============================================================
function aplicarAcrecao(celula, nomes_atributos, regrasAcrecao, taxaAcrecao_m)
    local attrSolo = nomes_atributos.solo
    local attrUso  = nomes_atributos.uso
    local attrAlt  = nomes_atributos.alt

    local soloPermitido = regrasAcrecao.solosPermitidos[celula.past[attrSolo]]
    local usoPermitido  = not regrasAcrecao.usosProibidos[celula.past[attrUso]]

    if soloPermitido and usoPermitido then
        celula[attrAlt] = celula[attrAlt] + taxaAcrecao_m 
    end
end


-- ===============================================================
-- MODELO DE DINÂMICA DE MANGUE
-- ===============================================================
function Mangue(espacoCelular,
                tabela_solos, tabela_usos, nomes_atributos)


    -- ===============================================================
-- REGRAS DE MIGRAÇÃO DE SOLOS
-- ===============================================================
-- Define condições de origem, destino e transformação para solos
local regrasMigracaoSolo = {
    origens = {
        [tabela_solos.MANGUE.valor]         = true,
        [tabela_solos.MANGUE_MIGRADO.valor] = true,
        [tabela_solos.CANAL_FLUVIAL.valor]  = true
    },
    alvos = {
        [tabela_usos.VEGETACAO_TERRESTRE.valor] = true,
        [tabela_usos.SOLO_DESCOBERTO.valor]     = true
    },
    soloDestino = tabela_solos.MANGUE_MIGRADO.valor
}



-- ===============================================================
-- REGRAS DE MIGRAÇÃO DE USOS
-- ===============================================================
-- Controla o processo de migração dos usos do solo relacionados ao mangue
local regrasMigracaoUsos = {
    origens = {
        [tabela_usos.MANGUE.valor]         = true,
        [tabela_usos.MANGUE_MIGRADO.valor] = true
    },
    alvos = {
        [tabela_usos.VEGETACAO_TERRESTRE.valor] = true,
        [tabela_usos.SOLO_DESCOBERTO.valor]     = true
    },
    condSolos = {
        [tabela_solos.MANGUE.valor]         = true,
        [tabela_solos.MANGUE_MIGRADO.valor] = true
    },
    usoDestino = tabela_usos.MANGUE_MIGRADO.valor
}



-- ===============================================================
-- REGRAS DE ACREÇÃO VERTICAL
-- ===============================================================
-- Controla o acúmulo vertical de sedimentos nos solos do tipo mangue
local regrasAcrecao = {
    solosPermitidos = {
        [tabela_solos.MANGUE.valor]         = true,
        [tabela_solos.MANGUE_MIGRADO.valor] = true
    },
    usosProibidos = {
        [tabela_usos.MAR.valor]                          = true,
        [tabela_usos.SOLO_INUNDADO.valor]                = true,
        [tabela_usos.AREA_ANTROPIZADA_INUNDADA.valor]    = true,
        [tabela_usos.MANGUE_INUNDADO.valor]              = true,
        [tabela_usos.VEGETACAO_TERRESTRE_INUNDADA.valor] = true
    }
}

    return Model {
        start = 1,
        finalTime = 100,

        areaCelula = 0.09,
        alturaMare = 6,
        taxaElevacaoMar = 0.5,

        coeficienteA    = 1.693,  -- intercepto da equação de Alongi 
        coeficienteB    = 0.939,   -- coeficiente de inclinação da equação de Alongi 
   

        execute = function(modelo, event)
            local tempo = event:getTime()

            -- Cálculo do nível do mar e taxa de acreção
            local nivelMar = tempo * modelo.taxaElevacaoMar
            local taxaAcrecao_m = modelo.coeficienteA/1000 + (modelo.coeficienteB * nivelMar) -- 1.693 + 0.939 * nivelMar_mm/ 1000

            local zonaInfluencia = modelo.alturaMare + nivelMar

            forEachCell(espacoCelular, function(celula)
                migrarSolos(celula, nomes_atributos, regrasMigracaoSolo, zonaInfluencia)
                migrarUsos(celula, nomes_atributos, regrasMigracaoUsos, zonaInfluencia)
                aplicarAcrecao(celula, nomes_atributos, regrasAcrecao, taxaAcrecao_m)
            end)
        end,

        init = function(model)
            model.timer = Timer { Event { action = model } }
        end
    }
end
