// Returns a list of key-value pairs sorted by value.
// If a key function is defined, the result is sorted by the result of the key function.
// The key function should accept any value in the map as parameter.
map.sorted = function(keyFunc = null, descending = false)
	reverse = function(list)
		result = []
		for i in range(1, list.len)
			result.push(list[list.len - i])
		end for
	end function

	result = []
	if keyFunc == null then
		for keyValuePair in self
			result.push({ "order":keyValuePair.value, "keyValuePair":keyValuePair })
		end for
	else
		for keyValuePair in self
			result.push({ "order":keyFunc(keyValuePair.value), "keyValuePair":keyValuePair })
		end for
	end if

	result.sort("order")
	if descending then result = reverse(result)
	return result
end function

TimeSlicer = { "sliceStartTime":1, "sliceSize":0.1, "slicePart":0.01, "currentSlicePartEnd":1 }
TimeSlicer.start = function()
	self.sliceStartTime = time
	self.currentSlicePartEnd = self.sliceStartTime + self.sliceSize * self.slicePart
end function
TimeSlicer.waitIfNeeded = function()
	if time > self.currentSlicePartEnd then
		// Micro break.
		wait(self.sliceSize * (1 - self.slicePart))
		self.sliceStartTime = time
		self.currentSlicePartEnd = self.sliceStartTime + self.sliceSize * self.slicePart
	end if
end function

getOrganizedRows = function(xyObjects)
	// Assumes every object sent is a map with an "x" and a "y" key.
	// Organize them in rows.
	rows = {}
	for xyObject in xyObjects
		if not rows.hasIndex(xyObject.y) then rows[xyObject.y] = { "y":xyObject.y }
		rows[xyObject.y][xyObject.x] = xyObject
	end for

	// Sort the rows.
	result = []
	sortedRows = rows.values
	sortedRows.sort("y")
	for row in sortedRows
		xys = []
		for value in row.values
			if value isa number then continue
			xys.push(value)
		end for
		xys.sort("x")
		result.push(xys)
	end for
	return result
end function


// Simple situation agnostic Dijkstra's implementation.
// Assumes the cost of travelling from A to B is purely determined by a cost in B.
// So no edges with weights here.
globals.pathfinding = {}

logPathfindingVariables = function(knownCells, startCell, targetCell, targetCellId, result = [])
	lines = []
	for element in knownCells.values
		lines.push("id:" + element.id + ", previous:" + element.previous + ", pathCost:" + element.pathCost + ", cost:" + element.cost)
	end for

	// Log to a file.
	file.makedir("logs")
	logFile = file.open("logs/pathing.log","a")
	logFile.writeLine(startCell)
	logFile.writeLine(targetCell)

	for line in result
		logFile.writeLine(line)
	end for
	for line in lines
		logFile.writeLine(line)
	end for

	// Now for a direction map.
	xys = []
	minX = 999999
	for element in knownCells.values
		// Yes, this is knowledge about the key that this code should not have.
		coordinate = element.id.split(";")
		x = coordinate[0].val;
		xys.push({"x":x,"y":coordinate[1].val,"info":element.id,"previous":element.previous})
		if x < minX then minX = x
	end for
	
	rows = getOrganizedRows(xys)
	
	for row in rows
		line = " " * (row[0].x - minX)
		for xyInfo in row
			symbol = "O"
			previousX = xyInfo.x
			previousY = xyInfo.y
			if xyInfo.previous != null then
				previousKeySplit = xyInfo.previous.split(";")
				previousX = previousKeySplit[0].val
				previousY = previousKeySplit[1].val
				
				arrows = "←→↑↓"
				if xyInfo.info == targetCellId then arrows = "<>Δ∇"
				if previousX == xyInfo.x - 1 and previousY == xyInfo.y then symbol = arrows[0] // Left
				if previousX == xyInfo.x + 1 and previousY == xyInfo.y then symbol = arrows[1] // Right
				if previousY == xyInfo.y + 1 and previousX == xyInfo.x then symbol = arrows[3] // Down
				if previousY == xyInfo.y - 1 and previousX == xyInfo.x then symbol = arrows[2] // Up
			end if
			line = line + symbol
		end for
		logFile.writeLine(line)
	end for

	logFile.close
