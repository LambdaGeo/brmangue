Elevacao = Model{
	taxaElevacaoMar = 0.011,
	alturaMare      =  6, -- altura da maré (Ferreira, 1988)
	finalTime       = 88,

    coeficienteA    = 1.693,  -- intercepto da equação de Alongi 
    coeficienteB    = 0.939,   -- coeficiente de inclinação da equação de Alongi 
    nivelMar = 0,
    taxaAcrecao_m = 0,

	execute = function(model, event)
        local tempo = event:getTime()
        

        model.nivelMar = tempo * model.taxaElevacaoMar
        -- Equation proposed by Alongi (2008) with R2 = 0,704 and p < 0,001
        model.taxaAcrecao_m = model.coeficienteA/1000 + (model.coeficienteB * model.nivelMar) -- 1.693 + 0.939 * nivelMar_mm / 1000

        model.zonaInfluencia = model.alturaMare + model.nivelMar 
        print (tempo+2012, string.format("%.2f", model.nivelMar ),  string.format("%.2f", model.taxaAcrecao_m), string.format("%.2f", model.zonaInfluencia))
	end,
	init = function(model)

    

		model.timer = Timer{
			Event{action = model},
		}
	end
}
