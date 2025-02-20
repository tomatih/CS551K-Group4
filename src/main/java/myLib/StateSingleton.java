package myLib;

import jason.asSemantics.Agent;

import java.util.HashMap;

public class StateSingleton {
    private static StateSingleton instance = null;

    private HashMap<Agent, AgentState> states = new HashMap<>();

    public static StateSingleton getInstance() {
        if (instance == null) {
            instance = new StateSingleton();
        }
        return instance;
    }

    public void register_agent(Agent agent){
        states.put(agent, new AgentState());
        System.out.println("registered "+agent.hashCode());
    }

    public AgentState get_agent_state(Agent agent){
        return states.get(agent);
    }
}
