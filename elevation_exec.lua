

require "models/elevation"






local env = Environment{
		elevacao =  Elevacao{}

}


chart = Chart{
	target = env.elevacao,
	select = {"nivelMar", "taxaAcrecao_m"},
	title = "Elevação do nível do mar e taxa de acreção",
	xLabel = "Ano",
	yLabel = "m",
}

env:add(Event{action = chart})


env:run()