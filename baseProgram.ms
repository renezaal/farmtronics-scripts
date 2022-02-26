imports = ["qa", "listUtil", "linqLike", "sortedList", "positioningUtils", "tileUtils"]
for name in imports
	import name
	globals[name] = locals[name]
end for
globals.program = {}

program.run = function()
	print "Program has not been provided with a run function"
end function

// -------------------------------
// Set the static values that the bot needs to know.
// -------------------------------
// These are in a space shared space to provide homogenous access to certain things for multiple programs.
// Think of it like a configuration and bookkeeping.
// Since this is the base of all, I'm keeping my notes here too.

// TODO: Store configuration in file.
//       Home computer configures file and decides order.
//       Bots read from file and communicate through it.

// TODO: If manual activation becomes a thing of the past,
//       make the bots self-regulating with the file as intermediary.

// TODO: Make the home computer report the status of the bots.

// TODO: Make the bots do more jobs than just watering.
//       Harvest.
//       Plant.
//       Fertilize.

// TODO: Bot energy management.

// TODO: Task pool system.

// TODO: Designate bot storage location.

// TODO: Bot-on-bot collision avoidance.

// TODO: Automatic field detection.
//       Loop through tiles on farm and figure out which ones belong together.
//       Just floodfill from the each non-processed HoeDirt tile and set all connected to processed.
//       Then each connected set of tiles is stored as a field.

// TODO: Tree management.
//       Stuff like sapping and managing a wood farm.

// TODO: Cleaning the farm.
//       Automatically remove all debris like weeds, stones and twigs.

// TODO: Update to double-Dijkstra.
//       Current implementation is a bit too performance hungry for my tastes.
//       If that does not help, I will probably give IDA* a try.

// DONE: Fix pathfinding loop bug.
//       Encountered a bug where the pathfinding produced a loop.
//       I am currently still in the process of diagnosing it.

// TODO: Add a check to the inaccessible tile registration decision to see if bot is out of energy.
//       If the bot is out of energy, it may not move into an empty tile.
//       This should not erroneously mark the tile as inaccessible.

// Here is the configuration.
program.commandMode = false

globals.tools = {}
tools.watering = {}
tools.watering.toolName = "Watering Can"

globals.routingInfo = {}
routingInfo.waterFillPoint = new Position
routingInfo.waterFillPoint.x = 61
routingInfo.waterFillPoint.y = 18

routingInfo.fieldToAttend = new Position
routingInfo.fieldToAttend.x = 70
routingInfo.fieldToAttend.y = 25

// Use the tile type string as key for pathing cost.
// Everything not in this map is simply off-limits.
// That goes especially for the type "Crafting"!
routingInfo.costOf = {}
routingInfo.costOf["Flooring"]      = 1
routingInfo.costOf["HoeDirt"]       = 20
routingInfo.costOf[null]            = 10
routingInfo.costOf["Artifact Spot"] = 10
routingInfo.costOf["Grass"]         = 15
routingInfo.costOf["Basic"]         = 1000
routingInfo.costOf["Stone"]         = 1000
routingInfo.costOf["Twig"]          = 1000
routingInfo.costOf["Weeds"]         = 1000
routingInfo.costOf["Tree"]          = 100000

routingInfo.energyCostOf = {}
routingInfo.energyCostOf["Flooring"]      = 0
routingInfo.energyCostOf["HoeDirt"]       = 0
routingInfo.energyCostOf[null]            = 0
routingInfo.energyCostOf["Artifact Spot"] = 0
routingInfo.energyCostOf["Grass"]         = 0
routingInfo.energyCostOf["Basic"]         = 2
routingInfo.energyCostOf["Stone"]         = 2
routingInfo.energyCostOf["Twig"]          = 2
routingInfo.energyCostOf["Weeds"]         = 2
routingInfo.energyCostOf["Tree"]          = 30

routingInfo.mapSymbol = {}
routingInfo.mapSymbol["Flooring"]      = "⬜"
routingInfo.mapSymbol["HoeDirt"]       = "🌱"
routingInfo.mapSymbol[null]            = "🟨"
routingInfo.mapSymbol["Artifact Spot"] = "✨"
routingInfo.mapSymbol["Grass"]         = "🟩"
routingInfo.mapSymbol["Stone"]         = "🪨"
routingInfo.mapSymbol["Boulder"]       = "🪨"
routingInfo.mapSymbol["Twig"]          = "🪵"
routingInfo.mapSymbol["Stump"]         = "🪵"
routingInfo.mapSymbol["Hollow Log"]    = "🪵"
routingInfo.mapSymbol["Weeds"]         = "❎"
routingInfo.mapSymbol["Tree"]          = "🌳"
routingInfo.mapSymbol["Water"]         = "🟦"
routingInfo.mapSymbol["Clump"]         = "🟤" // Type includes names "Stump", "Hollow Log" and "Boulder".
routingInfo.mapSymbol["Bot"]           = "🤖"
routingInfo.mapSymbol["Chest"]         = "📦"
routingInfo.mapSymbol["Building"]      = "🏠"
routingInfo.mapSymbol["Bush"]          = "🌿"

routingInfo.generateFarmMap = function()
	lines = []
	for y in range(1,farm.height-1)
		line = ""
		for x in range(1,farm.width-1)
			tile = TileFactory.create(x,y,farm)
			name = tile.getName
			type = tile.getType
			symbol = "❌"
			if routingInfo.isInaccessible(x, y) then
				symbol = "🚫"
			else if routingInfo.mapSymbol.hasIndex(name) then
				symbol = routingInfo.mapSymbol[name]
			else if routingInfo.mapSymbol.hasIndex(type) then
				symbol = routingInfo.mapSymbol[type]
			else if type == "Crafting" then
				if name[:3] == "Bot" then
					symbol = routingInfo.mapSymbol["Bot"]
				end if
			end if
			line = line + symbol
		end for
		lines.push(line)
	end for

	return lines
end function

routingInfo.saveFarmMap = function(lines)
	file.writeLines("/usr/resources/map.txt", lines)
end function

routingInfo.readFarmMap = function()
	return file.readLines("/usr/resources/map.txt")
end function

// Inaccessible tiles are tiles that can not be detected by Location.tile but are not walkable.
routingInfo.inaccessibleTiles = {}
routingInfo.hasUnsavedInaccessibleTiles = false
routingInfo.registerInaccessibleTile = function(x, y)
	if not self.inaccessibleTiles.hasIndex(y) then self.inaccessibleTiles[y] = []
	self.inaccessibleTiles[y].push(x)
	self.hasUnsavedInaccessibleTiles = true
end function
routingInfo.saveInaccessibleTiles = function()
	if not self.hasUnsavedInaccessibleTiles then return
	f = file.open("/usr/resources/inaccessibleTiles.txt", "w")
	for row in self.inaccessibleTiles
		y = row.key
		for x in row.value
			f.writeLine(x+";"+y)
		end for
	end for
	f.close
end function
routingInfo.loadInaccessibleTiles = function()
	lines = file.readLines("/usr/resources/inaccessibleTiles.txt")
	for line in lines
		split = line.split(";")
		if split.len == 2 then
			routingInfo.registerInaccessibleTile(split[0].val, split[1].val)
		end if
	end for
	self.hasUnsavedInaccessibleTiles = false
end function
routingInfo.isInaccessible = function(x, y)
	if not self.inaccessibleTiles.hasIndex(y) then return false
	return self.inaccessibleTiles[y].indexOf(x) != null
end function
routingInfo.loadInaccessibleTiles