end function

// Generates a path from the starting cell to the target cell.
// Returns a list of all cell ids in the order of the path.
// Returns null if no path could be found.
globals.pathfinding.generatePath = function(startCell, targetCell, getIdFunc, getCostFunc, getNeighboursFunc)
	targetCellId = getIdFunc(targetCell)
	sortedList = new SortedList
	sortedList.compareFunction = function(a, b)
		if a.id == targetCellId then return -1
		if a.pathCost < b.pathCost then return -1
		return 0
	end function

	knownCells = {}
	cellInfo = { "cost":0.01, "pathCost":0.01, "id":getIdFunc(startCell), "previous":null, "cell":startCell }
	knownCells[cellInfo.id] = cellInfo
	print "From: " + cellInfo.id + ", to: " + targetCellId

	// Keep track of time for abort if needed.
	startTime = time
	maxComputeTime = 30

	// And work in small batches as to not lag the player.
	timeSlicer = new TimeSlicer
	timeSlicer.slicePart = 0.9
	timeSlicer.start

	// Main pathfinding loop.
	while cellInfo != null and cellInfo.id != targetCellId
		neighbours = getNeighboursFunc(cellInfo.cell)
		for neighbour in neighbours
			// Get the identifier for this neighbour.
			neighbourId = getIdFunc(neighbour)

			// Create a new cellInfo if it does not exist.
			if not knownCells.hasIndex(neighbourId) then
				// Get the cost for moving to this neighbour.
				neighbourCost = getCostFunc(neighbour)

				// A cost of null is deemed inaccessible.
				// Inaccessible cells are skipped when pathfinding.
				if neighbourCost == null then continue

				// A non-positive cost is considered erroneous.
				if not neighbourCost > 0 then
					print "A cost of 0 or lower is not allowed, cost: " + neighbourCost
					continue
				end if

				// Initialized with a slightly higher path cost to trigger scheduling for evaluation.
				// Store in the known cells map.
				knownCells[neighbourId] = { "cost":neighbourCost, "pathCost":cellInfo.pathCost + neighbourCost + 1, "id":neighbourId, "previous":null, "cell":neighbour }
			end if

			neighbourInfo = knownCells[neighbourId]
			predictedNeighbourPathCost = cellInfo.pathCost + neighbourInfo.cost

			// If this is the shortest path to this (neighbour) cell found so far.
			// Then remember this path. And schedule the neighbour for re-evaluation.
			if predictedNeighbourPathCost < neighbourInfo.pathCost then
				neighbourInfo = knownCells[neighbourId]
				neighbourInfo.pathCost = predictedNeighbourPathCost
				neighbourInfo.previous = cellInfo.id
				sortedList.add(neighbourInfo)
			end if
		end for

		if time - startTime > maxComputeTime / timeSlicer.slicePart then
			print "Maximum pathfinding time ("+ maxTime +"s) reached."
			logPathfindingVariables(knownCells, startCell, targetCell, targetCellId)
			exit
		end if

		timeSlicer.waitIfNeeded

		cellInfo = sortedList.pull
	end while

	print "Pathfinding took " + (time - startTime) + "s"

	if cellInfo == null then
		print "No route found"
		return null
	end if

	// At this point, cellInfo.cell == targetCell.
	temp = cellInfo

	result = []
	startId = getIdFunc(startCell)

	// Follow the found path from end to start while saving the results in reverse order.
	while cellInfo.id != startId
		cellInfo.processed = true
		result.insert(0, cellInfo.cell)
		cellInfo = knownCells[cellInfo.previous]

		// Just detecting and logging circular references.
		if cellInfo.hasIndex("processed") then
			print "Circular reference detected in the result path."
			logPathfindingVariables(knownCells, startCell, targetCell, targetCellId, result)
			exit
		end if
	end while
	return result

	// While it might seem that this function uses an unnecessary amount of local variables,
	// keep in mind that we do not know the computational cost of the cell functions like getKey and getCost.
	// So by buffering the results in local variables, we reduce the potential overhead in return for a tiny storage penalty.
end function
