-- ===============================================================
-- IMPACTOS DA ELEVAÇÃO DO NÍVEL DO MAR EM ECOSSISTEMAS DE MANGUE
-- ESTUDO DE CASO: REENTRÂNCIAS MARANHENSES
-- AUTOR: Denilson da Silva Bezerra
-- REVISADO E REESTRUTURADO POR: Sergio Souza Costa
-- ===============================================================


-- ===============================================================
-- IMPORTAÇÃO DE BIBLIOTECAS
-- ===============================================================
import("gis")                 -- Biblioteca principal para operações GIS
require("models/mangue")      -- Modelo de dinâmica de mangue
require("models/hidro")       -- Modelo de hidrologia
require("models/utils")       -- Funções utilitárias auxiliares
require("visualization/maps") -- Módulo de visualização e mapeamento



-- ===============================================================
-- DEFINIÇÃO DOS NOMES DOS ATRIBUTOS
-- ===============================================================
-- Define os nomes dos campos presentes no shapefile que serão usados
local nomes_atributos = {
    uso  = "Uso",
    solo = "Solo",
    alt  = "Altitude"
}



-- ===============================================================
-- CLASSES DE USO DA TERRA
-- ===============================================================
tabela_usos = {
    MANGUE                        = { valor = 1,  cor = {0, 100, 0},      nome = "Mangue" },
    VEGETACAO_TERRESTRE           = { valor = 2,  cor = {128, 128, 0},    nome = "Vegetação Terrestre" },
    MAR                           = { valor = 3,  cor = {0, 0, 139},      nome = "Mar" },
    AREA_ANTROPIZADA              = { valor = 4,  cor = {255, 215, 0},    nome = "Área Antropizada" },
    SOLO_DESCOBERTO               = { valor = 5,  cor = {255, 222, 173},  nome = "Solo Descoberto" },
    SOLO_INUNDADO                 = { valor = 6,  cor = {0, 0, 0},        nome = "Solo Inundado" },
    AREA_ANTROPIZADA_INUNDADA     = { valor = 7,  cor = {50, 50, 50},     nome = "Área Antropizada Inundada" },
    MANGUE_MIGRADO                = { valor = 8,  cor = {0, 255, 0},      nome = "Mangue Migrado" },
    MANGUE_INUNDADO               = { valor = 9,  cor = {255, 0, 0},      nome = "Mangue Inundado" },
    VEGETACAO_TERRESTRE_INUNDADA  = { valor = 10, cor = {0, 0, 0},        nome = "Vegetação Terrestre Inundada" }
}


-- ===============================================================
-- CLASSES DE SOLO
-- ===============================================================
tabela_solos = {
    CANAL_FLUVIAL   = { valor = 0, cor = {0, 0, 255},   nome = "Canal Fluvial" },
    MANGUE          = { valor = 3, cor = {0, 100, 0},   nome = "Mangue" },
    MANGUE_MIGRADO  = { valor = 9, cor = {34, 139, 34}, nome = "Mangue Migrado" }
}


-- ===============================================================
-- USOS INUNDADOS
-- ===============================================================
-- Tabela auxiliar que identifica rapidamente quais usos estão sob inundação
local usos_inundados = {
    [tabela_usos.MAR.valor]                          = true,
    [tabela_usos.SOLO_INUNDADO.valor]                = true,
    [tabela_usos.AREA_ANTROPIZADA_INUNDADA.valor]    = true,
    [tabela_usos.MANGUE_INUNDADO.valor]              = true,
    [tabela_usos.VEGETACAO_TERRESTRE_INUNDADA.valor] = true
}



-- ===============================================================
-- REGRAS DE INUNDAÇÃO
-- ===============================================================
-- Define as transformações de uso da terra quando ocorre inundação
local regras_inundacao = {
    [tabela_usos.MANGUE.valor]               = tabela_usos.MANGUE_INUNDADO.valor,
    [tabela_usos.MANGUE_MIGRADO.valor]       = tabela_usos.MANGUE_INUNDADO.valor,
    [tabela_usos.VEGETACAO_TERRESTRE.valor]  = tabela_usos.VEGETACAO_TERRESTRE_INUNDADA.valor,
    [tabela_usos.AREA_ANTROPIZADA.valor]     = tabela_usos.AREA_ANTROPIZADA_INUNDADA.valor,
    [tabela_usos.SOLO_DESCOBERTO.valor]      = tabela_usos.SOLO_INUNDADO.valor
}






