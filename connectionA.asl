/* Initial beliefs and rules */

/* Initial goals */
!start.

/* Plans */
+!start : true <- 
	.print("hello massim world.");
	myLib.myAi.

+step(_) : true <-
	// .print("Received step percept.").
	// myLib.myAi;
	myLib.myPercept.
	
+actionID(_) : true <- 
	myLib.moveRandom(X);
	move(X).
