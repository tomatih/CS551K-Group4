/*--------------------------------------------------
                       Rules
--------------------------------------------------*/
// Pick a random element from a list of 4
choice_4(DirList, RandomNumber, Dir) :- 
    (RandomNumber <= 0.25 & .nth(0, DirList, Dir)) | 
    (RandomNumber <= 0.5 & .nth(1, DirList, Dir)) | 
    (RandomNumber <= 0.75 & .nth(2, DirList, Dir)) | 
    (.nth(3, DirList, Dir)).

// Converts a direction into an offset vector
dir_to_offset(Dir, X, Y) :- 
    (Dir=n & X=0 & Y=-1) | 
    (Dir=s & X=0 & Y=1) | 
    (Dir=e & X=1 & Y=0) | 
    (Dir=w & X=-1 & Y=0).

// Check if a given block is free
free(X, Y) :- 
    not saved_obstacle(X, Y) &
    (
        my_position(Mx, My) &
        Ox = X-Mx &
        Oy = Y-My &
        not thing(Ox, Oy, entity, _) &
        (not thing(Ox, Oy, block, _) | holding(Ox, Oy))
    ) &
    (
        wall(n, _, Ymin) & wall(s, _, Ymax) &
        Ymin <= Y & Ymax >= Y &
        wall(e, Xmax, _) & wall(w, Xmin, _) &
        Xmin <= X & Xmax >= X
    ).

// Enhanced navigation with obstacle avoidance and movement penalties
new_nav(Mx, My, Gx, Gy, Dir) :- 
    (
        Ny = My-1 &
        Sy = My+1 &
        Ex = Mx+1 &
        Wx = Mx-1 &
        NEy = My-1 & NEx = Mx+1 &
        NWy = My-1 & NWx = Mx-1 &
        SEy = My+1 & SEx = Mx+1 &
        SWy = My+1 & SWx = Mx-1
    ) & (
        distance(Mx, Ny, Gx, Gy, Nd) &
        distance(Mx, Sy, Gx, Gy, Sd) &
        distance(Ex, My, Gx, Gy, Ed) &
        distance(Wx, My, Gx, Gy, Wd) &
        distance(NEx, NEy, Gx, Gy, NEd) &
        distance(NWx, NWy, Gx, Gy, NWd) &
        distance(SEx, SEy, Gx, Gy, SEd) &
        distance(SWx, SWy, Gx, Gy, SWd)
    ) & (
        BigNum = 10000 &
        ((not free(Mx, Ny) & Nmult=BigNum) | Nmult = 1) &
        ((not free(Mx, Sy) & Smult=BigNum) | Smult = 1) &
        ((not free(Ex, My) & Emult=BigNum) | Emult = 1) &
        ((not free(Wx, My) & Wmult=BigNum) | Wmult = 1) &
        ((not free(NEx, NEy) & NEmult=BigNum) | NEmult = 1) &
        ((not free(NWx, NWy) & NWmult=BigNum) | NWmult = 1) &
        ((not free(SEx, SEy) & SEmult=BigNum) | SEmult = 1) &
        ((not free(SWx, SWy) & SWmult=BigNum) | SWmult = 1)
    ) & (
        Penalty = 5 &
        ((last_move(s) & Noff=Penalty) | Noff=0) &
        ((last_move(n) & Soff=Penalty) | Soff=0) &
        ((last_move(w) & Eoff=Penalty) | Eoff=0) &
        ((last_move(e) & Woff=Penalty) | Woff=0) &
        ((last_move(ne) & SWoff=Penalty) | SWoff=0) &
        ((last_move(nw) & SEoff=Penalty) | SEoff=0) &
        ((last_move(se) & NWoff=Penalty) | NWoff=0) &
        ((last_move(sw) & NEoff=Penalty) | NEoff=0)
    ) & (
        Nval = (Nd+Noff)*Nmult & 
        Sval = (Sd+Soff)*Smult & 
        Eval = (Ed+Eoff)*Emult & 
        Wval = (Wd+Woff)*Wmult &
        NEval = (NEd+2)*NEmult & // Slight penalty for diagonals
        NWval = (NWd+2)*NWmult &
        SEval = (SEd+2)*SEmult &
        SWval = (SWd+2)*SWmult
    ) &
    .min([c(Nval,n), c(Sval,s), c(Eval,e), c(Wval,w), 
          c(NEval,ne), c(NWval,nw), c(SEval,se), c(SWval,sw)], c(_, Dir)).

