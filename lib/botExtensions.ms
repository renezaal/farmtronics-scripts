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

MoveResult = { "success":1, "blockedByObject":2, "inaccessible":3 }
// Move in the desired direction (same values as facing).
// Clears the target tile if the tile name is in the clearNames list.
// If the bot moved succesfully in the desired direction true is returned, otherwise false.
bot.doMove = function(direction, clearNames = null)
	if clearNames == null then clearNames = ["Tree", "Stone", "Twig", "Weeds", "Stump"]
	self.setFacing(direction)
	tileAhead = self.ahead

	targetCoordinates = positioningUtils.getFacedCoordinates(self.position.x, self.position.y, self.facing)
	if routingInfo.isInaccessible(targetCoordinates.x, targetCoordinates.y) then return MoveResult.inaccessible

	// Wait for the player to step aside.
	// Doubles as an easy way to get a bot to stop moving.
	while tileAhead != null and tileAhead.type == "Character"
		wait
		tileAhead = self.ahead
	end while

	if tileAhead != null and clearNames.indexOf(tileAhead.name) != null then
		self.clearAhead
	end if

	moved = false
	tries = 0
	while not moved and tries < 3
		oldSpot = {"x":self.position.x, "y":self.position.y}
		self.forward
		moved = oldSpot.x != self.position.x or oldSpot.y != self.position.y
		tries = tries + 1
	end while

	if not moved then
		print "Movement restricted @" + self.position.x + ";" + bot.position.y + " by: " + self.ahead
		if self.ahead == null then
			routingInfo.registerInaccessibleTile(targetCoordinates.x, targetCoordinates.y)
			return MoveResult.inaccessible
		end if
		return MoveResult.blockedByObject
	end if

	return MoveResult.success
end function

// Pathing for the bot.
bot.findPathTo = function(x, y)
	CustomCell = { "tile":null, "requestingBotName":self.name }

	getIdFunc = function(cell)
		return cell.tile.getLocationKey
	end function

	getCostFunc = function(cell)
		// This assumes baseProgram has been loaded.
		if routingInfo.isInaccessible(cell.tile.x, cell.tile.y) then return null
		name = cell.tile.getName
		if routingInfo.costOf.hasIndex(name) then return routingInfo.costOf[name]
		if name == cell.requestingBotName then return 0.01
		// Since the bot should be able to walk where a character is walking,
		// just assume the most expensive walkable tile.
		if cell.tile.getType == "Character" then  return routingInfo.costOf["HoeDirt"]
		// print "Cost restriced by: " + name + "@" + cell.getKey
		return null
	end function

	getNeighboursFunc = function(cell)
		result = [];
		for element in cell.tile.getAdjacent
			newCell = new CustomCell
			newCell.tile = element
			result.push(newCell)
		end for
		return result
	end function

	fromCell = new CustomCell
	fromCell.tile = new Tile
	fromCell.tile.initialize(self.position.x, self.position.y, self.position.area)

	toCell = new CustomCell
	toCell.tile = new Tile
	toCell.tile.initialize(x, y, self.position.area)
	
	return pathfinding.generatePath(fromCell, toCell, @getIdFunc, @getCostFunc, @getNeighboursFunc)
end function

bot.followPath = function(path)
	for step in path
		tile = step.tile
		direction = positioningUtils.getFacing(self.position.x, self.position.y, tile.x, tile.y)

		print "Step: " + tile.getLocationKey + " Direction: " + direction
		if direction == null then
			print "invalid offset, movement aborted"
			return false
		end if

		moveResult = self.doMove(direction)
		if moveResult != MoveResult.success then return moveResult
	end for
	return MoveResult.success
end function

bot.goToCoordinate = function(x, y)
	moveResult = MoveResult.inaccessible
	triesWithoutMoving = 0
	oldSpot = {"x":self.position.x, "y":self.position.y}
	while moveResult == MoveResult.inaccessible and triesWithoutMoving < 4
		path = self.findPathTo(x, y)
		moveResult = self.followPath(path)

		triesWithoutMoving = triesWithoutMoving + 1
		moved = oldSpot.x != self.position.x or oldSpot.y != self.position.y
		oldSpot = {"x":self.position.x, "y":self.position.y}
		if moved then triesWithoutMoving = 0
	end while
	routingInfo.saveInaccessibleTiles
	return moveResult
end function

// Makes the bot move to the given position.
bot.goToPosition = function(position)
	if not position isa Position then return
	if self.goToCoordinate(position.x, position.y) != MoveResult.success then return false
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
		position.facing = Facing.south
	else if self.position.y > tile.y then
		yOffset = 1
		position.facing = Facing.north
	else if self.position.x > tile.x then
		xOffset = 1
		position.facing = Facing.west
	else
		xOffset = -1
		position.facing = Facing.east
	end if

	position.x = tile.x + xOffset
	position.y = tile.y + yOffset
	return position
end function