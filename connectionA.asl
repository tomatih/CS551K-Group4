/* Initial beliefs and rules */
random_dir(DirList,RandomNumber,Dir) :- 
    (RandomNumber <= 0.25 & .nth(0,DirList,Dir)) | 
    (RandomNumber <= 0.5 & .nth(1,DirList,Dir)) | 
    (RandomNumber <= 0.75 & .nth(2,DirList,Dir)) | 
    (.nth(3,DirList,Dir)).

/* Initial goals */

!start.

/* Plans */

+!start : true <- 
    .print("hello massim world.");
    !initialize.

+!initialize : true <-
    .print("Initializing agent.");
    ?my_name(Name);
    .print("My name is: ", Name);
    !move_sequence.

+step(X) : true <-
    .print("Received step percept.");
    !move_sequence.

+!move_sequence : true <-
    !move_n(e, 5);
    !move_n(s, 5);
    !move_n(w, 10);
    !move_n(n, 10);
    !move_n(e, 10).

+!move_n(Dir, 0) : true <- .print("Finished moving in direction: ", Dir).
+!move_n(Dir, N) : (N > 0) <-
    .print("Moving ", Dir, " - Remaining: ", N);
    move(Dir);
    N1 = N - 1;
    !move_n(Dir, N1).

// Perceiving free directions from the environment
+free_directions(Dirs) : true <-
    .print("Checking available movement directions.").
