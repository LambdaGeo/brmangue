-- Sea-Level Rise Impacts on Mangrove Ecosystem 
-- Case Study: Maranh�o Island
-- Authors: Denilson da Silva Bezerra, Silvana Amaral, Milton Kampel, Pedro Ribeiro de Andrade
-- Project funded by CAPES
--
-- Cell States and Cell attributtes 
SEE = 0
MANGROVE = 1
ANTHROPIC_AREA = 3 
ANTHROPIC_AREA2 = 7
TERRESTRIAL_VEGETATION = 4
MANGROVE_SOIL = 4
MANGROVE_SOIL2 = 7  
BEACH = 2
CHANNEL_RIVER = 2
MANGROVE_MIGRATION = 5
MANGROVE_INUNDATION = 6
--
-- Model Parameters 
Area_cell = 1   -- Cell area in ha 
Initial_time = 1 -- correspondent to 2013
Final_time = 88 --  correspondent to 2100
Tx_elev = 0.011 -- Rate of sea-level rise (m) in a scenario of increase of approximately 0.81 m by 2100 (IPCC, 2013, p.17). 
Z = 6 -- Tide height on the Maranh�o Island (Ferreira, 1988).
------------------------------------------------------------------------------------------------------------------------------------------------------
-- Database
cs = CellularSpace{
	dbType = "ADO",
	database = "C:\\Banco_mangue_4.2.0\\mangue.mdb",
	theme = "Cell_usos",
	select= { "Alt2", "ClasseUsos2", "ClasseSolos" }
    }
cs:createNeighborhood { 
   strategy = "moore", 
   self = false 
}
cs:synchronize(); 
-------------------------------------------------------------------------------------------------------------------------------------------------------
-- Legend
ClasseUsos2Leg = Legend{
	grouping = "uniquevalue",
	colorBar = {
		{value = SEE, color = "blue"},            
		{value = MANGROVE, color = {66,111,66}},
		{value = BEACH, color = "cyan"},
		{value = ANTHROPIC_AREA, color = "yellow"},
		{value = ANTHROPIC_AREA2, color = {0,0,0}},
		{value = TERRESTRIAL_VEGETATION, color = {35,142,104}},
		{value = MANGROVE_MIGRATION, color = {0,255,0}}, 
		{value = MANGROVE_INUNDATION, color = "red"}
	}
}
-------------------------------------------------------------------------------------------------------------------------------------------------------
-- Observers
 obsMap = Observer{ subject = cs, type = "map", attributes = {"ClasseUsos2"},legends = {ClasseUsos2Leg} }
