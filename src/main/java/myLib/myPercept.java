package myLib;

import jason.asSemantics.DefaultInternalAction;
import jason.asSemantics.InternalAction;
import jason.asSemantics.TransitionSystem;
import jason.asSemantics.Unifier;
import jason.asSyntax.Literal;
import jason.asSyntax.LiteralImpl;
import jason.asSyntax.StringTermImpl;
import jason.asSyntax.Term;
import jason.bb.BeliefBase;

import java.util.Iterator;

public class myPercept extends DefaultInternalAction {
    private static InternalAction singleton = null;
    public static InternalAction create() {
        if (singleton == null)
            singleton = new myPercept();
        return singleton;
    }

    @Override
    public Object execute(TransitionSystem ts, Unifier un, Term[] args) throws Exception {
        AgentState state = StateSingleton.getInstance().get_agent_state(ts.getAg());
        System.out.println(state.pos_x+" "+state.pos_y);
        for (Iterator<Literal> it = ts.getAg().getBB().getPercepts(); it.hasNext(); ) {
            Literal l = it.next();
            String functor = l.getFunctor();
            switch (functor){
                case "task" -> {}
                case "goal" -> {
                    Term pos_x = l.getTerm(0);
                    Term pos_y = l.getTerm(1);
                }
                case "obstacle" ->{
                    Term pos_x = l.getTerm(0);
                    Term pos_y = l.getTerm(1);
                }
                case "thing" -> {
                    Term pos_x = l.getTerm(0);
                    Term pos_y = l.getTerm(1);
                    String type = l.getTerm(2).toString();
                    if(type.equals("entity")){
                        //TODO: another bot handling
                    } else if (type.equals("dispenser")) {
                        Term block_type = l.getTerm(3);
                    }
                }
                case "lastActionResult" -> {}
//                case "vision","energy","team","timestamp","disabled","score","name","step","steps","deadline","simStart","actionID","lastAction","lastActionParams","requestAction"->{}
                default -> {}
            }
        }
        return true;
    }
}
