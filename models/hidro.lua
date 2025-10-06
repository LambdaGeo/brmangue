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
-- @param nomeAtributoUso: string com o nome do atributo de uso da célula
function aplicarInundacao(celula, regras, nomeAtributoUso)
    local usoAtual = celula.past[nomeAtributoUso]
    if regras[usoAtual] then
        celula[nomeAtributoUso] = regras[usoAtual]
    end
end

-- ===============================================================
-- MODELO HIDROLOGIA (Hidro)
-- ===============================================================
-- @param cs: espaço celular
-- @param usos_inundados: tabela de usos que podem ser inundados
-- @param regras_inundacao: regras de transformação de uso em inundado
-- @param nomeAtributoUso: string com o nome do atributo de uso da célula
function Hidro(cs, usos_inundados, regras_inundacao, nomeAtributoUso) 

    return Model {
        start = 1,
        finalTime = 100,  -- Duração da simulação em passos de tempo

        taxaElevacaoMar = 0.011, -- Taxa de elevação do nível do mar (IPCC, 2013)

        

        -- ===========================================================
        -- FUNÇÃO DE EXECUÇÃO (executada a cada passo do tempo)
        -- ===========================================================
        execute = function(model, event)
            local tempo = event:getTime()

            -- ===============================================================
            -- Checa se o parâmetro nomeAtributoUso foi informado
            -- ===============================================================
            if nomeAtributoUso == nil or nomeAtributoUso == "" then
                error("Parâmetro 'nomeAtributoUso' não informado. Informe o nome do atributo de uso da célula.")
            end

            local primeiraCelula = cs.cells[1]  -- supondo que cs seja uma grade 2D
            
            if primeiraCelula.past[nomeAtributoUso] == nil then
                error("Atributo '" .. nomeAtributoUso .. "' não existe no espaço celular. Verifique o nome do atributo.")
            end

            forEachCell(cs, function(celula)
                -- Verifica se a célula é mar ou já está inundada e se Alt2 >= 0
                if ehMarOuInundado(celula.past[nomeAtributoUso], usos_inundados) and celula.past.Alt2 >= 0 then
                    local vizinhosBaixos = 1 -- inclui a própria célula

                    -- Conta quantos vizinhos têm altitude menor ou igual
                    forEachNeighbor(celula, function(vizinho)
                        if vizinho.past.Alt2 <= celula.past.Alt2 then
                            vizinhosBaixos = vizinhosBaixos + 1
                        end
                    end)

                    -- Calcula fluxo de água distribuído entre vizinhos baixos
                    local fluxo = model.taxaElevacaoMar / vizinhosBaixos

                    -- Atualiza a altitude da célula atual
                    celula.Alt2 = celula.Alt2 + fluxo

                    -- Propaga o fluxo para os vizinhos baixos
                    forEachNeighbor(celula, function(vizinho)
                        if vizinho.past.Alt2 <= celula.past.Alt2 then
                            vizinho.Alt2 = vizinho.Alt2 + fluxo

                            -- Aplica inundação caso o vizinho não seja mar/inundado
                            if not ehMarOuInundado(vizinho.past[nomeAtributoUso], usos_inundados) then
                                aplicarInundacao(vizinho, regras_inundacao, nomeAtributoUso)
                            end
                        end
                    end)

                end
            end)
        end,

        -- ===========================================================
        -- FUNÇÃO DE INICIALIZAÇÃO DO MODELO
        -- ===========================================================
        init = function(model)
            -- Cria o temporizador para acionar a função execute a cada passo
            model.timer = Timer { Event { action = model } }
        end
    }
end
