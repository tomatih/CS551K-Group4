package myLib.actions;

import jason.asSemantics.DefaultInternalAction;
import jason.asSemantics.InternalAction;
import jason.asSemantics.TransitionSystem;
import jason.asSemantics.Unifier;
import jason.asSyntax.*;
import myLib.helpers.PerceptionResults;
import myLib.helpers.Position;
import myLib.helpers.myLiterals;
import myLib.state_managment.StateMachine;
import myLib.state_managment.StateSingleton;

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
                        String agent_name = ((StringTermImpl)percept.getTerm(0)).getString();
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
                    // get local coordinates
                    var pos_x = ((NumberTermImpl)percept.getTerm(0)).solve();
                    var pos_y = ((NumberTermImpl)percept.getTerm(1)).solve();
                    // package them
                    var goal_position = new Position((int) pos_x, (int) pos_y);
                    perception.goals.add(goal_position);
                }
                case "obstacle" ->{
                    Term pos_x = percept.getTerm(0);
                    Term pos_y = percept.getTerm(1);
                    //TODO: handle obstacles
                }
                case "thing" -> {
                    // get local coordinates
                    var pos_x = ((NumberTermImpl)percept.getTerm(0)).solve();
                    var pos_y = ((NumberTermImpl)percept.getTerm(1)).solve();
                    var entity_position = new Position((int) pos_x, (int) pos_y);
                    String type = percept.getTerm(2).toString();
                    if(type.equals("entity")){
                        //TODO: another bot handling
                    } else if (type.equals("dispenser")) {
                        Term block_type_l = percept.getTerm(3);
                        if(block_type_l.equals(myLiterals.dispenser_type_0)){
                            perception.dispensers_0.add(entity_position);
                        } else if (block_type_l.equals(myLiterals.dispenser_type_1)) {
                            perception.dispensers_1.add(entity_position);
                        }
                        else {
                            System.out.println("PANIC UNKNOWN DISPENSER TYPE");
                        }
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
                    state.position.y += 1;
                } else if (perception.last_action_arg.equals(myLiterals.direction_s)) {
                    state.position.y -= 1;
                } else if(perception.last_action_arg.equals(myLiterals.direction_w)){
                    state.position.x -= 1;
                } else if (perception.last_action_arg.equals(myLiterals.direction_e)) {
                    state.position.x += 1;
                }
                else {
                    System.out.println("PANIC MOVE INTO UNKNOWN DIRECTION");
                }
            }
        }

        // add observed things to memory
        if(state.chosen_goal == null && !perception.goals.isEmpty()){
            Position goal_position = perception.goals.get(0);
            goal_position.add(state.position);
            state.chosen_goal = goal_position;
        }

        //TODO: remember dispensers found before the goal
        if(state.chosen_goal != null){
            for(Position pos : perception.dispensers_0){
                pos.add(state.position);
                if (state.closest_dispenser_0 == null){
                    state.closest_dispenser_0 = pos;
                }
                else {
                    int current_distance = state.chosen_goal.distance(state.closest_dispenser_0);
                    int new_distance = pos.distance(state.chosen_goal);
                    if(new_distance < current_distance){
                        state.closest_dispenser_0 = pos;
                    }
                }
            }

            for(Position pos : perception.dispensers_1){
                pos.add(state.position);
                if (state.closest_dispenser_1 == null){
                    state.closest_dispenser_1 = pos;
                }
                else {
                    int current_distance = state.chosen_goal.distance(state.closest_dispenser_1);
                    int new_distance = pos.distance(state.chosen_goal);
                    if(new_distance < current_distance){
                        state.closest_dispenser_1 = pos;
                    }
                }
            }
        }

        // update state
        switch (state.stateMachine){
            case Lost -> {
                if(state.chosen_goal != null && state.closest_dispenser_0 != null && state.closest_dispenser_1 != null){
                    state.stateMachine = StateMachine.Idle;
                    System.out.println("Bot fully initialized: "+state.agent_name);
                }
            }
            case Idle -> {
            }
            case Going_to_dispenser -> {
            }
            case At_dispenser -> {
            }
            case About_to_attach -> {
            }
            case Going_to_goal -> {
            }
            case Rotating -> {
            }
            case Submit -> {
            }
        }


        return true;
    }
}
