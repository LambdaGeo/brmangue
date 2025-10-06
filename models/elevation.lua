Elevacao = Model{
	taxaElevacaoMar = 0.011,
	alturaMare      =  6, -- altura da maré (Ferreira, 1988)
	finalTime       = 88,
    nivelMar = 0,
	execute = function(model, event)
        local tempo = event:getTime()

        model.nivelMar = tempo * model.taxaElevacaoMar
        -- no modelo de 2014: Increased_see = cell.Alt2 + (time * Tx_elev) 
        --- Pergunta: na tese tem esses valor por iteracao, se assumir todas celulas zero, entao nao precisa estar dentro do loop de celulas
                    
        local nivelMar_mm = model.nivelMar  * 1000
        local taxaAcrecao_mm = 1.693 + (0.939 * nivelMar_mm)

        model.taxaAcrecao_m = taxaAcrecao_mm / 1000
        model.zonaInfluencia = model.alturaMare + model.nivelMar 
        print (tempo+2012, string.format("%.2f", model.nivelMar ),  string.format("%.2f", model.taxaAcrecao_m), model.zonaInfluencia)
	end,
	init = function(model)

        
        -- ===============================================================
        -- INICIALIZAÇÃO DAS CÉLULAS
        -- ===============================================================
        -- testes
        forEachCell(espacoCelular, function(celula)
            -- Inicializa a semente aleatória para cada célula
            math.randomseed(os.time())
            local n = math.random(0, 5)  -- Valor aleatório de teste (pode ser usado para Alt2)
            --celula.Alt2 = n
            --celula.Usos = USO_MAR
        end)


		model.timer = Timer{
			Event{action = model},
		}
	end
}
