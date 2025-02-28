// Initial Beliefs and Rules for 5 Agents
position(0,0).  
team_member(agent2).  // List all teammates
team_member(agent3).
team_member(agent4).
team_member(agent5).
my_bid(none, 9999).      // (TaskID, BidValue)
received_bid(none, none, 9999).  // (TaskID, AgentID, BidValue)
bid_count(0).            // Track received bids

// Initial Goal
!start.

// Plans
+!start : true <- 
    .print("Agent initialized.");
    !shareLocation;  
    !listenForTasks.

// Share location with all teammates
+!shareLocation : true <- 
    ?position(X, Y);
    .for(team_member(AgentID), 
        .send(AgentID, tell, position(self, X, Y))
    );
    .print("Shared location with team").

// Listen for teammate locations
+position(AgentID, X, Y) : team_member(AgentID) <- 
    .print("Received location from ", AgentID, ": (", X, ",", Y, ")");
    +teammate_position(AgentID, X, Y).

// Auction System for 5 Agents
+!listenForTasks : perceive(task(TaskID, BlockType, Dispenser, GoalX, GoalY)) <- 
    .print("New task detected: ", TaskID);
    !calculateBid(TaskID, Dispenser, GoalX, GoalY);
    !sendBid(TaskID).

// Calculate bid based on Manhattan distance
+!calculateBid(TaskID, DispenserX, DispenserY, GoalX, GoalY) : true <- 
    ?position(CurX, CurY);
    DistanceToDispenser is abs(DispenserX - CurX) + abs(DispenserY - CurY);
    DistanceToGoal is abs(GoalX - CurX) + abs(GoalY - CurY);
    TotalDistance is DistanceToDispenser + DistanceToGoal;
    -my_bid(_, _);
    +my_bid(TaskID, TotalDistance);
    .print("My bid for ", TaskID, ": ", TotalDistance).

// Broadcast bid to all 4 teammates
+!sendBid(TaskID) : my_bid(TaskID, BidValue) <- 
    .for(team_member(AgentID), 
        .send(AgentID, tell, bid(TaskID, BidValue))
    );
    .print("Broadcasted bid for ", TaskID, ": ", BidValue);
    +bid_count(0).  // Reset counter

// Collect bids from teammates
+bid(TaskID, BidValue) : team_member(Sender) & my_bid(TaskID, MyBid) <- 
    .print("Received bid from ", Sender, ": ", BidValue);
    +received_bid(TaskID, Sender, BidValue);
    ?bid_count(Count);
    NewCount is Count + 1;
    -bid_count(Count);
    +bid_count(NewCount);
    (NewCount == 4 ->  // Received all 4 teammate bids
        !determineAuctionWinner(TaskID)
    ).

// Determine winner (agent with lowest bid)
+!determineAuctionWinner(TaskID) : 
    my_bid(TaskID, MyBid),
    .findall(received_bid(TaskID, _, Bid), [Bid1, Bid2, Bid3, Bid4]),
    MinBid is min([MyBid, Bid1, Bid2, Bid3, Bid4]) 
    <- 
    if (MyBid == MinBid) then
        .print("I won task ", TaskID);
        !executeTask(TaskID)
    else
        .print("Task ", TaskID, " assigned to another agent").

// Execute task if won
+!executeTask(TaskID) : true <- 
    .print("Executing task ", TaskID);
    perceive(task(TaskID, BlockType, Dispenser, GoalX, GoalY));
    !navigateTo(DispenserX, DispenserY);  // Go to dispenser
    !requestBlock(BlockType);
    !navigateTo(GoalX, GoalY);           // Go to goal
    submit(TaskID);
    .print("Task ", TaskID, " completed");
    -my_bid(TaskID, _);                  // Cleanup
    -received_bid(TaskID, _, _);
    !listenForTasks.

// Navigation with obstacle avoidance
+!navigateTo(X, Y) : not obstacle(X, Y) <- 
    move(X, Y);
    .print("Moving to (", X, ",", Y, ")").

+!navigateTo(X, Y) : obstacle(X, Y) <- 
    .print("Obstacle at (", X, ",", Y, ")");
    !findAlternativePath(X, Y).

// Obstacle detection and sharing
+perceive(obstacle(X, Y)) : true <- 
    .for(team_member(AgentID), 
        .send(AgentID, tell, obstacle(X, Y))
    );
    +obstacle(X, Y).

// Step handler
+step(_) : true <- 
    ?position(X, Y);
    !updatePosition(X, Y).

+!updatePosition(X, Y) : true <- 
    -position(_, _);
    +position(X, Y);
    !shareLocation.