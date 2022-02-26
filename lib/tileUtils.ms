print "Imported tile utilities"
// Helper library for tiles.
// Mainly to retain and reuse the coordinates of the tile.
// Uses "positioningUtils".
globals.Tile = { "x":0, "y":0, "location":new Location, "info":{} }
Tile.Connectedness = { "eight":8, "four":4, "none":1 }

// Refresh the info contained in the tile.
Tile.refreshInfo = function()
	self.info = self.location.tile(self.x, self.y)
end function

// Gets all 8-connected tiles.
Tile.get8Connected = function()
	neighbours = []
	addNeighbour = function(x, y, location)
		if x < 1 or x > location.width - 2 then return
		if y < 1 or y > location.height - 2 then return

		neighbour = TileFactory.create(x, y, location)
		outer.neighbours.push(neighbour)
	end function

	addNeighbour(self.x - 1, self.y - 1, self.location)
	addNeighbour(self.x + 0, self.y - 1, self.location)
	addNeighbour(self.x + 1, self.y - 1, self.location)
	
	addNeighbour(self.x - 1, self.y + 0, self.location)
	addNeighbour(self.x + 1, self.y + 0, self.location)

	addNeighbour(self.x - 1, self.y + 1, self.location)
	addNeighbour(self.x + 0, self.y + 1, self.location)
	addNeighbour(self.x + 1, self.y + 1, self.location)

	return neighbours
end function

// Gets all 4-connected tiles.
Tile.get4Connected = function()
	neighbours = []
	addNeighbour = function(x, y, location)
		if x < 1 or x > location.width - 2 then return
		if y < 1 or y > location.height - 2 then return

		neighbour = TileFactory.create(x, y, location)
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
Tile.doFloodFillFromHere = function(test, connectedness = Tile.Connectedness.four)
	getNeighboursFunc = null
	if connectedness == Tile.Connectedness.four then
		getNeighboursFunc = function(tile)
			return tile.get4Connected
		end function
	else if connectedness == Tile.Connectedness.eight then
		getNeighboursFunc = function(tile)
			return tile.get8Connected
		end function
	else if connectedness == Tile.Connectedness.none then
		return [self]
	end if


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
		neighbours = getNeighboursFunc(tile)
		for neighbour in neighbours
			queue.push(neighbour)
		end for
	end while

	return visited.values
end function



// |------------------------------------------
// |    Factory
// |------------------------------------------

// Provides factory methods for tiles.
globals.TileFactory = {}

// Factory method for a Tile instance.
TileFactory.create = function(x, y, location)
	tile = new Tile
	qa.assert(location != null)
	tile.x = x
	tile.y = y
	tile.location = location
	tile.refreshInfo
	return tile
end function

// Factory method for a Tile instance.
TileFactory.createFromPosition = function(position, location)
	return self.create(position.x, position.y, location)
end function

// Factory method for a Tile instance.
TileFactory.createFromLocationKey = function(key, location)
	splitString = key.split(";")
	if splitString.len != 2 then exit
	return self.create(splitString[0].val,splitString[1].val, location)
end function