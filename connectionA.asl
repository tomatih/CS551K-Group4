/* 
 * Enhanced agent for CS551K-Contest
 * Capabilities: navigation, block detection, carrying, goal finding, task completion
 */

/* Initial Beliefs */
random_dir(n).
random_dir(s).
random_dir(e).
random_dir(w).

// A* pathfinding beliefs ,Trying to implement A* graph path finding algo
at(0, 0, 0). // (x, y, cost)
visited([]).

// Team coordination 
//free_agent.

/* Initial Goals */
!start.

/* Plans */
+!start : true <- 
    .print("Agent started and ready for operation.");
    !find_tasks.

/* Task Management */
+!find_tasks : true <- 
    ?my_name(Name);
    .print(Name, " looking for available tasks");
    !scan_environment.

+!scan_environment : true <-
    .findall(block(X,Y,Type), percept(block(X,Y,Type)), Blocks);
    .findall(task(Id,Deadline,Reward,Reqs), task(Id,Deadline,Reward,Reqs), Tasks);
    .print("Environment scan: ", Blocks.length, " blocks, ", Tasks.length, " tasks");
    !prioritize_tasks(Tasks).

+!prioritize_tasks([]) : true <-
    .print("No tasks available, exploring environment");
    !explore.

+!prioritize_tasks(Tasks) : true <-
    // Sort tasks by reward/deadline ratio
    .sort(Tasks, SortedTasks);
    .nth(0, SortedTasks, BestTask);
    BestTask = task(Id,Deadline,Reward,_);
    .print("Selected task: ", Id, " with reward ", Reward, " and deadline ", Deadline);
    !work_on_task(BestTask).

+!work_on_task(task(Id,_,_,Requirements)) : true <-
    .print("Working on task ", Id, " with requirements ", Requirements);
    !gather_blocks(Requirements).

/* Block Gathering */
+!gather_blocks([]) : true <-
    .print("All required blocks gathered");
    !deliver_task.

+!gather_blocks([req(Type,X,Y)|Rest]) : true <-
    .print("Looking for block of type ", Type);
    !find_block(Type).

+!find_block(Type) : percept(block(X,Y,Type)) & my_position(MyX,MyY) & not carrying(_) <-
    .print("Found block of type ", Type, " at position (", X, ", ", Y, ")");
    !calculate_path(MyX, MyY, X, Y);
    !move_to(X, Y);
    !attach_block.

+!find_block(Type) : true <-
    .print("No visible block of type ", Type, ", exploring");
    !explore.

+!attach_block : my_position(X,Y) & percept(block(X,Y,_)) <-
    .print("Attaching block at position (", X, ", ", Y, ")");
    attach;
    !find_tasks.

+!attach_block : true <-
    .print("No block at current position to attach");
    !explore.

/* Movement and Navigation */
+!move_to(X, Y) : my_position(X, Y) <-
    .print("Already at destination (", X, ", ", Y, ")").

+!move_to(X, Y) : my_position(MyX, MyY) <-
    // Determine best direction
    if (MyX < X) {
        Dir = e;
    } else {
        if (MyX > X) {
            Dir = w;
        } else {
            if (MyY < Y) {
                Dir = n;
            } else {
                Dir = s;
            }
        }
    }
    .print("Moving ", Dir, " towards (", X, ", ", Y, ")");
    move(Dir);
    !move_to(X, Y).

+!calculate_path(StartX, StartY, EndX, EndY) : true <-
    .print("Calculating path from (", StartX, ", ", StartY, ") to (", EndX, ", ", EndY, ")");
    // A* pathfinding would be implemented here
    // For now we'll use simple direct path.

/* Exploration */
+!explore : true <-
    .print("Exploring environment");
    !move_random.

+!move_random : true <-
    .random(R);
    if (R < 0.25) {
        move(n);
    } else {
        if (R < 0.5) {
            move(s);
        } else {
            if (R < 0.75) {
                move(e);
            } else {
                move(w);
            }
        }
    }
    .print("Moving randomly");
    !scan_environment.

/* Task Delivery */
+!deliver_task : carrying(_) & percept(goal(X,Y)) <-
    .print("Goal found at (", X, ", ", Y, "), delivering task");
    !move_to(X, Y);
    submit;
    .print("Task submitted successfully!");
    !find_tasks.

+!deliver_task : carrying(_) <-
    .print("Carrying block but goal not found, searching for goal");
    !explore.

+!deliver_task : true <-
    .print("Not carrying any block, cannot deliver");
    !find_tasks.

/* Perception Handlers */
+step(S) : true <-
    .print("Step ", S);
    !scan_environment.

+my_position(X, Y) : true <-
    .print("Position updated to (", X, ", ", Y, ")").

+carrying(Block) : Block \== none <-
    .print("Now carrying block: ", Block);
    !deliver_task.

+carrying(none) : true <-
    .print("Not carrying any block");
    !find_tasks.

/* Error Handling */
-!find_tasks : true <-
    .print("Error in find_tasks, retrying");
    !explore.

-!gather_blocks(_) : true <-
    .print("Error in gather_blocks, retrying");
    !explore.

-!deliver_task : true <-
    .print("Error in deliver_task, retrying");
    !explore.