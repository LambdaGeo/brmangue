

function calcularAltMedia(espacoCelular)
    local conta = 0
    local somaArea = 0

    forEachCell(espacoCelular, function(celula)
        if ehMarOuInundado(celula.Usos) then
            somaArea = somaArea + celula.Alt2
            conta = conta + 1
        end
    end)

    return somaArea / conta
end


-- ===============================================================
-- MODELO PRINCIPAL
-- ===============================================================
function Hidro (cs) 
    
    return Model {
    start = 1,
    finalTime = 20,

    taxaElevacaoMar = 0.011, -- Taxa de elevação do nível do mar (IPCC, 2013)
    altmedia = 0,
    

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
        end)

        cs:synchronize()
        model.altmedia = calcularAltMedia(cs)


        print(tempo + 2012, model.altmedia)
    end,

    init = function(model)
        -- testar o aumento da altitude
        model.altmedia = calcularAltMedia(cs)

       print (cs, model.altmedia)

    end
}
end