// Fallback navigation when primary navigation fails
fallback_nav(Mx, My, Gx, Gy, Dir) :-
    delta(Gx, Mx, Dx) &
    delta(Gy, My, Dy) &
    (
        (Dx > Dy & Mx < Gx & Dir = e) |
        (Dx > Dy & Mx > Gx & Dir = w) |
        (Dx <= Dy & My < Gy & Dir = s) |
        (Dx <= Dy & My > Gy & Dir = n)
    ).

// Enhanced task scoring with multiple factors
score_task(TaskId, BlockType, Deadline, Step, Score) :-
    dispenser(BlockType, Dx, Dy) &
    chosen_goal(Gx, Gy) &
    my_position(Mx, My) &
    distance(Mx, My, Dx, Dy, DispDist) &
    distance(Dx, Dy, Gx, Gy, GoalDist) &
    TimeWindow = Deadline - Step &
    // Calculate task value per step
    TaskValue = 10 / (DispDist + GoalDist + 5) &
    // Factor in time window - avoid tasks with tight deadlines
    TimeRisk = min(TimeWindow / (DispDist + GoalDist + 10), 2) &
    // Check if this task is being done by another agent
    (assigned_task(TaskId, OtherAgent) & OtherAgent \== my_name & Conflict = 0.5) | (Conflict = 1) &
    // Final score calculation
    Score = TaskValue * TimeRisk * Conflict * 100.

// Distance between points + helper math rules
abs(In, Out) :- (In < 0 & Out = -In) | Out = In.
delta(A, B, Out) :- Delta = A-B & abs(Delta, Out).
distance(Ax, Ay, Bx, By, Dist) :- delta(Ax, Bx, Dx) & delta(Ay, By, Dy) & Dist = Dx + Dy.

// Mapping for offset vector component wall bouncing
bounce(In, Out) :- (In = 0 & Out = 1) | ((In = -1 | In = 1) & Out = -1).

// Min/max helpers
min(A, B, Min) :- (A <= B & Min = A) | (B < A & Min = B).
max(A, B, Max) :- (A >= B & Max = A) | (B > A & Max = B).

/*--------------------------------------------------
                  Initial Beliefs
--------------------------------------------------*/
state_machine(lost).       // The starting state of the top level state machine
my_position(0, 0).         // Initial position in the personal global coordinate space
last_move(none).           // Dummy before first actual move 
state_timeout(50).         // Default timeout for states (steps)
last_state_change(0).      // Track when the last state change happened
consecutive_failures(0).   // Counter for consecutive action failures
exploration_mode(0).       // Exploration mode (0 = normal, 1 = aggressive)
my_name(agent).            // Will be updated with the agent's actual name

// World boundaries (initially set to far values)
wall(n, 0, -1000).
wall(s, 0, 1000).
wall(e, 1000, 0).
wall(w, -1000, 0).

/*--------------------------------------------------
                       Core
--------------------------------------------------*/
// Initialization
!init.

// Pick a random diagonal direction and start exploring
+!init : 
    .random(RandomNumber) &
    choice_4([a(1,1), a(1,-1), a(-1,1), a(-1,-1)], RandomNumber, a(Dx, Dy))
    <- 
    B = 500; // A sufficiently big number to be definitely out of the board
    Gx = B * Dx;
    Gy = B * Dy; 
    +nav_goal(Gx, Gy); 
    .my_name(Name);
    -my_name(agent);
    +my_name(Name);
    .print("Initialized agent ", Name, " for ", Gx, " ", Gy).

// Main step cycle with timeout check and action failure tracking
@step[atomic]
+step(S) <-
    // Reset agent if it's been stuck in the same state for too long
    !check_state_timeout(S);
    
    // Handle consecutive failures
    !check_consecutive_failures;
    
    // Update beliefs and make decisions
    !updateBeliefs;
    !updateStateMachine;
    !decideAction.

// Timeout mechanism to prevent getting stuck in states
+!check_state_timeout(CurrentStep) :
    state_machine(State) & 
    State \== lost & 
    State \== idle &
    last_state_change(LastChange) & 
    state_timeout(Timeout) & 
    CurrentStep - LastChange > Timeout
    <-
    .print("State ", State, " timed out after ", Timeout, " steps. Switching to idle.");
    .abolish(nav_goal(_,_));
    -state_machine(State);
    +state_machine(idle);
    -last_state_change(LastChange);
    +last_state_change(CurrentStep);
    
    // Change exploration mode when stuck
    exploration_mode(Mode);
    NewMode = (Mode + 1) mod 2;
    -exploration_mode(Mode);
    +exploration_mode(NewMode);
    .print("Changing exploration mode to ", NewMode).

