
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
function Hidro (cs, usos_inundados, regras_inundacao) 


    
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
                    if vizinho.past.Alt2 <= celula.past.Alt2  then -- <= para testar a distribuicao
                        vizinhosBaixos = vizinhosBaixos + 1
                    end
                end)

                
                local fluxo = model.taxaElevacaoMar  / vizinhosBaixos

                celula.Alt2 = celula.Alt2 + fluxo

                --print (vizinhosBaixos)

                forEachNeighbor(celula, function(vizinho)
                    if vizinho.past.Alt2 <= celula.past.Alt2   then
                        vizinho.Alt2 = vizinho.Alt2 + fluxo

                        if not ehMarOuInundado(vizinho.past.Usos, usos_inundados)  then
                            aplicarInundacao(vizinho, regras_inundacao)
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