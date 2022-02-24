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