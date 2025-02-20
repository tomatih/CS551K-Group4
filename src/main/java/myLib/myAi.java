package myLib;

import jason.JasonException;
import jason.asSemantics.DefaultInternalAction;
import jason.asSemantics.InternalAction;
import jason.asSemantics.TransitionSystem;
import jason.asSemantics.Unifier;
import jason.asSyntax.*;
import jason.bb.BeliefBase;

@SuppressWarnings("serial")
public class myAi extends DefaultInternalAction {

    private static InternalAction singleton = null;
    public static InternalAction create() {
        if (singleton == null)
            singleton = new myAi();
        return singleton;
    }

    @Override
    public Object execute(TransitionSystem ts, Unifier un, Term[] args) throws Exception {
        System.out.println("JAVA HELLO");
        BeliefBase bb = ts.getAg().getBB();
//        LiteralImpl literal = new LiteralImpl("test_belief");
        PredicateIndicator indicator = new PredicateIndicator("test_belief",1);
        var iter = bb.getCandidateBeliefs(indicator);
        Literal test = iter.next();

        System.out.println("Belief: "+test);d
//        StateSingleton states = StateSingleton.getInstance();
//        states.register_agent(ts.getAg().hashCode());
        return true;
    }

}
