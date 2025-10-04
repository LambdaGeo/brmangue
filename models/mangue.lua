function Mangue (espacoCelular) 
    
    return   Model {
    start = 1,
    finalTime = 100,

    areaCelula = 0.09,
    alturaMare = 6, -- altura da maré (Ferreira, 1988)
    taxaElevacaoMar = 0.5,
    --taxaElevacaoMar = 0.011,  -- Taxa de elevação do nível do mar (IPCC, 2013)

    init = function(modelo)

        --inicializarAreas(modelo)

        print ("oi")

        modelo.timer = Timer {
            Event {
                action = function(evento)
                    local tempo = evento:getTime()
                    
                    local nivelMar = 0
                    local zonaInfluencia = modelo.alturaMare 

                    forEachCell(espacoCelular, function(celula)
                        -- AUMENTO DE NÍVEL DO MAR
                        if ehMarOuInundado(celula.past.Usos) and celula.past.Alt2 >= 0 then
                            local vizinhosBaixos = 1

                            forEachNeighbor(celula, function(vizinho)
                                if vizinho.past.Alt2 < celula.past.Alt2 then
                                    vizinhosBaixos = vizinhosBaixos + 1
                                end
                            end)

                            local fluxo = modelo.taxaElevacaoMar / vizinhosBaixos
                            celula.Alt2 = celula.Alt2 + fluxo

                            forEachNeighbor(celula, function(vizinho)
                                if vizinho.past.Alt2 < celula.past.Alt2 then
                                    vizinho.Alt2 = vizinho.Alt2 + fluxo

                                    if not ehMarOuInundado(vizinho.past.Usos) then
                                        aplicarInundacao(vizinho)
                                    end
                                end
                            end)
                        end
                        ---------------------------------------------------------
                        -- DINÂMICA DO MANGUE
                        ----------------------------------
                        --local nivelMar = tempo * modelo.taxaElevacaoMar
                        nivelMar = tempo * modelo.taxaElevacaoMar
                        local nivelMar_mm = nivelMar * 1000
                        local taxaAcrecao_mm = 1.693 + (0.939 * nivelMar_mm)
                        local taxaAcrecao_m = taxaAcrecao_mm / 1000
                        zonaInfluencia = modelo.alturaMare + nivelMar

                        
                        -- acho que faltou aqui olhar para o mangue migrado 
                        -- if celula.ClaseSolos == SOLO_MANGUE  or  celula.ClaseSolos == SOLO_MANGUE_MIGRADO  or  celula.ClaseSolos == SOLO_CANAL_FLUVIAL then
                        -- e ter cuidado com o past
                        if celula.past.ClaseSolos == SOLO_MANGUE or  celula.past.ClaseSolos == SOLO_MANGUE_MIGRADO  or celula.past.ClaseSolos == SOLO_CANAL_FLUVIAL then
                        --if celula.ClaseSolos == SOLO_MANGUE or celula.ClaseSolos == SOLO_CANAL_FLUVIAL then
                            forEachNeighbor(celula, function(vizinho)
                                if (vizinho.Usos == USO_VEGETACAO_TERRESTRE or vizinho.Usos == USO_SOLO_DESCOBERTO)
                                    and vizinho.ClaseSolos ~= SOLO_MANGUE
                                    and vizinho.Alt2 <= zonaInfluencia then
                                    vizinho.ClaseSolos = SOLO_MANGUE_MIGRADO
                                    print ("hhhh")
                                end
                            end)
                        end


                        --if celula.Usos == USO_MANGUE then
                        if celula.past.Usos == USO_MANGUE or celula.past.Usos == USO_MANGUE_MIGRADO then
                            forEachNeighbor(celula, function(vizinho)
                                if (vizinho.Usos == USO_VEGETACAO_TERRESTRE or vizinho.Usos == USO_SOLO_DESCOBERTO)
                                    and vizinho.Alt2 <= zonaInfluencia
                                    and (vizinho.ClaseSolos == SOLO_MANGUE_MIGRADO or vizinho.ClaseSolos == SOLO_MANGUE) then
                                    vizinho.Usos = USO_MANGUE_MIGRADO
                                end
                            end)
                        end

                        -- ACREÇÃO VERTICAL DA LAMA
                        if (celula.ClaseSolos == SOLO_MANGUE or celula.ClaseSolos == SOLO_MANGUE_MIGRADO)
                            and not ehMarOuInundado(celula.Usos) then
                            -- Duvida: posso somar direto a acreacao_m se ela é um valor acumulado?
                            --celula.Alt2 = celula.Alt2 + taxaAcrecao_m
                        end
                        
                    end)

                    --espacoCelular:synchronize()
                    print("ITERAÇÃO:", tempo, nivelMar, zonaInfluencia)

                   -- print("Pressione ENTER para continuar...")
                    --io.read() -- aguarda o usuário digitar algo (ENTER já basta)
                end
            },

            --Event { action = modelo.mapaAltitude },
            --Event { action = modelo.mapaUso },
            --Event { action = modelo.mapaSolo },

            Event {
                action = function(evento)
                    --contarUsoDaTerra(modelo, espacoCelular, modelo.areaCelula)
                end
            },


        }
    end
}

end