// Hello,
// This is a script aimed at making it easy for people to get started with farmtronics.
// I am René, also known as Epiphaner, I will be your guide throughout this program.

// Code looks best when viewed in a monospace font, this code too.
// Everything on a line after two slashes "//" is not read as code.
// Statements like this are called comments.

// Before you run the script, try to understand it a bit.
// You also may want to tweak the configuration.
// The configuration can be found by searching for the keyword "Configuration".
// You can load this program into your bot by placing it in the "usrdisk" folder in your Stardew Valley save folder.
// Then, on your bot type: load "beginnerScript"
// Press enter, it should then be loaded.
// The just type: run
// And press enter again. 
// The program should now run.

// This script is only for bots, so if this is not running on a bot, we exit the program.
if not bot then
	print("This program can only be run on a bot")
	exit
end if

// While you may expect the program to begin directly after that, first we need to do some set-up.
// Setting up imports, helpers and main functions makes it easier to program.
// Also the resulting program is, in my opinion, easier to read.

// |---------------|
// |    Imports    |
// |---------------|
// We import some standard farmtronics libraries.
// You may think of a library like a set of functions and helpers we can use to build our program.
// First we import the list utilities.
import "listUtil"

// |---------------|
// |    Helpers    |
// |---------------|
// We create some helper functions, helpers for short.
// Helpers are functions that are not productive by themselves, but may be used by other parts of the program to produce results.
// Like how a hammer is not productive until you start using it.

// The first helper is for making the bot turn in a specific direction.
// This is so that we don't have to count turns later on in the program.
// "bot" is the robot.
// "turnToDirection" does not exist, we create it by assigning something.
// Assignment is done with the "=".
// Here we assign a function to bot.turnToDirection.
// A function can take zero or more values as input.
// These input values are called parameters.
// This function takes one parameter, "direction".
bot.turnToDirection = function(direction)
	// Direction can be one of four values: 0, 1, 2 or 3.
	// 0 is north, 1 is east, 2 is south and 3 is west.
	// To make the bot turn to the desired facing, we just turn the bot right until it's facing is correct.
	// Since there are only four directions the bot can face, if it has turned four times and has not faced the right way, the direction we got is not valid.

	// Keep track of the amount of times the bot has turned.
	timesTurned = 0

	// Keep turning until the bot faces in the desired direction.
	while bot.facing != direction
		// Do the turn
		// While it is not needed to add the empty brackets after the function, I like to make clear that we're calling a function.
		// So it's just a visual aid at this point. 
		// It would behave the same if the line was "bot.right".
		bot.right()
		// And count one for the amount of times turned.
		timesTurned = timesTurned + 1

		if timesTurned == 4 then
			// Checks and output like this can make it a lot easier to find out why things go wrong when they do.
			print("The bot has turned 4 times but did not face the desired direction")
			print("The direction given was: " + direction)

			// Since something went wrong, we exit the program.
			exit
		end if
	end while
end function

// Helpers come in many shapes and sizes.
// Some can be really small.
// This one just prints some text if the bot is low on energy.
// We just put it in a function because it is used so often.
bot.checkEnergy = function()
	if bot.energy() == 0 then
		print("The bot is out of energy")
	end if
end function

