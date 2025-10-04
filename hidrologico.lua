-- IMPACTOS DA ELEVAÇÃO DO NÍVEL DO MAR EM ECOSSISTEMAS DE MANGUE
-- ESTUDO DE CASO: REENTRÂNCIAS MARANHENSES
-- AUTOR: Denilson da Silva Bezerra
-- REVISADO E REESTRUTURADO POR: Sergio Souza Costa

-- ===============================================================
-- IMPORTAÇÃO DE BIBLIOTECAS
-- ===============================================================
import("gis")

-- ===============================================================
-- CONSTANTES - CLASSES DE USO DA TERRA
-- ===============================================================
USO_MANGUE = 1
USO_VEGETACAO_TERRESTRE = 2
USO_MAR = 3
USO_AREA_ANTROPIZADA = 4
USO_SOLO_DESCOBERTO = 5
USO_SOLO_INUNDADO = 6
USO_AREA_ANTROPIZADA_INUNDADA = 7
USO_MANGUE_MIGRADO = 8
USO_MANGUE_INUNDADO = 9
USO_VEGETACAO_TERRESTRE_INUNDADA = 10

-- ===============================================================
-- CONSTANTES - CLASSES DE SOLO
-- ===============================================================
SOLO_MANGUE = 3
SOLO_MANGUE_MIGRADO = 9
SOLO_CANAL_FLUVIAL = 0

-- ===============================================================
-- MAPEAMENTO DE CLASSES DE USO PARA CAMPOS DO MODELO
-- ===============================================================
mapa_uso_campo = {
    [USO_MAR] = "areaMar",
    [USO_MANGUE] = "areaMangueRemanescente",
    [USO_MANGUE_INUNDADO] = "areaMangueInundado",
    [USO_MANGUE_MIGRADO] = "areaMangueMigrado",
    [USO_AREA_ANTROPIZADA] = "areaAntropizada",
    [USO_AREA_ANTROPIZADA_INUNDADA] = "areaAntropizadaInundada",
    [USO_SOLO_DESCOBERTO] = "areaSoloDescoberto",
    [USO_SOLO_INUNDADO] = "areaSoloInundado",
    [USO_VEGETACAO_TERRESTRE] = "areaVegetacao",
    [USO_VEGETACAO_TERRESTRE_INUNDADA] = "areaVegetacaoInundada"
}



function calcularAltMedia (modelo, espacoCelular)
    
    local conta = 0
    local somaArea = 0

    forEachCell(espacoCelular, function(celula)
        somaArea = somaArea + celula.Alt2
        conta = conta + 1
    end)

    modelo.altmedia = somaArea / conta

end



-- ===============================================================
-- CARREGAMENTO DO PROJETO E ESPAÇO CELULAR
-- ===============================================================
local projeto = Project {
    file = "recorte.qgs",
    --cell_usos = "data/anil/elevacao_pol.shp",
    cell_usos = "data/teste1/Recorte_Teste.shp",
    clean = true
}

local espacoCelular = CellularSpace {
    project = projeto,
    layer = "cell_usos",
    xy = { "Col", "Lin" },
    select = { "ClaseSolos", "Alt2", "Usos" }
}

espacoCelular:createNeighborhood { strategy = "moore", self = false }
espacoCelular:synchronize()

-- apagar
forEachCell(espacoCelular, function(celula)
            celula.Alt2 = 0
end)


-- ===============================================================
-- MODELO PRINCIPAL
-- ===============================================================
ModeloMangue = Model {
    start = 1,
    finalTime = 10,

    taxaElevacaoMar = 0.5,
    --taxaElevacaoMar = 0.011,  -- Taxa de elevação do nível do mar (IPCC, 2013)
    altmedia = 0,

    init = function(modelo)
        

        modelo.grafico = Chart{
            target = modelo,
            select = {

                "altmedia",
            }
        }


        modelo.timer = Timer {
            Event {
                action = function(evento)
                    local tempo = evento:getTime()


                    forEachCell(espacoCelular, function(celula)
                        -- AUMENTO DE NÍVEL DO MAR
                        
                            local vizinhosBaixos = 1 -- inclui ele mesmo

                            forEachNeighbor(celula, function(vizinho)
                                if vizinho.past.Alt2 < celula.past.Alt2 then
                                    vizinhosBaixos = vizinhosBaixos + 1
                                end
                            end)
                            --print("VIZINHOS BAIXOS:", vizinhosBaixos)
                            local fluxo = modelo.taxaElevacaoMar / vizinhosBaixos


                            forEachNeighbor(celula, function(vizinho)
                                if vizinho.past.Alt2 < celula.past.Alt2 then
                                    vizinho.Alt2 = vizinho.Alt2 + fluxo
                                end
                            end)
                            
                            celula.Alt2 = celula.Alt2 + fluxo 
                            

                        
                    end)

                    espacoCelular:synchronize()

                    calcularAltMedia(modelo, espacoCelular)
                    print(tempo + 2012, modelo.altmedia)
                    
                end
            },


            Event {
                start = modelo.start + 1,
                action = modelo.grafico
            }
        }
    end
}

ModeloMangue:run()
