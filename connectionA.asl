/* Initial beliefs and rules */
test_belief(1).

/* Initial goals */
!start.

/* Plans */
+!start : true <- 
	.print("hello massim world.");
	myLib.myAi.

+step(_) : true <-
	myLib.myPercept.
	
+actionID(_) : true <- 
	myLib.moveRandom(X);
	move(X).
