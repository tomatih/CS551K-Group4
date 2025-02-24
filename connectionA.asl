/* Initial beliefs and rules */
last_dir(none).
target_block(none).

/* Initial goals */
!start.

/* Plans */
+!start : true <- 
    .print("Block collector started");
    !search_for_block.

+!search_for_block : true <- 
    .print("Scanning for blocks...").

/* When a block is perceived, set it as target and move toward it */
+block(X,Y)[source(percept)] : pos(AgentX,AgentY) <- 
    .print("Detected block at: ", X, ", ", Y);
    -target_block(none);
    +target_block([X,Y]);
    !move_to_target(AgentX, AgentY, X, Y).

/* If no block is visible, explore randomly */
+actionID(ID) : not block(_,_) <- 
    .print("No blocks visible, exploring randomly");
    .random(R);
    !explore(R).

/* Move toward the target block */
+!move_to_target(AgentX,AgentY,BlockX,BlockY) <- 
    if (AgentX < BlockX) {
        move(e);
        +last_dir(e);
    } elif (AgentX > BlockX) {
        move(w);
        +last_dir(w);
    } elif (AgentY < BlockY) {
        move(s);
        +last_dir(s);
    } elif (AgentY > BlockY) {
        move(n);
        +last_dir(n);
    } else {
        pickup;
        -target_block([BlockX,BlockY]);
    }.

/* Random exploration based on a random value */
+!explore(R) : R <= 0.25 <- move(n).
+!explore(R) : R <= 0.5 <- move(s).
+!explore(R) : R <= 0.75 <- move(e).
+!explore(R) <- move(w).

/* When reaching a block's cell, attempt to pick it up */
+pos(X,Y) : block(X,Y) <- 
    .print("At block location: ", X, ", ", Y);
    pickup.