-- ===============================================================
-- REGRAS DE MIGRAÇÃO DE SOLOS
-- ===============================================================
-- Define condições de origem, destino e transformação para solos
local regrasMigracaoSolo = {
    origens = {
        [tabela_solos.MANGUE.valor]         = true,
        [tabela_solos.MANGUE_MIGRADO.valor] = true,
        [tabela_solos.CANAL_FLUVIAL.valor]  = true
    },
    alvos = {
        [tabela_usos.VEGETACAO_TERRESTRE.valor] = true,
        [tabela_usos.SOLO_DESCOBERTO.valor]     = true
    },
    soloDestino = tabela_solos.MANGUE_MIGRADO.valor
}



-- ===============================================================
-- REGRAS DE MIGRAÇÃO DE USOS
-- ===============================================================
-- Controla o processo de migração dos usos do solo relacionados ao mangue
local regrasMigracaoUsos = {
    origens = {
        [tabela_usos.MANGUE.valor]         = true,
        [tabela_usos.MANGUE_MIGRADO.valor] = true
    },
    alvos = {
        [tabela_usos.VEGETACAO_TERRESTRE.valor] = true,
        [tabela_usos.SOLO_DESCOBERTO.valor]     = true
    },
    condSolos = {
        [tabela_solos.MANGUE.valor]         = true,
        [tabela_solos.MANGUE_MIGRADO.valor] = true
    },
    usoDestino = tabela_usos.MANGUE_MIGRADO.valor
}



-- ===============================================================
-- REGRAS DE ACREÇÃO VERTICAL
-- ===============================================================
-- Controla o acúmulo vertical de sedimentos nos solos do tipo mangue
local regrasAcrecao = {
    solosPermitidos = {
        [tabela_solos.MANGUE.valor]         = true,
        [tabela_solos.MANGUE_MIGRADO.valor] = true
    },
    usosProibidos = {
        [tabela_usos.MAR.valor]                          = true,
        [tabela_usos.SOLO_INUNDADO.valor]                = true,
        [tabela_usos.AREA_ANTROPIZADA_INUNDADA.valor]    = true,
        [tabela_usos.MANGUE_INUNDADO.valor]              = true,
        [tabela_usos.VEGETACAO_TERRESTRE_INUNDADA.valor] = true
    }
}



-- ===============================================================
-- CARREGAMENTO DO PROJETO E CRIAÇÃO DO ESPAÇO CELULAR
-- ===============================================================
local projeto = Project {
    file = "recorte.qgs",
    cell_usos = "data/teste_dinamica/Recorte_Teste.shp",
    clean = true
}

-- Criação do espaço celular com os atributos definidos
local espacoCelular = CellularSpace {
    project = projeto,
    layer   = "cell_usos",
    xy      = { "Col", "Lin" },
    select  = nomes_atributos
}

-- Criação da vizinhança de Moore e sincronização inicial
espacoCelular:createNeighborhood { strategy = "moore", self = false }
espacoCelular:synchronize()



-- ===============================================================
-- AMBIENTE DE SIMULAÇÃO
-- ===============================================================
local env = Environment {
    -- Modelos dinâmicos principais
    hidro = Hidro(
        espacoCelular,
        usos_inundados,
        regras_inundacao,
        nomes_atributos
    ) {
        taxaElevacaoMar = 0.5
    },

    mangue = Mangue(
        espacoCelular,
        tabela_usos,
        tabela_solos,
        usos_inundados,
        regrasMigracaoSolo,
        regrasMigracaoUsos,
        regrasAcrecao,
        nomes_atributos
    ) {
        taxaElevacaoMar = 0.5
    },

    -- Cálculo inicial da altitude média
    CalcularAltitudeMedia(espacoCelular, nomes_atributos) {}
}



-- ===============================================================
-- MAPAS E VISUALIZAÇÃO
-- ===============================================================
mapaUso = mapaUso(espacoCelular, tabela_usos, nomes_atributos.uso)
env:add(Event { action = mapaUso })

mapaSolo = mapaSolo(espacoCelular, tabela_solos, nomes_atributos.solo)
env:add(Event { action = mapaSolo })

mapaAltitude = mapaAltitude(espacoCelular, nomes_atributos.alt)
env:add(Event { action = mapaAltitude })

-- Atualização periódica do espaço celular
env:add(Event { action = function() espacoCelular:synchronize() end })



-- ===============================================================
-- EXECUÇÃO DA SIMULAÇÃO
-- ===============================================================
-- env:add(Event { action = function() print("Pressione ENTER para continuar...") io.read() end })
env:run()
