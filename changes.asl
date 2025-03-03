visited(0,0,1). // Mark starting position as visited

// Enhanced navigation logic that combines different strategies
navigate(Ox,Oy,Dx,Dy,Dir) :- 

    potential_field_navigate(Ox,Oy,Dx,Dy,Dir) |
    // If potential field fails, fall back to weighted exploration
    explore_navigate(Ox,Oy,Dx,Dy,Dir) |
    // Last resort: simple direct navigation
    simple_navigate(Ox,Oy,Dx,Dy,Dir).

// Simple direct navigation 

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

/* Potential field navigation implementation -*/
potential_field_navigate(X,Y,GoalX,GoalY,Dir) :-
    distance(X,Y,GoalX,GoalY,Dist) & Dist > 0 &
    // Determine primary direction based on distance components
    delta(X,GoalX,Dx) & delta(Y,GoalY,Dy) &
    // Choose direction with bias toward larger distance component
    ((Dx > Dy & X < GoalX & not saved_obstacle(X+1,Y) & Dir = e) |
     (Dx > Dy & X > GoalX & not saved_obstacle(X-1,Y) & Dir = w) |
     (Dx <= Dy & Y < GoalY & not saved_obstacle(X,Y+1) & Dir = s) |
     (Dx <= Dy & Y > GoalY & not saved_obstacle(X,Y-1) & Dir = n)) &
    // Get offset for this direction
    dir_to_offset(Dir,OffX,OffY) &
    // Calculate new position if we move in this direction
    NewX = X + OffX &
    NewY = Y + OffY &
    // Avoid going back to recently visited cells if possible
    (not visited(NewX,NewY,_) | 
     visited(NewX,NewY,Count) & Count < 3).

/* Memory-enhanced exploration navigation */
// Exploration-based navigation using visit counts
explore_navigate(X,Y,GoalX,GoalY,Dir) :-
    // Try directions that haven't been visited or visited less frequently
    ((not saved_obstacle(X+1,Y) & (not visited(X+1,Y,_) | 
        (visited(X+1,Y,CountE) & CountE < 2)) & Dir = e) |
     (not saved_obstacle(X,Y-1) & (not visited(X,Y-1,_) | 
        (visited(X,Y-1,CountN) & CountN < 2)) & Dir = n) |
     (not saved_obstacle(X-1,Y) & (not visited(X-1,Y,_) | 
        (visited(X-1,Y,CountW) & CountW < 2)) & Dir = w) |
     (not saved_obstacle(X,Y+1) & (not visited(X,Y+1,_) | 
        (visited(X,Y+1,CountS) & CountS < 2)) & Dir = s)).


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