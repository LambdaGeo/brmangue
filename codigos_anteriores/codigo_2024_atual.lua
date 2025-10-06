-- Sea-Level Rise Impacts on Mangrove Ecosystem 
-- Case Study:  Maranhense retrances
-- Author: Denilson da Silva Bezerra
-- New version refactored by: H�lder Pereira Borges
-------uso e ocupa��o
MANGUE = 1
VEGETACAO_TERRESTRE = 2
MAR = 3
AREA_ANTROPIZADA = 4
SOLO_DESCOBERTO = 5
SOLO_DESCOBERTO_INUNDADO = 6
AREA_ANTROPIZADA_INUNDADO = 7 
MANGUE_MIGRADO = 8
MANGUE_INUNDADO = 9
VEGETACAO_TERRESTRE_INUNDADO = 10
-------
-------tipo de solo
SOLO_MANGUE = 1
SOLO_MANGUE_MIGRADO = 3
CHANNEL_RIVER = 0
-------
-------Model Parameters 
areaCelula = 0.09 -- ha
Initial_time = 1   -- Simulando de 2012 (data da imagem) a 2100 (dados do IPC registram a eleva��o at� este ano). S�o 88 anos, sendo simulado 1 itera��o por ano
Final_time = 75
Tx_elev = 0.00813 -- Rate of sea-level rise (m) -
alturaMare = 2.6 -- Tide height on the Sierra Leone).
-------Database Conection
cs = CellularSpace{
	dbType = "ado", --n obrigatorio
	--database = "C:\\Magist�rio\\Pesquisa\\BR_Mangue\\Bancos\\elevacaoNOVO.mdb",
	--database = "D:\\TerraMe\\elevacao.mdb",
	database = "C:\\Users\\franr\\Documents\\DENILSON\\WABlue\\Sierra_Leone\\ModelSLR\\SierraLeoneQ1c.mdb",  
	theme = "Cell_Usos",
	select= { "ClasseSolos", "Alt2", "Usos" }
}
cs:createNeighborhood { 
   strategy = "moore", 
   self = false 
}
cs:synchronize(); 
-------
-------Legend
UsosLeg = Legend{
	grouping = "uniquevalue",
	colorBar = {
		{value = MANGUE, color = {0, 100, 0}, label = "Mangue"},         
		{value = VEGETACAO_TERRESTRE, color = {128,128,0}, label = "Vegeta��o Terrestre"},
		{value = MAR, color = {0, 0, 139}, label = "Mar"}, 
		{value = AREA_ANTROPIZADA, color = {255, 215, 0}, label = "�rea Antropizada"},
		{value = SOLO_DESCOBERTO, color = {255,222,173}, label = "Solo Descoberto"},
		{value = SOLO_DESCOBERTO_INUNDADO, color = {0, 0, 0}, label = "Solo Descoberto Inundado"},
		{value = AREA_ANTROPIZADA_INUNDADO, color = {0, 0, 0}, label = "�rea Antr�pica Inundado"},
		{value = MANGUE_MIGRADO, color = {0,255,0}, label = "Mangue Migrado"},
		{value = MANGUE_INUNDADO, color = {255, 0, 0}, label = "Mangue Inundado"},
		{value = VEGETACAO_TERRESTRE_INUNDADO, color = {0, 0, 0}, label = "Vegeta��o Terrestre Inundado"}
	}
}
-------
-------Observers
-- obsMap = Observer{ subject = cs, type = "map", attributes = {"Usos"},legends = {UsosLeg} }
--  obsMap = Observer{ subject = cs, type = "image", DB_HOME = TME_PATH .. "HD-Acer (C:)\\terrame", attributes = {"Usos"},legends = {UsosLeg} }
-- -------
-------Auxiliar variables
	areaMar_USO_Texto = ""
	areaMangue_USO_Texto = ""
	areaMangueRemanescente_USO_Texto = ""
	areaMangueInundado_USO_Texto = ""
	areaMangueMigrado_USO_Texto = ""
	areaAntropizada_USO_Texto = ""
	areaAntropizadaInundada_USO_Texto = ""
	areaSoloDescoberto_USO_Texto = ""
	areaSoloDescobertoInundado_USO_Texto = ""
	areaVegetacao_USO_Texto = ""
	areaVegetacaoInundado_USO_Texto = ""
	areaTotal_USO_Texto = ""
