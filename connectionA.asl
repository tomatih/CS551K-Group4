/*--------------------------------------------------
                       Rules
--------------------------------------------------*/
// Pick a random element fom a list of 4
choice_4(DirList,RandomNumber,Dir) :- 
    (RandomNumber <= 0.25 & .nth(0,DirList,Dir)) | 
    (RandomNumber <= 0.5 & .nth(1,DirList,Dir)) | 
    (RandomNumber <= 0.75 & .nth(2,DirList,Dir)) | 
    (.nth(3,DirList,Dir)).

// converts a direction into an offset vector
dir_to_offset(Dir,X,Y) :- 
    (Dir=n & X=0 & Y=-1) | 
    (Dir=s & X=0 & Y=1) | 
    (Dir=e & X=1 & Y=0) | 
    (Dir=w & X=-1 & Y=0).

// check if a given block is free
//TODO: handle resizing
free(X,Y) :- 
    (not saved_obstacle(X,Y)) &
    (
        my_position(Mx,My) &
        Ox = X-Mx &
        Oy = Y-My &
        (not thing(Ox,Oy,entity,_)) &
        ((not thing(Ox,Oy,block,_)) | holding(Ox,Oy) )
    )&
    (
        wall(n,_,Ymin) & wall(s,_, Ymax) &
        Ymin <= Y & Ymax >= Y &
        wall(e, Xmax,_) & wall(w,Xmin,_) &
        Xmin <= X & Xmax >= X
    ).

// Idea: generate a list of choices for each move
// format: [choice(dist,dir)]
// before adding to list chech for freeness
// if not free multiply by big number
// then on move choose minimum from that list
new_nav(Mx,My,Gx,Gy,Dir) :- 
	(
		Ny = My-1 &
		Sy = My+1 &
		Ex = Mx+1 &
		Wx = Mx-1 
	) & (
		distance(Mx,Ny,Gx,Gy,Nd) &
		distance(Mx,Sy,Gx,Gy,Sd) &
		distance(Ex,My,Gx,Gy,Ed) &
		distance(Wx,My,Gx,Gy,Wd) 
	) & (
		BigNum = 10000 &
		( ((not free(Mx,Ny)) & Nmult=BigNum) | Nmult = 1) &
		( ((not free(Mx,Sy)) & Smult=BigNum) | Smult = 1) &
		( ((not free(Ex,My)) & Emult=BigNum) | Emult = 1) &
		( ((not free(Wx,My)) & Wmult=BigNum) | Wmult = 1) 
	) & (
        Penalty = 5 &
        ( (last_move(s) & Noff=Penalty ) | Noff=0 ) &
        ( (last_move(n) & Soff=Penalty ) | Soff=0 ) &
        ( (last_move(w) & Eoff=Penalty ) | Eoff=0 ) &
        ( (last_move(e) & Woff=Penalty ) | Woff=0 )
    ) & (
        Nval = (Nd+Noff)*Nmult & 
        Sval = (Sd+Soff)*Smult & 
        Eval = (Ed+Eoff)*Emult & 
        Wval = (Wd+Woff)*Wmult
    ) &
	.min([c(Nval,n),c(Sval,s),c(Eval,e),c(Wval,w) ],c(_,Dir)).

// simplistic navigation
// just a diagonal b-line for the target with no regard for anything
navigate(Ox,Oy,Dx,Dy,Dir) :- 
    ( 
        distance(Ox,Dy,Dx,Dy, Gx) & 
        distance(Dx,Oy,Dx,Dy,Gy) 
    ) &
    (
        ( Gy>Gx & ((Oy<Dy & Dir = s ) | Dir=n )) |
        ( (Ox < Dx & Dir = e) | Dir = w )
    ).

// Distance between points + helper math rules
abs(In,Out) :- (In<0 & Out=-In) | Out = In.
delta(A,B,Out) :- Delta = A-B & abs(Delta,Out).
distance(Ax,Ay,Bx,By,Dist) :- delta(Ax,Bx,Dx) & delta(Ay,By,Dy) & Dist = Dx+Dy.

