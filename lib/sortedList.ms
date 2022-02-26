// A list that keeps itself sorted.
// Use list.add when adding values to keep list in sorted order.
// Use list.reSort when any values have been modified directly.
globals.SortedList = { "list":null }

// Function used to compare elements in the list.
// Overwrite when not using numbers.
// The compare function should have a signature like function(A, B).
// Accepted parameters should be values in this list.
// The compare function should return:
//		-1 if A precedes B
//		0 if A and B have the same order
//		1 if A succeeds B
// The default comparer simply does an inequality comparison (A < B).
// While -1, 0 and 1 are the preferred return values from a readability standpoint,
// this function may return any number < 0, 0 and any number > 0.
SortedList.compareFunction = function(a, b)
	// Example implementation of a compare function.
	// This example assumes the values provided are Number types.
	if a < b then return -1
	if a == b then return 0
	return 1
end function

// Adds a element to the given list using the comparer.
// Can net some strange results if the target list is not sorted.
addToList = function(element, list, compareFunction)
	i = 0
	while i < list.len
		order = compareFunction(element, list[i])
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
	return addToList(value, self.list, @self.compareFunction)
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

SortedList.pull = function
	return self.list.pull
end function

SortedList.pop = function
	return self.list.pop
end function

// |------------------------------------------
// |    Factory
// |------------------------------------------

// Provides factory methods for soted lists.
globals.SortedListFactory = {}

// Factory method for a SortedList instance.
// See <SortedList.compareFunction> for a description of the compareFunction.
SortedListFactory.create = function(compareFunction = null)
	sortedList = new SortedList
	sortedList.list = []
	if @compareFunction != null then sortedList.compareFunction = @compareFunction
	return sortedList
end function

// Factory method for a SortedList instance.
// Populates the list from the existing list.
// The existing list is not modified or linked by this function.
// See <SortedList.compareFunction> for a description of the compareFunction.
// If the list is already sorted, you can set isSorted to true to save a bit of performance.
SortedListFactory.createFrom = function(existingList, compareFunction = null, isSorted = false)
	sortedList = self.create(@compareFunction)
	
	for element in existingList
		sortedList.list.push(element)
	end for
	
	if not isSorted then sortedList.reSort
	return sortedList
end function