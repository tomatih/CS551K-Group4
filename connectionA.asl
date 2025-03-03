/* Initial beliefs and rules */
random_dir(DirList,RandomNumber,Dir) :- (RandomNumber <= 0.25 & .nth(0,DirList,Dir)) | (RandomNumber <= 0.5 & .nth(1,DirList,Dir)) | (RandomNumber <= 0.75 & .nth(2,DirList,Dir)) | (.nth(3,DirList,Dir)).

dir_to_offset(Dir,X,Y) :- (Dir=n & X=0 & Y=-1) | (Dir=s & X=0 & Y=1) | (Dir=e & X=1 & Y=0) | (Dir=w & X=-1 & Y=0).

// Enhanced navigation logic that combines different strategies
navigate(Ox,Oy,Dx,Dy,Dir) :- 
    // Try potential field navigation first (balances goal attraction and obstacle repulsion)
    balanced_navigate(Ox,Oy,Dx,Dy,Dir) |
    // If potential field fails, fall back to weighted exploration
    explore_navigate(Ox,Oy,Dx,Dy,Dir) |
    // Last resort: simple direct navigation
    simple_navigate(Ox,Oy,Dx,Dy,Dir).

// Simple direct navigation (improved version of original)
simple_navigate(Ox,Oy,Dx,Dy,Dir) :- 
    ((Ox < Dx & not saved_obstacle(Ox+1,Oy) & Dir = e) |
     (Ox > Dx & not saved_obstacle(Ox-1,Oy) & Dir = w) |
     (Oy < Dy & not saved_obstacle(Ox,Oy+1) & Dir = s) |
     (Oy > Dy & not saved_obstacle(Ox,Oy-1) & Dir = n) |
     (not saved_obstacle(Ox+1,Oy) & Dir = e) |
     (not saved_obstacle(Ox,Oy-1) & Dir = n) |
     (not saved_obstacle(Ox-1,Oy) & Dir = w) |
     (not saved_obstacle(Ox,Oy+1) & Dir = s)).

// Helper functions
abs(In,Out) :- (In<0 & Out=-In) | Out = In.
delta(A,B,Out) :- Delta = A-B & abs(Delta,Out).
distance(Ax,Ay,Bx,By,Dist) :- delta(Ax,Bx,Dx) & delta(Ay,By,Dy) & Dist = Dx+Dy.
bounce(In,Out) :- (In=0 & Out=1) | ( (In=-1 | In=1) & Out=-1 ).

/* Balanced navigation implementation - FIXED and BALANCED */
balanced_navigate(X,Y,GoalX,GoalY,Dir) :-
    distance(X,Y,GoalX,GoalY,Dist) & Dist > 0 &
    // Calculate absolute differences
    delta(X,GoalX,Dx) & delta(Y,GoalY,Dy) &
    // Get agent identifier or use time as pseudo-random value
    .my_name(Name) & .length(Name, NameLen) &
    step(S) &
    // Use a combination of step and agent name to vary behavior
    VaryFactor = (S + NameLen) mod 4 &
    
    // Option 1: Prioritize horizontal (33% chance)
    ((VaryFactor = 0 | VaryFactor = 1) & 
     ((X < GoalX & not saved_obstacle(X+1,Y) & Dir = e) |
      (X > GoalX & not saved_obstacle(X-1,Y) & Dir = w) |
      (Y < GoalY & not saved_obstacle(X,Y+1) & Dir = s) |
      (Y > GoalY & not saved_obstacle(X,Y-1) & Dir = n))) |
    
    // Option 2: Prioritize vertical (33% chance)
    ((VaryFactor = 2 | VaryFactor = 3) & 
     ((Y < GoalY & not saved_obstacle(X,Y+1) & Dir = s) |
      (Y > GoalY & not saved_obstacle(X,Y-1) & Dir = n) |
      (X < GoalX & not saved_obstacle(X+1,Y) & Dir = e) |
      (X > GoalX & not saved_obstacle(X-1,Y) & Dir = w))) &
    
    // Get offset for this direction and check visit history
    dir_to_offset(Dir,OffX,OffY) &
    NewX = X + OffX &
    NewY = Y + OffY &
    (not visited(NewX,NewY,_) | visited(NewX,NewY,Count) & Count < 3).

