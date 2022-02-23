// Basically a library imitating the C# linq ideas.
// Although lambda's are impossible, this will help a bit for those accustomed to C# linq.
// Also at the moment, unlike linq, these functions will not wait to execute until the result is actualized.
// They execute directly when called.
// In the future, that will change.
// Also in the future, these functions will be extended to strings and maps.
// That being said, let's start with the most used two.

// Select the part of the elements that you wish to return.
// Can be used to transorm the elements into different objects.
list.select = function(func)
	print "select" + @func
	result = [];
	for element in self
		result.push(func(element))
	end for
	return result
end function

// Return only those elements in the list where the function returns true.
list.where = function(func)
	print "where" + @func
	result = []
	for element in self
		if func(element) == true then result.push(element)
	end for
	return result
end function
