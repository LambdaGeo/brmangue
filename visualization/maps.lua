-- ===============================================================
-- FUNÇÃO DE VISUALIZAÇÃO DOS MAPAS
-- ===============================================================
function mapaUso(espacoCelular, usos, select)
    local valores, cores, rotulos = {}, {}, {}

    for _, uso in pairs(usos) do
        table.insert(valores, uso.valor)
        table.insert(cores, uso.cor)
        table.insert(rotulos, uso.nome)
    end

    return Map {
        target = espacoCelular,
        select = select,
        value = valores,
        color = cores,
        label = rotulos
    }
end



function mapaSolo(espacoCelular, tabela_solos, select)
    local valores = {}
    local cores = {}
    local nomes = {}

    for _, solo in pairs(tabela_solos) do
        table.insert(valores, solo.valor)
        table.insert(cores, solo.cor)
        table.insert(nomes, solo.nome)
    end

    return Map {
        target = espacoCelular,
        select = select,
        value = valores,
        color = cores,
        label = nomes
    }
end



function mapaAltitude(espacoCelular)
    return Map {
        target = espacoCelular,
        select = "Alt2",
        color = "RdYlGn",
        slices = 10,
        size = 1
    }
end