// The next helper is to make the bot go move into a direction.
// This uses the previous helper function (bot.turnToDirection) for more complex patterns.
// This helper also takes a list as parameter.
// Whatever is in the list, the bot is allowed to clear if it is in the way.
// Using an assignment to the parameter, we specify a default.
// If no value is provided for the parameter, the default is used.
// Here the default value for "allowedToClear" is "[]", an empty list.
// So by default, this function will not clear a tile.
bot.moveInDirection = function(direction, allowedToClear = [])
	// First, turn to face the direction.
	// Here you can see we are already using the earlier helper function.
	bot.turnToDirection(direction)

	// Then, check the name and type of whatever is ahead.
	// The check may return null (no value) if the tile is empty.
	// If a value is null, you cannot access any of its fields or functions.
	// Doing so will result in an error.
	// Also, if the tile is empty, we don't need to clear it.
	// So access the clearing code on the condition that the tile is not empty.
	tile = bot.ahead()
	if tile != null then
		// If it is in the list of things we are allowed to clear, clear it.
		// This uses the single line version of the conditional logic control block.
		if allowedToClear.contains(tile.type) or allowedToClear.contains(tile.name) then bot.clearAhead()

		// Special case, if the tile ahead contains the player, wait for the player to move.
		// Tell the player why the bot is standing still.
		if tile.type == "Character" then
			print("Waiting for player to move away")
			while tile.type == "Character"
				// Wait waits for the amount of seconds you give it, the default is 1.
				wait(0.5)
				tile = bot.ahead()
			end while
		end if
	end if

	// Remember our current position.
	// We can use this to check if the bot has actually moved.
	oldPosition = { "x":bot.position.x, "y":bot.position.y }
	// Then, do the actual move forward.
	bot.forward()

	// If the x and y of the old position are the same as the x and y of the current position, we did not move.
	if bot.position.x == oldPosition.x and bot.position.y == oldPosition.y then
		// Now, if we did not move, something is wrong.
		// So we try to output what went wrong.
		print("The bot was unable to move")

		// Check if we have the energy to move.
		bot.checkEnergy()

		// Check if something is in the way.
		tile = bot.ahead()
		if tile != null then
			// Not everything blocks the bot from entering a tile.
			canEnter = ["Grass", "HoeDirt"]
			if not (canEnter.contains(tile.type) or canEnter.contains(tile.name)) then
				print("The bot was blocked by " + tile.type + " or " + tile.name)
				// Report if the bot was blocked by something it was allowed to clear or not.
				if allowedToClear.contains(tile.type) or allowedToClear.contains(tile.name) then
					print("The bot was allowed to clear the obstacle")
					print("So something probably went wrong with clearing it")
				else
					print("The bot was not allowed to clear the obstacle")
				end if
			end if
		end if

		// Finally, since we could not do the move and something is wrong, we exit the program.
		exit
	end if
end function

// X and y are numbers representing coordinates.
// From here on out, I will refer to coordinates with the notation [x; y].
// So [12; 30] refers to coordinates with x = 12 and y = 30.
// The top left of the map is [0; 0].
// The bottom right is [map.width; map.height].
// The y is counted in rows from the top of the map.
// The x is counted in columns from the left of the map.
// So the tile to the right of [12; 30] is [13; 30].
// And the one above [12; 30] is [12; 29].
// This function has the bot going from wherever it is standing, to [x; y].
// Like before with moveInDirection, we get a list telling us what the bot is allowed to clear.
bot.goTo = function(x, y, allowedToClear = [])
	// The path this takes is straight.
	// If no straight line is possible, it takes two straight lines.
	// The "elbow" between the lines is always low.
	// So when going from [42; 55] to [67; 20] or vice versa, the bot first goes to [67; 55] (remember, 55 is lower on the map than 20).
	// This way the bot moves in more consistent patterns, making it easier to plan for.

	// First, as long as we are above the target coordinates, move down.
	while bot.position().y < y
		// Remember, 2 is south.
		bot.moveInDirection(2, allowedToClear)
	end while

	// Then, move right as needed.
	while bot.position().x < x
		// Remember, 1 is east.
		bot.moveInDirection(1, allowedToClear)
	end while

	// Then, move left as needed.
	while bot.position().x > x
		// Remember, 3 is west.
		bot.moveInDirection(3, allowedToClear)
	end while

	// Finally, move up as needed.
	while bot.position().y > y
		// Remember, 0 is north.
		bot.moveInDirection(0, allowedToClear)
	end while
end function

// I don't like it when the tool is already selected that the bot would still print that it selected the tool.
// So this function is just a bit of sanitation of the output.
// You can ignore this for now and read it as a replacement for bot.select().
bot.selectToolWithoutUnnecessaryPrint = function(toolNameOrIndex)
	if bot.currentToolIndex() == toolNameOrIndex then return
	if bot.inventory()[self.currentToolIndex()].name == toolNameOrIndex then return
	bot.select(toolNameOrIndex)
end function

// Tills the tile in front of the bot.
// Notice that I refer to the bot with "self".
// In this function, "bot" and "self" are interchangeable.
// If you call a function on an object like calling "till" on "bot" with "bot.till()",
// then "self" refers to the object. So here "self" refers to "bot".
bot.till = function()
	self.selectToolWithoutUnnecessaryPrint("Hoe")
	self.useTool()
end function

// Waters the tile in front of the bot.
bot.water = function()
	self.selectToolWithoutUnnecessaryPrint("Watering Can")
	self.useTool()
end function

