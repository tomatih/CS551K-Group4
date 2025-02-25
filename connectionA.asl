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
	myLib.actions.myAction(A);
	!execute(A).
	// myLib.actions.moveRandom(X);
	// move(X).

+!execute(m(D)) : true <- move(D).
+!execute(r(D)) : true <- request(D).
+!execute(a(D)) : true <- attach(D).
+!execute(p(T)) : true <- submit(T).
+!execute(t(D)) : true <- rotate(D).
+!execute(s) : true <- skip.
