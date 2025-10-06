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
            model.timer = Timer { Event { action = model } }
        end
    }
end