/* Memory-enhanced exploration navigation */
// Exploration-based navigation using visit counts
explore_navigate(X,Y,GoalX,GoalY,Dir) :-
    // Add randomization to exploration order based on step
    step(S) & DirectionOffset = S mod 4 &
    
    // Try directions in a randomized order
    ((DirectionOffset = 0 &
      ((not saved_obstacle(X+1,Y) & (not visited(X+1,Y,_) | 
          (visited(X+1,Y,CountE) & CountE < 2)) & Dir = e) |
       (not saved_obstacle(X,Y-1) & (not visited(X,Y-1,_) | 
          (visited(X,Y-1,CountN) & CountN < 2)) & Dir = n) |
       (not saved_obstacle(X-1,Y) & (not visited(X-1,Y,_) | 
          (visited(X-1,Y,CountW) & CountW < 2)) & Dir = w) |
       (not saved_obstacle(X,Y+1) & (not visited(X,Y+1,_) | 
          (visited(X,Y+1,CountS) & CountS < 2)) & Dir = s))) |
          
    (DirectionOffset = 1 &
      ((not saved_obstacle(X,Y-1) & (not visited(X,Y-1,_) | 
          (visited(X,Y-1,CountN) & CountN < 2)) & Dir = n) |
       (not saved_obstacle(X-1,Y) & (not visited(X-1,Y,_) | 
          (visited(X-1,Y,CountW) & CountW < 2)) & Dir = w) |
       (not saved_obstacle(X,Y+1) & (not visited(X,Y+1,_) | 
          (visited(X,Y+1,CountS) & CountS < 2)) & Dir = s) |
       (not saved_obstacle(X+1,Y) & (not visited(X+1,Y,_) | 
          (visited(X+1,Y,CountE) & CountE < 2)) & Dir = e))) |
          
    (DirectionOffset = 2 &
      ((not saved_obstacle(X-1,Y) & (not visited(X-1,Y,_) | 
          (visited(X-1,Y,CountW) & CountW < 2)) & Dir = w) |
       (not saved_obstacle(X,Y+1) & (not visited(X,Y+1,_) | 
          (visited(X,Y+1,CountS) & CountS < 2)) & Dir = s) |
       (not saved_obstacle(X+1,Y) & (not visited(X+1,Y,_) | 
          (visited(X+1,Y,CountE) & CountE < 2)) & Dir = e) |
       (not saved_obstacle(X,Y-1) & (not visited(X,Y-1,_) | 
          (visited(X,Y-1,CountN) & CountN < 2)) & Dir = n))) |
          
    (DirectionOffset = 3 &
      ((not saved_obstacle(X,Y+1) & (not visited(X,Y+1,_) | 
          (visited(X,Y+1,CountS) & CountS < 2)) & Dir = s) |
       (not saved_obstacle(X+1,Y) & (not visited(X+1,Y,_) | 
          (visited(X+1,Y,CountE) & CountE < 2)) & Dir = e) |
       (not saved_obstacle(X,Y-1) & (not visited(X,Y-1,_) | 
          (visited(X,Y-1,CountN) & CountN < 2)) & Dir = n) |
       (not saved_obstacle(X-1,Y) & (not visited(X-1,Y,_) | 
          (visited(X-1,Y,CountW) & CountW < 2)) & Dir = w)))).

/* Initial beliefs */
state_machine(lost).
my_position(0,0).
visited(0,0,1). // Mark starting position as visited

!init.
// IMPROVED: Better initialization with more diverse goals
+!init : .random(R1) & .random(R2) & .random(R3) & .my_name(Name) <- 
    // Extract a number from the agent name (last character of name as number)
    .length(Name, L);
    .substring(Name, L-1, L, LastChar);
    .term2string(LastCharNum, LastChar);
    // Use different quadrant for each agent based on name
    Quadrant = (LastCharNum mod 4);
    
    // Calculate direction based on quadrant
    if (Quadrant = 0) {
        Dx = 1; Dy = 1;  // Northeast
    } else {
        if (Quadrant = 1) {
            Dx = -1; Dy = 1;  // Southeast
        } else {
            if (Quadrant = 2) {
                Dx = -1; Dy = -1;  // Southwest
            } else {
                Dx = 1; Dy = -1;  // Northwest
            }
        }
    };
    
    // Randomize distance a bit
    B = 300 + math.floor(R1 * 200);
    
    // Calculate goal, adding slight randomization
    XVar = math.floor(R2 * 50) - 25;
    YVar = math.floor(R3 * 50) - 25;
    Gx = B * Dx + XVar;
    Gy = B * Dy + YVar;
    
    +nav_goal(Gx, Gy);
    .print("Initialized for ", Gx, " ", Gy, " (Quadrant ", Quadrant, ")").

