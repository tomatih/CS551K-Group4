/* Initial beliefs and rules */
random_dir(DirList,RandomNumber,Dir) :- 
(RandomNumber <= 0.25 & .nth(0,DirList,Dir)) | 
(RandomNumber <= 0.5 & .nth(1,DirList,Dir)) | 
(RandomNumber <= 0.75 & .nth(2,DirList,Dir)) | 
(.nth(3,DirList,Dir)).

position(self, X, Y).  /* Current position */
percept_range(R).  /* Field of view range */
visited(X, Y).  /* Track visited positions */
boundary(X, Y).  /* Points marking the boundary of the previous percept */

/* Initial goal */
!start.

/* Plan: Start the exploration */
+!start : true <- 
    .print("Starting percept-expanding movement");
    !find_boundary.

/* Plan: Identify boundary positions */
+!find_boundary : percept_range(R) & position(self, X, Y) <- 
    Xmax = X + R;
    Xmin = X - R;
    Ymax = Y + R;
    Ymin = Y - R;
    -visited(Xmin, Y); -visited(Xmax, Y); -visited(X, Ymin); -visited(X, Ymax);
    +boundary(Xmin, Y); +boundary(Xmax, Y); +boundary(X, Ymin); +boundary(X, Ymax);
    !move_to_boundary.

/* Plan: Move to a boundary point */
+!move_to_boundary : boundary(Xb, Yb) & position(self, X, Y) & not visited(Xb, Yb) <- 
    .print("Moving to boundary at ", Xb, ", ", Yb);
    move_towards(Xb, Yb);
    +visited(Xb, Yb);
    !follow_boundary.

/* Plan: Follow the previously seen boundary */
+!follow_boundary : boundary(Xb, Yb) & position(self, X, Y) <- 
    .print("Following the edge of previous percept");
    (Xb > X -> move(e);
    Xb < X -> move(w);
    Yb > Y -> move(n);
    move(s)).