// No timeout needed
+!check_state_timeout(_) : true <- true.

// Reset consecutive failures counter on successful actions
+lastActionResult(success) : consecutive_failures(F) & F > 0 <-
    -consecutive_failures(F);
    +consecutive_failures(0).

// Track action failures
+lastActionResult(failed) : consecutive_failures(F) <-
    -consecutive_failures(F);
    NewF = F + 1;
    +consecutive_failures(NewF);
    .print("Action failed. Consecutive failures: ", NewF).

+lastActionResult(failed_forbidden) : consecutive_failures(F) <-
    -consecutive_failures(F);
    NewF = F + 1;
    +consecutive_failures(NewF);
    .print("Action forbidden. Consecutive failures: ", NewF).

+lastActionResult(failed_path) : consecutive_failures(F) <-
    -consecutive_failures(F);
    NewF = F + 1;
    +consecutive_failures(NewF);
    .print("Path failed. Consecutive failures: ", NewF).

// Check if we've had too many consecutive failures and reset if needed
+!check_consecutive_failures : consecutive_failures(F) & F > 5 <-
    .print("Too many consecutive failures, resetting agent state");
    -consecutive_failures(F);
    +consecutive_failures(0);
    .abolish(nav_goal(_,_));
    -state_machine(_);
    +state_machine(idle);
    step(S);
    -last_state_change(_);
    +last_state_change(S).

// Default case for failure checks
+!check_consecutive_failures : true <- true.

/*--------------------------------------------------
                Belief base updates
--------------------------------------------------*/
// Belief updating sequence
+!updateBeliefs <-
    !update_position;
    !update_obstacles;
    !get_goal;
    !get_dispenser(b0);
    !get_dispenser(b1);
    !update_task_assignments;
    !fix_task.

// Keeping track of internal positions
+!update_position : 
    lastActionResult(success) &
    lastAction(move) &
    lastActionParams([Dir]) &
    dir_to_offset(Dir, Dx, Dy) &
    my_position(Ox, Oy) 
    <-
    Nx = Ox + Dx;
    Ny = Oy + Dy;
    -my_position(Ox, Oy);
    +my_position(Nx, Ny);
    -last_move(_);
    +last_move(Dir).

// Handle wall bouncing for exploration
+!update_position : 
    (lastActionResult(failed_forbidden) | lastActionResult(failed_path)) & 
    lastAction(move) & 
    lastActionParams([Dir]) & 
    state_machine(lost) & 
    nav_goal(Ox, Oy) & 
    dir_to_offset(Dir, Fx, Fy) & 
    bounce(Fx, Dx) & 
    bounce(Fy, Dy) &
    my_position(Mx, My) &
    abs(Ox, Ax) &
    abs(Oy, Ay) 
    <- 
    -nav_goal(Ox, Oy); 
    Nx = 500 * (Ox/Ax) * Dx + Mx; 
    Ny = 500 * (Oy/Ay) * Dy + My;
    +nav_goal(Nx, Ny).

// Don't panic on lack of success or different actions
+!update_position : true <- true.

// Saving obstacles to memory
+!update_obstacles :
    my_position(Mx, My) 
    <- 
    for (obstacle(Rx, Ry)) { 
        X = Mx + Rx;
        Y = My + Ry;
        if (not saved_obstacle(X, Y)) { 
            +saved_obstacle(X, Y); 
        }; 
    }.

// Memory management: Limit saved obstacles to nearby ones
+!update_obstacles :
    my_position(Mx, My) &
    step(S) &
    S mod 100 == 0 // Periodically clean up distant obstacles
    <-
    for (saved_obstacle(X, Y)) {
        distance(Mx, My, X, Y, Dist);
        if (Dist > 50) { // If obstacle is far away
            -saved_obstacle(X, Y);
        };
    }.

// Bind to the first seen valid goal
+!get_goal : 
    not chosen_goal(_, _) & 
    goal(Rx, Ry) & 
    my_position(Mx, My) & 
    X = Rx + Mx & 
    Y = Ry + My & 
    Fy = Y + 1 & 
    not saved_obstacle(X, Fy) 
    <- 
    +chosen_goal(X, Y);
    .print("Found goal at ", X, ", ", Y).

