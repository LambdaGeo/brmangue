-- models/mangue.lua

-- ===============================================================
-- FUNÇÃO GERAL DE MIGRAÇÃO DE SOLOS
-- ===============================================================
function migrarSolos(celula, tabela_usos, tabela_solos, params, zonaInfluencia)
    -- Parâmetros esperados:
    -- params.origens: solos que podem gerar migração
    -- params.alvos: usos que permitem receber migração
    -- params.soloDestino: tipo de solo migrado
    -- params.zonaInfluencia: limite de altitude para migração

    if params.origens[celula.past.ClaseSolos] then
        forEachNeighbor(celula, function(vizinho)
            if params.alvos[vizinho.Usos]
                and vizinho.ClaseSolos ~= params.soloDestino
                and vizinho.Alt2 <= zonaInfluencia then
                vizinho.ClaseSolos = params.soloDestino
            end
        end)
    end
end


-- ===============================================================
-- FUNÇÃO GERAL DE MIGRAÇÃO DE USOS
-- ===============================================================
function migrarUsos(celula, tabela_usos, tabela_solos, params, zonaInfluencia)
    -- params.origens: usos que podem causar migração
    -- params.alvos: usos vizinhos que podem mudar
    -- params.condSolos: solos que permitem a mudança
    -- params.usoDestino: novo uso a ser atribuído
    -- params.zonaInfluencia: limite de altitude
    if params.origens[celula.past.Usos] then
        forEachNeighbor(celula, function(vizinho)
            if params.alvos[vizinho.Usos] 
                and vizinho.Alt2 <= zonaInfluencia 
                and params.condSolos[vizinho.ClaseSolos] then
                vizinho.Usos = params.usoDestino
            end
        end)
    end
end


-- ===============================================================
-- FUNÇÃO DE ACREÇÃO VERTICAL DA LAMA
-- ===============================================================
-- Aplica acreção apenas em solos permitidos e usos não proibidos
function aplicarAcrecao(celula, tabela_solos, regrasAcrecao, taxaAcrecao_m)
    local soloPermitido = regrasAcrecao.solosPermitidos[celula.ClaseSolos]
    local usoPermitido = not regrasAcrecao.usosProibidos[celula.Usos]

    if soloPermitido and usoPermitido then
        celula.Alt2 = celula.Alt2 + taxaAcrecao_m
    end
end


-- ===============================================================
-- MODELO DE DINÂMICA DE MANGUE
-- ===============================================================
-- @param espacoCelular: espaço celular da simulação
-- @param tabela_usos: tabela com classes de uso da terra
-- @param tabela_solos: tabela com tipos de solo
-- @param usos_inundados: tabela de usos considerados inundados
-- @param regrasMigracaoSolo: parâmetros para migração de solos
-- @param regrasMigracaoUsos: parâmetros para migração de usos
-- @param regrasAcrecao: parâmetros para acreção vertical da lama
function Mangue(espacoCelular, tabela_usos, tabela_solos, usos_inundados, regrasMigracaoSolo, regrasMigracaoUsos, regrasAcrecao)
    return Model {
        start = 1,
        finalTime = 100,         -- Duração da simulação em passos de tempo

        -- Parâmetros físicos e ambientais
        areaCelula = 0.09,       -- Área de cada célula (ha ou km² dependendo da unidade)
        alturaMare = 6,          -- Altura da maré (Ferreira, 1988)
        taxaElevacaoMar = 0.5,   -- Taxa de elevação do nível do mar (ou 0.011 para IPCC, 2013)

        -- =======================================================
        -- FUNÇÃO DE EXECUÇÃO (executada a cada passo do tempo)
        -- =======================================================
        execute = function(modelo, event)
            local tempo = event:getTime()

            -- Cálculo do nível do mar e taxa de acreção
            local nivelMar = tempo * modelo.taxaElevacaoMar
            local nivelMar_mm = nivelMar * 1000
            local taxaAcrecao_mm = 1.693 + (0.939 * nivelMar_mm) -- fórmula de acreção (mm)
            local taxaAcrecao_m = taxaAcrecao_mm / 1000            -- converte para metros
            local zonaInfluencia = modelo.alturaMare + nivelMar    -- zona de influência do mangue

            -- Iteração sobre cada célula do espaço celular
            forEachCell(espacoCelular, function(celula)
                -- Migração de solos
                migrarSolos(celula, tabela_usos, tabela_solos, regrasMigracaoSolo, zonaInfluencia)

                -- Migração de usos
                migrarUsos(celula, tabela_usos, tabela_solos, regrasMigracaoUsos, zonaInfluencia)

                -- Acreção vertical da lama
                --aplicarAcrecao(celula, tabela_solos, regrasAcrecao, taxaAcrecao_m)
            end)

            --print("ITERAÇÃO:", tempo, nivelMar, zonaInfluencia)
        end,

        -- =======================================================
        -- FUNÇÃO DE INICIALIZAÇÃO DO MODELO
        -- =======================================================
        init = function(model)
            -- Cria temporizador que dispara a função execute a cada passo
            model.timer = Timer { Event { action = model } }
        end
    }
end
