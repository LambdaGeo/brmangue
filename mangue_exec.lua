-- IMPACTOS DA ELEVAÇÃO DO NÍVEL DO MAR EM ECOSSISTEMAS DE MANGUE
-- ESTUDO DE CASO: REENTRÂNCIAS MARANHENSES
-- AUTOR: Denilson da Silva Bezerra
-- REVISADO E REESTRUTURADO POR: Sergio Souza Costa

-- ===============================================================
-- IMPORTAÇÃO DE BIBLIOTECAS
-- ===============================================================
import("gis")

--require("models/mangue")
require("models/hidro")

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




function calcularAltMedia(espacoCelular)
    local conta = 0
    local somaArea = 0
    forEachCell(espacoCelular, function(celula)
  
            somaArea = somaArea + celula.Alt2
            conta = conta + 1

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



function mapaSolo(espacoCelular)
    return Map {
        target = espacoCelular,
        select = "ClaseSolos",
        value = {
            SOLO_CANAL_FLUVIAL,
            SOLO_MANGUE,
            SOLO_MANGUE_MIGRADO
            -- adicione aqui outras classes de solo que você tiver definido
        },
        color = {
            { 0,   0,   255 },   -- Canal Fluvial (azul)
            { 0,   100, 0 },     -- Mangue (verde escuro)
            { 34,  139, 34 }     -- Mangue Migrado (verde floresta)
        },
        label = {
            "Canal Fluvial",
            "Mangue",
            "Mangue Migrado"
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


---- novos parametros

local USOS = {
    MANGUE = 1,
    VEGETACAO_TERRESTRE = 2,
    MAR = 3,
    AREA_ANTROPIZADA = 4,
    SOLO_DESCOBERTO = 5,
    SOLO_INUNDADO = 6,
    AREA_ANTROPIZADA_INUNDADA = 7,
    MANGUE_MIGRADO = 8,
    MANGUE_INUNDADO = 9,
    VEGETACAO_TERRESTRE_INUNDADA = 10,
}

local usos_inundados = {
    [USOS.MAR] = true,
    [USOS.SOLO_INUNDADO] = true,
    [USOS.AREA_ANTROPIZADA_INUNDADA] = true,
    [USOS.MANGUE_INUNDADO] = true,
    [USOS.VEGETACAO_TERRESTRE_INUNDADA] = true
}

local REGRAS_INUNDACAO = {
    [USOS.MANGUE] = USOS.MANGUE_INUNDADO,
    [USOS.MANGUE_MIGRADO] = USOS.MANGUE_INUNDADO,
    [USOS.VEGETACAO_TERRESTRE] = USOS.VEGETACAO_TERRESTRE_INUNDADA,
    [USOS.AREA_ANTROPIZADA] = USOS.AREA_ANTROPIZADA_INUNDADA,
    [USOS.SOLO_DESCOBERTO] = USOS.SOLO_INUNDADO
}

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

espacoCelular:synchronize()





env = Environment {

    hidro = Hidro(espacoCelular, USOS, usos_inundados, REGRAS_INUNDACAO) { taxaElevacaoMar = 0.5 },
    --mangue = Mangue(espacoCelular, USOS, usos_inundados, REGRAS_INUNDACAO) { taxaElevacaoMar = 0.5 },

    altmedia = calcularAltMedia(espacoCelular),
    
}




mapaUso = mapaUso(espacoCelular)
mapaSolo = mapaSolo(espacoCelular)

env:add(Event { action = mapaUso })
env:add(Event { action = mapaSolo})

mapaAltitude = mapaAltitude(espacoCelular)
env:add(Event { action = mapaAltitude })



env:add(Event { action = function() espacoCelular:synchronize() end })

env:add(Event { action = function(event) 
    env.altmedia = calcularAltMedia(espacoCelular)
    print("Altura média do mar: ", event:getTime(), env.altmedia)

    end })

forEachCell(espacoCelular, function(celula)
        --celula.Alt2 = 0
        math.randomseed(os.time())

        local n = math.random(0, 5)
        --celula.Alt2 = n
        celula.Usos = USO_MAR
end)

env:add(Event { action = function()   print("Pressione ENTER para continuar...")  io.read() end })
env:run()