// Activated for each step of the simulation
@step[atomic]
+step(S) <-
    !updateBeliefs;
    !updateStateMachine;
    !decideAction.

/* Belief base plans */
+!updateBeliefs <-
    !update_position;
    !update_obstacles;
    !get_goal;
    !get_dispenser(b0);
    !get_dispenser(b1);
    !fix_task.

// Enhanced position update that tracks visit history
+!update_position : lastActionResult(success) & lastAction(move) & lastActionParams([Dir]) & dir_to_offset(Dir,Dx,Dy) & my_position(Ox,Oy) <- 
    Nx=Ox+Dx; 
    Ny=Oy+Dy; 
    -my_position(Ox,Oy); 
    +my_position(Nx,Ny);
    // Track visit count for this cell
    if (visited(Nx,Ny,Count)) {
        -visited(Nx,Ny,Count);
        NewCount = Count + 1;
        +visited(Nx,Ny,NewCount);
    } else {
        +visited(Nx,Ny,1);
    }.

+!update_position : lastActionResult(failed_forbidden) & lastAction(move) & lastActionParams([Dir]) & state_machine(lost) & nav_goal(Ox,Oy) & dir_to_offset(Dir, Fx,Fy) & bounce(Fx,Dx) & bounce(Fy,Dy) <- 
    -nav_goal(Ox,Oy); 
    Nx=Ox*Dx; 
    Ny=Oy*Dy; 
    +nav_goal(Nx,Ny);
    // Mark the blocked cell as an obstacle
    my_position(Mx,My);
    BlockedX = Mx + Fx;
    BlockedY = My + Fy;
    +saved_obstacle(BlockedX,BlockedY).

+!update_position : true <- true. // No change in position

+!update_obstacles : my_position(Mx,My) <- 
    for (obstacle(Rx,Ry)) { 
        X=Mx+Rx;
        Y=My+Ry; 
        if(not saved_obstacle(X,Y)) { 
            +saved_obstacle(X,Y) 
        }; 
    }.

+!get_goal : not chosen_goal(_,_) & goal(Rx,Ry) & my_position(Mx,My) & X=Rx+Mx & Y=Ry+My & Fy=Y+1 & not saved_obstacle(X,Fy) <- 
    +chosen_goal(X,Y).
+!get_goal : true <- true.

+!get_dispenser(BlockType) : not dispenser(BlockType,_,_) & thing(Rx,Ry,dispenser,BlockType) & my_position(Mx,My) & X=Rx+Mx & Y=Ry+My & not saved_obstacle(X,Y) & Fy=Y-1 & not saved_obstacle(X,Fy) <- 
    +dispenser(BlockType,X,Y).
+!get_dispenser(BlockType) : dispenser(BlockType,OldX,OldY) & chosen_goal(GoalX,GoalY) & thing(Rx,Ry,dispenser,BlockType) & my_position(Mx,My) & NewX=Rx+Mx & NewY=Ry+My & not saved_obstacle(NewX,NewY) & Fy=NewY-1 & not saved_obstacle(NewX,Fy) & distance(OldX,OldY,GoalX,GoalY,OldDistance) & distance(NewX,NewY,GoalX,GoalY,NewDistance) & NewDistance < OldDistance <- 
    -dispenser(BlockType,OldX,OldY); 
    +dispenser(BlockType,NewX,NewY).
+!get_dispenser(_) : true <- true.

+!fix_task : current_task(TaskId, BlockType) & not task(TaskId,_,_,_) & task(NewTaskId, Deadline, 10,[req(_,_,BlockType)] ) & step(Step) & Deadline > Step <- 
    -current_task(TaskId, BlockType); 
    +current_task(NewTaskId, BlockType).
+!fix_task : true <- true.

/* State Machine plans */
+!updateStateMachine : state_machine(lost) & chosen_goal(_,_) & dispenser(b0, _,_) & dispenser(b1,_,_) <- 
    -state_machine(lost); 
    +state_machine(idle); 
    .print("Fully initialized").
+!updateStateMachine : state_machine(lost) <- true.

