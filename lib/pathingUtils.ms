// Simple situation agnostic Dijkstra's implementation.
// Assumes the cost of travelling from A to B is purely determined by a cost in B.
// So no edges with weights here.
globals.pathfinding = {}
pathfinding.Cell = {}
pathfinding.Cell.getKey = function()
	return null
end function
pathfinding.Cell.getCost = function()
	return 1
end function
pathfinding.Cell.getNeighbours = function()
	return []
end function

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

// A list that keeps itself sorted.
globals.SortedList = { "list":[] }

// Function used to compare elements in the list.
// Overwrite when not using numbers.
SortedList.compareFunction = function(a, b)
	// Example implementation of a compare function.
	// This example assumes the values provided are Number types.
	if a < b then return -1
	if a == b then return 0
	return 1
end function

// Adds a element to the given list using the comparer.
// Can net some strange results if the target list is not sorted.
SortedList.addToList = function(element, list)
	i = 0
	while i < list.len
		order = self.compareFunction(element, list[i])
		if order < 0 then
			list.insert(i, element)
			return i
		end if
		i = i + 1
	end while

	list.push(element)
	return list.len - 1
end function

// Adds a value to the sorted list.
// Returns the index of the element in the list.
SortedList.add = function(value)
	return self.addToList(value, self.list)
end function

// Re-sorts the list using the existing comparison function.
// Uses bog standard insertion sort, so use sparingly.
// May be upgraded to mergesort in the future.
// But insertion sort is good enough for small amounts of elements.
// Does not need to be called when using only SortedList.add for adding and modifying values in the list.
// Not tested, but should be a stable sort the way I implemented it...
SortedList.reSort = function()
	temp = []
	for element in self.list
		self.addToList(element, temp)
	end for

	for i in range(0, self.list.len - 1)
		self.list[i] = temp[i]
	end for
end function

// Makes the list into a sorted list.
// Use list.pushSorted when adding values to keep list in sorted order.
// Use list.reSortSorted when any values have been modified directly.
// The optional compare function should have a signature like function(A, B).
// Accepted parameters should be values in this list.
// The compare function should return:
//		-1 if A precedes B
//		0 if A and B have the same order
//		1 if A succeeds B
// The default comparer simply does an inequality comparison (A < B).
// While those are the preferred return values from a readability standpoint,
// this function reads any number < 0 as -1 and any number > 0 as 1.
// Returns the new SortedList.
SortedList.createNewFrom = function(list, compareFunction = null)
	sortedList = new SortedList
	if @compareFunction != null then sortedList.compareFunction = @compareFunction
	sortedList.reSort
	return sortedList
end function

SortedList.pull = function
	return self.list.pull
end function

SortedList.pop = function
	return self.list.pop
end function

// Generates a path from the starting cell to the target cell.
// Returns a list of all cell ids in the order of the path.
// Returns null if no path could be found.
globals.pathfinding.generatePath = function(startCell, targetCell)
	targetCellId = targetCell.getKey
	sortedList = new SortedList
	sortedList.compareFunction = function(a, b)
		if a.id == targetCellId then return -1
		if a.pathCost < b.pathCost then return -1
		return 0
	end function

	cellInfos = {}
	cellInfo = { "pathCost":0, "id":startCell.getKey, "previous":null, "cell":startCell }
	cellInfos[cellInfo.id] = cellInfo
	print "From: " + cellInfo.id + ", to: " + targetCellId

	// Keep track of time for abort if needed.
	startTime = time
	maxTime = 60
	// And work in small batches as to not lag the player.
	batchSize = 50
	batchCounter = 1

	// Somewhat inefficient way to break off when the target cell is found.
	// Since it could go on for many iterations if the cost for entering the target cell is very high.
	// To cirumvent that, the compare function of the sorted list has a special case for the target cell.
	// It's a bit hack-ish, but I'm lazy.
	while cellInfo != null and cellInfo.id != targetCellId
		// print "pathfinding outer loop"
		for neighbour in cellInfo.cell.getNeighbours
			neighbourCost = neighbour.getCost

			// A cost of null is deemed inaccessible.
			// Inaccessible cells are skipped when pathfinding.
			if neighbourCost == null then continue
			neighbourId = neighbour.getKey
			neighbourPathCost = cellInfo.pathCost + neighbourCost

			// If this is the shortest path to this (neighbour) cell found so far.
			// Then remember this path. And schedule the neighbour for re-evaluation.
			if not cellInfos.hasIndex(neighbourId) then
				// By creating a new cellInfo if none exists.
				neighbourInfo = { "pathCost":neighbourPathCost, "id":neighbourId, "previous":cellInfo.id, "cell":neighbour }
				// print "New: " + neighbourInfo.id
				cellInfos[neighbourInfo.id] = neighbourInfo
				sortedList.add(neighbourInfo)
			else if cellInfos[neighbourId].pathCost > neighbourPathCost then
				// Or by modifying the existing one.
				neighbourInfo = cellInfos[neighbourId]
				// print "Old: " + neighbourInfo.id
				neighbourInfo.pathCost = neighbourPathCost
				neighbourInfo.previous = cellInfo.id
				sortedList.add(neighbourInfo)
			end if
		end for

		if time - startTime > maxTime then
			print "Maximum pathfinding time ("+ maxTime +"s) reached."
			exit
		end if

		if batchCounter > batchSize then
			batchCounter = 0
			// Micro break.
			wait(0.1)
		end if

		batchCounter = batchCounter + 1
		cellInfo = sortedList.pull
	end while

	print "Pathfinding took " + (time - startTime) + "s"

	if cellInfo == null then
		print "No route found"
		return null
	end if

	// At this point, cellInfo.cell == targetCell.
	result = []
	id = cellInfo.id
	while id != null
		result.insert(0, id)
		id = cellInfos[id].previous
		if result.len > 10000 then
			print "The result is larger than expected."
			pprint result[:100]
			pprint result[-100:]
			return null
		end if
	end while
	return result

	// While it might seem that this function uses an unnecessary amount of local variables,
	// keep in mind that we do not know the computational cost of the cell functions like getKey and getCost.
	// So by buffering the results in local variables, we reduce the potential overhead in return for a tiny storage penalty.
end function
