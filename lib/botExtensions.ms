print "Imported bot extensions"
// Helper library with extension methods for bots.
// Mostly used for movement actions.
import "pathingUtils"

// Sets the facing of the bot.
bot.setFacing = function(facing)
	turns = 0;
	while self.facing != facing
		self.right
		turns = turns + 1
		if turns >= 4 then return
	end while
end function

// Move in the desired direction (same values as facing).
// Clears the target tile if the tile name is in the clearNames list.
// If the bot moved succesfully in the desired direction true is returned, otherwise false.
bot.doMove = function(direction, clearNames = null)
	if clearNames == null then clearNames = ["Tree", "Stone", "Twig", "Weeds", "Stump"]
	self.setFacing(direction)
	tileAhead = self.ahead

	// Wait for the player to step aside.
	// Doubles as an easy way to get a bot to stop moving.
	while tileAhead != null and tileAhead.type == "Character"
		wait
		tileAhead = self.ahead
	end while

	// pprint tileAhead
	// print clearNames
	if tileAhead != null and clearNames.indexOf(tileAhead.name) != null then
		self.clearAhead
	end if

	// According to my tests, moving forward consistently takes a bit longer than 1 second.
	// If the way is blocked by the player, it takes as long as needed, but still completes the move.
	// If the way is blocked by a non-moving obstacle, the move is aborted within 0.000035 seconds.
	// So testing for a move time above 0.1 seconds should be very reliable.
	// If it turns out to not be reliable, I'll just have to switch to checking if the bot position has changed.
	startTime = time
	self.forward
	deltaTime = time - startTime
	if deltaTime < 0.1 then print "Movement restricted @" + self.position.x + ";" + bot.position.y + " by: " + tileAhead
	return deltaTime > 0.1
end function

// Pathing for the bot.
bot.goToCoordinate = function(x,y)
	CustomCell = new pathfinding.Cell
	CustomCell.tile = new Tile
	CustomCell.requestingBotName = self.name
	CustomCell.getKey = function()
		return self.tile.getLocationKey
	end function
	CustomCell.getCost = function()
		name = self.tile.getName
		// This assumes baseProgram has been loaded.
		if routingInfo.costOf.hasIndex(name) then return routingInfo.costOf[name]
		if name == self.requestingBotName then return 0
		// Since the bot should be able to walk where a character is walking,
		// just assume the empty tile.
		if self.tile.getType == "Character" then  return routingInfo.costOf[null]
		// print "Cost restriced by: " + name + "@" + self.getKey
		return null
	end function
	CustomCell.getNeighbours = function()
		result = [];
		for element in self.tile.getAdjacent
			cell = new CustomCell
			cell.tile = element
			result.push(cell)
		end for
		return result
	end function

	fromTile = new Tile
	fromTile.initialize(self.position.x, self.position.y, self.position.area)
	fromCell = new CustomCell
	fromCell.tile = fromTile
	toTile = new Tile
	toTile.initialize(x, y, self.position.area)
	toCell = new CustomCell
	toCell.tile = toTile
	path = pathfinding.generatePath(fromCell, toCell)
	// pprint path
	
	for step in path
		tile = Tile.GetTileByLocationKey(step, self.position.area)
		xOffset = self.position.x - tile.x
		yOffset = self.position.y - tile.y
		if xOffset == 0 and yOffset == 0 then continue

		direction = -1
		if      yOffset ==  1 then
			direction = 0
		else if xOffset == -1 then
			direction = 1
		else if yOffset == -1 then
			direction = 2
		else if xOffset ==  1 then
			direction = 3
		end if

		print "Step: " + step + ", offset: " + xOffset + ";" + yOffset + " Direction: " + direction
		if direction == -1 then
			print "invalid offset, movement aborted"
			return false
		end if

		if self.doMove(direction) == false then return false
	end for

	return true
end function

// Makes the bot move to the given position.
bot.goToPosition = function(position)
	if not position isa Position then return
	if not self.goToCoordinate(position.x, position.y) then return false
	self.setFacing(position.facing)
	return true
end function

// Makes the bot move to the given tile.
// Doesn't really fit in this library, but it's the best place I've got for it at the moment.
bot.goToTile = function(tile)
	if not tile isa Tile then return
	return self.goToCoordinate(tile.x, tile.y)
end function

// Gets the position adjacent to the tile, facing the tile, that is closest for the bot.
bot.getClosestPositionFacingTile = function(tile)
	if not tile isa Tile then return
	position = new Position
	xOffset = 0;
	yOffset = 0;
	if self.position.y < tile.y then
		yOffset = -1
		position.facing = 2
	else if self.position.y > tile.y then
		yOffset = 1
		position.facing = 0
	else if self.position.x > tile.x then
		xOffset = 1
		position.facing = 3
	else
		xOffset = -1
		position.facing = 1
	end if

	position.x = tile.x + xOffset
	position.y = tile.y + yOffset
	return position
end function