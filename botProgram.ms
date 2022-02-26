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

// -------------------------------
// Main program.
// -------------------------------

// Make the bot get water for the watering tool.
bot.goGetWater = function()
	if self.goToPosition(routingInfo.waterFillPoint) != botExtensions.MoveResult.success then
		print "Could not move to water fill point: "
		print routingInfo.waterFillPoint
		print "Aborting all tasks"
		exit
	end if

	self.select tools.watering.toolName
	self.useTool
end function

// Get the water level of the watering tool.
bot.getWateringToolWaterLevel = function()
	self.select tools.watering.toolName
	return self.inventory[self.currentToolIndex].waterLeft
end function

loadFields = function()
	lines = file.readLines("/usr/resources/fields.txt")
	fields = []
	field = []
	for line in lines
		if line.len > 0 then
			if line[0] == "F" then
				if field.len > 0 then
					fields.push(field)
					field = []
				end if
			else
				tile = TileFactory.createFromLocationKey(line, farm)
				field.push(tile)
			end if
		end if
	end for

	if field.len > 0 then fields.push(field)
	return fields
end function

attendField = function(field)
	// Organize the tiles in rows.
	rows = {}
	for tile in field
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

		for tile in tiles
			// One of the values is a y-coordinate.
			// And we only care about the dry tiles.
			if not tile isa Tile then continue
			if not tile.getIsDry then continue
			
			// Manage the watering tool.
			if bot.getWateringToolWaterLevel < 4 then
				bot.goGetWater
			end if

			// Face the tile.
			if bot.goFaceCoordinate(tile.x, tile.y) != botExtensions.MoveResult.success then
				print "Could not move to target position: "
				print targetPosition
				print "Aborting task"
				return
			end if

			botTile = TileFactory.create(bot.position.x, bot.position.y, bot.position.area)
			for adjacentTile in botTile.get4Connected
				if not adjacentTile.getIsDry then continue
				bot.setFacing(positioningUtils.getFacing(bot.position.x, bot.position.y, adjacentTile.x, adjacentTile.y))
				bot.select tools.watering.toolName
				bot.useTool
			end for
		end for
	end for

	// The watering spot is also the resting/storage spot for the singular bot I'm using at the moment.
	bot.goGetWater
end function

attendFields = function
	fields = loadFields
	for field in fields
		attendField(field)
	end for
end function

program.run = function()
	if program.commandMode then
		while true
			print ""
			print "I can do the following:"
			print "- Attend fields"
			print "- Quit"
			print "Please command me. "
			command = input("Command: ")

			if command == "Attend fields" then
				attendFields
			else if command == "Quit" then
				break
			else
				print "Unknow command: """ + command + """"
			end if
		end while

		print "Goodbye"
	else
		attendFields
	end if
end function