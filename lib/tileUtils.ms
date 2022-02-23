print "Imported tile utilities"
// Helper library for tiles.
// Mainly to retain and reuse the coordinates of the tile.
// Uses "positioningUtils".
globals.Tile = { "x":0, "y":0, "location":new Location, "info":{} }

Tile.refreshInfo = function()
	self.info = self.location.tile(self.x, self.y)
end function

Tile.initialize = function(x, y, location)
	qa.assert(location != null)
	self.x = x
	self.y = y
	self.location = location
	self.refreshInfo
end function

// Working with tiles made a bit easier.
Tile.fromPosition = function(position, location)
	self.initialize(position.x, position.y, location)
end function

// Gets all tiles neighbouring this tile.
// 8-connected.
Tile.getNeighbours = function()
	neighbours = []

	for yOffset in range(-1,1)
		for xOffset in range(-1,1)
			if xOffset == 0 and yOffset == 0 then continue
			neighbourX = self.x + xOffset;
			neighbourY = self.y + yOffset;
			if neighbourX < 1 or neighbourX > self.location.width - 2 then continue
			if neighbourY < 1 or neighbourY > self.location.height - 2 then continue

			neighbour = new Tile
			neighbour.initialize(neighbourX, neighbourY, self.location)
			neighbours.push(neighbour)
		end for
	end for

	return neighbours
end function

// Similar to Tile.getNeighbours but 4-connected.
Tile.getAdjacent = function()
	neighbours = []
	addNeighbour = function(x, y, location)
		if x < 1 or x > location.width - 2 then return
		if y < 1 or y > location.height - 2 then return

		neighbour = new Tile
		neighbour.initialize(x, y, location)
		outer.neighbours.push(neighbour)
	end function

	addNeighbour(self.x - 1, self.y + 0, self.location)
	addNeighbour(self.x + 1, self.y + 0, self.location)
	addNeighbour(self.x + 0, self.y - 1, self.location)
	addNeighbour(self.x + 0, self.y + 1, self.location)

	return neighbours
end function

// Gets a string that represents the coordinates of this tile.
// Can be used as a unique key for this tile in the location the tile belongs to.
Tile.getLocationKey = function()
	return self.x + ";" + self.y
end function

// Gets a tile by a location key and the location.
Tile.GetTileByLocationKey = function(key, location)
	tile = new Tile
	splitString = key.split(";")
	tile.initialize(splitString[0].val,splitString[1].val, location)
	return tile
end function

// Gets a globally unique key for this tile.
Tile.getGlobalKey = function()
	return location.name + self.getLocationKey
end function

// Short for reliably accessing self.info.type.
Tile.getType = function()
	if not self.info then return null
	if not self.info.hasIndex("type") then return null
	return self.info.type
end function

// Short for reliably accessing self.info.name.
Tile.getName = function()
	if not self.info then return null
	if not self.info.hasIndex("name") then return null
	return self.info.name
end function

// Short for reliably accessing self.info.dry.
Tile.getIsDry = function()
	if not self.info then return null
	if not self.info.hasIndex("dry") then return null
	return self.info.dry
end function

// Does a floodfill of 8-connected tiles using the provided test.
// Starts at the tile this function is called on.
Tile.doFloodFillFromHere = function(test)
	print "Floodfill started"
	visited = {}
	queue = [self]
	
	while queue.len > 0
		tile = queue.pull
		// print "x"+tile.x+"y"+tile.y+"t"+tile.getType
		if not tile then continue
		key = tile.getLocationKey

		if not test(tile) then continue
		if visited.hasIndex(key) then continue
		
		// At this point we know we have an unvisited, connected tile of the correct type.
		// Start with remembering our visit to this tile.
		visited[key] = tile

		// Then enqueue all neighbours.
		neighbours = tile.getNeighbours
		for neighbour in neighbours
			queue.push(neighbour)
		end for
	end while

	return visited
end function