// If both dispensers set, and a goal seen, if the goal is closer to both of them, rebind
+!get_goal :
    chosen_goal(Ox, Oy) & 
    dispenser(b0, Xb0, Yb0) &
    dispenser(b1, Xb1, Yb1) &
    goal(Rx, Ry) & 
    my_position(Mx, My) & 
    X = Rx + Mx & 
    Y = Ry + My & 
    Fy = Y + 1 & 
    not saved_obstacle(X, Fy) &
    distance(Ox, Oy, Xb0, Yb0, Dob0) &
    distance(Ox, Oy, Xb1, Yb1, Dob1) &
    distance(X, Y, Xb0, Yb0, Dnb0) &
    distance(X, Y, Xb1, Yb1, Dnb1) &
    Dnb0 < Dob0 &
    Dnb1 < Dob1 
    <-
    -chosen_goal(Ox, Oy);
    +chosen_goal(X, Y);
    .print("Switched to better goal at ", X, ", ", Y).

// Don't panic if a goal exist or no goal seen    
+!get_goal : true <- true.

// Bind to first seen dispenser of each type
+!get_dispenser(BlockType) : 
    not dispenser(BlockType, _, _) & 
    thing(Rx, Ry, dispenser, BlockType) & 
    my_position(Mx, My) & 
    X = Rx + Mx & 
    Y = Ry + My & 
    not saved_obstacle(X, Y) & 
    Fy = Y - 1 & 
    not saved_obstacle(X, Fy) 
    <- 
    +dispenser(BlockType, X, Y);
    .print("Found dispenser ", BlockType, " at ", X, ", ", Y).

// If a dispenser is seen that is closer to the bound goal switch to it
+!get_dispenser(BlockType) : 
    dispenser(BlockType, OldX, OldY) & 
    chosen_goal(GoalX, GoalY) & 
    thing(Rx, Ry, dispenser, BlockType) & 
    my_position(Mx, My) & 
    NewX = Rx + Mx & 
    NewY = Ry + My & 
    not saved_obstacle(NewX, NewY) & 
    Fy = NewY - 1 & 
    not saved_obstacle(NewX, Fy) & 
    distance(OldX, OldY, GoalX, GoalY, OldDistance) & 
    distance(NewX, NewY, GoalX, GoalY, NewDistance) & 
    NewDistance < OldDistance - 5 // Only switch if significantly closer
    <- 
    -dispenser(BlockType, OldX, OldY); 
    +dispenser(BlockType, NewX, NewY);
    .print("Switched to better dispenser ", BlockType, " at ", NewX, ", ", NewY).

// Don't panic if no dispensers found
+!get_dispenser(_) : true <- true.

// Update task assignments to help with coordination
+!update_task_assignments :
    current_task(TaskId, BlockType) & my_name(Name)
    <-
    -assigned_task(TaskId, _);
    +assigned_task(TaskId, Name).

// No task to update
+!update_task_assignments : true <- true.

// If the currently held task is no longer valid
// find a new task for the same block type
+!fix_task : 
    current_task(TaskId, BlockType) &
    not task(TaskId, _, _, _) 
    <-
    // Try to find a similar task with the same block type
    .findall(NewTaskId, 
             task(NewTaskId, Deadline, 10, [req(_, _, BlockType)]) & 
             step(Step) & Deadline > Step + 20, 
             SimilarTasks);
    if (.length(SimilarTasks, L) & L > 0) {
        .nth(0, SimilarTasks, NewId);
        -current_task(TaskId, BlockType);
        +current_task(NewId, BlockType);
        .print("Replaced invalid task with similar task: ", NewId);
    } else {
        -current_task(TaskId, BlockType);
        -assigned_task(TaskId, _);
        .print("Task ", TaskId, " is no longer valid and no similar task found");
    }.

// Don't panic nothing to fix.
+!fix_task : true <- true.

// If run into a wall save it
+lastActionResult(failed_forbidden) : 
    my_position(Mx, My) & 
    lastActionParams([Dir]) 
    <- 
    -wall(Dir, _, _); 
    +wall(Dir, Mx, My);
    .print("Updated wall location for direction ", Dir, " at ", Mx, ", ", My).

/*--------------------------------------------------
             State Machine transitions
--------------------------------------------------*/
// Helper to update state and record the time of change
+!update_state(OldState, NewState, Step) <-
    -state_machine(OldState);
    +state_machine(NewState);
    -last_state_change(_);
    +last_state_change(Step);
    .print("State change: ", OldState, " -> ", NewState, " at step ", Step).

