-- ===============================================================
-- FUNÇÕES AUXILIARES
-- ===============================================================

-- Verifica se o uso da terra corresponde a mar ou a um uso inundado.
-- Essa função é usada para determinar se uma célula já está sob influência
-- da maré ou da inundação.
--
-- @param uso : valor do uso atual da célula
-- @return true se o uso for mar ou um tipo inundado, false caso contrário
function ehMarOuInundado(uso)
    -- Lista dos usos considerados inundados
    local usos_inundados = {
        [tabela_usos.MAR.valor]                          = true,
        [tabela_usos.SOLO_INUNDADO.valor]                = true,
        [tabela_usos.AREA_ANTROPIZADA_INUNDADA.valor]    = true,
        [tabela_usos.MANGUE_INUNDADO.valor]              = true,
        [tabela_usos.VEGETACAO_TERRESTRE_INUNDADA.valor] = true
    }

    return usos_inundados[uso] == true
end



-- Aplica a regra de inundação a uma célula, se houver regra definida.
-- Transforma o uso atual em sua versão "inundada" correspondente.
--
-- @param celula  : célula do espaço celular
-- @param attrUso : nome do atributo de uso da célula (ex: "Usos")
function aplicarInundacao(celula, attrUso)
    local usoAtual = celula.past[attrUso]

    -- Tabela de regras de conversão: uso seco -> uso inundado
    local regras = {
        [tabela_usos.MANGUE.valor]               = tabela_usos.MANGUE_INUNDADO.valor,
        [tabela_usos.MANGUE_MIGRADO.valor]       = tabela_usos.MANGUE_INUNDADO.valor,
        [tabela_usos.VEGETACAO_TERRESTRE.valor]  = tabela_usos.VEGETACAO_TERRESTRE_INUNDADA.valor,
        [tabela_usos.AREA_ANTROPIZADA.valor]     = tabela_usos.AREA_ANTROPIZADA_INUNDADA.valor,
        [tabela_usos.SOLO_DESCOBERTO.valor]      = tabela_usos.SOLO_INUNDADO.valor
    }

    -- Se o uso atual tiver uma regra correspondente, aplica a transformação
    if regras[usoAtual] then
        celula[attrUso] = regras[usoAtual]
    end
end



-- ===============================================================
-- MODELO DE HIDROLOGIA (Hidro)
-- ===============================================================
-- Simula os impactos da elevação do nível do mar sobre a altimetria e o uso do solo.
-- Distribui o acréscimo do nível do mar entre as células inundadas e seus vizinhos,
-- propagando a inundação de forma gradual ao longo do tempo.
--
-- @param cs              : espaço celular (CellularSpace)
-- @param tabela_usos     : tabela com os códigos de uso do solo
-- @param nomes_atributos : tabela com os nomes dos atributos da célula (ex: { uso = "Usos", alt = "Alt2" })
function Hidro(cs, tabela_usos, nomes_atributos)
    return Model {
        start = 1,
        finalTime = 100,
        taxaElevacaoMar = 0.011,

        execute = function(model, event)
            local attrUso  = nomes_atributos.uso
            local attrAlt  = nomes_atributos.alt
            local nivelMar = event:getTime() * model.taxaElevacaoMar

            forEachCell(cs, function(celula)
                local usoAtual = celula.past[attrUso]
                local altAtual = celula.past[attrAlt]

                if ehMarOuInundado(usoAtual) and altAtual >= 0 then
                    local vizinhosBaixos = 1

                    forEachNeighbor(celula, function(vizinho)
                        if vizinho.past[attrAlt] <= altAtual then
                            vizinhosBaixos = vizinhosBaixos + 1
                        end
                    end)

                    local fluxo = model.taxaElevacaoMar / vizinhosBaixos

                    -- altimetria: condicao relativa (difusao de fluxo)
                    celula[attrAlt] = celula[attrAlt] + fluxo

                    forEachNeighbor(celula, function(vizinho)
                        if vizinho.past[attrAlt] <= altAtual then
                            vizinho[attrAlt] = vizinho[attrAlt] + fluxo
                        end

                        -- inundacao: cota absoluta (BR-MANGUE, Bezerra 2014)
                        if vizinho.past[attrAlt] <= nivelMar then
                            if not ehMarOuInundado(vizinho.past[attrUso]) then
                                aplicarInundacao(vizinho, attrUso)
                            end
                        end
                    end)
                end
            end)
        end,

        init = function(model)
            model.timer = Timer { Event { action = model } }
        end
    }
end