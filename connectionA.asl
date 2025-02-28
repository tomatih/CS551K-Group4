/* 
 * Enhanced agent for CS551K-Contest
 * Capabilities: navigation, block detection, carrying, goal finding, task completion
 */

/* Initial Beliefs */
random_dir(n).
random_dir(s).
random_dir(e).
random_dir(w).

// A* pathfinding beliefs
path([]).      // Current path being followed
obstacle(X,Y) :- thing(X,Y,obstacle,_).  // Define obstacles
open_list([]).   // A* open list
closed_list([]). // A* closed list

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
    !navigate_to(X, Y);
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

/* A* Pathfinding Implementation */

// Start A* path calculation
+!calculate_path(StartX, StartY, GoalX, GoalY) : true <-
    .print("Calculating A* path from (", StartX, ", ", StartY, ") to (", GoalX, ", ", GoalY, ")");
    -+open_list([]);
    -+closed_list([]);
    
    // Calculate heuristic for start node
    H = math.abs(GoalX - StartX) + math.abs(GoalY - StartY);
    
    // Add start node to open list: [X, Y, G, H, F, ParentX, ParentY]
    // G is cost from start, H is heuristic to goal, F = G + H
    -+open_list([[StartX, StartY, 0, H, H, -1, -1]]);
    
    !astar_loop(GoalX, GoalY).

// Main A* loop
+!astar_loop(GoalX, GoalY) : open_list([]) <-
    .print("No path found to goal (", GoalX, ", ", GoalY, ")");
    -+path([]);  // Clear path
    !explore.    // Fall back to exploration

// Path found - reconstruct and store
+!astar_loop(GoalX, GoalY) : open_list([Current|_]) & Current = [GoalX, GoalY, _, _, _, _, _] <-
    .print("Path found to goal (", GoalX, ", ", GoalY, ")");
    !reconstruct_path(GoalX, GoalY).

// Continue A* search
+!astar_loop(GoalX, GoalY) : open_list(OpenList) & closed_list(ClosedList) <-
    // Sort open list by F value (lowest first)
    .sort(OpenList, SortedOpen, f_compare);
    
    // Get lowest F cost node
    .nth(0, SortedOpen, [CurrentX, CurrentY, G, H, F, ParentX, ParentY]);
    
    // Remove current from open list and add to closed list
    .delete(OpenList, [CurrentX, CurrentY, G, H, F, ParentX, ParentY], NewOpenList);
    -+open_list(NewOpenList);
    
    // Add to closed list
    +closed_list([[CurrentX, CurrentY, G, H, F, ParentX, ParentY]|ClosedList]);
    
    // Generate successors in four directions (n, s, e, w)
    !generate_successor(CurrentX, CurrentY+1, CurrentX, CurrentY, G, GoalX, GoalY); // North
    !generate_successor(CurrentX, CurrentY-1, CurrentX, CurrentY, G, GoalX, GoalY); // South
    !generate_successor(CurrentX+1, CurrentY, CurrentX, CurrentY, G, GoalX, GoalY); // East
    !generate_successor(CurrentX-1, CurrentY, CurrentX, CurrentY, G, GoalX, GoalY); // West
    
    !astar_loop(GoalX, GoalY).

// Generate successor node and add to open list if valid
+!generate_successor(X, Y, ParentX, ParentY, ParentG, GoalX, GoalY) : 
    not obstacle(X, Y) &              // Not an obstacle
    not in_closed_list(X, Y) <-       // Not in closed list
    
    // Calculate G (cost from start) - assume cost of 1 for each step
    G = ParentG + 1;
    
    // Calculate H (heuristic to goal) using Manhattan distance
    H = math.abs(GoalX - X) + math.abs(GoalY - Y);
    
    // Calculate F = G + H
    F = G + H;
    
    // Check if node is already in open list
    if (in_open_list(X, Y, OldG)) {
        // Node already in open list, update if new path is better
        if (G < OldG) {
            // Better path found, update node
            update_open_list(X, Y, G, H, F, ParentX, ParentY);
        }
    } else {
        // Node not in open list, add it
        ?open_list(OpenList);
        -+open_list([[X, Y, G, H, F, ParentX, ParentY]|OpenList]);
    }
    true.

+!generate_successor(X, Y, ParentX, ParentY, ParentG, GoalX, GoalY) : true <- 
    true. // Skip invalid successors

// Check if node is in closed list
+in_closed_list(X, Y) : closed_list(ClosedList) & .member([X, Y, _, _, _, _, _], ClosedList).