// If all necessary bits found no longer lost
+!updateStateMachine : 
    state_machine(lost) & 
    chosen_goal(_, _) & 
    dispenser(b0, _, _) & 
    dispenser(b1, _, _) &
    step(S)
    <-
    !update_state(lost, idle, S);
    .print("Fully initialized").

// Stay lost if not fully initialized
+!updateStateMachine : state_machine(lost) <- true. 

// Pick up task with best score instead of first available
+!updateStateMachine : 
    state_machine(idle) & 
    step(Step) &
    .findall(score(TaskId, BlockType, Score), 
             (task(TaskId, Deadline, 10, [req(_, _, BlockType)]) & 
              Deadline > Step + 20 &
              score_task(TaskId, BlockType, Deadline, Step, Score)), 
             ScoredTasks) &
    .length(ScoredTasks, L) &
    L > 0 &
    .sort(ScoredTasks, SortedTasks) &
    .reverse(SortedTasks, [score(BestTaskId, BestBlockType, _)|_]) &
    dispenser(BestBlockType, Dx, Dy) & 
    Gy = Dy - 1 // Moving to the slot above a dispenser to avoid requiring rotation 
    <- 
    .abolish(nav_goal(_,_));
    +nav_goal(Dx, Gy);
    +current_task(BestTaskId, BestBlockType);
    +assigned_task(BestTaskId, my_name);
    !update_state(idle, toDispenser, Step);
    .print("Picked highest scored task: ", BestTaskId, " with block type ", BestBlockType).

// Can't find any tasks stay idle with random exploration
+!updateStateMachine : state_machine(idle) <- true. 

// If arrived at the dispenser move onto block requests
+!updateStateMachine : 
    state_machine(toDispenser) & 
    my_position(Mx, My) & 
    nav_goal(Mx, My) &
    step(S)
    <-
    .abolish(nav_goal(_,_)); 
    -last_move(_);
    +last_move(none);
    !update_state(toDispenser, atDispenser, S);
    .print("At dispenser").

// If we're close to the dispenser but not exactly at the right position, adjust
+!updateStateMachine : 
    state_machine(toDispenser) & 
    my_position(Mx, My) & 
    nav_goal(Dx, Dy) &
    distance(Mx, My, Dx, Dy, Dist) &
    Dist <= 2 & // We're close but not exactly there
    current_task(TaskId, BlockType) &
    thing(Rx, Ry, dispenser, BlockType) & // If we can see the dispenser
    step(S)
    <-
    .abolish(nav_goal(_,_));
    +nav_goal(Mx+Rx, My+Ry-1); // Position one square above the dispenser
    !update_state(toDispenser, toDispenser, S); // Stay in same state but reset timeout
    .print("Adjusting position to be above dispenser").

// Don't panic still on my way
+!updateStateMachine : state_machine(toDispenser) <- true. 

// If requesting succeeded move onto binding
+!updateStateMachine : 
    state_machine(atDispenser) & 
    lastActionResult(success) & 
    lastAction(request) &
    step(S)
    <- 
    !update_state(atDispenser, aboutToAttach, S);
    .print("Block requested").

// Handle failed request
+!updateStateMachine : 
    state_machine(atDispenser) &
    lastActionResult(failed) &
    lastAction(request) &
    step(S)
    <-
    .print("Block request failed - trying again");
    // Stay in same state but update timeout
    -last_state_change(_);
    +last_state_change(S).

// Don't panic still waiting on block
+!updateStateMachine : state_machine(atDispenser) <- true. 

// If bind successful, start heading for the goal
+!updateStateMachine : 
    state_machine(aboutToAttach) & 
    lastActionResult(success) & 
    lastAction(attach) & 
    chosen_goal(Gx, Gy) &
    lastActionParams([Dir]) &
    dir_to_offset(Dir, Ax, Ay) &
    step(S)
    <-
    .abolish(nav_goal(_,_));
    +nav_goal(Gx, Gy); 
    !update_state(aboutToAttach, toGoal, S);
    +holding(Ax, Ay);
    .print("Block attached, heading to goal").

// Handle failed attachment
+!updateStateMachine : 
    state_machine(aboutToAttach) &
    lastActionResult(failed) &
    lastAction(attach) &
    step(S)
    <-
    .print("Block attachment failed - returning to dispenser state");
    !update_state(aboutToAttach, atDispenser, S).

// Don't panic still waiting attachment
+!updateStateMachine : state_machine(aboutToAttach) <- true. 

