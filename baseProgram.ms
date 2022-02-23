imports = ["qa", "listUtil", "linqLike", "positioningUtils", "tileUtils"]
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

// TODO: Fix pathfinding loop bug.
//       Encountered a bug where the pathfinding produced a loop.
//       I am currently still in the process of diagnosing it.


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
routingInfo.costOf["Flooring"] = 1
routingInfo.costOf["HoeDirt"] = 100
routingInfo.costOf[null] = 10
routingInfo.costOf["Artifact Spot"] = 10
routingInfo.costOf["Grass"] = 10
routingInfo.costOf["Basic"] = 1000
routingInfo.costOf["Stone"] = 1000
routingInfo.costOf["Twig"] = 1000
routingInfo.costOf["Weeds"] = 1000
// Only go through trees if you really need to.
routingInfo.costOf["Tree"] = 100000

routingInfo.energyCostOf = {}
routingInfo.energyCostOf["Flooring"] = 0
routingInfo.energyCostOf["HoeDirt"] = 0
routingInfo.energyCostOf[null] = 0
routingInfo.energyCostOf["Artifact Spot"] = 0
routingInfo.energyCostOf["Grass"] = 0
routingInfo.energyCostOf["Basic"] = 2
routingInfo.energyCostOf["Stone"] = 2
routingInfo.energyCostOf["Twig"] = 2
routingInfo.energyCostOf["Weeds"] = 2
routingInfo.energyCostOf["Tree"] = 30