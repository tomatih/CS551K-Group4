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
    !move_right.

+step(X) : true <-
    .print("Received step percept.");
    !move_right.

+!move_right : true <-
    .print("Attempting to move right.");
    move(e);
    !check_block.

+!check_block : true <-
    .wait(2);
    ?free_directions(Dirs);
    ( .member(e, Dirs) -> 
        .print("Path is clear, moving right again");
        !move_right
    ;
        .print("Right blocked, moving left 1 step and stopping.");
        move(w)
    ).

// Perceiving free directions from the environment
+free_directions(Dirs) : true <-
    .print("Checking available movement directions.").