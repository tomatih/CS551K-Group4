/* Initial Beliefs and Rules */
random_dir(DirList, RandomNumber, Dir) :- 
    (RandomNumber <= 0.25 & .nth(0, DirList, Dir)) | 
    (RandomNumber <= 0.5 & .nth(1, DirList, Dir)) | 
    (RandomNumber <= 0.75 & .nth(2, DirList, Dir)) | 
    (.nth(3, DirList, Dir)).

position(0,0).

/* Initial Goal */
!start.

/* Plans */
+!start : true <- 
    .print("Agent initialized in MASSIM environment.");
    !searchForTask.  /* Start looking for tasks */

/* Searching for a Task */
+!searchForTask : perceive(task(TaskID, BlockColor, Dispenser, GoalX, GoalY)) <- 
    .print("Received task: ", TaskID, " Collect ", BlockColor, " from ", Dispenser, " to ", GoalX, GoalY);
    !goToDispenser(Dispenser, BlockColor, GoalX, GoalY).

/* Navigate to the Dispenser */
+!goToDispenser(Dispenser, BlockColor, GoalX, GoalY) : true <- 
    .print("Navigating to dispenser ", Dispenser);
    ?position(X, Y);
    !moveTo(Dispenser);
    !bindBlock(BlockColor, GoalX, GoalY).

/* Bind and Pick Up Block */
+!bindBlock(BlockColor, GoalX, GoalY) : true <- 
    .print("Binding to block ", BlockColor);
    bind(BlockColor);
    !pickBlock(BlockColor, GoalX, GoalY).

+!pickBlock(BlockColor, GoalX, GoalY) : holding(BlockColor) <-  
    .print("Picked up block: ", BlockColor);
    !moveTo(GoalX, GoalY);
    !deliverBlock(BlockColor).

/* Deliver block */
+!deliverBlock(BlockColor) : holding(BlockColor) <- 
    .print("Delivering block: ", BlockColor);
    drop(BlockColor);
    .print("Delivered block: ", BlockColor);
    !searchForTask.  /* Go back to searching for tasks */

/* Perceive environment updates */
+step(_) : true <- 
    .print("Received step percept.");
    ?position(X, Y);
    !decideAction.

/* Deciding Action */
+!decideAction : holding(BlockColor) <- 
    !deliverBlock(BlockColor).

+!decideAction : perceive(block(Color, BX, BY)) <- 
    !moveTo(BX, BY);
    !pickBlock(Color).

+!decideAction : true <- 
    !move_random.

/* Movement (Avoid Obstacles) */
+!moveTo(X, Y) : not obstacleInPath(X, Y) <- 
    move(X, Y).

+!moveTo(X, Y) : obstacleInPath(X, Y) <- 
    !findAlternativePath(X, Y).

/* Checking for Obstacles */
+!isPathClear(X, Y) <- 
    not obstacleInPath(X, Y).

obstacleInPath(X, Y) :- 
    perceive(obstacle(X, Y)).

/* Alternative Paths */
+!findAlternativePath(X, Y) <- 
    !tryMoveSideways(X, Y).

+!tryMoveSideways(X, Y) <- 
    X1 = X+1; not obstacleInPath(X1, Y); move(X1, Y).

+!tryMoveSideways(X, Y) <- 
    X1 = X-1; not obstacleInPath(X1, Y); move(X1, Y).

+!tryMoveSideways(X, Y) <- 
    Y1 = Y+1; not obstacleInPath(X, Y1); move(X, Y1).

+!tryMoveSideways(X, Y) <- 
    Y1 = Y-1; not obstacleInPath(X, Y1); move(X, Y1).

/* Default Random Movement */
+!move_random : .random(RandomNumber) & random_dir([n, s, e, w], RandomNumber, Dir) <- 
    move(Dir).
