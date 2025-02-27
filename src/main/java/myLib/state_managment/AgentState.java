package myLib.state_managment;

import jason.asSyntax.LiteralImpl;
import myLib.helpers.Position;
import myLib.helpers.Task;

import java.util.HashSet;

public class AgentState {
    // general agent state
    public Position position = new Position(0, 0);
    public String agent_name = null;
    public StateMachine stateMachine = StateMachine.Lost;
    //mapping
    public HashSet<Position> map = new HashSet<>();
    // for tasks
    public int step = 0;
    public Task current_task = null;
    // initialization
    public Position chosen_goal = null;
    public Position closest_dispenser_0 = null;
    public Position closest_dispenser_1 = null;
    // task acceleration
    public Position dispenser_access_position = null;
    public LiteralImpl dispenser_access_direction = null;
}
