
function ehMarOuInundado(uso, usos_inundados)
    -- usos_inundados é uma tabela onde a chave é o uso e o valor true
    return usos_inundados[uso] == true
end


function Mangue (espacoCelular,USOS, usos_inundados, REGRAS_INUNDACAO) 
    
    return   Model {
    start = 1,
    finalTime = 100,

    areaCelula = 0.09,
    alturaMare = 6, -- altura da maré (Ferreira, 1988)
    taxaElevacaoMar = 0.5,
    --taxaElevacaoMar = 0.011,  -- Taxa de elevação do nível do mar (IPCC, 2013)

    init = function(modelo)

        --inicializarAreas(modelo)



        modelo.timer = Timer {
            Event {
                action = function(evento)
                    local tempo = evento:getTime()
                    
                        ---------------------------------------------------------
                        -- DINÂMICA DO MANGUE
                        ----------------------------------
                    local nivelMar = tempo * modelo.taxaElevacaoMar
                    local nivelMar_mm = nivelMar * 1000
                    local taxaAcrecao_mm = 1.693 + (0.939 * nivelMar_mm)
                    local taxaAcrecao_m = taxaAcrecao_mm / 1000
                     zonaInfluencia = modelo.alturaMare + nivelMar

                    

                    forEachCell(espacoCelular, function(celula)
          
                        
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
                            and not ehMarOuInundado(celula.Usos,usos_inundados) then
                            -- Duvida: posso somar direto a acreacao_m se ela é um valor acumulado?
                            --celula.Alt2 = celula.Alt2 + taxaAcrecao_m
                        end
                        
                    end)

                    --espacoCelular:synchronize()
                    print("ITERAÇÃO:", tempo, nivelMar, zonaInfluencia)

                end
            },


        }
    end
}

end