// Check if node is in open list and return G value
+in_open_list(X, Y, G) : open_list(OpenList) & .member([X, Y, G, _, _, _, _], OpenList).

// Update node in open list with better path
+update_open_list(X, Y, G, H, F, ParentX, ParentY) : open_list(OpenList) <-
    .findall([A, B, C, D, E, PX, PY], 
             (.member([A, B, C, D, E, PX, PY], OpenList) & (A \== X | B \== Y)), 
             FilteredList);
    -+open_list([[X, Y, G, H, F, ParentX, ParentY]|FilteredList]).

// Custom function to compare nodes by F value
+f_compare([_, _, _, _, F1, _, _], [_, _, _, _, F2, _, _], R) : F1 < F2 <- R = "<".
+f_compare([_, _, _, _, F1, _, _], [_, _, _, _, F2, _, _], R) : F1 > F2 <- R = ">".
+f_compare([_, _, _, _, F1, _, _], [_, _, _, _, F2, _, _], R) : F1 == F2 <- R = "=".

// Reconstruct path from closed list
+!reconstruct_path(X, Y) : closed_list(ClosedList) <-
    .print("Reconstructing path...");
    
    // Find goal node in closed list
    .member([X, Y, _, _, _, ParentX, ParentY], ClosedList);
    
    // Start with goal position
    ReconstructedPath = [[X, Y]];
    
    // Reconstruct by following parents until we reach start (-1, -1)
    !build_path(ParentX, ParentY, ReconstructedPath, FinalPath);
    
    // Reverse path so it starts from start position
    .reverse(FinalPath, ForwardPath);
    
    .print("Path constructed: ", ForwardPath);
    -+path(ForwardPath).

// Build path recursively by following parent pointers
+!build_path(-1, -1, Path, Path) : true <- 
    .print("Path reconstruction complete").

+!build_path(X, Y, CurrentPath, FinalPath) : closed_list(ClosedList) <-
    // Find parent in closed list
    .member([X, Y, _, _, _, ParentX, ParentY], ClosedList);
    
    // Add current position to path
    .concat(CurrentPath, [[X, Y]], NewPath);
    
    // Continue with parent
    !build_path(ParentX, ParentY, NewPath, FinalPath).

/* Movement and Navigation using A* */
+!navigate_to(X, Y) : my_position(MyX, MyY) <-
    if (MyX == X & MyY == Y) {
        .print("Already at destination (", X, ", ", Y, ")");
    } else {
        .print("Starting navigation to (", X, ", ", Y, ")");
        !calculate_path(MyX, MyY, X, Y);
        !follow_path(X, Y);
    }.

// Follow the calculated path
+!follow_path(TargetX, TargetY) : path([]) <-
    .print("Path is empty, recalculating");
    ?my_position(MyX, MyY);
    !calculate_path(MyX, MyY, TargetX, TargetY).

// Successfully reached target
+!follow_path(TargetX, TargetY) : my_position(TargetX, TargetY) <-
    .print("Reached target position (", TargetX, ", ", TargetY, ")");
    -+path([]). // Clear path

// Follow next step in path
+!follow_path(TargetX, TargetY) : path([[NextX, NextY]|Rest]) & my_position(MyX, MyY) <-
    // Determine direction to move
    if (NextX > MyX) {
        Dir = e;
    } else {
        if (NextX < MyX) {
            Dir = w;
        } else {
            if (NextY > MyY) {
                Dir = n;
            } else {
                Dir = s;
            }
        }
    }
    
    .print("Following path, moving ", Dir, " to (", NextX, ", ", NextY, ")");
    move(Dir);
    
    // Update path to remove the step we just took
    -+path(Rest);
    
    // Continue following path
    !follow_path(TargetX, TargetY).

// Fallback if path following fails
-!follow_path(TargetX, TargetY) : true <-
    .print("Error following path, recalculating");
    -+path([]);  // Clear path
    ?my_position(MyX, MyY);
    !calculate_path(MyX, MyY, TargetX, TargetY).

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
    !navigate_to(X, Y);
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

// Handle obstacle perception
+thing(X, Y, obstacle, _) : true <-
    .print("Detected obstacle at (", X, ", ", Y, ")").

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

-!calculate_path(_, _, _, _) : true <-
    .print("Error in calculate_path, using random movement");
    !move_random.

-!astar_loop(_, _) : true <-
    .print("Error in A* loop, using random movement");
    !move_random.