-------
-------Calculate Area Function
function contagem(tipo)
	areaMar_USO = 0
	areaMangue_USO = 0 -- in ha
	areaMangueRemanescente_USO = 0
	areaMangueInundado_USO = 0 
	areaMangueMigrado_USO = 0 
	areaAntropizada_USO = 0
	areaAntropizadaInundada_USO = 0
	areaSoloDescoberto_USO = 0
	areaSoloDescobertoInundado_USO = 0
	areaVegetacao_USO = 0
	areaVegetacaoInundado_USO = 0
	
	areaProgradacaoLama_SOLO = 0 	--5
	areaLeitoRio_SOLO = 0			--1
	areaSoloDescoberto_SOLO = 0
	areaSoloMangue_SOLO = 0			--4
	areaLatoSolo_SOLO = 0
	areaPodzolico_SOLO = 0	
	
	forEachCell(cs, function(cell)
		if cell.Usos == MAR then areaMar_USO = areaMar_USO + areaCelula end
		--if cell.Usos == MANGUE then areaMangue_USO = areaMangue_USO + areaCelula end
		if cell.past.Usos == MANGUE and cell.Usos == MANGUE then areaMangueRemanescente_USO = areaMangueRemanescente_USO + areaCelula end
		if cell.Usos == MANGUE_INUNDADO then areaMangueInundado_USO = areaMangueInundado_USO + areaCelula end
		if cell.Usos == MANGUE_MIGRADO then areaMangueMigrado_USO = areaMangueMigrado_USO + areaCelula end
		if cell.Usos == AREA_ANTROPIZADA then areaAntropizada_USO = areaAntropizada_USO + areaCelula end
		if cell.Usos == AREA_ANTROPIZADA_INUNDADO then areaAntropizadaInundada_USO = areaAntropizadaInundada_USO + areaCelula end		
		if cell.Usos == SOLO_DESCOBERTO then areaSoloDescoberto_USO = areaSoloDescoberto_USO + areaCelula end
		if cell.Usos == SOLO_DESCOBERTO_INUNDADO then areaSoloDescobertoInundado_USO = areaSoloDescobertoInundado_USO + areaCelula end		
		if cell.Usos == VEGETACAO_TERRESTRE then areaVegetacao_USO = areaVegetacao_USO + areaCelula end
		if cell.Usos == VEGETACAO_TERRESTRE_INUNDADO then areaVegetacaoInundado_USO = areaVegetacaoInundado_USO + areaCelula end	
		if cell.ClasseSolos == 1 then areaLeitoRio_SOLO = areaLeitoRio_SOLO + areaCelula end
		if cell.ClasseSolos == 2 then areaPodzolico_SOLO = areaPodzolico_SOLO + areaCelula end
		if cell.ClasseSolos == 3 then areaLatoSolo_SOLO = areaLatoSolo_SOLO + areaCelula end
		if cell.ClasseSolos == 4 then areaSoloMangue_SOLO = areaSoloMangue_SOLO + areaCelula end
	end)
		total_USO = areaMar_USO + areaMangueRemanescente_USO + areaMangueInundado_USO + areaMangueMigrado_USO + areaAntropizada_USO + areaAntropizadaInundada_USO + 
			areaSoloDescoberto_USO + areaSoloDescobertoInundado_USO + areaVegetacao_USO + areaVegetacaoInundado_USO
		total_SOLO = areaProgradacaoLama_SOLO + areaLeitoRio_SOLO +	areaSoloDescoberto_SOLO + areaSoloMangue_SOLO + areaLatoSolo_SOLO + areaPodzolico_SOLO
	
	if (tipo == 1) then
		areaMar_USO_Texto = string.format ("%7d",areaMar_USO)
		--areaMangue_USO_Texto = string.format ("%7d",areaMangue_USO)
		areaMangueRemanescente_USO_Texto = string.format ("%7d",areaMangueRemanescente_USO)
		areaMangueInundado_USO_Texto = string.format ("%7d",areaMangueInundado_USO)
		areaMangueMigrado_USO_Texto = string.format ("%7d",areaMangueMigrado_USO)
		areaAntropizada_USO_Texto = string.format ("%7d",areaAntropizada_USO)
		areaAntropizadaInundada_USO_Texto = string.format ("%7d",areaAntropizadaInundada_USO)
		areaSoloDescoberto_USO_Texto = string.format ("%7d",areaSoloDescoberto_USO)
		areaSoloDescobertoInundado_USO_Texto = string.format ("%7d",areaSoloDescobertoInundado_USO)
		areaVegetacao_USO_Texto = string.format ("%7d",areaVegetacao_USO)
		areaVegetacaoInundado_USO_Texto = string.format ("%7d",areaVegetacaoInundado_USO)
		areaTotal_USO_Texto = string.format ("%7d",total_USO)
	else
		areaMar_USO_Texto = areaMar_USO_Texto .. "; " .. string.format ("%7d",areaMar_USO)
		--areaMangue_USO_Texto = areaMangue_USO_Texto .. "; " .. string.format ("%7d",areaMangue_USO)
		areaMangueRemanescente_USO_Texto = areaMangueRemanescente_USO_Texto .. "; " .. string.format ("%7d",areaMangueRemanescente_USO)
		areaMangueInundado_USO_Texto = areaMangueInundado_USO_Texto .. "; " .. string.format ("%7d",areaMangueInundado_USO)
		areaMangueMigrado_USO_Texto = areaMangueMigrado_USO_Texto .. "; " .. string.format ("%7d",areaMangueMigrado_USO)
		areaAntropizada_USO_Texto = areaAntropizada_USO_Texto .. "; " .. string.format ("%7d",areaAntropizada_USO)
		areaAntropizadaInundada_USO_Texto = areaAntropizadaInundada_USO_Texto .. "; " .. string.format ("%7d",areaAntropizadaInundada_USO)
		areaSoloDescoberto_USO_Texto = areaSoloDescoberto_USO_Texto .. "; " .. string.format ("%7d",areaSoloDescoberto_USO)
		areaSoloDescobertoInundado_USO_Texto = areaSoloDescobertoInundado_USO_Texto .. "; " .. string.format ("%7d",areaSoloDescobertoInundado_USO)
		areaVegetacao_USO_Texto = areaVegetacao_USO_Texto .. "; " .. string.format ("%7d",areaVegetacao_USO)
		areaVegetacaoInundado_USO_Texto = areaVegetacaoInundado_USO_Texto .. "; " .. string.format ("%7d",areaVegetacaoInundado_USO)
		areaTotal_USO_Texto = areaTotal_USO_Texto .. "; " .. string.format ("%7d",total_USO)
	end	