// Mapping for offset vector component wall bouncing
bounce(In,Out) :- (In=0 & Out=1) | ( (In=-1 | In=1) & Out=-1 ).

/*--------------------------------------------------
                  Initial Beliefs
--------------------------------------------------*/
state_machine(lost). // the starting state of the top level state machine
my_position(0,0). // initial position in the personal global coodinate space
last_move(none). // dummy before first actual move 
// know that the world end somewhere not exactly sure where, but far
wall(n,0,-1000).
wall(s,0, 1000).
wall(e, 1000,0).
wall(w,-1000,0).

/*--------------------------------------------------
                       Core
--------------------------------------------------*/
// initalisation
!init.
// pick a random diagonal direction and start exploring there
+!init : 
    .random(RandomNumber) &
    choice_4([a(1,1),a(1,-1),a(-1,1),a(-1,-1)],RandomNumber,a(Dx,Dy))
    <- 
    B=500; // a sufficiently big number to de definetly out of the board
    Gx=B*Dx;
    Gy=B*Dy; 
    +nav_goal(Gx,Gy); 
    .print("Initialized for ",Gx," ",Gy).

// Activated for each step of the simulation (quanta of this world)
// only children of this plan are allowed to emit actions
@step[atomic]
+step(S) <-
    //.print("Step: ",S," start");
    !updateBeliefs;
    !updateStateMachine;
    !decideAction.
    //.print("Step: ",S," end").

/*--------------------------------------------------
                Belief base upates
--------------------------------------------------*/
// belief upating sequence
+!updateBeliefs <-
    !update_position;
    !update_obstacles;
    !get_goal;
    !get_dispenser(b0);
    !get_dispenser(b1);
    !fix_task.

// keeping track of internal positions
+!update_position : 
    lastActionResult(success) &
    lastAction(move) &
    lastActionParams([Dir]) &
    dir_to_offset(Dir,Dx,Dy) &
    my_position(Ox,Oy) 
    <-
    Nx=Ox+Dx;
    Ny=Oy+Dy;
    -my_position(Ox,Oy);
    +my_position(Nx,Ny).
+!update_position : 
    (lastActionResult(failed_forbidden) | lastActionResult(failed_path)) & 
    lastAction(move) & 
    lastActionParams([Dir]) & 
    state_machine(lost) & 
    nav_goal(Ox,Oy) & 
    dir_to_offset(Dir, Fx,Fy) & 
    bounce(Fx,Dx) & 
    bounce(Fy,Dy) &
    my_position(Mx,My) &
    abs(Ox,Ax) &
    abs(Oy,Ay) 
    <- 
    -nav_goal(Ox,Oy); 
    Nx=500*(Ox/Ax)*Dx + Mx; 
    Ny=500*(Oy/Ay)*Dy + My;
    +nav_goal(Nx,Ny).
// don't panic on lack of success or different actions
+!update_position : true <- true. 

// saving obstacles to memory
+!update_obstacles :
    my_position(Mx,My) 
    <- 
    for (obstacle(Rx,Ry)) { 
        X=Mx+Rx;
        Y=My+Ry;
        if(not saved_obstacle(X,Y)) { 
            +saved_obstacle(X,Y) 
        }; 
    }.

// bind to the first seen valid goal
+!get_goal : 
    (not chosen_goal(_,_)) & 
    goal(Rx,Ry) & 
    my_position(Mx,My) & 
    X=Rx+Mx & 
    Y=Ry+My & 
    (not saved_obstacle(X,Y)) &
    Fy=Y+1 & 
    (not saved_obstacle(X,Fx)) 
    <- 
    +chosen_goal(X,Y).
