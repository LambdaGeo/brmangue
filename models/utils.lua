function calcularAltMedia(espacoCelular, nomes_atributos)
    local conta = 0
    local somaAltura = 0
    local attrAlt = nomes_atributos.alt

    

    forEachCell(espacoCelular, function(celula)
        if celula[attrAlt] then
            somaAltura = somaAltura + celula[attrAlt]
            conta = conta + 1
        end
    end)

    if conta == 0 then
        return 0
    end

    return somaAltura / conta
end


function CalcularAltitudeMedia(espacoCelular, nomes_atributos)
    return Model {
        start = 1,
        finalTime = 100,

        -- Passa corretamente os parâmetros
        alt_media = calcularAltMedia(espacoCelular, nomes_atributos),

        execute = function(model, event)
            local tempo = event:getTime()
            model.alt_media = calcularAltMedia(espacoCelular, nomes_atributos)
            print("Altura média:", tempo, model.alt_media)
        end,

        init = function(model)


            forEachCell(espacoCelular, function(celula)
                --celula["Uso"] = 3
                --celula["Altitude"] = 0
            end)

            model.timer = Timer { Event { action = model } }
        end
    }
end


-- somente para testes

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