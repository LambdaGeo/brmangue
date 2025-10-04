

require "models/elevation"


env = Environment{
	Elevacao{},

}


chart = Chart{
	target = env,
	select = "nivelMar"
}

env:add(Event{action = chart})


env:run()