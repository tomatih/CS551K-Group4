package myLib;

import jason.asSemantics.DefaultInternalAction;
import jason.asSemantics.InternalAction;
import jason.asSemantics.TransitionSystem;
import jason.asSemantics.Unifier;
import jason.asSyntax.*;

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
        var state = StateSingleton.getInstance().get_agent_state(ts.getAg());

        // parse the list of percceptions into a single struct
        var perception = new PerceptionResults();
        for (Iterator<Literal> it = ts.getAg().getBB().getPercepts(); it.hasNext(); ) {
            Literal percept = it.next();
            switch (percept.getFunctor()){
                case "name" ->{
                    if(state.agent_name == null){
                        // extract agent name
                        String agent_name = percept.getTerm(0).toString().substring(1,3);
                        // add it to the belief base
                        LiteralImpl name_literal = new LiteralImpl("agent_name");
                        name_literal.addTerm(new StringTermImpl(agent_name));
                        ts.getAg().getBB().add(name_literal);
                        // register with internal
                        state.agent_name = agent_name;
                        StateSingleton.getInstance().register_agent(agent_name, state);
                    }
                }
                case "task" -> {}
                case "goal" -> {
                    Term pos_x = percept.getTerm(0);
                    Term pos_y = percept.getTerm(1);
                }
                case "obstacle" ->{
                    Term pos_x = percept.getTerm(0);
                    Term pos_y = percept.getTerm(1);
                }
                case "thing" -> {
                    Term pos_x = percept.getTerm(0);
                    Term pos_y = percept.getTerm(1);
                    String type = percept.getTerm(2).toString();
                    if(type.equals("entity")){
                        //TODO: another bot handling
                    } else if (type.equals("dispenser")) {
                        Term block_type = percept.getTerm(3);
                    }
                }
                case "lastActionResult" -> {
                    LiteralImpl success_literal = new LiteralImpl("success");
                    perception.last_action_success = percept.getTerm(0).equals(success_literal);
                }
                case "lastAction" ->{
                    perception.last_action = percept.getTerm(0);
                }
                case "lastActionParams" -> {
                    perception.last_action_arg = ((ListTermImpl)percept.getTerm(0)).get(0); // safe as all have only one parameter
                }
//                case "vision","energy","team","timestamp","disabled","score","step","steps","deadline","simStart","actionID","requestAction"->{}
                default -> {}
            }
        }

        // update internal state based on last action
        if(perception.last_action_success){
            // handle internal map updates
            if(perception.last_action.equals(myLiterals.action_move)){
                if(perception.last_action_arg.equals(myLiterals.direction_n)){
                    state.pos_y += 1;
                } else if (perception.last_action_arg.equals(myLiterals.direction_s)) {
                    state.pos_y -= 1;
                } else if(perception.last_action_arg.equals(myLiterals.direction_w)){
                    state.pos_x -= 1;
                } else if (perception.last_action_arg.equals(myLiterals.direction_e)) {
                    state.pos_x += 1;
                }
                else {
                    System.out.println("PANIC MOVE INTO UNKNOWN DIRECTION");
                }
            }
        }

        return true;
    }
}
