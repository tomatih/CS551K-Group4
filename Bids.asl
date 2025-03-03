/*--------------------------------------------------
               Initial Permanent Auctioneer Setup
--------------------------------------------------*/
// Self and team setup (in initial beliefs)
self_name(Self) <- .my_name(Self).
team_members(Members) <- .my_team(Members).

// Permanent auctioneer selection at initialization
+!select_auctioneer : 
    .my_name(Self) &
    .sort(Members, [Auctioneer|_]) &  // Alphabetical first agent
    Self == Auctioneer 
    <-
    +auctioneer(Self);
    .print("I am permanent auctioneer: ", Self).

+!select_auctioneer : true <- true. // For non-auctioneers

/*--------------------------------------------------
                First 2 Bids Communication Flow
--------------------------------------------------*/
// Auctioneer: Task detection and bid request
+task(TaskID, _, _, _) : 
    auctioneer(Self) & 
    not current_auction(_)
    <-
    +current_auction(TaskID);
    .print("Announcing auction for ", TaskID);
    // Send CFP to first 2 team members
    .send(teammates[0], achieve, submit_bid(TaskID), [protocol(auction), performative(cfp)]);
    .send(teammates[1], achieve, submit_bid(TaskID), [protocol(auction), performative(cfp)]).

// Bidder 1: Bid calculation and response
+submit_bid(TaskID)[source(Auctioneer), protocol(auction), performative(cfp)] : 
    .my_name(Self) &
    not auctioneer(Self) &
    task(TaskID, _, _, [req(_,_,BlockType)])
    <-
    ?dispenser(BlockType, Dx, Dy);
    ?my_position(Mx, My);
    distance(Mx, My, Dx, Dy, Dist);
    .send(Auctioneer, tell, bid(TaskID, Self, Dist), [protocol(auction), performative(propose)]).

// Bidder 2: Same bid logic
+submit_bid(TaskID)[source(Auctioneer), protocol(auction), performative(cfp)] : 
    .my_name(Self) &
    not auctioneer(Self) &
    task(TaskID, _, _, [req(_,_,BlockType)])
    <-
    ?dispenser(BlockType, Dx, Dy);
    ?my_position(Mx, My);
    distance(Mx, My, Dx, Dy, Dist);
    .send(Auctioneer, tell, bid(TaskID, Self, Dist), [protocol(auction), performative(propose)]).

/*--------------------------------------------------
              Auctioneer Decision Logic
--------------------------------------------------*/
// Receive first bid
+bid(TaskID, Bidder1, Bid1)[source(Bidder1), protocol(auction)] : 
    auctioneer(Self) &
    current_auction(TaskID)
    <-
    +bid1(TaskID, Bidder1, Bid1).

// Receive second bid
+bid(TaskID, Bidder2, Bid2)[source(Bidder2), protocol(auction)] : 
    auctioneer(Self) &
    current_auction(TaskID) &
    bid1(TaskID, Bidder1, Bid1)
    <-
    (Bid1 < Bid2 -> 
        Winner = Bidder1 |
        Winner = Bidder2
    );
    .send(Winner, achieve, execute_task(TaskID), [protocol(auction), performative(accept-proposal)]);
    .print("Awarded ", TaskID," to ", Winner);
    -current_auction(TaskID);
    -bid1(TaskID, _, _).


/* Implementation Flow:

Initialization (One-time):


sequenceDiagram
    participant Agent1
    participant Agent2
    participant Agent3
    Note over Agent1: !select_auctioneer
    Agent1->>Agent1: +auctioneer(agent1)
    Agent2->>Agent2: !select_auctioneer (no-op)
    Agent3->>Agent3: !select_auctioneer (no-op)
Bidding Process:


sequenceDiagram
    participant Auctioneer
    participant Bidder1
    participant Bidder2
    
    Auctioneer->>Bidder1: achieve(submit_bid(T1)) [cfp]
    Auctioneer->>Bidder2: achieve(submit_bid(T1)) [cfp]
    
    Bidder1->>Auctioneer: tell(bid(T1,150)) [propose]
    Bidder2->>Auctioneer: tell(bid(T1,200)) [propose]
    
    Auctioneer->>Bidder1: achieve(execute_task(T1)) [accept-proposal]


Key Message Types (FIPA Compliant):

cfp: Call for Proposal

propose: Bid submission

accept-proposal: Task award

Distance Calculation (Using existing rules):

distance(Ax,Ay,Bx,By,Dist) :- 
    delta(Ax,Bx,Dx) & 
    delta(Ay,By,Dy) & 
    Dist = Dx+Dy.
*/