end
-------

for time = Initial_time, Final_time + 1, 1 do 
	if(time <= 1) then 
		contagem(1) --serve para pegar os valores iniciais do BD e criar a primeira imagem com estes valores
	else
		forEachCell(cs, function(cell)
			-------------------------------------INI AVALIA�AO MAR E INUNDADOS
			if (cell.Usos == MAR or cell.Usos == MANGUE_INUNDADO or cell.Usos == AREA_ANTROPIZADA_INUNDADO or 
				cell.Usos == SOLO_DESCOBERTO_INUNDADO or cell.Usos == VEGETACAO_TERRESTRE_INUNDADO)and cell.Alt2 >= 0 then
				
				aumentoNivelMar = cell.Alt2 * Tx_elev --taxa de eleva��o n�o corresponde para o mar todo
				elevacaoNivemMar_mm = aumentoNivelMar * 1000
				
				deslocamentoVerticalLama = (1.693 + (0.939 * elevacaoNivemMar_mm))/1000 --ALONGI, 2008
				deslocamentoHorizontalLama = alturaMare + aumentoNivelMar
				
				countNeigh = 1 -- no m�nimo ter� a pr�pria c�lula
				forEachNeighbor(cell, function(cell, neigh) --CONTA QTOS VIZINHOS S�O DIFERENTES DE MAR E MAIS BAIXOS QUE A C�LULA CORRENTE
					if (neigh.Usos ~= MAR) or (neigh.Usos ~= MANGUE_INUNDADO) or (neigh.Usos ~= AREA_ANTROPIZADA_INUNDADO) or 
						(neigh.Usos ~= SOLO_DESCOBERTO_INUNDADO) or (neigh.Usos ~= VEGETACAO_TERRESTRE_INUNDADO)
						 and (cell.Alt2 >= neigh.Alt2) then
						countNeigh = countNeigh + 1
					end
				end)
				qtdAgua = aumentoNivelMar /countNeigh -- Simulating the flow of water to the neighbors
				
				-- Simulation of the inundation from neighboring
				cell.Alt2 = cell.Alt2 + qtdAgua --DISTRIBUINDO O AUMENTO DE �GUA, ---QUANDO N�O TEM VIZINHO MAIS BAIXO A C�LULA RECEBE A �GUA TODA
				
				forEachNeighbor(cell, function(cell, neigh)
					if (neigh.Usos ~= MAR or neigh.Usos ~= MANGUE_INUNDADO or neigh.Usos ~= AREA_ANTROPIZADA_INUNDADO or 
						neigh.Usos ~= SOLO_DESCOBERTO_INUNDADO or neigh.Usos ~= VEGETACAO_TERRESTRE_INUNDADO) 
						and aumentoNivelMar >= (neigh.Alt2 + qtdAgua) then -- NAO DEVERIA SER APENAS: cell.Alt2 > neigh.Alt2
							  --simulations of inundations  -- DEVERIA SER GRADATIVA
							if neigh.Usos == AREA_ANTROPIZADA then neigh.Usos = AREA_ANTROPIZADA_INUNDADO end
							if neigh.Usos == SOLO_DESCOBERTO then neigh.Usos = SOLO_DESCOBERTO_INUNDADO end
							if neigh.Usos == VEGETACAO_TERRESTRE then neigh.Usos = VEGETACAO_TERRESTRE_INUNDADO end
							if (neigh.Usos == MANGUE or neigh.Usos == MANGUE_MIGRADO) then neigh.Usos = MANGUE_INUNDADO end
					end
				end)
		  	end 
		  	-------------------------------------FIM AVALIA�AO MAR E INUNDADOS
		-- Simulating the advancement of mud banks
			if (cell.ClasseSolos == SOLO_MANGUE)then			
				forEachNeighbor(cell, function(cell, neigh)
					if (neigh.Usos == VEGETACAO_TERRESTRE) or (neigh.Usos == SOLO_DESCOBERTO) and (neigh.Alt2 <= deslocamentoHorizontalLama) then
						neigh.ClasseSolos = SOLO_MANGUE_MIGRADO  -- DEVERIA SER GRADATIVA
					end
				end)
			end				
			
			-- Simulation of mangrove migration
			if(cell.Usos == MANGUE)then			
				forEachNeighbor(cell, function(cell, neigh)
					if (neigh.Usos == VEGETACAO_TERRESTRE) or (neigh.Usos == SOLO_DESCOBERTO) then
						neigh.Usos = MANGUE_MIGRADO
					end
				end)
			end				
		end)
		contagem(2)
	end
	--
 	if time == 75 then
 		cs:save(time,"resultNew","Usos") 
 	end
	--
    cs:notify()
    print("ITERACAO : ", time)
end
	print("")
--	print("Area Mangue Total        ; ", areaMangue_USO_Texto)
	print("Area Mangue Remanescente ; ", areaMangueRemanescente_USO_Texto)
	print("Area Vegeta��o           ; ", areaVegetacao_USO_Texto)
	print("Area Mar                 ; ", areaMar_USO_Texto)
	print("Area Antropizada         ; ", areaAntropizada_USO_Texto)
	print("Area Solo Descoberto     ; ", areaSoloDescoberto_USO_Texto)
	print("Area Solo Desc Inundada	; ", areaSoloDescobertoInundado_USO_Texto)
	print("Area Antropizada Inundada; ", areaAntropizadaInundada_USO_Texto)	
	print("Area Mangue Migrado      ; ", areaMangueMigrado_USO_Texto)
	print("Area Mangue Inundado     ; ", areaMangueInundado_USO_Texto)
	print("Area Vegeta��o Inundado  ; ", areaVegetacaoInundado_USO_Texto)
	print("AREA TOTAL               ; ", areaTotal_USO_Texto)
	print("Tempo Execucao: ", os.clock (), " segundos")	
