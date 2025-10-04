




-- ===============================================================
-- MODELO PRINCIPAL
-- ===============================================================
function Hidro (cs) 
    
    return Model {
    start = 1,
    finalTime = 20,

    taxaElevacaoMar = 0.011, -- Taxa de elevação do nível do mar (IPCC, 2013)
 
    

    execute = function(model, event)
        local tempo = event:getTime()

        forEachCell(cs, function(celula)
            --if ehMarOuInundado(celula.past.Usos) and celula.past.Alt2 >= 0 then
                local vizinhosBaixos = 1 -- inclui ele mesmo

                forEachNeighbor(celula, function(vizinho)
                    if vizinho.past.Alt2 < celula.past.Alt2 then
                        vizinhosBaixos = vizinhosBaixos + 1
                    end
                end)

                
                local fluxo = model.taxaElevacaoMar  / vizinhosBaixos

                celula.Alt2 = celula.Alt2 + fluxo

                forEachNeighbor(celula, function(vizinho)
                    if vizinho.past.Alt2 < celula.past.Alt2 then
                        vizinho.Alt2 = vizinho.Alt2 + fluxo

                      --  if not ehMarOuInundado(vizinho.past.Usos) then
                         --   aplicarInundacao(vizinho)
                       -- end
                    end
                end)

                
            --end

            --cs:synchronize() 
        end)

   

    end,

    init = function(model)
        -- testar o aumento da altitude
        model.altmedia = calcularAltMedia(cs)

    end
}
end