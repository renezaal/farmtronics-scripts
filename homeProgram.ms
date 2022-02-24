import "baseProgram"
program.run = function()
	print "Generating map"
	lines = routingInfo.generateFarmMap
	print "Saving generated map"
	routingInfo.saveFarmMap(lines)
	print "Done"
end function