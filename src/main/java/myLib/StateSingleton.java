package myLib;

import jason.asSemantics.Agent;

import java.util.HashMap;

public class StateSingleton {
    private static StateSingleton instance = null;

    private HashMap<Integer, AgentState> states = new HashMap<>();

    public static StateSingleton getInstance() {
        if (instance == null) {
            instance = new StateSingleton();
        }
        return instance;
    }

    public void register_agent(Integer agent_hash){
        states.put(agent_hash, new AgentState());
    }

    public AgentState get_agent_state(Integer agent_hash){
        return states.get(agent_hash);
    }
}
