import "baseProgram"

// Determine a crop field from a single tile in that field.
// Tiles are considered part of the same field when they are 8-connected tilled earth tiles.
// So basically a floodfill for tilled earth tiles from the given position.
// Returns a map with all connected tilled earth tiles.
getField = function(x, y)
	test = function(tile)
		return tile.getType == "HoeDirt"
	end function

	tile = TileFactory.create(x, y, farm)
	return tile.doFloodFillFromHere(@test, Tile.Connectedness.eight)
end function

// Generates a list of fields on the farm.
generateFieldList = function()
	// A list of lists of tiles.
	fields = []
	visited = {}

	for y in range(1,farm.height-1)
		for x in range(1,farm.width-1)
			tile = TileFactory.create(x, y, farm)
			if visited.hasIndex(tile.getLocationKey) then continue
			if tile.getType == "HoeDirt" then
				field = getField(x, y)
				fields.push(field)

				for fieldTile in field
					visited[fieldTile.getLocationKey] = true
				end for
			end if

			visited[tile.getLocationKey] = true
		end for
	end for

	return fields
end function

saveFields = function(fields)
	f = file.open("/usr/resources/fields.txt", "w")
	i = 0
	for field in fields
		i = i + 1
		f.writeLine("Field " + i + ", Size: " + field.len)
		for tile in field
			f.writeLine(tile.getLocationKey)
		end for
	end for
	f.close
end function




program.run = function()
	print "Generating map"
	lines = routingInfo.generateFarmMap
	print "Saving generated map"
	routingInfo.saveFarmMap(lines)
	print "Done"

	print "Generating field list"
	fieldList = generateFieldList
	print "Saving generated list"
	saveFields(fieldList)
	print "Done"
end function