// Gets the water level of the watering can in the bot inventory.
bot.getWaterLevel = function()
	self.selectToolWithoutUnnecessaryPrint("Watering Can")
	return self.inventory()[self.currentToolIndex()].waterLeft
end function

// Gets the water level of the watering can in the bot inventory.
bot.getMaxWaterLevel = function()
	self.selectToolWithoutUnnecessaryPrint("Watering Can")
	return self.inventory()[self.currentToolIndex()].waterMax
end function

// Gets the distance from the bot to the given coordinates.
bot.getDistanceFrom = function(x, y)
	return abs(x - bot.position.x) + abs(y - bot.position.y)
end function

// |---------------|
// |  Subprograms  |
// |---------------|
// Subprograms are small programs that could be used by themselves, but are used in support of the main program.

// This is the first function not in the context of bot.
// This adds the function to the locals of this program.
// Also, this is the first function with a return value.
// So far, when we called a function, we expected nothing back from the function.
// When calling this function, it is all about what it gives back.
// This function detects the fields on the farm.
// For each field, it gives back the top left coordinates of the field, its width and its height.
detectFields = function()
	// This list will be filled with all the fields that we find.
	fields = []

	// We use this list to know when to skip tiles that belong to a field we already detected.
	isPartOfExistingField = list.init2d(farm.width, farm.height, false)

	// We start from the top left and go to the bottom right row by row.
	// This makes it so that the first tile of any field found is the top left.
	// The for loop goes through a list of elements.
	// The range function gives a list of numbers.
	// So this for loop goes over each y-coordinate on the farm.
	// The "-1" is needed to make sure we are not checking tiles beyond the bounds of the farm.
	for y in range(0, farm.height - 1)
		// And this one goes over each x-coordinate on the farm.
		for x in range(0, farm.width - 1)
			// Skip this coordinate if it is part of an existing field.
			// The continue command skips to the next iteration of the innermost loop.
			if isPartOfExistingField[x][y] then continue

			// We get the tile from the farm.
			tile = farm.tile(x, y)

			// We can't read the tile when the player is standing there.
			// This might mess up the detection, so we must wait.
			if tile != null and tile.type == "Character" then
				print("Waiting for player to move away")
				while tile != null and tile.type == "Character"
					wait(0.5)
					tile = farm.tile(x, y)
				end while
			end if

			// Check if it is a field tile.
			// Field tiles have type "HoeDirt".
			if tile != null and tile.type == "HoeDirt" then
				// At this point we know this is a field tile that is not part of a field we detected earlier.
				// So we're going to detect its size and register this field.
				// The field is initialized with the current x and y as its top left coordinates.
				field = { "x":x, "y":y }

				// Check how wide the field is.
				width = 0
				checkTile = tile
				// Keep checking more and more to the right as you keep finding farmland.
				// When this loop is done, "width" contains the width of this field.
				while checkTile != null and checkTile.type == "HoeDirt" and not isPartOfExistingField[x + width][y]
					width = width + 1
					checkTile = farm.tile(x + width, y)
				end while

				// Do the same for the height.
				// This time going down as long as you keep finding farmland.
				height = 0
				checkTile = tile
				while checkTile != null and checkTile.type == "HoeDirt" and not isPartOfExistingField[x][y + height]
					height = height + 1
					checkTile = farm.tile(x, y + height)
				end while

				// Store the values in the field object.
				field.width = width
				field.height = height

				// Mark all tiles in the spanned area as part of an existing field.
				for inFieldX in range(field.x, field.x + width - 1)
					for inFieldY in range(field.y, field.y + height - 1)
						isPartOfExistingField[inFieldX][inFieldY] = true
					end for
				end for

				// And add the field object to the list.
				fields = fields + [field]
			end if
		end for
	end for

	// After all fields are detected, we return the found fields.
	return fields
end function

// |---------------|
// | Configuration |
// |---------------|
// The configuration tells the bot about the farm and how you wish for it to behave.
// This can be put further up in the file where it is easier to find.
// But I like it here, closed to where it will be used.

// Here, we just tell it about the places where it can get water.
// This way, we can tell the bot where it needs to go in case it runs out of water.
// A water filling position has three values, x, y and direction.
// You need to fill this in such a way, that when the bot is at [x, y] facing the given direction, it can use the watering tool to refill it.
waterFillingPositions = []
waterFillingPositions.push({ "x":61, "y":18, "direction":0 })
waterFillingPositions.push({ "x":62, "y":18, "direction":0 })