-- obsMap = Observer{ subject = cs, type = "image", DB_HOME = TME_PATH .. "C:\\Program Files (x86)\\terrame", attributes = {"ClasseUsos2"},legends = {ClasseUsos2Leg} }
-------------------------------------------------------------------------------------------------------------------------------------------------------	
-- Model Loop for sea-level rise	
for time = Initial_time, Final_time, 1 do
    
    coord = Coord{x = 68, y = 132}
	cellreference = cs:getCell(coord)  
	cellreference.Alt2 = 0,147705
    --
	Mangrove_area = MANGROVE or MANGROVE_MIGRATION -- Total area of mangrove in ha
	Mangrove_area_remaining = MANGROVE -- Area of remaining mangrove in ha
	Mangrove_area_inundation = MANGROVE_INUNDATION -- Mangrove inundation in ha  
	Mangrove_area_migration = MANGROVE_MIGRATION -- Mangrove migration in ha
	SOIL2_AREA_progradation = MANGROVE_SOIL2 -- areas of progradation of mud (ha)
	ANTHROPIC_inundation = ANTHROPIC_AREA2
	--
	--
	forEachCell(cs, function(cell)
		-- Simulation of the rising sea level
		if cell.ClasseUsos2 == SEE and cell.Alt2 >=0 then		
			Increased_see = cell.Alt2 + (time * Tx_elev) 
			-- Sea-level rise in the cell reference
			Elev_cellreference = cellreference.Alt2 + (time * Tx_elev)
			-- rate of vertical accretion of mud - Txa (in mm)
			Elev_mm = Elev_cellreference * 1000 -- Sea-level rise in mm
			Txa = 1.693 + (0.939 * Elev_mm) -- Equation proposed by Alongi (2008) with R2 = 0,704 and p < 0,001
			Txa_m = Txa / 1000 -- Txa in metrs
			-- Increment of the area of tidal influence
			Z_m = Z + Elev_cellreference
			-- Find the lowest neighbor
			countNeigh = 0
			forEachNeighbor(cell,	function(cell, neigh)
				if (cell.Alt2 >= neigh.Alt2) then
					countNeigh = countNeigh + 1
				end
			end)
			--
			-- Simulating the advancement of mud banks
			if (cell.ClasseSolos == MANGROVE_SOIL or cell.ClasseSolos == CHANNEL_RIVER) and (neigh.ClasseSolos ~= MANGROVE_SOIL) then							
				forEachNeighbor(cell, function(cell, neigh)
				if (neigh.Alt2 <= Z_m) and 
				(neigh.ClasseUsos2 ~= SEE)then
						neigh.ClasseSolos = MANGROVE_SOIL2
						SOIL2_AREA_progradation = SOIL2_AREA_progradation + Area_cell 
					end						 	
				end)
			end
			--
			-- rate of vertical accretion of mud in each cell
			if (cell.past.ClasseSolos ~= MANGROVE_SOIL2 and cell.ClasseSolos == MANGROVE_SOIL2) or (cell.ClassesSolos == MANGROVE_SOIL) and 
			(cell.ClasseUsos2 ~= SEE) then												 	
				cell.Alt2 = cell.Alt2 + Txa_m
			end
			--
			-- Simulating the flow of water to the neighbors
			if (countNeigh > 0) then
			flux = Increased_see / countNeigh
			end
			--
		
			-- Simulation of the inundation from neighboring
			if cell.ClasseUsos2 == SEE and neigh.ClasseUsos2 ~= SEE then							
				forEachNeighbor(cell, function(cell, neigh)
					if  Increased_see >= (neigh.Alt2 + flux) then
						neigh.ClasseUsos2 = SEE
					end						 	
				end)
			end
		--
		--
	  end								
	end)
	--
	--End: Simulation of the sea-level rise	
	---------------------------------------------------------------------------------------------------------------------------------------------------		
	-- Simulation of mangrove migration	
	forEachCell(cs, function(cell)
		if(cell.ClasseUsos2 == MANGROVE) then							
			forEachNeighbor(cell, function(cell, neigh)
				 if (neigh.ClasseUsos2 ~= MANGROVE) then
				 	if (Z_m >= neigh.Alt2) and
				 	   (neigh.ClasseUsos2 == TERRESTRIAL_VEGETATION) and
				 	   (neigh.ClasseSolos == MANGROVE_SOIL or MANGROVE_SOIL2) then
					         neigh.ClasseUsos2 = MANGROVE_MIGRATION
					end								 	
				end
			end)
		end
	end)
	--
	-- Simulation of mangrove inundation 
	forEachCell(cs,function(cell)
		if (cell.past.ClasseUsos2 == MANGROVE or cell.past.ClasseUsos2 == MANGROVE_MIGRATION) and cell.ClasseUsos2 == SEE then 
		cell.ClasseUsos2 = MANGROVE_INUNDATION 
		Mangrove_area_inundation = Mangrove_area_inundation + Area_cell 
		end
	end)
	-- 
	-- Simulation of mangrove migration  
	forEachCell(cs,function(cell)
		if cell.past.ClasseUsos2 == TERRESTRIAL_VEGETATION and cell.ClasseUsos2 == MANGROVE_MIGRATION then 
		Mangrove_area_migration = Mangrove_area_migration + Area_cell 
		end
	end)
	--
	-- Simulation of remaining mangrove
	forEachCell(cs,function(cell)
		if cell.past.ClasseUsos2 == MANGROVE and cell.ClasseUsos2 == MANGROVE then 
		Mangrove_area_remaining = Mangrove_area_remaining + Area_cell
		end
	end)
	--
	-- Simulation of total area (mangrove)
	forEachCell(cs,function(cell)
		if (cell.ClasseUsos2 == MANGROVE or
		cell.ClasseUsos2 == MANGROVE_MIGRATION) then 
		Mangrove_area = Mangrove_area + Area_cell
		end
	end)
	--
	-- Simulation of anthropic area inundation  
	forEachCell(cs,function(cell)
		if cell.past.ClasseUsos2 == ANTHROPIC_AREA and cell.ClasseUsos2 == SEE then 
		cell.ClasseUsos2 = ANTHROPIC_AREA2 
		ANTHROPIC_inundation = ANTHROPIC_inundation + Area_cell 
		end
	end)
	--
--   	print("Total area:", Mangrove_area)
--   	print("Remaining area:", Mangrove_area_remaining)
-- 	print("Progration:",SOIL2_AREA_progradation)
-- 	print("Vertical accretion:",Txa_m)
-- 	print("Sea-level rise:",Elev_cellreference)
--  	print("Tide height:",Z_m)
    print("Mangrove migration:",Mangrove_area_migration) 
--     print("Mangrove inundation:",Mangrove_area_inundation)
--     print("Anthropic area inundation:", ANTHROPIC_inundation)
	-- -- 
	--
-- 	if i == 88 then
-- 		cs:save(i,"result","ClasseUsos") 
-- 	end
    cs:notify()
end
print("Simulation performed with successfully")