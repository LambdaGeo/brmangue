
function ehMarOuInundado(uso, usos_inundados)
    -- usos_inundados é uma tabela onde a chave é o uso e o valor true
    return usos_inundados[uso] == true
end


function aplicarInundacao(celula, regras)
    local usoAtual = celula.past.Usos
    if regras[usoAtual] then
        celula.Usos = regras[usoAtual]
    end
end


-- ===============================================================
-- MODELO PRINCIPAL
-- ===============================================================
function Hidro (cs, USOS, usos_inundados, REGRAS_INUNDACAO) 
    
    return Model {
    start = 1,
    finalTime = 20,

    taxaElevacaoMar = 0.011, -- Taxa de elevação do nível do mar (IPCC, 2013)
 
    

    execute = function(model, event)
        local tempo = event:getTime()

        forEachCell(cs, function(celula)
            if ehMarOuInundado(celula.past.Usos, usos_inundados) and celula.past.Alt2 >= 0 then
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

                        if not ehMarOuInundado(vizinho.past.Usos, usos_inundados)  then
                            aplicarInundacao(vizinho, REGRAS_INUNDACAO)
                        end
                    end
                end)

                
            end

        end)
    end,

    init = function(model)
        

        model.timer = Timer {
            Event { action = model },
        }

    end
}
end