//if both dispensers set, anf a goal seen, if the goal is closer to both of them, rebind
+!get_goal:
    chosen_goal(Ox,Oy) & 
    dispenser(b0,Xb0,Yb0) &
    dispenser(b1,Xb1,Yb0) &
    goal(Rx,Ry) & 
    my_position(Mx,My) & 
    X=Rx+Mx & 
    Y=Ry+My & 
    (not saved_obstacle(X,Y)) &
    Fy=Y+1 & 
    (not saved_obstacle(X,Fx)) &
    distance(Ox,Oy,Xb0,Yb0, Dob0) &
    distance(Ox,Oy,Xb1,Yb1, Dob1) &
    distance(X,Y,Xb0,Yb0, Dnb0) &
    distance(X,Y,Xb1,Yb1, Dnb1) &
    (Dnb0 < Dob0) &
    (Dnb1 < Dnb0) 
    <-
    -chosen_goal(Ox,Oy);
    +chosen_goal(X,Y).
// don't panic if a goal exist or no goal seen    
+!get_goal : true <- true.

// bind to first seen dispenser of each type
+!get_dispenser(BlockType) : 
    (not dispenser(BlockType,_,_)) & 
    thing(Rx,Ry,dispenser,BlockType) & 
    my_position(Mx,My) & 
    X=Rx+Mx & 
    Y=Ry+My & 
    (not saved_obstacle(X,Y)) & 
    Fy=Y-1 & 
    (not saved_obstacle(X,Fy)) 
    <- 
    +dispenser(BlockType,X,Y).
// if a dispenser is seen that is closer to the bound goal switch to it
+!get_dispenser(BlockType) : 
    dispenser(BlockType,OldX,OldY) & 
    chosen_goal(GoalX,GoalY) & 
    thing(Rx,Ry,dispenser,BlockType) & 
    my_position(Mx,My) & 
    NewX=Rx+Mx & 
    NewY=Ry+My & 
    (not saved_obstacle(NewX,NewY) )& 
    Fy=Y-1 & 
    (not saved_obstacle(X,Fy) )& 
    distance(OldX,OldY,GoalX,GoalY,OldDistance) & 
    distance(NewX,NewY,GoalX,GoalY,NewDistance) & 
    NewDistance < OldDistance
    <- 
    -dispenser(BlockType,OldX,OldY); 
    +dispenser(BlockType,NewX,NewY).
// don't panic if no dispensers found
+!get_dispenser(_) : true <- true.

// If the currently held task is no longer valid
// find a new task for the same block type
+!fix_task : 
    current_task(TaskId, BlockType) &
    (not task(TaskId,_,_,_) )& 
    task(NewTaskId, Deadline, 10,[req(_,_,BlockType)] ) &
    step(Step) &
    Deadline > Step 
    <-
    -current_task(TaskId, BlockType);
    +current_task(NewTaskId, BlockType).
// don't panic nothing to fix.
+!fix_task : true <- true.

// If run into a wall save it
+lastActionResult(failed_forbidden) : 
    my_position(Mx,My) & 
    lastActionParams([Dir]) 
    <- 
    -wall(Dir,_,_); 
    +wall(Dir,Mx,My).

/*--------------------------------------------------
             State Machine transitions
--------------------------------------------------*/
// if all necessary bits found no longer lost
+!updateStateMachine : 
    state_machine(lost) & 
    chosen_goal(_,_) & 
    dispenser(b0, _,_) & 
    dispenser(b1,_,_) 
    <-
    -state_machine(lost);
    +state_machine(idle);
    .print("Fully initialized").
// stay lost
+!updateStateMachine : state_machine(lost) <- true. 

// Pick up an avaible valid task, start heading to the right dispenser
+!updateStateMachine : 
    state_machine(idle) & 
    // configuration details ingored as all 1 block tasks are always south
    task(TaskId, Deadline, 10,[req(_,_,BlockType)] ) &
    step(Step) & 
    Deadline > Step & 
    dispenser(BlockType, Dx, Dy) & 
    Gy=Dy-1 // moving to the slot above a dispenser to avoid requiring rotation 
    <- 
    -nav_goal(_,_);
    +nav_goal(Dx,Gy);
    +current_task(TaskId,BlockType);
    -state_machine(idle);
    +state_machine(toDispenser); 
    .print("Picked task: ",TaskId).
