-- ===============================================================
-- IMPACTOS DA ELEVAÇÃO DO NÍVEL DO MAR EM ECOSSISTEMAS DE MANGUE
-- AUTOR ORIGINAL: Denilson da Silva Bezerra
-- REVISADO E REESTRUTURADO POR: Sergio Souza Costa
-- ===============================================================


-- ===============================================================
-- IMPORTAÇÃO DE BIBLIOTECAS
-- ===============================================================
import("gis")                 -- Biblioteca principal para operações espaciais (GIS)
require("models/mangue")      -- Modelo de dinâmica de mangue
require("models/hidro")       -- Modelo de hidrologia
require("models/utils")       -- Funções utilitárias de apoio
require("visualization/maps") -- Módulo de visualização e geração de mapas




-- ===============================================================
-- DEFINIÇÃO DOS NOMES DOS ATRIBUTOS
-- ===============================================================
-- Define os nomes dos campos no shapefile que serão usados no modelo
local nomes_atributos = {
    uso  = "uso",
    solo = "solo",
    alt  = "alt"
}


-- ===============================================================
-- CLASSES DE USO DA TERRA
-- ===============================================================
-- Cada classe representa um tipo de cobertura ou uso do solo
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
-- Representa diferentes tipos de solo ou substrato na área de estudo
tabela_solos = {
    CANAL_FLUVIAL   = { valor = 0, cor = {0, 0, 255},   nome = "Canal Fluvial" },
    MANGUE          = { valor = 3, cor = {0, 100, 0},   nome = "Mangue" },
    MANGUE_MIGRADO  = { valor = 9, cor = {34, 139, 34}, nome = "Mangue Migrado" },
    OUTROS          = { valor = 4, cor = {0, 0, 0},     nome = "Outros" }
}


-- ===============================================================
-- CARREGAMENTO DO PROJETO E CRIAÇÃO DO ESPAÇO CELULAR
-- ===============================================================
-- Carrega o projeto QGIS e define o espaço celular com base no shapefile
local projeto = Project {
    file = "flood2.qgs",
    uso_solo = "/home/sergio/Downloads/mangue_model/flood_model.shp",
    clean = true
}

-- Cria o espaço celular com os atributos definidos
local espacoCelular = CellularSpace {
    project = projeto,
    layer   = "uso_solo",
    xy      = { "col", "row" },
    select  = nomes_atributos
}

-- Define a vizinhança de Moore (8 vizinhos) e sincroniza o estado inicial
espacoCelular:createNeighborhood { strategy = "moore", self = false }
espacoCelular:synchronize()

local hidro_model = Hidro(espacoCelular, tabela_usos, nomes_atributos)
local mangue_model = Mangue(espacoCelular, tabela_solos, tabela_usos, nomes_atributos)


-- ===============================================================
-- CONSTANTES DO MODELO
-- ===============================================================
-- Taxa de elevação do nível do mar (em metros/ano, por exemplo)
local TAXA_ELEVACAO_MAR = 0.011
local ALTURA_MARE = 0
local FINAL_TIME = 80

-- ===============================================================
-- AMBIENTE DE SIMULAÇÃO
-- ===============================================================
-- Criação do ambiente principal com os modelos e processos envolvidos
local env = Environment {
    
    -- Modelos de dinâmica
    hidro  =  hidro_model{ 
            finalTime = FINAL_TIME, 
            taxaElevacaoMar = TAXA_ELEVACAO_MAR 
    },
    mangue =  mangue_model{ 
            finalTime = FINAL_TIME, 
            taxaElevacaoMar = TAXA_ELEVACAO_MAR, alturaMare = ALTURA_MARE 
    },

    -- Cálculo inicial da altitude média
    -- usado para verificar se o aumento do nivel do mar esta funcionando
    --CalcularAltitudeMedia(espacoCelular, nomes_atributos) {}
}


-- ===============================================================
-- MAPAS E VISUALIZAÇÃO
-- ===============================================================
-- Adiciona diretamente ao ambiente os mapas temáticos de uso, solo e altitude

env:add(Event { action = mapaUso(espacoCelular, tabela_usos, nomes_atributos.uso) })
env:add(Event { action = mapaSolo(espacoCelular, tabela_solos, nomes_atributos.solo) })
--env:add(Event { action = mapaAltitude(espacoCelular, nomes_atributos.alt) })

-- Sincronização periódica do espaço celular durante a simulação
env:add(Event { action = function() espacoCelular:synchronize() end })


-- ===============================================================
-- EXECUÇÃO DA SIMULAÇÃO
-- ===============================================================
-- Inicia a simulação completa
-- (para modo interativo, descomente a linha abaixo)
--env:add(Event { action = function() print("Pressione ENTER para continuar...") io.read() end })

env:run()
