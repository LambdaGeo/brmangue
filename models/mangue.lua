
function ehMarOuInundado(uso, usos_inundados)
    -- usos_inundados é uma tabela onde a chave é o uso e o valor true
    return usos_inundados[uso] == true
end


function Mangue(espacoCelular, tabela_usos)
    return Model {
        start = 1,
        finalTime = 100,

        areaCelula = 0.09,
        alturaMare = 6,        -- altura da maré (Ferreira, 1988)
        taxaElevacaoMar = 0.5, -- ou 0.011 (IPCC, 2013)

        execute = function(modelo, event)
            local tempo = event:getTime()

            ---------------------------------------------------------
            -- DINÂMICA DO MANGUE
            ---------------------------------------------------------
            local nivelMar = tempo * modelo.taxaElevacaoMar
            local nivelMar_mm = nivelMar * 1000
            local taxaAcrecao_mm = 1.693 + (0.939 * nivelMar_mm)
            local taxaAcrecao_m = taxaAcrecao_mm / 1000
            local zonaInfluencia = modelo.alturaMare + nivelMar

            forEachCell(espacoCelular, function(celula)

                ---------------------------------------------------------
                -- MIGRAÇÃO DE SOLOS
                ---------------------------------------------------------
                if celula.past.ClaseSolos == tabela_usos.MANGUE.valor
                    or celula.past.ClaseSolos == tabela_usos.MANGUE_MIGRADO.valor
                    or celula.past.ClaseSolos == tabela_usos.MAR.valor then

                    forEachNeighbor(celula, function(vizinho)
                        if (vizinho.Usos == tabela_usos.VEGETACAO_TERRESTRE.valor
                            or vizinho.Usos == tabela_usos.SOLO_DESCOBERTO.valor)
                            and vizinho.ClaseSolos ~= tabela_usos.MANGUE.valor
                            and vizinho.Alt2 <= zonaInfluencia then
                            vizinho.ClaseSolos = tabela_usos.MANGUE_MIGRADO.valor
                        end
                    end)
                end

                ---------------------------------------------------------
                -- MIGRAÇÃO DE USOS
                ---------------------------------------------------------
                if celula.past.Usos == tabela_usos.MANGUE.valor
                    or celula.past.Usos == tabela_usos.MANGUE_MIGRADO.valor then

                    forEachNeighbor(celula, function(vizinho)
                        if (vizinho.Usos == tabela_usos.VEGETACAO_TERRESTRE.valor
                            or vizinho.Usos == tabela_usos.SOLO_DESCOBERTO.valor)
                            and vizinho.Alt2 <= zonaInfluencia
                            and (vizinho.ClaseSolos == tabela_usos.MANGUE_MIGRADO.valor
                                or vizinho.ClaseSolos == tabela_usos.MANGUE.valor) then
                            vizinho.Usos = tabela_usos.MANGUE_MIGRADO.valor
                        end
                    end)
                end

                ---------------------------------------------------------
                -- ACREÇÃO VERTICAL DA LAMA
                ---------------------------------------------------------
                if (celula.ClaseSolos == tabela_usos.MANGUE.valor
                    or celula.ClaseSolos == tabela_usos.MANGUE_MIGRADO.valor)
                    and celula.Usos ~= tabela_usos.MAR.valor
                    and celula.Usos ~= tabela_usos.MANGUE_INUNDADO.valor then
                    -- celula.Alt2 = celula.Alt2 + taxaAcrecao_m
                end
            end)

            print("ITERAÇÃO:", tempo, nivelMar, zonaInfluencia)
        end,

        init = function(model)
            model.timer = Timer { Event { action = model } }
        end
    }
end