// These are the names and types of tiles that the bot is allowed to clear.
botIsallowedToClearThese = ["Tree", "Stone", "Twig", "Weeds", "Stump", "Boulder", "Hollow Log"]

// |---------------|
// | Main program  |
// |---------------|
// Finally, hundreds of lines into the file, we get to the main program.
// This is where the code will start running and doing things other than set-up.
// Here you can see the fruits of our labor, uncomplicated programming to get things done quickly.

// First we want to know where the fields are.
print("Detecting fields")
fields = detectFields()
print("Fields detected: " + fields.len)

// Then we want to water each of the fields.
for field in fields
	print("Processing field [" + field.x + ";" + field.y + "], size: " + field.height * field.width)

	// Because it is usually shorter and more fun to see, we process every odd row in reverse.
	reverse = true
	for y in range(field.y, field.y + field.height - 1)
		// Switch between true and false every row.
		reverse = not reverse
		// Get the x-coordinates before the loop starts.
		xCoordinates = range(field.x, field.x + field.width - 1)
		// And reverse them if desired.
		if reverse then xCoordinates = xCoordinates.reversed()

		for x in xCoordinates
			// For each tile in the field, move the bot to above the tile.
			// From there, if it faces south, it can interact with the tile.
			// This does mean that the bot needs to be able to enter the tile above each farm tile.
			bot.goTo(x, y - 1, botIsallowedToClearThese)
			bot.turnToDirection(2)

			// Check if the tile needs to be cleared.
			tile = bot.ahead()
			if tile != null and (botIsallowedToClearThese.contains(tile.type) or botIsallowedToClearThese.contains(tile.name)) then
				bot.clearAhead()
			end if

			// Check if the tile needs to be tilled.
			tile = bot.ahead()
			if tile == null then bot.till()

			// Check if the tile is a proper farm tile.
			tile = bot.ahead()
			if tile == null or tile.type != "HoeDirt" then
				print("The tile could not be tilled")
				bot.checkEnergy()
				// And since this is a problem, we exit the program.
				exit
			end if

			// Water the tile if it needs to be watered.
			// We do not need to get tile from bot.ahead() again since we did nothing that could change the tile since the last time.
			// Tile.dry is available when tile.type is "HoeDirt".
			if tile.dry then
				bot.water()

				// After watering, check if the tile is not dry anymore.
				tile = bot.ahead()
				if tile.dry then
					print("The tile is still dry after watering")
					bot.checkEnergy()
					print("The water level is " + bot.getWaterLevel() + "/" + bot.getMaxWaterLevel())
					// You know the drill.
					exit
				end if

				// After watering, check if we still have enough water to water the next tile.
				if bot.getWaterLevel() == 0 then
					// If it is empty, go get some water.
					// Find the closest filling position.
					closestFillingPosition = null
					for fillingPosition in waterFillingPositions
						// If this position is closer than the currently closest, that makes this one the closest so far.
						if closestFillingPosition == null or bot.getDistanceFrom(fillingPosition.x, fillingPosition.y) < bot.getDistanceFrom(closestFillingPosition.x, closestFillingPosition.y) then
							closestFillingPosition = fillingPosition
						end if
					end for

					// With the closest filling position known, all we have to do is go there,
					bot.goTo(closestFillingPosition.x, closestFillingPosition.y, botIsallowedToClearThese)
					// face the correct direction,
					bot.turnToDirection(closestFillingPosition.direction)
					// and fill the water tool back up.
					bot.water()
					
					// Check if the water was properly filled.
					if self.getWaterLevel() < self.getMaxWaterLevel() then
						// If not, let the player know.
						print("The water did not get refilled")
						// Check if we have the energy to use the tool.
						bot.checkEnergy()
						// And, you know it by now, since something went wrong, we exit the program.
						exit
					end if
				end if
			end if
		end for
	end for
end for

// Congratulations, you made it to the end of the program!
print("Program done")

// The program can be run again with the "run"-command.
// You can use this script as a base for your own program.
// Alternatively, use it just for inspiration and find your own way of setting things up.
// The options are endless. The only thing not permitted is telling people you made this version of the program instead of me ;)
// Show your creation on the MiniScript Discord for feedback and support.
// Or head there just to hang out.

// But this is where I must leave you now.
// I wish you the best of luck in your journey.
// May your farm be ever thriving.

// With kind regards,
// René