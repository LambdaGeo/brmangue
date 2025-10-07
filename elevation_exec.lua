

require "models/elevation"


local elevacao = Elevacao{}
env = Environment{
	elevacao,

}


chart = Chart{
	target = elevacao,
	select = {"nivelMar", "taxaAcrecao_m"},
	title = "Elevação do nível do mar e taxa de acreção",
	xLabel = "Ano",
	yLabel = "m",
}

env:add(Event{action = chart})


env:run()