+!updateStateMachine : state_machine(idle) & task(TaskId, Deadline, 10,[req(_,_,BlockType)] ) & step(Step) & Deadline > Step & dispenser(BlockType, Dx, Dy) & Gy=Dy-1 <- 
    -nav_goal(_,_); 
    +nav_goal(Dx,Gy);
    +current_task(TaskId,BlockType); 
    -state_machine(idle); 
    +state_machine(toDispenser); 
    .print("Picked task: ",TaskId).
+!updateStateMachine : state_machine(idle) <- true.

+!updateStateMachine : state_machine(toDispenser) & my_position(Mx,My) & nav_goal(Mx,My) <- 
    -nav_goal(Mx,My); 
    -state_machine(toDispenser); 
    +state_machine(atDispenser); 
    .print("At dispenser").
+!updateStateMachine : state_machine(toDispenser) <- true.

+!updateStateMachine : state_machine(atDispenser) & lastActionResult(success) & lastAction(request) <- 
    -state_machine(atDispenser); 
    +state_machine(aboutToAttach); 
    .print("Block requested").
+!updateStateMachine : state_machine(atDispenser) <- true.

+!updateStateMachine : state_machine(aboutToAttach) & lastActionResult(success) & lastAction(attach) & chosen_goal(Gx,Gy) <- 
    +nav_goal(Gx,Gy); 
    -state_machine(aboutToAttach); 
    +state_machine(toGoal); 
    .print("Block attached").
+!updateStateMachine : state_machine(aboutToAttach) <- true.

+!updateStateMachine : state_machine(toGoal) & my_position(Mx,My) & nav_goal(Mx,My) <- 
    -nav_goal(Mx,My); 
    -state_machine(toGoal); 
    +state_machine(shouldSubmit);
    .print("At goal").
+!updateStateMachine : state_machine(toGoal) <- true.

+!updateStateMachine : state_machine(shouldSubmit) & lastActionResult(success) & lastAction(submit) <- 
    -current_task(_,_);
    -state_machine(shouldSubmit); 
    +state_machine(idle); 
    .print("Task submitted").
+!updateStateMachine : state_machine(shouldSubmit) <- true.

/* Action emitting plans */
+!decideAction : state_machine(idle) <- 
    skip.

// Enhanced navigation plan that uses the improved navigation strategies
+!decideAction : (state_machine(lost) | state_machine(toDispenser) | state_machine(toGoal)) & nav_goal(Dx,Dy) & my_position(Mx,My) <- 
    ?navigate(Mx,My,Dx,Dy,Dir);
    .print("Navigating from (", Mx, ",", My, ") to (", Dx, ",", Dy, ") with direction ", Dir);
    move(Dir).

// Fallback to random direction if navigation fails
+!decideAction : (state_machine(lost) | state_machine(toDispenser) | state_machine(toGoal)) & .random(R) & random_dir([n,s,e,w],R,Dir) <-
    .print("Using random fallback direction: ", Dir);
    move(Dir).

+!decideAction : state_machine(atDispenser) <- 
    request(s).

+!decideAction : state_machine(aboutToAttach) <- 
    attach(s).

+!decideAction : state_machine(shouldSubmit) & current_task(TaskId,_) <- 
    submit(TaskId).

+!decideAction : true <- 
    .print("Action failed")./* Initial beliefs and rules */
dir_to_offset(n,0,-1).
dir_to_offset(s,0,1).
dir_to_offset(e,1,0).
dir_to_offset(w,-1,0).

// Helper functions
abs(In,Out) :- (In<0 & Out=-In) | Out = In.
delta(A,B,Out) :- Delta = A-B & abs(Delta,Out).
distance(Ax,Ay,Bx,By,Dist) :- delta(Ax,Bx,Dx) & delta(Ay,By,Dy) & Dist = Dx+Dy.

// Simplified navigation that prioritizes getting to the goal quickly
navigate(Ox,Oy,Dx,Dy,Dir) :- 
    // Calculate absolute differences in X and Y
    delta(Ox,Dx,AbsDx) & delta(Oy,Dy,AbsDy) &
    
    // Decide which axis to prioritize based on larger difference
    ((AbsDx > AbsDy & Ox < Dx & not saved_obstacle(Ox+1,Oy) & Dir = e) |
     (AbsDx > AbsDy & Ox > Dx & not saved_obstacle(Ox-1,Oy) & Dir = w) |
     (AbsDx <= AbsDy & Oy < Dy & not saved_obstacle(Ox,Oy+1) & Dir = s) |
     (AbsDx <= AbsDy & Oy > Dy & not saved_obstacle(Ox,Oy-1) & Dir = n) |
     // Fallbacks if preferred direction is blocked
     (not saved_obstacle(Ox+1,Oy) & Dir = e) |
     (not saved_obstacle(Ox-1,Oy) & Dir = w) |
     (not saved_obstacle(Ox,Oy-1) & Dir = n) |
     (not saved_obstacle(Ox,Oy+1) & Dir = s)).

