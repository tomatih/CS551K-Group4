/* Initial beliefs and rules */
random_dir(DirList,RandomNumber,Dir) :- (RandomNumber <= 0.25 & .nth(0,DirList,Dir)) | (RandomNumber <= 0.5 & .nth(1,DirList,Dir)) | (RandomNumber <= 0.75 & .nth(2,DirList,Dir)) | (.nth(3,DirList,Dir)).

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
+!updateBeliefs : my_position(X,Y) <-
    !update_position;
    !get_goal;
    !get_dispenser(b0);
    !get_dispenser(b1).

+!update_position : lastActionResult(success) & lastAction(move) & lastActionParams([n]) & my_position(X,Oy) <- Ny=Oy-1; -my_position(X,Oy); +my_position(X,Ny).
+!update_position : lastActionResult(success) & lastAction(move) & lastActionParams([s]) & my_position(X,Oy) <- Ny=Oy+1; -my_position(X,Oy); +my_position(X,Ny).
+!update_position : lastActionResult(success) & lastAction(move) & lastActionParams([e]) & my_position(Ox,Y) <- Nx=Ox+1; -my_position(Ox,Y); +my_position(Nx,Y).
+!update_position : lastActionResult(success) & lastAction(move) & lastActionParams([w]) & my_position(Ox,Y) <- Nx=Ox-1; -my_position(Ox,Y); +my_position(Nx,Y).
+!update_position : true <- true. // don't panic on lack of success or different actions

+!get_goal : not chosen_goal(_,_) & goal(Rx,Ry) & my_position(Mx,My) <- X=Rx+Mx; Y=Ry+My; +chosen_goal(X,Y).
+!get_goal : true <- true. // don't panic if a goal exist or no goal seen

+!get_dispenser(BlockType) : not dispenser(BlockType,_,_) & thing(Rx,Ry,dispenser,BlockType) & my_position(Mx,My) <- X=Rx+Mx; Y=Ry+My; +dispenser(BlockType,X,Y).
+!get_dispenser(_) : true <- true. // don't panic if no dispensers found

/* State Machine plans */
+!updateStateMachine : state_machine(lost) & chosen_goal(_,_) & dispenser(b0, _,_) & dispenser(b1,_,_) <- -state_machine(lost); +state_machine(idle); .print("Fully initialized"). // become idle if all required fields are in the belief base
+!updateStateMachine : state_machine(lost) <- true. // stay lost


+!updateStateMachine : state_machine(idle) & task(TaskId, Deadline, 10,[req(_,_,BlockType)] ) & step(Step) & Deadline > Step <- +current_task(TaskId,BlockType); -state_machine(idle); +state_machine(toDispenser); .print("Picked task: ",TaskId).
+!updateStateMachine : state_machine(idle) <- true. // can't find any tasks

/* Action emitting plans */
// Exploring logic
+!decideAction : state_machine(lost) & .random(RandomNumber) & random_dir([n,s,e,w],RandomNumber,Dir) <- move(Dir).

+!decideAction : state_machine(idle) <- skip. // No tasks found there is nothing to do

+!decideAction : true <- true.

