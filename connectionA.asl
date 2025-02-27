/* Initial beliefs and rules */
random_dir(DirList,RandomNumber,Dir) :- (RandomNumber <= 0.25 & .nth(0,DirList,Dir)) | (RandomNumber <= 0.5 & .nth(1,DirList,Dir)) | (RandomNumber <= 0.75 & .nth(2,DirList,Dir)) | (.nth(3,DirList,Dir)).

navigate(Ox,Oy,Dx,Dy,Dir) :- ( not Oy = Dy & ( (Oy<Dy & Dir = s ) | Dir=n ) ) | ( (Ox < Dx & Dir = e) | Dir = w ).

abs(In,Out) :- (In<0 & Out=-In) | Out = In.
delta(A,B,Out) :- Delta = A-B & abs(Delta,Out).
distance(Ax,Ay,Bx,By,Dist) :- delta(Ax,Bx,Dx) & delta(Ay,By,Dy) & Dist = Dx+Dy.

state_machine(lost).
my_position(0,0).

// Activated for each step of the simulation (quanta of this world)
// only children of this plan are allowed to emit actions
@step[atomic]
+step(S) <-
    //.print("Step: ",S," start");
    //myLib.parsePercepts(Percepts);
    //myLib.updateBeliefBase(Percepts);
    !updateBeliefs;
    !updateStateMachine;
    !decideAction.
    //.print("Step: ",S," end").

/* Belief base plans */
+!updateBeliefs <-
    !update_position;
    !get_goal;
    !get_dispenser(b0);
    !get_dispenser(b1);
    !fix_task.

+!update_position : lastActionResult(success) & lastAction(move) & lastActionParams([n]) & my_position(X,Oy) <- Ny=Oy-1; -my_position(X,Oy); +my_position(X,Ny).
+!update_position : lastActionResult(success) & lastAction(move) & lastActionParams([s]) & my_position(X,Oy) <- Ny=Oy+1; -my_position(X,Oy); +my_position(X,Ny).
+!update_position : lastActionResult(success) & lastAction(move) & lastActionParams([e]) & my_position(Ox,Y) <- Nx=Ox+1; -my_position(Ox,Y); +my_position(Nx,Y).
+!update_position : lastActionResult(success) & lastAction(move) & lastActionParams([w]) & my_position(Ox,Y) <- Nx=Ox-1; -my_position(Ox,Y); +my_position(Nx,Y).
+!update_position : true <- true. // don't panic on lack of success or different actions

+!get_goal : not chosen_goal(_,_) & goal(Rx,Ry) & my_position(Mx,My) <- X=Rx+Mx; Y=Ry+My; +chosen_goal(X,Y).
+!get_goal : true <- true. // don't panic if a goal exist or no goal seen

+!get_dispenser(BlockType) : not dispenser(BlockType,_,_) & thing(Rx,Ry,dispenser,BlockType) & my_position(Mx,My) <- X=Rx+Mx; Y=Ry+My; +dispenser(BlockType,X,Y).
+!get_dispenser(BlockType) : dispenser(BlockType,OldX,OldY) & chosen_goal(GoalX,GoalY) & thing(Rx,Ry,dispenser,BlockType) & my_position(Mx,My) & NewX=Rx+Mx & NewY=Ry+My & distance(OldX,OldY,GoalX,GoalY,OldDistance) & distance(NewX,NewY,GoalX,GoalY,NewDistance) & NewDistance < OldDistance <- -dispenser(BlockType,OldX,OldY); +dispenser(BlockType,NewX,NewY).
+!get_dispenser(_) : true <- true. // don't panic if no dispensers found

+!fix_task : current_task(TaskId, BlockType) & not task(TaskId,_,_,_) & task(NewTaskId, Deadline, 10,[req(_,_,BlockType)] ) & step(Step) & Deadline > Step <- -current_task(TaskId, BlockType); +current_task(NewTaskId, BlockType).
+!fix_task : true <- true. // don't panic nothing to fix.

/* State Machine plans */
+!updateStateMachine : state_machine(lost) & chosen_goal(_,_) & dispenser(b0, _,_) & dispenser(b1,_,_) <- -state_machine(lost); +state_machine(idle); .print("Fully initialized"). // become idle if all required fields are in the belief base
+!updateStateMachine : state_machine(lost) <- true. // stay lost

+!updateStateMachine : state_machine(idle) & task(TaskId, Deadline, 10,[req(_,_,BlockType)] ) & step(Step) & Deadline > Step <- +current_task(TaskId,BlockType); -state_machine(idle); +state_machine(toDispenser); .print("Picked task: ",TaskId).
+!updateStateMachine : state_machine(idle) <- true. // can't find any tasks


+!updateStateMachine : state_machine(toDispenser) & my_position(Mx,My) & current_task(_,Bt) & Cy = My+1 & dispenser(Bt,Mx,Cy) <- -state_machine(toDispenser); +state_machine(atDispenser); .print("At dispenser").
+!updateStateMachine : state_machine(toDispenser) <- true. // don't panic still on my way

+!updateStateMachine : state_machine(atDispenser) & lastActionResult(success) & lastAction(request) <- -state_machine(atDispenser); +state_machine(aboutToAttach); .print("Block requested").
+!updateStateMachine : state_machine(atDispenser) <- true. // don't panic still waiting on block (should never trigger unless blocked)

+!updateStateMachine : state_machine(aboutToAttach) & lastActionResult(success) & lastAction(attach) <- -state_machine(aboutToAttach); +state_machine(toGoal); .print("Block attached").
+!updateStateMachine : state_machine(aboutToAttach) <- true. // don't panic still waiting attachment (should never trigger unless blocked)

+!updateStateMachine : state_machine(toGoal) & my_position(Mx,My) & chosen_goal(Mx,My) <- -state_machine(toGoal); +state_machine(shouldSubmit);.print("At goal").
+!updateStateMachine : state_machine(toGoal) <- true. // don't panic still on my way

+!updateStateMachine : state_machine(shouldSubmit) & lastActionResult(success) & lastAction(submit) <- -current_task(_,_) ;-state_machine(shouldSubmit); +state_machine(idle); .print("Task submitted").
+!updateStateMachine : state_machine(shouldSubmit) <- true. // don't panic still submitting (shouldn't trigger unless task duplicate)

/* Action emitting plans */
// Exploring logic
+!decideAction : state_machine(lost) & .random(RandomNumber) & random_dir([n,s,e,w],RandomNumber,Dir) <- move(Dir).

+!decideAction : state_machine(idle) <- skip. // No tasks found there is nothing to do

+!decideAction : state_machine(toDispenser) & my_position(Mx,My) & current_task(_,Bt) & dispenser(Bt,Dx,Dy) & Cy = Dy-1 & navigate(Mx,My,Dx,Cy,Dir)  <- move(Dir). // No tasks found there is nothing to do

+!decideAction : state_machine(atDispenser) <- request(s).

+!decideAction : state_machine(aboutToAttach) <- attach(s).

+!decideAction : state_machine(toGoal) & my_position(Mx,My) & chosen_goal(Gx,Gy) & navigate(Mx,My,Gx,Gy,Dir) <- move(Dir).

+!decideAction : state_machine(shouldSubmit) & current_task(TaskId,_) <- submit(TaskId).

+!decideAction : true <- true.