// can't find any tasks stay idle
+!updateStateMachine : state_machine(idle) <- true. 

// If arrived at the dispenser move onto block requests
+!updateStateMachine : 
    state_machine(toDispenser) & 
    my_position(Mx,My) & 
    nav_goal(Mx,My) 
    <-
    -nav_goal(Mx,My); 
    -last_move(_);
    +last_move(none);
    -state_machine(toDispenser);
    +state_machine(atDispenser);
    .print("At dispenser").
// don't panic still on my way
+!updateStateMachine : state_machine(toDispenser) <- true. 

// If requesting succedded move onto binding
+!updateStateMachine : 
    state_machine(atDispenser) & 
    lastActionResult(success) & 
    lastAction(request) 
    <- 
    -state_machine(atDispenser); 
    +state_machine(aboutToAttach); 
    .print("Block requested").
// don't panic still waiting on block (should never trigger unless blocked)
+!updateStateMachine : state_machine(atDispenser) <- true. 

// if bind succesfull, start heading for the goal
+!updateStateMachine : 
    state_machine(aboutToAttach) & 
    lastActionResult(success) & 
    lastAction(attach) & 
    chosen_goal(Gx,Gy) &
    lastActionParams([Dir]) &
    dir_to_offset(Dir,Ax,Ay)
    <-
    +nav_goal(Gx,Gy); 
    -state_machine(aboutToAttach);
    +state_machine(toGoal);
    +holding(Ax,Ay);
    .print("Block attached").
// don't panic still waiting attachment (should never trigger unless blocked)
+!updateStateMachine : state_machine(aboutToAttach) <- true. 

// If at goal move onto submission
+!updateStateMachine : 
    state_machine(toGoal) & 
    my_position(Mx,My) & 
    nav_goal(Mx,My) 
    <- 
    -nav_goal(Mx,My);
    -last_move(_);
    +last_move(none);
    -state_machine(toGoal); 
    +state_machine(shouldSubmit);
    .print("At goal").
// don't panic still on my way
+!updateStateMachine : state_machine(toGoal) <- true. 

// if submission succesfull become idle again 
+!updateStateMachine : 
    state_machine(shouldSubmit) &
    lastActionResult(success) &
    lastAction(submit)
    <-
    -current_task(_,_);
    -holding(_,_);
    -state_machine(shouldSubmit);
    +state_machine(idle);
    .print("Task submitted").
// don't panic still submitting (shouldn't trigger unless task duplicate)
+!updateStateMachine : state_machine(shouldSubmit) <- true. 

/*--------------------------------------------------
               Action emitting plans
--------------------------------------------------*/
// No tasks found there is nothing to do
+!decideAction : state_machine(idle) <- skip. 

// navigation tasks
+!decideAction : 
	state_machine(lost) &
	nav_goal(Dx,Dy) & 
    my_position(Mx,My) & 
    navigate(Mx,My,Dx,Dy,Dir)  
    <-
    move(Dir).
+!decideAction : 
    (
        state_machine(toDispenser) | 
        state_machine(toGoal)
    ) &
    nav_goal(Dx,Dy) & 
    my_position(Mx,My) & 
    new_nav(Mx,My,Dx,Dy,Dir) 
    <- 
    -last_move(_);
    +last_move(Dir);
    move(Dir).


+!decideAction : state_machine(atDispenser) <- request(s).

+!decideAction : state_machine(aboutToAttach) <- attach(s).

+!decideAction : 
    state_machine(shouldSubmit) & 
    current_task(TaskId,_) 
    <- 
    submit(TaskId).

// should never trigger, here to prevent plan failure
+!decideAction : true <- .print("Action faield").
