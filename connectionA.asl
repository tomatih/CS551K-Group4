/* Initial beliefs and rules */

/* Initial goals */
!start.

/* Plans */
+!start : true <- 
	.print("hello massim world.");
	myLib.actions.myAi.

+step(_) : true <-
	myLib.actions.myPercept.
	
+actionID(_) : true <- 
	myLib.actions.moveRandom(X);
	move(X).
