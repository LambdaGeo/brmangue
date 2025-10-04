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
    elseif usoAtual == USO_MANGUE_MIGRADO then -- inclui nos testes
        celula.Usos = USO_MANGUE_INUNDADO
    elseif usoAtual == USO_VEGETACAO_TERRESTRE then
        celula.Usos = USO_VEGETACAO_TERRESTRE_INUNDADA
    elseif usoAtual == USO_AREA_ANTROPIZADA then
        celula.Usos = USO_AREA_ANTROPIZADA_INUNDADA
    elseif usoAtual == USO_SOLO_DESCOBERTO then
        celula.Usos = USO_SOLO_INUNDADO
    end
end

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
        slices = 10,
        size = 1
    }
end

-- ===============================================================
-- CARREGAMENTO DO PROJETO E ESPAÇO CELULAR
-- ===============================================================
local projeto = Project {
    file = "recorte.qgs",
    --cell_usos = "data/anil/elevacao_pol.shp",
    cell_usos = "data/teste_dinamica/Recorte_Teste.shp",
    clean = true
}

local espacoCelular = CellularSpace {
    project = projeto,
    layer = "cell_usos",
    xy = { "Col", "Lin" },
    select = { "ClaseSolos", "Alt2", "Usos" }
}

espacoCelular:createNeighborhood { strategy = "moore", self = false }





-- ===============================================================
-- MODELO PRINCIPAL
-- ===============================================================
Hidrologico = Model {
    start = 1,
    finalTime = 10,

    taxaElevacaoMar = 0.011, -- Taxa de elevação do nível do mar (IPCC, 2013)
    altmedia = calcularAltMedia(espacoCelular),

    execute = function(model, event)
        local tempo = event:getTime()

        forEachCell(espacoCelular, function(celula)
            if ehMarOuInundado(celula.past.Usos) and celula.past.Alt2 >= 0 then
                local vizinhosBaixos = 1 -- inclui ele mesmo

                forEachNeighbor(celula, function(vizinho)
                    if vizinho.past.Alt2 < (celula.past.Alt2 + model.taxaElevacaoMar) then
                        vizinhosBaixos = vizinhosBaixos + 1
                    end
                end)

                local fluxo = model.taxaElevacaoMar / vizinhosBaixos

                celula.Alt2 = celula.Alt2 + fluxo

                forEachNeighbor(celula, function(vizinho)
                    if vizinho.past.Alt2 < (celula.past.Alt2 + model.taxaElevacaoMar) then
                        vizinho.Alt2 = vizinho.Alt2 + fluxo

                        if not ehMarOuInundado(vizinho.past.Usos) then
                            aplicarInundacao(vizinho)
                        end
                    end
                end)

                
            end
        end)

        espacoCelular:synchronize()

        model.altmedia = calcularAltMedia(espacoCelular)
        print(tempo + 2012, model.altmedia)
    end,

    init = function(model)
        -- testar o aumento da altitude
        forEachCell(espacoCelular, function(celula)
            --celula.Alt2 = 0
            --celula.Usos = USO_MAR
        end)

        espacoCelular:synchronize()

        model.timer = Timer {
            Event { action = model },
        }
    end
}

env = Environment {

    Hidrologico { taxaElevacaoMar = 0.5 },

}

--clean()

chart = Chart {
    target = env,
    select = "altmedia"
}

env:add(Event { action = chart })

mapaUso = mapaUso(espacoCelular)
--mapaAltitude = mapaAltitude(espacoCelular)

env:add(Event { action = mapaUso })
--env:add(Event { action = mapaAltitude })


env:add(Event { action = function()
     print("Pressione ENTER para continuar...")
    io.read() -- aguarda o usuário digitar algo (ENTER já basta)
end })
env:run()
