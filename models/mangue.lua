-- ===============================================================
-- FUNÇÕES AUXILIARES
-- ===============================================================

-- Verifica se o uso da terra corresponde a mar ou a um uso inundado
-- @param uso: valor do uso atual da célula
-- @param usos_inundados: tabela onde a chave é o uso e o valor é true
function ehMarOuInundado(uso, usos_inundados)
    return usos_inundados[uso] == true
end


---------------------------------------------------------
-- FUNÇÃO GERAL DE MIGRAÇÃO DE SOLOS
---------------------------------------------------------
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

---------------------------------------------------------
-- FUNÇÃO GERAL DE MIGRAÇÃO DE USOS
---------------------------------------------------------
function migrarUsos(celula, tabela_usos, tabela_solos, params, zonaInfluencia)
    -- params.origens: usos que podem causar migração
    -- params.alvos: usos vizinhos que podem mudar
    -- params.condSolos: solos que permitem a mudança
    -- params.usoDestino: novo uso a ser atribuído
    -- params.zonaInfluencia: limite de altitude
    if params.origens[celula.past.Usos] then
        forEachNeighbor(celula, function(vizinho)
            if params.alvos[vizinho.Usos] and 
                vizinho.Alt2 <= zonaInfluencia and 
                params.condSolos[vizinho.ClaseSolos] then
                vizinho.Usos = params.usoDestino
            end
        end)
    end
end

-- ===============================================================
-- MODELO DE DINÂMICA DE MANGUE
-- ===============================================================
-- @param espacoCelular: espaço celular da simulação
-- @param tabela_usos: tabela com classes de uso da terra
-- @param tabela_solos: tabela com tipos de solo
function Mangue(espacoCelular, tabela_usos, tabela_solos, regrasMigracaoSolo, regrasMigracaoUsos)
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

            ---------------------------------------------------------
            -- CÁLCULO DO NÍVEL DO MAR E TAXA DE ACRESCIMENTO DE LAMA
            ---------------------------------------------------------
            local nivelMar = tempo * modelo.taxaElevacaoMar
            local nivelMar_mm = nivelMar * 1000
            local taxaAcrecao_mm = 1.693 + (0.939 * nivelMar_mm) -- fórmula de acreção (mm)
            local taxaAcrecao_m = taxaAcrecao_mm / 1000            -- converte para metros
            local zonaInfluencia = modelo.alturaMare + nivelMar    -- zona de influência do mangue

            ---------------------------------------------------------
            -- ITERAÇÃO SOBRE CADA CÉLULA DO ESPAÇO CELULAR
            ---------------------------------------------------------
            forEachCell(espacoCelular, function(celula)

                ---------------------------------------------------------
                -- MIGRAÇÃO DE SOLOS
                -- Solo adjacente à vegetação terrestre ou solo descoberto migra para mangue
                ---------------------------------------------------------
                migrarSolos(celula, tabela_usos, tabela_solos, regrasMigracaoSolo, zonaInfluencia)

                ---------------------------------------------------------
                -- MIGRAÇÃO DE USOS
                -- Uso da célula adjacente muda para mangue se estiver dentro da zona de influência
                ---------------------------------------------------------
                migrarUsos(celula, tabela_usos, tabela_solos, regrasMigracaoUsos, zonaInfluencia)

                ---------------------------------------------------------
                -- ACREÇÃO VERTICAL DA LAMA
                -- Eleva a superfície do mangue de acordo com a taxa de acreção
                ---------------------------------------------------------
                if (celula.ClaseSolos == tabela_solos.MANGUE.valor
                    or celula.ClaseSolos == tabela_solos.MANGUE_MIGRADO.valor)
                    and celula.Usos ~= tabela_usos.MAR.valor
                    and celula.Usos ~= tabela_usos.MANGUE_INUNDADO.valor then
                    -- celula.Alt2 = celula.Alt2 + taxaAcrecao_m
                end
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