// If at goal move onto submission
+!updateStateMachine : 
    state_machine(toGoal) & 
    my_position(Mx, My) & 
    nav_goal(Mx, My) &
    step(S)
    <- 
    .abolish(nav_goal(_,_));
    -last_move(_);
    +last_move(none);
    !update_state(toGoal, shouldSubmit, S);
    .print("At goal").

// If we're close to the goal but not exactly at the right position, adjust
+!updateStateMachine : 
    state_machine(toGoal) & 
    my_position(Mx, My) & 
    nav_goal(Dx, Dy) &
    distance(Mx, My, Dx, Dy, Dist) &
    Dist <= 2 & // We're close but not exactly there
    step(S)
    <-
    .abolish(nav_goal(_,_));
    +nav_goal(Dx, Dy); // Explicitly target the goal coordinates
    !update_state(toGoal, toGoal, S); // Stay in same state but reset timeout
    .print("Adjusting position to exact goal coordinates").

// Don't panic still on my way
+!updateStateMachine : state_machine(toGoal) <- true. 

// If submission successful become idle again 
+!updateStateMachine : 
    state_machine(shouldSubmit) &
    lastActionResult(success) &
    lastAction(submit) &
    current_task(TaskId, _) &
    step(S)
    <-
    -current_task(TaskId, _);
    -assigned_task(TaskId, _);
    -holding(_, _);
    !update_state(shouldSubmit, idle, S);
    .print("Task submitted successfully").

// Handle submission failure
+!updateStateMachine : 
    state_machine(shouldSubmit) &
    (lastActionResult(failed) | lastActionResult(failed_invalid_param)) &
    lastAction(submit) &
    current_task(TaskId, _) &
    step(S)
    <-
    -current_task(TaskId, _);
    -assigned_task(TaskId, _);
    -holding(_, _);
    !update_state(shouldSubmit, idle, S);
    .print("Task submission failed - returning to idle state").

// Don't panic still submitting
+!updateStateMachine : state_machine(shouldSubmit) <- true. 

/*--------------------------------------------------
               Action emitting plans
--------------------------------------------------*/
// No tasks found - active exploration
+!decideAction : 
    state_machine(idle) & 
    exploration_mode(0) &  // Normal exploration
    step(S) 
    <- 
    DirectionSeed = (S mod 4);
    if (DirectionSeed == 0) { move(n) }
    else { if (DirectionSeed == 1) { move(e) }
           else { if (DirectionSeed == 2) { move(s) }
                  else { move(w) }
                }
         }.

// Aggressive exploration for when we're stuck
+!decideAction : 
    state_machine(idle) & 
    exploration_mode(1) &  // Aggressive exploration
    step(S) 
    <- 
    DirectionSeed = (S mod 8);
    if (DirectionSeed == 0) { move(n) }
    else { if (DirectionSeed == 1) { move(ne) }
           else { if (DirectionSeed == 2) { move(e) }
                  else { if (DirectionSeed == 3) { move(se) }
                         else { if (DirectionSeed == 4) { move(s) }
                                else { if (DirectionSeed == 5) { move(sw) }
                                       else { if (DirectionSeed == 6) { move(w) }
                                              else { move(nw) }
                                            }
                                     }
                              }
                       }
                }
         }.

// Navigation tasks for lost state
+!decideAction : 
    state_machine(lost) &
    nav_goal(Dx, Dy) & 
    my_position(Mx, My) & 
    navigate(Mx, My, Dx, Dy, Dir)  
    <-
    move(Dir).
    
// Navigation with smart pathfinding for other states
+!decideAction : 
    (
        state_machine(toDispenser) | 
        state_machine(toGoal)
    ) &
    nav_goal(Dx, Dy) & 
    my_position(Mx, My) & 
    new_nav(Mx, My, Dx, Dy, Dir) 
    <- 
    -last_move(_);
    +last_move(Dir);
    move(Dir).

// Request block at dispenser
+!decideAction : state_machine(atDispenser) <- request(s).

// Attach block
+!decideAction : state_machine(aboutToAttach) <- attach(s).

// Submit task at goal
+!decideAction : 
    state_machine(shouldSubmit) & 
    current_task(TaskId, _) 
    <- 
    submit(TaskId).

// Fallback to prevent plan failure - try a random move
+!decideAction : true <- 
    .print("No applicable action plan, using fallback movement");
    .random(R);
    if (R < 0.25) { move(n) }
    else { if (R < 0.5) { move(e) }
           else { if (R < 0.75) { move(s) }
                  else { move(w) }
                }
         }.