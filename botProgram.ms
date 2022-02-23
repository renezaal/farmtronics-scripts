import "baseProgram"
qa.assert(bot != null, "No bot instance while calling botProgram")
qa.assert(bot.position.area == farm, "This script may only be run on the main player farm")

// -------------------------------
// Imports.
// -------------------------------
import "botExtensions"

// -------------------------------
// Basic classes.
// -------------------------------

// None for now.



// -------------------------------
// Some helper functions.
// -------------------------------

// Working with grids.
// Not used for now.
// Grid = { "width":0, "height":0, "list":[] }
// 
// Grid.get = function(x,y)
//   return self.list[x+y*width]
// end function
// 
// Grid.set = function(x,y,value)
//   self.list[x+y*width] = value
// end function
// 
// Grid.setAll = function(value)
//   self.list = []
//   for i in range(self.width * self.height - 1)
//     self.list.push(value)
//   end for
// end function

// Determine a crop field from a single tile in that field.
// Tiles are considered part of the same field when they are 8-connected tilled earth tiles.
// So basically a floodfill for tilled earth tiles from the given position.
// Returns a map with all connected tilled earth tiles.
getField = function(position)
	if not position isa Position then return null
	test = function(tile)
		return tile.getType == "HoeDirt"
	end function

	tile = new Tile
	tile.fromPosition(position, farm)
	return tile.doFloodFillFromHere(@test)
end function

// -------------------------------
// Main program.
// -------------------------------

// Make the bot get water for the watering tool.
bot.goGetWater = function()
	self.goToPosition(routingInfo.waterFillPoint)
	self.select tools.watering.toolName
	self.useTool
end function

// Get the water level of the watering tool.
bot.getWateringToolWaterLevel = function()
	self.select tools.watering.toolName
	return self.inventory[self.currentToolIndex].waterLeft
end function

attendField = function()
	// Get the (tiles of the) field to attend to.
	field = getField(routingInfo.fieldToAttend)
	print "Gathered field information, " + field.len + " tile(s)"

	// Organize them in rows.
	rows = {}
	for tile in field.values
		if not rows.hasIndex(tile.y) then rows[tile.y] = { "y":tile.y }
		rows[tile.y][tile.x] = tile
	end for

	// Water each row in a logical order.
	sortedRows = rows.values
	sortedRows.sort("y")
	even = 0
	for row in sortedRows
		tiles = row.values
		tiles.sort("x")
		// Reverse the even rows watering order to reduce the amount of movement needed.
		// Also, the bot movements look way better this way :P
		if even then tiles.reverse
		even = not even

		// Manage the watering tool.
		// Obviously, this fails for rows with more tiles than the maximum water level of the tool.
		// But I don't like this to be checked for every tile.
		// So future versions might have changes to support larger row sizes.
		if bot.getWateringToolWaterLevel < tiles.len then
			bot.goGetWater
		end if

		for tile in tiles
			// One of the values is a y-coordinate.
			// And we only care about the dry tiles.
			if not tile isa Tile then continue
			if not tile.getIsDry then continue

			// Face the tile.
			targetPosition = bot.getClosestPositionFacingTile(tile)
			if bot.goToPosition(targetPosition) == false then
				print "Could not move to target position: "
				print targetPosition
				print "Aborting task"
				return
			end if

			bot.select tools.watering.toolName
			bot.useTool
		end for
	end for

	// The watering spot is also the resting/storage spot for the singular bot I'm using at the moment.
	bot.goGetWater
end function

program.run = function()
	if program.commandMode then
		while true
			print ""
			print "I can do the following:"
			print "- Attend field"
			print "- Quit"
			print "Please command me. "
			command = input("Command: ")

			if command == "Attend field" then
				attendField
			else if command == "Quit" then
				break
			else
				print "Unknow command: """ + command + """"
			end if
		end while

		print "Goodbye"
	else
		attendField
	end if
end function