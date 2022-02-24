print "Imported positioning utilities"

// Simple class describing a bot position.
globals.Position = { "x":0, "y":0, "facing":0 }

globals.Facing = { "north":0, "east":1, "south":2, "west":3 }
Facing.n = Facing.north
Facing.N = Facing.north
Facing.North = Facing.north
Facing.e = Facing.east
Facing.E = Facing.east
Facing.East = Facing.east
Facing.s = Facing.south
Facing.S = Facing.south
Facing.South = Facing.south
Facing.w = Facing.west
Facing.W = Facing.west
Facing.West = Facing.west

// Returns the coordinates faced from the given position with the given facing.
// Returns null if the facing is invalid.
getFacedCoordinates = function(x, y, facing)
	if facing == Facing.N then return {"x":x  , "y":y-1}
	if facing == Facing.E then return {"x":x+1, "y":y  }
	if facing == Facing.S then return {"x":x  , "y":y+1}
	if facing == Facing.W then return {"x":x-1, "y":y  }
	return null
end function

// Returns the coordinates faced from the given position with the given facing.
// Returns null if the facing is invalid.
getFacedCoordinatesFromPosition = function(position)
	return getFacedCoordinates(position.x, position.y, position.facing)
end function

// Returns the way you are facing if looking from "from" to "to".
// Null if from and to are the same.
getFacing = function(fromX, fromY, toX, toY)
	if toY < fromY then return Facing.N
	if toX > fromX then return Facing.E
	if toY > fromY then return Facing.S
	if toX < fromX then return Facing.W
	return null
end function