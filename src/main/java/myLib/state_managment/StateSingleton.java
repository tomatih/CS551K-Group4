package myLib.state_managment;

import jason.asSemantics.Agent;
import jason.asSyntax.PredicateIndicator;
import jason.asSyntax.StringTermImpl;

import java.util.HashMap;

public class StateSingleton {
    private static StateSingleton instance = null;

    private HashMap<String, AgentState> states = new HashMap<>();

    public static StateSingleton getInstance() {
        if (instance == null) {
            instance = new StateSingleton();
        }
        return instance;
    }

    public void register_agent(String agent_name, AgentState state) {
        states.put(agent_name, state);
    }

    public AgentState get_agent_state(Agent agent) {
        var name_candidates = agent.getBB().getCandidateBeliefs(new PredicateIndicator("agent_name", 1));
        if (name_candidates == null || !name_candidates.hasNext()) {
            return new AgentState();
        }

        var name = ((StringTermImpl) name_candidates.next().getTerm(0)).getString();
        return states.get(name);
    }
}
