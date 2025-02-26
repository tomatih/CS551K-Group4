/* Initial beliefs and rules */

/* Initial goals */
!start.

/* Plans */
+!start : true <- 
	.print("hello massim world.");
	myLib.actions.myAi.

//TODO: temporary concurrency issues solution. Make it concurrent again
//TODO: make more of the use of JASON concurrency split up tasks more, with JASON side data passing
@step[atomic]
+step(_) : true <-
	myLib.actions.myPercept;
	myLib.actions.myAction(A);
	!execute(A).

// java-JASON action mappings
+!execute(m(D)) : true <- move(D).
+!execute(r(D)) : true <- request(D).
+!execute(a(D)) : true <- attach(D).
+!execute(p(T)) : true <- submit(T).
+!execute(t(D)) : true <- rotate(D).
+!execute(s) : true <- skip.
