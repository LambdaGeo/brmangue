-- ===============================================================
-- IMPACTOS DA ELEVAÇÃO DO NÍVEL DO MAR EM ECOSSISTEMAS DE MANGUE
-- ESTUDO DE CASO: REENTRÂNCIAS MARANHENSES
-- AUTOR: Denilson da Silva Bezerra
-- REVISADO E REESTRUTURADO POR: Sergio Souza Costa
-- ===============================================================

-- ===============================================================
-- IMPORTAÇÃO DE BIBLIOTECAS
-- ===============================================================
import("gis")                 -- Biblioteca principal para GIS
require("models/mangue")      -- Modelo de dinâmica de mangue
require("models/hidro")       -- Modelo de hidrologia
require("models/utils")       -- Funções utilitárias
require("visualization/maps") -- Visualização e mapeamento

-- ===============================================================
-- DEFINIÇÃO DAS CLASSES DE USO DA TERRA
-- ===============================================================
tabela_usos = {
    MANGUE = { valor = 1, cor = {0, 100, 0}, nome = "Mangue" },
    VEGETACAO_TERRESTRE = { valor = 2, cor = {128, 128, 0}, nome = "Vegetação Terrestre" },
    MAR = { valor = 3, cor = {0, 0, 139}, nome = "Mar" },
    AREA_ANTROPIZADA = { valor = 4, cor = {255, 215, 0}, nome = "Área Antropizada" },
    SOLO_DESCOBERTO = { valor = 5, cor = {255, 222, 173}, nome = "Solo Descoberto" },
    SOLO_INUNDADO = { valor = 6, cor = {0, 0, 0}, nome = "Solo Inundado" },
    AREA_ANTROPIZADA_INUNDADA = { valor = 7, cor = {50, 50, 50}, nome = "Área Antropizada Inundada" },
    MANGUE_MIGRADO = { valor = 8, cor = {0, 255, 0}, nome = "Mangue Migrado" },
    MANGUE_INUNDADO = { valor = 9, cor = {255, 0, 0}, nome = "Mangue Inundado" },
    VEGETACAO_TERRESTRE_INUNDADA = { valor = 10, cor = {0, 0, 0}, nome = "Vegetação Terrestre Inundada" }
}

-- ===============================================================
-- DEFINIÇÃO DE USOS INUNDADOS
-- ===============================================================
-- Tabela para identificar rapidamente quais usos da terra são afetados por inundação
local usos_inundados = {
    [tabela_usos.MAR.valor] = true,
    [tabela_usos.SOLO_INUNDADO.valor] = true,
    [tabela_usos.AREA_ANTROPIZADA_INUNDADA.valor] = true,
    [tabela_usos.MANGUE_INUNDADO.valor] = true,
    [tabela_usos.VEGETACAO_TERRESTRE_INUNDADA.valor] = true
}

-- ===============================================================
-- REGRAS DE INUNDAÇÃO
-- ===============================================================
-- Define a transformação de um uso da terra para seu estado inundado correspondente
local regras_inundacao = {
    [tabela_usos.MANGUE.valor] = tabela_usos.MANGUE_INUNDADO.valor,
    [tabela_usos.MANGUE_MIGRADO.valor] = tabela_usos.MANGUE_INUNDADO.valor,
    [tabela_usos.VEGETACAO_TERRESTRE.valor] = tabela_usos.VEGETACAO_TERRESTRE_INUNDADA.valor,
    [tabela_usos.AREA_ANTROPIZADA.valor] = tabela_usos.AREA_ANTROPIZADA_INUNDADA.valor,
    [tabela_usos.SOLO_DESCOBERTO.valor] = tabela_usos.SOLO_INUNDADO.valor
}

-- ===============================================================
-- DEFINIÇÃO DE TIPOS DE SOLO
-- ===============================================================
tabela_solos = {
    CANAL_FLUVIAL = { valor = 0, cor = {0,0,255}, nome = "Canal Fluvial" },
    MANGUE = { valor = 3, cor = {0,100,0}, nome = "Mangue" },
    MANGUE_MIGRADO = { valor = 9, cor = {34,139,34}, nome = "Mangue Migrado" }
}

