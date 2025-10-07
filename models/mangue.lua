-- ===============================================================
-- FUNÇÃO GERAL DE MIGRAÇÃO DE SOLOS
-- ===============================================================
function migrarSolos(celula, nomes_atributos, params, zonaInfluencia)
    local attrSolo = nomes_atributos.solo
    local attrUso  = nomes_atributos.uso
    local attrAlt  = nomes_atributos.alt

    if params.origens[celula.past[attrSolo]] then
        forEachNeighbor(celula, function(vizinho)
            if params.alvos[vizinho[attrUso]]
                and vizinho[attrSolo] ~= params.soloDestino
                and vizinho[attrAlt] <= zonaInfluencia then
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
            if params.alvos[vizinho[attrUso]]
                and vizinho[attrAlt] <= zonaInfluencia
                and params.condSolos[vizinho[attrSolo]] then
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

    local soloPermitido = regrasAcrecao.solosPermitidos[celula[attrSolo]]
    local usoPermitido  = not regrasAcrecao.usosProibidos[celula[attrUso]]

    if soloPermitido and usoPermitido then
        celula[attrAlt] = celula[attrAlt] + taxaAcrecao_m
    end
end


-- ===============================================================
-- MODELO DE DINÂMICA DE MANGUE
-- ===============================================================
function Mangue(espacoCelular, tabela_usos, tabela_solos, usos_inundados,
                regrasMigracaoSolo, regrasMigracaoUsos, regrasAcrecao, nomes_atributos)

    return Model {
        start = 1,
        finalTime = 100,

        areaCelula = 0.09,
        alturaMare = 6,
        taxaElevacaoMar = 0.5,

        execute = function(modelo, event)
            local tempo = event:getTime()

            -- Cálculo do nível do mar e taxa de acreção
            local nivelMar = tempo * modelo.taxaElevacaoMar
            local taxaAcrecao_m = 0.001693 + (0.939 * nivelMar) -- 1.693 + 0.939 * nivelMar_mm / 1000

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
