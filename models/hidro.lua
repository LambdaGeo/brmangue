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
-- @param nomeAtributoUso: nome do atributo de uso da célula (ex: "Usos")
function aplicarInundacao(celula, regras, nomeAtributoUso)
    local usoAtual = celula.past[nomeAtributoUso]
    if regras[usoAtual] then
        celula[nomeAtributoUso] = regras[usoAtual]
    end
end


-- ===============================================================
-- MODELO DE HIDROLOGIA (Hidro)
-- ===============================================================
-- Este modelo simula os impactos da elevação do nível do mar sobre a altimetria e uso da terra.
-- Os parâmetros nomeAtributoUso e nomeAtributoAltimetria permitem generalizar o modelo
-- para diferentes estruturas de dados no espaço celular.
--
-- @param cs: espaço celular
-- @param usos_inundados: tabela de usos considerados inundados
-- @param regras_inundacao: regras de transformação de uso (uso -> uso_inundado)
-- @param nomeAtributoUso: nome do atributo de uso da célula (ex: "Usos")
-- @param nomeAtributoAltimetria: nome do atributo de altimetria (ex: "Alt2")
function Hidro(cs, usos_inundados, regras_inundacao, nomeAtributoUso, nomeAtributoAltimetria)

    return Model {
        start = 1,
        finalTime = 100,  -- duração da simulação (em passos de tempo)
        taxaElevacaoMar = 0.011,  -- taxa média anual (m/ano) — IPCC, 2013

        -- ===========================================================
        -- FUNÇÃO DE EXECUÇÃO (executada a cada passo da simulação)
        -- ===========================================================
        execute = function(model, event)
            local tempo = event:getTime()

            -----------------------------------------------------------
            -- Validação dos parâmetros de atributos
            -----------------------------------------------------------
            if not nomeAtributoUso or nomeAtributoUso == "" then
                error("Parâmetro 'nomeAtributoUso' não informado. Informe o nome do atributo de uso.")
            end
            if not nomeAtributoAltimetria or nomeAtributoAltimetria == "" then
                error("Parâmetro 'nomeAtributoAltimetria' não informado. Informe o nome do atributo de altimetria.")
            end

            local primeiraCelula = cs.cells[1]
            if primeiraCelula.past[nomeAtributoUso] == nil then
                error("Atributo '" .. nomeAtributoUso .. "' não existe no espaço celular.")
            end
            if primeiraCelula.past[nomeAtributoAltimetria] == nil then
                error("Atributo '" .. nomeAtributoAltimetria .. "' não existe no espaço celular.")
            end

            -----------------------------------------------------------
            -- Dinâmica hidrológica: elevação e propagação da inundação
            -----------------------------------------------------------
            forEachCell(cs, function(celula)
                local usoAtual = celula.past[nomeAtributoUso]
                local altAtual = celula.past[nomeAtributoAltimetria]

                -- Se for mar ou uso inundado e altitude válida
                if ehMarOuInundado(usoAtual, usos_inundados) and altAtual >= 0 then
                    local vizinhosBaixos = 1 -- inclui a célula atual

                    -- Conta vizinhos com altitude menor ou igual
                    forEachNeighbor(celula, function(vizinho)
                        if vizinho.past[nomeAtributoAltimetria] <= altAtual then
                            vizinhosBaixos = vizinhosBaixos + 1
                        end
                    end)

                    -- Calcula o fluxo médio de elevação distribuído entre vizinhos
                    local fluxo = model.taxaElevacaoMar / vizinhosBaixos

                    -- Atualiza a célula atual
                    celula[nomeAtributoAltimetria] = celula[nomeAtributoAltimetria] + fluxo

                    -- Propaga o fluxo para os vizinhos baixos
                    forEachNeighbor(celula, function(vizinho)
                        if vizinho.past[nomeAtributoAltimetria] <= altAtual then
                            vizinho[nomeAtributoAltimetria] = vizinho[nomeAtributoAltimetria] + fluxo

                            -- Se o vizinho ainda não está inundado, aplica a regra
                            if not ehMarOuInundado(vizinho.past[nomeAtributoUso], usos_inundados) then
                                aplicarInundacao(vizinho, regras_inundacao, nomeAtributoUso)
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
