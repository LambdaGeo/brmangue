-- ===============================================================
-- FUNÇÕES AUXILIARES
-- ===============================================================

-- Verifica se o uso da terra corresponde a mar ou a um uso inundado
-- @param uso: valor do uso atual da célula
-- @param usos_inundados: tabela onde a chave é o uso e o valor é true
function ehMarOuInundado(uso, usos_inundados)
    return usos_inundados[uso] == true
end

-- Aplica a regra de inundação a uma célula, se houver regra definida
-- @param celula: célula do espaço celular
-- @param regras: tabela de regras de inundação (uso -> uso inundado)
-- @param attrUso: nome do atributo de uso da célula (ex: "Usos")
function aplicarInundacao(celula, regras, attrUso)
    local usoAtual = celula.past[attrUso]
    if regras[usoAtual] then
        celula[attrUso] = regras[usoAtual]
    end
end


-- ===============================================================
-- MODELO DE HIDROLOGIA (Hidro)
-- ===============================================================
-- Simula os impactos da elevação do nível do mar sobre a altimetria
-- e o uso da terra, de forma generalizável para diferentes modelos.
--
-- @param cs: espaço celular
-- @param usos_inundados: tabela de usos considerados inundados
-- @param regras_inundacao: tabela de transformações (uso -> uso_inundado)
-- @param nomes_atributos: tabela com os nomes dos atributos da célula:
--        { uso = "Usos", alt = "Alt2" }
function Hidro(cs, usos_inundados, regras_inundacao, nomes_atributos)

    return Model {
        start = 1,
        finalTime = 100,
        taxaElevacaoMar = 0.011,  -- taxa média anual (m/ano) — IPCC, 2013

        -- ===========================================================
        -- EXECUÇÃO (a cada passo da simulação)
        -- ===========================================================
        execute = function(model, event)
            local tempo = event:getTime()

            -----------------------------------------------------------
            -- Validação dos parâmetros
            -----------------------------------------------------------
            local attrUso = nomes_atributos.uso
            local attrAlt = nomes_atributos.alt

            if not attrUso or attrUso == "" then
                error("Campo 'uso' ausente em nomes_atributos.")
            end
            if not attrAlt or attrAlt == "" then
                error("Campo 'alt' ausente em nomes_atributos.")
            end

            local primeiraCelula = cs.cells[1]
            if primeiraCelula.past[attrUso] == nil then
                error("Atributo '" .. attrUso .. "' não existe no espaço celular.")
            end
            if primeiraCelula.past[attrAlt] == nil then
                error("Atributo '" .. attrAlt .. "' não existe no espaço celular.")
            end

            -----------------------------------------------------------
            -- Dinâmica hidrológica: elevação e propagação da inundação
            -----------------------------------------------------------
            forEachCell(cs, function(celula)
                local usoAtual = celula.past[attrUso]
                local altAtual = celula.past[attrAlt]

                -- Se for mar ou uso inundado e altitude válida
                if ehMarOuInundado(usoAtual, usos_inundados) and altAtual >= 0 then
                    local vizinhosBaixos = 1 -- inclui a célula atual

                    -- Conta vizinhos com altitude menor ou igual
                    forEachNeighbor(celula, function(vizinho)
                        if vizinho.past[attrAlt] <= altAtual then
                            vizinhosBaixos = vizinhosBaixos + 1
                        end
                    end)

                    -- Calcula o fluxo médio de elevação distribuído entre vizinhos
                    local fluxo = model.taxaElevacaoMar / vizinhosBaixos

                    -- Atualiza a célula atual
                    celula[attrAlt] = celula[attrAlt] + fluxo

                    -- Propaga o fluxo para os vizinhos baixos
                    forEachNeighbor(celula, function(vizinho)
                        if vizinho.past[attrAlt] <= altAtual then
                            vizinho[attrAlt] = vizinho[attrAlt] + fluxo

                            -- Se o vizinho ainda não está inundado, aplica a regra
                            if not ehMarOuInundado(vizinho.past[attrUso], usos_inundados) then
                                aplicarInundacao(vizinho, regras_inundacao, attrUso)
                            end
                        end
                    end)
                end
            end)
        end,

        -- ===========================================================
        -- INICIALIZAÇÃO DO MODELO
        -- ===========================================================
        init = function(model)
            model.timer = Timer { Event { action = model } }
        end
    }
end
