/*--------------------------------------------------
                       Rules
--------------------------------------------------*/
// Original navigation rules unchanged
choice_4(DirList,RandomNumber,Dir) :- 
    (RandomNumber <= 0.25 & .nth(0,DirList,Dir)) | 
    (RandomNumber <= 0.5 & .nth(1,DirList,Dir)) | 
    (RandomNumber <= 0.75 & .nth(2,DirList,Dir)) | 
    (.nth(3,DirList,Dir)).

dir_to_offset(Dir,X,Y) :- 
    (Dir=n & X=0 & Y=-1) | 
    (Dir=s & X=0 & Y=1) | 
    (Dir=e & X=1 & Y=0) | 
    (Dir=w & X=-1 & Y=0).

navigate(Ox,Oy,Dx,Dy,Dir) :- 
    ( 
        distance(Ox,Dy,Dx,Dy, Gx) & 
        distance(Dx,Oy,Dx,Dy,Gy) 
    ) &
    (
        ( Gy>Gx & ((Oy<Dy & Dir = s ) | Dir=n )) |
        ( (Ox < Dx & Dir = e) | Dir = w )
    ).

abs(In,Out) :- (In<0 & Out=-In) | Out = In.
delta(A,B,Out) :- Delta = A-B & abs(Delta,Out).
distance(Ax,Ay,Bx,By,Dist) :- delta(Ax,Bx,Dx) & delta(Ay,By,Dy) & Dist = Dx+Dy.
bounce(In,Out) :- (In=0 & Out=1) | ( (In=-1 | In=1) & Out=-1 ).

/*--------------------------------------------------
                  Initial Beliefs
--------------------------------------------------*/
// Added team coordination
self_name(Self) <- .my_name(Self).
team_member(Agent) <- .my_team(Members) & .member(Agent, Members) & Agent \== Self.

// Original beliefs
state_machine(lost).
my_position(0,0).
auctioned_task(none).
current_bid(none, 9999).

/*--------------------------------------------------
                       Core
--------------------------------------------------*/
// Enhanced initialization
+!init : 
    .my_name(Self) &
    .my_team(Members) &
    not initialized
    <- 
    // Set up team relationships
    for (.member(M, Members)) {
        if (M \== Self) {
            +teammate(M)
        }
    };
    +initialized;
    // Original exploration setup
    .random(RandomNumber);
    choice_4([a(1,1),a(1,-1),a(-1,1),a(-1,-1)],RandomNumber,a(Dx,Dy));
    B=500;
    Gx=B*Dx;
    Gy=B*Dy; 
    +nav_goal(Gx,Gy); 
    .print(Self," initialized").

// Auction-enhanced task handling
+task(TaskID, Deadline, Reward, Requirements) : 
    not auctioned_task(TaskID) &
    .my_name(Self)
    <-
    +auctioned_task(TaskID);
    .print(Self," detected new task ",TaskID);
    !calculateBid(TaskID);
    .send(teammate(T), auction_start(TaskID, Self)).

+!calculateBid(TaskID) : 
    task(TaskID, _, _, [req(_,_,BlockType)]) &
    dispenser(BlockType, Dx, Dy) &
    my_position(Mx, My)
    <-
    distance(Mx, My, Dx, Dy, Dist);
    -current_bid(TaskID, _);
    +current_bid(TaskID, Dist);
    .send(teammate(T), auction_bid(TaskID, Self, Dist)).

// Bid processing
+auction_start(TaskID, Initiator)[source(_)] : 
    .my_name(Self) & 
    Self \== Initiator &
    not current_bid(TaskID, _)
    <-
    !calculateBid(TaskID).

+auction_bid(TaskID, Bidder, BidValue)[source(_)] : 
    current_bid(TaskID, MyBid) &
    .my_name(Self)
    <-
    (BidValue < MyBid | (BidValue == MyBid & Bidder < Self)) ->
        -current_bid(TaskID, _);
        +current_bid(TaskID, BidValue);
        .print(Self," updated bid for ",TaskID," to ",BidValue).

// Auction resolution integrated with state machine
+!updateStateMachine : 
    state_machine(idle) & 
    current_bid(TaskID, WinningBid) &
    auction_bid(TaskID, Self, WinningBid) &
    .my_name(Self)
    <-
    .print(Self," won task ",TaskID);
    -current_bid(TaskID, _);
    -auctioned_task(TaskID);
    +current_task(TaskID, BlockType);
    -state_machine(idle);
    +state_machine(toDispenser);
    !bindTaskToNavigation(TaskID).

/*--------------------------------------------------
        Original Core Logic (Preserved Exactly)
--------------------------------------------------*/
// Keep all existing plans below unchanged
@step[atomic]
+step(S) <-
    !updateBeliefs;
    !updateStateMachine;
    !decideAction.

// Original belief update plans
+!updateBeliefs <-
    !update_position;
    !update_obstacles;
    !get_goal;
    !get_dispenser(b0);
    !get_dispenser(b1);
    !fix_task.

// Original position update logic
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

// Original state machine transitions
+!updateStateMachine : 
    state_machine(lost) & 
    chosen_goal(_,_) & 
    dispenser(b0, _,_) & 
    dispenser(b1,_,_) 
    <-
    -state_machine(lost);
    +state_machine(idle);
    .print("Fully initialized").

// Original action selection
+!decideAction : 
    (
        state_machine(lost) | 
        state_machine(toDispenser) | 
        state_machine(toGoal)
    ) &
    nav_goal(Dx,Dy) & 
    my_position(Mx,My) & 
    navigate(Mx,My,Dx,Dy,Dir) 
    <-
    move(Dir).

// Remainder of original code unchanged...