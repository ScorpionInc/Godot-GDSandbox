extends Node2D


#Recursion is usually slower but cleaner in code as per source(s):

#https://stackoverflow.com/questions/15688019/recursion-versus-iteration
#https://www.tutorialspoint.com/what-are-the-differences-between-recursion-and-iteration-in-java#:~:text=Recursion%20is%20when%20a%20statement,the%20controlling%20condition%20becomes%20false.
#https://www.codeit-project.eu/differences-between-iterative-and-recursive-algorithms/

#Verifing with a quick test script to test this hypothesis if it still applies in GDScript as it's an interpreted language.
#There is probably different ways to implement this, and results will differ based upon machine, but follows are my results:
#Iterative usec: 13, 14, 13 Avg: 13.33
#Recursive usec: 74, 87, 79 Avg: 80.00
#Which does support my expected results in general. Perhaps in a certain use-case it's faster but if it can be done iteratively and it's speed sensitive then it should be.

#Thus, it may well not be worth the effort to rewrite a function in a recursive way as it may well decrease the speed at which it is executed.
#The test code I used follows below, thank you for reading.

func _ready() -> void:
	#System timing used for optimization tests not the most accurate but it'll do
	#Initializing variables before running the test
	var tick_start : float = 0.0 #Total elapsed time before test
	var tick_stop : float = 0.0  #Total elapsed time after test finished
	var tick_delta0 : float = 0.0 #Iterative difference of times or the time taken during test
	var tick_delta1 : float = 0.0 #Recursive difference of times or the time taken during test
	var number : float = 42.42 #Answer to the universe
	var addCount : int = 123 #Large-ish number to test *Beware of stack overflows*
	var result0 : float = 0.0 #Iterative result should equal Recursive
	var result1 : float = 0.0 #Recursive result should match Iterative
	#Run the two functions to add the integer value of addCount to number.
	tick_start = OS.get_ticks_usec()
	result0 = iterative_add( number, addCount )
	tick_stop = OS.get_ticks_usec()
	tick_delta0 = ( tick_stop - tick_start )
	tick_start = OS.get_ticks_usec()
	result1 = recursive_add( number, addCount )
	tick_stop = OS.get_ticks_usec()
	tick_delta1 = ( tick_stop - tick_start )
	#Print out the results of the tests for comparison/debugging as needed.
	print("[INFO]: Iterative function time: '" + str( tick_delta0 ) + "'\tValue: '" + str(result0) + ".'")#Debugging
	print("[INFO]: Recursive function time: '" + str( tick_delta1 ) + "'\tValue: '" + str(result1) + ".'")#Debugging

func iterative_add( toNumber : float, count : int ) -> float:
	#Using a for loop to count through the loops to add one to the toNumber value.
	for i in range(count):
		toNumber += 1.0
	return toNumber

func recursive_add( toNumber : float, count : int ) -> float:
	#Using a recursive call to self.recursiveAdd() to add one to the toNumber value count times.
	if(count > 0):
		return self.recursiveAdd( toNumber + 1.0, count - 1 )
	else:
		return toNumber
