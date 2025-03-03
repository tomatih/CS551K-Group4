Step 1: Agent Identification and Role Assignment

/*--------------------------------------------------
                  Auction Roles Setup
--------------------------------------------------*/
// Self identification (Set via MAS2J parameters)
self_name(Self) <- .my_name(Self).

// Team knowledge (Same for all agents)
team_member(Agent) <- 
    .my_team(Members) & 
    .member(Agent, Members) & 
    Agent \== Self.

// Dynamic auction role assignment
+task(TaskID, _, _, _) : 
    not auction_in_progress(TaskID) & 
    .my_name(Self)
    <-
    +auctioneer(Self, TaskID);      // First agent to detect becomes auctioneer
    +auction_in_progress(TaskID);
    .print(Self," is auctioneer for ",TaskID);
    !start_auction(TaskID).
Step 2: Auction Initiation Process (Auctioneer)

/*--------------------------------------------------
                  Auctioneer Logic
--------------------------------------------------*/
// Auctioneer: Start bidding process
+!start_auction(TaskID) : 
    auctioneer(Self, TaskID)
    <-
    .print(Self," starting auction for ",TaskID);
    .send(teammate(Bidder), auction_announce(TaskID));
    +bid_collection(TaskID, []);    // Empty bid list
    .wait(2000, check_bids(TaskID)). // Wait 2 seconds for bids

// Auctioneer: Collect bids
+auction_bid(TaskID, Bidder, BidValue)[source(Bidder)] : 
    auctioneer(Self, TaskID) & 
    bid_collection(TaskID, CurrentBids)
    <-
    -bid_collection(TaskID, CurrentBids);
    +bid_collection(TaskID, [bid(Bidder,BidValue)|CurrentBids]).

// Auctioneer: Evaluate bids after timeout
+check_bids(TaskID) : 
    auctioneer(Self, TaskID) & 
    bid_collection(TaskID, AllBids)
    <-
    .min_member(bid(_,MinBid), AllBids); // Find lowest bid
    .findall(Bidder, .member(bid(Bidder,MinBid), AllBids), Winners);
    (Winners = [Winner|_] ->          // Select first winner if tie
        .send(Winner, award_task(TaskID));
        .print(Self," awarded ",TaskID," to ",Winner)
    );
    -auction_in_progress(TaskID);
    -auctioneer(Self, TaskID).
Step 3: Bidder Logic (Participants)

/*--------------------------------------------------
                  Bidder Logic
--------------------------------------------------*/
// Participant: Handle auction announcement
+auction_announce(TaskID)[source(Auctioneer)] : 
    not auctioneer(_, TaskID) & 
    .my_name(Self)
    <-
    .print(Self," participating in auction for ",TaskID);
    !calculate_bid(TaskID, Auctioneer).

// Participant: Dynamic bid calculation
+!calculate_bid(TaskID, Auctioneer) : 
    task(TaskID, _, _, [req(_,_,BlockType)]) &
    dispenser(BlockType, DispenserX, DispenserY) &
    goal(GoalX, GoalY) &
    my_position(CurrentX, CurrentY)
    <-
    // Calculate total path cost
    distance(CurrentX, CurrentY, DispenserX, DispenserY, ToDispenser);
    distance(DispenserX, DispenserY, GoalX, GoalY, ToGoal);
    TotalCost is ToDispenser + ToGoal;
    // Add random variance to prevent ties
    .random(0.0, 0.5, Variance);
    FinalBid is TotalCost * (1.0 + Variance);
    .send(Auctioneer, auction_bid(TaskID, Self, FinalBid));
    .print(Self," bid ",FinalBid," for ",TaskID).

// Participant: Handle task award
+award_task(TaskID)[source(Auctioneer)] : 
    .my_name(Self)
    <-
    .print(Self," won ",TaskID);
    !handle_awarded_task(TaskID).
Step 4: Task Binding and Execution

/*--------------------------------------------------
                  Task Execution Binding
--------------------------------------------------*/
// Winner: Integrate with existing task handling
+!handle_awarded_task(TaskID) : 
    task(TaskID, _, _, [req(_,_,BlockType)]) &
    state_machine(idle)
    <-
    -state_machine(idle);
    +state_machine(toDispenser);
    +current_task(TaskID, BlockType);
    !bindTaskToNavigation(TaskID).  // Use existing navigation

// Existing navigation plans remain unchanged
// ...
Step 5: Cleanup and Conflict Prevention

/*--------------------------------------------------
                  Auction Cleanup
--------------------------------------------------*/
// All agents: Handle auction completion
+auction_complete(TaskID)[source(Auctioneer)] : 
    .my_name(Self) & 
    Self \== Auctioneer
    <-
    -auction_announce(TaskID);
    -auction_bid(TaskID, _, _).

// Auctioneer: Final cleanup
+check_bids(TaskID) : 
    auctioneer(Self, TaskID)
    <-
    .send(teammate(Bidder), auction_complete(TaskID));
    -bid_collection(TaskID, _);
    .print(Self," completed auction for ",TaskID).




Implementation Flow

1. Task Detection

First agent to detect task becomes auctioneer

Others become bidders automatically

2. Bid Calculation

Real-time Manhattan distance calculation

Random variance prevents bidding ties

Considers both dispenser and goal distances

3. Auction Process

sequenceDiagram
    participant Auctioneer
    participant Bidder1
    participant Bidder2
    Auctioneer->>Bidder1: auction_announce(T1)
    Auctioneer->>Bidder2: auction_announce(T1)
    Bidder1->>Auctioneer: auction_bid(T1, 15.2)
    Bidder2->>Auctioneer: auction_bid(T1, 18.7)
    Auctioneer->>Bidder1: award_task(T1)
    Auctioneer->>All: auction_complete(T1)

4. Execution Binding

Winner integrates with existing navigation through !bindTaskToNavigation

Uses original state machine transitions

5. Failure Handling

Timeout-based bid collection (2 seconds)

Automatic cleanup of auction artifacts

Conflict prevention through atomic role assignment