-- ===============================================================
-- CONFIGURAÇÃO DOS PARÂMETROS DE MIGRAÇÃO DE SOLOS
-- ===============================================================
local regrasMigracao = {
    origens = {
        [tabela_solos.MANGUE.valor] = true,
        [tabela_solos.MANGUE_MIGRADO.valor] = true,
        [tabela_solos.CANAL_FLUVIAL.valor] = true
    },
    alvos = {
        [tabela_usos.VEGETACAO_TERRESTRE.valor] = true,
        [tabela_usos.SOLO_DESCOBERTO.valor] = true
    },
    soloDestino = tabela_solos.MANGUE_MIGRADO.valor
}

-- ===============================================================
-- PARÂMETROS DA REGRA DE MIGRAÇÃO DE USOS (MANGUE)
-- ===============================================================
local regrasMigracaoUsos = {
    origens = {
        [tabela_usos.MANGUE.valor] = true,
        [tabela_usos.MANGUE_MIGRADO.valor] = true
    },
    alvos = {
        [tabela_usos.VEGETACAO_TERRESTRE.valor] = true,
        [tabela_usos.SOLO_DESCOBERTO.valor] = true
    },
    condSolos = {
        [tabela_solos.MANGUE.valor] = true,
        [tabela_solos.MANGUE_MIGRADO.valor] = true
    },
    usoDestino = tabela_usos.MANGUE_MIGRADO.valor
}

-- ===============================================================
-- PARÂMETROS DA REGRA DE ACREÇÃO VERTICAL
-- ===============================================================
local regrasAcrecao = {
    solosPermitidos = {
        [tabela_solos.MANGUE.valor] = true,
        [tabela_solos.MANGUE_MIGRADO.valor] = true
    },
    usosProibidos = {
        [tabela_usos.MAR.valor] = true,
        [tabela_usos.SOLO_INUNDADO.valor] = true,
        [tabela_usos.AREA_ANTROPIZADA_INUNDADA.valor] = true,
        [tabela_usos.MANGUE_INUNDADO.valor] = true,
        [tabela_usos.VEGETACAO_TERRESTRE_INUNDADA.valor] = true
    }
}

-- ===============================================================
-- CARREGAMENTO DO PROJETO E ESPAÇO CELULAR
-- ===============================================================
local projeto = Project {
    file = "recorte.qgs",
    cell_usos = "data/teste_dinamica/Recorte_Teste.shp",
    clean = true
}

-- Criação do espaço celular
local espacoCelular = CellularSpace {
    project = projeto,
    layer = "cell_usos",
    xy = { "Col", "Lin" },
    select = { "ClaseSolos", "Alt2", "Usos" }
}

-- Criação da vizinhança de Moore e sincronização inicial
espacoCelular:createNeighborhood { strategy = "moore", self = false }
espacoCelular:synchronize()

-- ===============================================================
-- AMBIENTE DE SIMULAÇÃO
-- ===============================================================
env = Environment {
    -- Modelos que compõem o ambiente
    hidro = Hidro(espacoCelular, usos_inundados, regras_inundacao, "Usos", "Alt2") { taxaElevacaoMar = 0.5 },
    --mangue = Mangue(espacoCelular, tabela_usos, tabela_solos, usos_inundados, 
    --                regrasMigracao, regrasMigracaoUsos, regrasAcrecao) { taxaElevacaoMar = 0.5 },

    -- Cálculo inicial de altitude média das células
    CalcularAltitudeMedia(espacoCelular){}
}

-- ===============================================================
-- MAPAS E VISUALIZAÇÃO
-- ===============================================================
mapaUso = mapaUso(espacoCelular, tabela_usos, "Usos")
env:add(Event { action = mapaUso })

mapaSolo = mapaSolo(espacoCelular, tabela_solos, "ClaseSolos")
env:add(Event { action = mapaSolo })

mapaAltitude = mapaAltitude(espacoCelular)
env:add(Event { action = mapaAltitude })

-- Sincronização periódica do espaço celular
env:add(Event { action = function() espacoCelular:synchronize() end })


-- ===============================================================
-- EXECUÇÃO DA SIMULAÇÃO
-- ===============================================================
--env:add(Event { action = function() print("Pressione ENTER para continuar...") io.read() end })
env:run()
