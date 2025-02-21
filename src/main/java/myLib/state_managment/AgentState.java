package myLib.state_managment;

import myLib.helpers.Position;

public class AgentState {
    public Position position = new Position(0,0);
    public String agent_name = null;
    public int step = 0;
    public Position chosen_goal = null;
    public Position closest_dispenser_0 = null;
    public Position closest_dispenser_1 = null;
    public StateMachine stateMachine = StateMachine.Lost;
}
