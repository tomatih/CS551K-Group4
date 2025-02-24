// connectionA.asl

/* Beliefs */
random_dir(n).
random_dir(s).
random_dir(e).
random_dir(w).

+my_position(0, 0).  // Example initial position
+percept(block(1, 1)).  // Example block position
+percept(goal(2, 2)).  // Example goal position
+percept(obstacle(3, 3)).  // Example obstacle position
+carrying(none).  // Example: Agent is not carrying anything

/* Initial goal */
!start.

/* Plans */
+!start <- 
    .print("Agent started. Waiting for perceptions...").

+step(_) <- 
    .print("Received step percept.");
    !decide_movement.

/* Decision Making */
+!decide_movement : percept(block(X,Y)) & carrying(none)  // If there's a block nearby and not carrying
    <- !move_towards(X,Y).

+!decide_movement : carrying(_) & percept(goal(X,Y))  // If carrying a block and sees the goal
    <- !move_towards(X,Y).

+!decide_movement : percept(obstacle(_,_))  // Avoid obstacles
    <- !move_random.

+!decide_movement : true  // No useful perception, move randomly
    <- !move_random.

/* Move Towards Target */
+!move_towards(X, Y) <- 
    .print("Moving towards (", X, ", ", Y, ")");
    my_position(MyX, MyY);
    if (MyX < X) then { move(e) };
    if (MyX > X) then { move(w) };
    if (MyY < Y) then { move(n) };
    if (MyY > Y) then { move(s) }.

/* Random movement */
+!move_random <- 
    .print("Moving randomly.");
    .random(R);
    if (R < 0.25) then { move(n) };
    if (R < 0.5) then { move(s) };
    if (R < 0.75) then { move(e) };
    move(w).