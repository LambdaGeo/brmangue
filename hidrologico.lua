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

-- ===============================================================
-- FUNÇÕES DE INICIALIZAÇÃO E CONTAGEM
-- ===============================================================
function inicializarAreas(modelo)
    for _, campo in pairs(mapa_uso_campo) do
        modelo[campo] = 0
    end


end

function contarUsoDaTerra(modelo, espacoCelular, areaCelula)
    inicializarAreas(modelo)

    local conta = 0

    forEachCell(espacoCelular, function(celula)
        local campo = mapa_uso_campo[celula.Usos]
        if campo then
            modelo[campo] = modelo[campo] + areaCelula
        end

        conta = conta + 1
        modelo.altmedia = modelo.altmedia + celula.Alt2
    end)

    modelo.altmedia = modelo.altmedia / conta

    modelo.areaTotal = 0
    for _, campo in pairs(mapa_uso_campo) do
        modelo.areaTotal = modelo.areaTotal + (modelo[campo] or 0)
    end
end

-- ===============================================================
-- FUNÇÕES AUXILIARES
-- ===============================================================
function ehMarOuInundado(uso)
    return uso == USO_MAR
        or uso == USO_SOLO_INUNDADO
        or uso == USO_AREA_ANTROPIZADA_INUNDADA
        or uso == USO_MANGUE_INUNDADO
        or uso == USO_VEGETACAO_TERRESTRE_INUNDADA
end

function aplicarInundacao(celula)
    local usoAtual = celula.past.Usos
    if usoAtual == USO_MANGUE then
        celula.Usos = USO_MANGUE_INUNDADO
    elseif usoAtual == USO_VEGETACAO_TERRESTRE then
        celula.Usos = USO_VEGETACAO_TERRESTRE_INUNDADA
    elseif usoAtual == USO_AREA_ANTROPIZADA then
        celula.Usos = USO_AREA_ANTROPIZADA_INUNDADA
    elseif usoAtual == USO_SOLO_DESCOBERTO then
        celula.Usos = USO_SOLO_INUNDADO
    end
end

-- ===============================================================
-- FUNÇÃO DE VISUALIZAÇÃO DOS MAPAS
-- ===============================================================
function mapaUso(espacoCelular)
    return Map {
        target = espacoCelular,
        select = "Usos",
        value = {
            USO_MANGUE,
            USO_VEGETACAO_TERRESTRE,
            USO_MAR,
            USO_AREA_ANTROPIZADA,
            USO_SOLO_DESCOBERTO,
            USO_SOLO_INUNDADO,
            USO_AREA_ANTROPIZADA_INUNDADA,
            USO_MANGUE_MIGRADO,
            USO_MANGUE_INUNDADO,
            USO_VEGETACAO_TERRESTRE_INUNDADA
        },
        color = {
            { 0,   100, 0 },
            { 128, 128, 0 },
            { 0,   0,   139 },
            { 255, 215, 0 },
            { 255, 222, 173 },
            { 0,   0,   0 },
            { 0,   0,   0 },
            { 0,   255, 0 },
            { 255, 0,   0 },
            { 0,   0,   0 }
        },
        label = {
            "Mangue",
            "Vegetação Terrestre",
            "Mar",
            "Área Antropizada",
            "Solo Descoberto",
            "Solo Descoberto Inundado",
            "Área Antropizada Inundada",
            "Mangue Migrado",
            "Mangue Inundado",
            "Vegetação Terrestre Inundada"
        }
    }
end

function mapaAltitude(espacoCelular)
    return Map {
        target = espacoCelular,
        select = "Alt2",
        color = "RdYlGn",
        slices = 5,
        size = 1
    }
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

    init = function(modelo)

        modelo.altmedia = 0
        

        modelo.grafico = Chart{
            target = modelo,
            select = {
                --"areaVegetacao",
                ---"areaVegetacaoInundada",
                --"areaMangueMigrado"
                "altmedia",
            }
        }

        --modelo.mapaAltitude = mapaAltitude(espacoCelular)
        modelo.mapaUso = mapaUso(espacoCelular)

        modelo.timer = Timer {
            Event {
                action = function(evento)
                    local tempo = evento:getTime()
                    --print("ITERAÇÃO:", tempo, modelo.altmedia)

                    ----- AUMENTO DE NÍVEL DO MAR
                    local nivelMar = tempo * modelo.taxaElevacaoMar
                    -- no modelo de 2014: Increased_see = cell.Alt2 + (time * Tx_elev) 
                    --- Pergunta: na tese tem esses valor por iteracao, se assumir todas celulas zero, entao nao precisa estar dentro do loop de celulas
                    
                    local nivelMar_mm = nivelMar * 1000
                    local taxaAcrecao_mm = 1.693 + (0.939 * nivelMar_mm)
                    local taxaAcrecao_m = taxaAcrecao_mm / 1000

                    --print (tempo+2012,nivelMar)
                    io.write(tempo + 2012, "\t", nivelMar, "\t")

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

                            --celula.Alt2 = celula.Alt2 + modelo.taxaElevacaoMar                            

                            forEachNeighbor(celula, function(vizinho)
                                if vizinho.past.Alt2 < celula.past.Alt2 then
                                    vizinho.Alt2 = vizinho.Alt2 + fluxo
                                end
                            end)
                            
                            celula.Alt2 = celula.Alt2 + fluxo
                            

                        
                    end)

                    espacoCelular:synchronize()
                    
                end
            },

            --Event { action = modelo.mapaAltitude },
            Event { action = modelo.mapaUso },

            Event {
                action = function(evento)
                    contarUsoDaTerra(modelo, espacoCelular, modelo.areaCelula)

                    print ( modelo.altmedia)
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
