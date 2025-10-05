function calcularAltMedia(espacoCelular)
    local conta = 0
    local somaArea = 0
    forEachCell(espacoCelular, function(celula)
  
            somaArea = somaArea + celula.Alt2
            conta = conta + 1
    end)
    return somaArea / conta
end


function CalcularAltitudeMedia(espacoCelular)
    return Model {

        start = 1,
        finalTime = 100,
    
        alt_media = calcularAltMedia(espacoCelular),

        execute = function(model, event)
            local tempo = event:getTime()

            model.alt_media = calcularAltMedia(espacoCelular)
            print("Altura média: ", tempo, model.alt_media)
        end,

        init = function(model)
            model.timer = Timer { Event { action = model } }
        end
    }
end