/* Initial beliefs */
state_machine(exploring).
my_position(0,0).

// Initialization
!init.
+!init <- 
    // Pick an exploration quadrant based on agent name 
    .my_name(Name);
    .length(Name, L);
    .substring(Name, L-1, L, LastChar);
    .term2string(LastCharNum, LastChar);
    Quadrant = (LastCharNum mod 4);
    
    // Set X and Y direction based on quadrant
    if (Quadrant = 0) { DirX = 1; DirY = 1; }    // Northeast
    else { if (Quadrant = 1) { DirX = -1; DirY = 1; }    // Southeast
    else { if (Quadrant = 2) { DirX = -1; DirY = -1; }   // Southwest
    else { DirX = 1; DirY = -1; }}}; // Northwest
    
    // Set exploration goal
    Gx = 300 * DirX;
    Gy = 300 * DirY;
    +explore_goal(Gx, Gy);
    
    .print("Started exploring toward (", Gx, ", ", Gy, ")").

// Main execution cycle
@step[atomic]
+step(S) <-
    !updateBeliefs;
    !updateStateMachine;
    !decideAction.

/* Belief updates */
+!updateBeliefs <-
    !update_position;
    !update_obstacles;
    !get_goal;
    !get_dispensers;
    !check_tasks.

// Update position after successful move
+!update_position : lastActionResult(success) & lastAction(move) & lastActionParams([Dir]) & dir_to_offset(Dir,Dx,Dy) & my_position(Ox,Oy) <- 
    Nx = Ox + Dx; 
    Ny = Oy + Dy; 
    -my_position(Ox,Oy); 
    +my_position(Nx,Ny).

// Handle failed move (hit obstacle)
+!update_position : lastActionResult(failed_forbidden) & lastAction(move) & lastActionParams([Dir]) & dir_to_offset(Dir,Dx,Dy) & my_position(Mx,My) <- 
    // Mark obstacle location
    Ox = Mx + Dx;
    Oy = My + Dy;
    +saved_obstacle(Ox,Oy).

+!update_position : true <- true. // Default case

// Update obstacles from perception
+!update_obstacles : my_position(Mx,My) <- 
    for (obstacle(Rx,Ry)) { 
        X = Mx + Rx;
        Y = My + Ry; 
        if (not saved_obstacle(X,Y)) { 
            +saved_obstacle(X,Y); 
        }; 
    }.

// Update goals from perception
+!get_goal : not chosen_goal(_,_) & goal(Rx,Ry) & my_position(Mx,My) <- 
    X = Mx + Rx;
    Y = My + Ry;
    +chosen_goal(X,Y);
    .print("Found goal at (", X, ", ", Y, ")").
+!get_goal : true <- true.

// Update dispensers from perception 
+!get_dispensers <- 
    !check_dispenser(b0);
    !check_dispenser(b1).

+!check_dispenser(BlockType) : thing(Rx,Ry,dispenser,BlockType) & my_position(Mx,My) <- 
    X = Mx + Rx;
    Y = My + Ry;
    
    // Only update if we don't have this dispenser or found a better one
    if (dispenser(BlockType,OldX,OldY)) {
        if (chosen_goal(GoalX,GoalY)) {
            distance(X,Y,GoalX,GoalY,NewDist);
            distance(OldX,OldY,GoalX,GoalY,OldDist);
            if (NewDist < OldDist) {
                -dispenser(BlockType,OldX,OldY);
                +dispenser(BlockType,X,Y);
                .print("Updated ", BlockType, " dispenser to (", X, ", ", Y, ")");
            }
        }
    } else {
        +dispenser(BlockType,X,Y);
        .print("Found ", BlockType, " dispenser at (", X, ", ", Y, ")");
    }.
+!check_dispenser(_) : true <- true.

