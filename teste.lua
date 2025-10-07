environment = Environment{
    Timer{Event{action = function(ev) 

        print("Executando...", ev:getTime())

    end}}
}

cs1 = CellularSpace{xdim = 10}
--ag1 = Agent{}
--t1 = Timer{}

environment:add(cs1)

print(environment)
environment:run(10)