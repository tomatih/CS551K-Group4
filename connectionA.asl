/* Initial beliefs and rules */

/* Initial goals */
!start.

/* Plans */
+!start : true <- 
	.print("hello massim world.");
	myLib.myAi.

+step(X) : true <-
	// .print("Received step percept.").
	true.
	
+actionID(_) : true <- 
	myLib.moveRandom(X);
	move(X).
//	skip.