// Look for available tasks
+!check_tasks : not current_task(_,_) & chosen_goal(_,_) <- 
    // Find tasks with blocks we know dispensers for
    for (task(TaskId, Deadline, Reward, [req(_,_,BlockType)]) & dispenser(BlockType,_,_) & step(S) & Deadline > S + 10) {
        if (not current_task(_,_)) {
            +current_task(TaskId, BlockType);
            .print("Selected task: ", TaskId, " with ", BlockType);
        }
    }.
+!check_tasks : true <- true.

/* State Machine Logic */
+!updateStateMachine : state_machine(exploring) & chosen_goal(_,_) & (dispenser(b0,_,_) | dispenser(b1,_,_)) <- 
    -state_machine(exploring); 
    +state_machine(working);
    .print("Found resources, ready to work").

+!updateStateMachine : state_machine(exploring) & current_task(_,_) <- 
    -state_machine(exploring); 
    +state_machine(working);
    .print("Taking on task while exploring").

+!updateStateMachine : true <- true. // Default case

/* Action Logic */
+!decideAction : state_machine(exploring) & explore_goal(Gx,Gy) & my_position(Mx,My) <- 
    ?navigate(Mx,My,Gx,Gy,Dir);
    .print("Exploring toward (", Gx, ", ", Gy, ")");
    move(Dir).

+!decideAction : state_machine(working) & current_task(TaskId,BlockType) & dispenser(BlockType,Dx,Dy) & not attached(_) <- 
    !go_to_dispenser(BlockType).

+!decideAction : state_machine(working) & current_task(TaskId,_) & attached(_) & chosen_goal(Gx,Gy) <- 
    !go_to_goal.

+!decideAction : state_machine(working) & not current_task(_,_) <- 
    // No current task, look for one or continue exploring
    if (chosen_goal(_,_) & (dispenser(b0,_,_) | dispenser(b1,_,_))) {
        !check_tasks;
        if (current_task(_,_)) {
            !decideAction;
        } else {
            skip;
        }
    } else {
        if (explore_goal(Gx,Gy)) {
            !decideAction;
        } else {
            skip;
        }
    }.

+!decideAction : true <- 
    .random(R);
    if (R < 0.25) { move(n); }
    else { if (R < 0.5) { move(e); }
    else { if (R < 0.75) { move(s); }
    else { move(w); }}}.

/* Helper plans for actions */
+!go_to_dispenser(BlockType) : dispenser(BlockType,Dx,Dy) & my_position(Mx,My) <- 
    if (Mx = Dx & My = Dy) {
        // At dispenser position, try to request
        request(s);
        .print("Requesting block");
    } else {
        if (Mx = Dx & My = Dy + 1) {
            // North of dispenser, try to request
            request(n);
            .print("Requesting block from north");
        } else {
            if (Mx = Dx & My = Dy - 1) {
                // South of dispenser, in position!
                request(s);
                .print("Requesting block from south");
            } else {
                if (Mx = Dx + 1 & My = Dy) {
                    // East of dispenser
                    request(w);
                    .print("Requesting block from east");
                } else {
                    if (Mx = Dx - 1 & My = Dy) {
                        // West of dispenser
                        request(e);
                        .print("Requesting block from west");
                    } else {
                        // Navigate to dispenser
                        ?navigate(Mx,My,Dx,Dy,Dir);
                        .print("Moving to dispenser at (", Dx, ", ", Dy, ")");
                        move(Dir);
                    }
                }
            }
        }
    }.

+!go_to_goal : chosen_goal(Gx,Gy) & my_position(Mx,My) & current_task(TaskId,_) <- 
    if (distance(Mx,My,Gx,Gy) <= 1) {
        // At or adjacent to goal, submit task
        submit(TaskId);
        .print("Submitting task: ", TaskId);
    } else {
        // Navigate to goal
        ?navigate(Mx,My,Gx,Gy,Dir);
        .print("Moving to goal at (", Gx, ", ", Gy, ")");
        move(Dir);
    }.

// Handle successful attachment of block
+attached(Dir) : current_task(TaskId,_) & chosen_goal(Gx,Gy) <- 
    .print("Block attached, heading to goal").

// Handle successful task submission - clear task and look for new one
+lastActionResult(success) : lastAction(submit) & lastActionParams([TaskId]) <- 
    -current_task(TaskId,_);
    !check_tasks;
    .print("Task completed successfully!").

// Handle request success - try to attach
+lastActionResult(success) : lastAction(request) <- 
    .print("Got block, attaching");
    attach(s).