package myLib.actions;

import jason.JasonException;
import jason.asSemantics.DefaultInternalAction;
import jason.asSemantics.InternalAction;
import jason.asSemantics.TransitionSystem;
import jason.asSemantics.Unifier;
import jason.asSyntax.*;
import jason.bb.BeliefBase;
import myLib.helpers.PerceptionResults;
import myLib.helpers.Position;
import myLib.helpers.Task;
import myLib.helpers.myLiterals;
import myLib.state_managment.AgentState;
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

        // parse the list of perceptions into a single struct
        var state = StateSingleton.getInstance().get_agent_state(ts.getAg());
        PerceptionResults perception = parse_percepts(ts.getAg().getBB(), state);

        // update internal state based on last action
        if (perception.last_action_success) {
            // handle internal map updates
            if (perception.last_action.equals(myLiterals.action_move)) {
                Position move_dir = Position.from_direction(perception.last_action_arg);
                if (move_dir == null) {
                    System.out.println("PANIC MOVE INTO UNKNOWN DIRECTION");
                    return false;
                }
                state.position.add(move_dir);
            } else if (perception.last_action.equals(myLiterals.action_rotate)) {
                if (state.dispenser_access_direction.equals(myLiterals.direction_n)) {
                    state.dispenser_access_direction = myLiterals.direction_e;
                } else if (state.dispenser_access_direction.equals(myLiterals.direction_e) || state.dispenser_access_direction.equals(myLiterals.direction_w)) {
                    state.dispenser_access_direction = myLiterals.direction_s;
                }
            }
        }

        // add observed things to memory
        if (state.chosen_goal == null && !perception.goals.isEmpty()) {
            Position goal_position = perception.goals.get(0);
            goal_position.add(state.position);
            state.chosen_goal = goal_position;
        }
        //TODO: remember dispensers found before the goal
        if (state.chosen_goal != null) {
            for (Position pos : perception.dispensers_0) {
                pos.add(state.position);
                if (state.closest_dispenser_0 == null) {
                    state.closest_dispenser_0 = pos;
                } else {
                    int current_distance = state.chosen_goal.distance(state.closest_dispenser_0);
                    int new_distance = pos.distance(state.chosen_goal);
                    if (new_distance < current_distance) {
                        state.closest_dispenser_0 = pos;
                    }
                }
            }

            for (Position pos : perception.dispensers_1) {
                pos.add(state.position);
                if (state.closest_dispenser_1 == null) {
                    state.closest_dispenser_1 = pos;
                } else {
                    int current_distance = state.chosen_goal.distance(state.closest_dispenser_1);
                    int new_distance = pos.distance(state.chosen_goal);
                    if (new_distance < current_distance) {
                        state.closest_dispenser_1 = pos;
                    }
                }
            }
        }

        // update state
        update_state(perception, state);

        return true;
    }

    PerceptionResults parse_percepts(BeliefBase beliefBase, AgentState state) throws JasonException {
        var perception = new PerceptionResults();
        for (Iterator<Literal> it = beliefBase.getPercepts(); it.hasNext(); ) {
            Literal percept = it.next();
            switch (percept.getFunctor()) {
                case "name" -> {
                    if (state.agent_name == null) {
                        // extract agent name
                        String agent_name = ((StringTermImpl) percept.getTerm(0)).getString();
                        // add it to the belief base
                        LiteralImpl name_literal = new LiteralImpl("agent_name");
                        name_literal.addTerm(new StringTermImpl(agent_name));
                        beliefBase.add(name_literal);
                        // register with internal
                        state.agent_name = agent_name;
                        StateSingleton.getInstance().register_agent(agent_name, state);
                    }
                }
                case "task" -> {
                    int deadline = (int) ((NumberTermImpl) percept.getTerm(1)).solve();
                    int value = (int) ((NumberTermImpl) percept.getTerm(2)).solve();
                    // filter out dead and 2 block tasks
                    if (value != 10 || deadline < state.step) {
                        continue;
                    }
                    String task_id = ((Atom) percept.getTerm(0)).getFunctor();
                    var block_definition = (Structure) ((ListTermImpl) percept.getTerm(3)).get(0);
                    boolean is_type_0 = block_definition.getTerm(2).equals(myLiterals.block_type_0);
                    var offset = Position.from_terms(block_definition.getTerm(0), block_definition.getTerm(1));
                    Task task = new Task(task_id, offset, is_type_0);
                    perception.available_tasks.add(task);
                }
                case "goal" -> {
                    // package them
                    var goal_position = Position.from_terms(percept.getTerm(0), percept.getTerm(1));
                    perception.goals.add(goal_position);
                }
                case "obstacle" -> {
                    //TODO: handle obstacles
                }
                case "thing" -> {
                    // get local coordinates
                    var entity_position = Position.from_terms(percept.getTerm(0), percept.getTerm(1));
                    String type = percept.getTerm(2).toString();
                    if (type.equals("entity")) {
                        //TODO: another bot handling
                    } else if (type.equals("dispenser")) {
                        Term block_type_l = percept.getTerm(3);
                        if (block_type_l.equals(myLiterals.dispenser_type_0)) {
                            perception.dispensers_0.add(entity_position);
                        } else if (block_type_l.equals(myLiterals.dispenser_type_1)) {
                            perception.dispensers_1.add(entity_position);
                        } else {
                            System.out.println("PANIC UNKNOWN DISPENSER TYPE");
                        }
                    } else if (type.equals("block")) {
                        perception.attached_block_position = entity_position;
                    }
                }
                case "lastActionResult" -> {
                    LiteralImpl success_literal = new LiteralImpl("success");
                    perception.last_action_success = percept.getTerm(0).equals(success_literal);
                }
                case "lastAction" -> {
                    perception.last_action = percept.getTerm(0);
                }
                case "lastActionParams" -> {
                    perception.last_action_arg = ((ListTermImpl) percept.getTerm(0)).get(0); // safe as all have only one parameter
                }
                case "step" -> {
                    var current_step = (int) ((NumberTermImpl) percept.getTerm(0)).solve();
                    if (current_step == state.step) {
                        System.out.println("A SINGLE STEP GENERATED MULTIPLE PERCEPTS");
                    }
                    state.step = current_step;
                }
//                case "vision","energy","team","timestamp","disabled","score","steps","deadline","simStart","actionID","requestAction"->{}
                default -> {
                }
            }
        }
        return perception;
    }

    void update_state(PerceptionResults perception, AgentState state) {
        switch (state.stateMachine) {
            case Lost -> {
                // become idle if fully initialized
                if (state.chosen_goal != null && state.closest_dispenser_0 != null && state.closest_dispenser_1 != null) {
                    state.stateMachine = StateMachine.Idle;
                    System.out.println("Bot " + state.agent_name + " fully initialized");
                }
            }
            case Idle -> {
                //TODO: task selection logic
                state.current_task = perception.available_tasks.get(0);

                // get base dispenser position
                if (state.current_task.is_type_0) {
                    state.dispenser_access_position = state.closest_dispenser_0.clone();
                } else {
                    state.dispenser_access_position = state.closest_dispenser_1.clone();
                }

                // offset as need to be next to dispenser not on top of it
                if (state.position.y != state.dispenser_access_position.y) {
                    if (state.position.x > state.dispenser_access_position.x) {
                        state.dispenser_access_position.add(1, 0);
                        state.dispenser_access_direction = myLiterals.direction_w;
                    } else {
                        state.dispenser_access_position.add(-1, 0);
                        state.dispenser_access_direction = myLiterals.direction_e;
                    }
                } else if (state.position.x > state.dispenser_access_position.x) {
                    state.dispenser_access_position.add(0, 1);
                    state.dispenser_access_direction = myLiterals.direction_n;
                } else {
                    state.dispenser_access_position.add(0, -1);
                    state.dispenser_access_direction = myLiterals.direction_s;
                }

                state.stateMachine = StateMachine.Going_to_dispenser;
                System.out.println("Bot " + state.agent_name + " picked task " + state.current_task.id);
            }
            case Going_to_dispenser -> {
                if (state.current_task.is_type_0 && state.position.distance(state.closest_dispenser_0) == 1) {
                    state.stateMachine = StateMachine.At_dispenser;
                    System.out.println("Bot " + state.agent_name + " at dispenser");
                }
                if (!state.current_task.is_type_0 && state.position.distance(state.closest_dispenser_1) == 1) {
                    state.stateMachine = StateMachine.At_dispenser;
                    System.out.println("Bot " + state.agent_name + " at dispenser");
                }

            }
            case At_dispenser -> {
                if (perception.last_action_success && perception.last_action.equals(myLiterals.action_request)) {
                    state.stateMachine = StateMachine.About_to_attach;
                    System.out.println("Bot " + state.agent_name + " got block");
                }
            }
            case About_to_attach -> {
                if (perception.last_action_success && perception.last_action.equals(myLiterals.action_attach)) {
                    state.stateMachine = StateMachine.Going_to_goal;
                    System.out.println("Bot " + state.agent_name + " attached to block");
                }
            }
            case Going_to_goal -> {
                if (state.position.equals(state.chosen_goal)) {
                    System.out.println("Bot " + state.agent_name + " at goal");
                    if(state.dispenser_access_direction.equals(myLiterals.direction_s)){
                        state.stateMachine = StateMachine.Submit;
                    }
                    else{
                        state.stateMachine = StateMachine.Rotating;
                    }
                }
            }
            case Rotating -> {
                if (perception.attached_block_position.x == 0 && perception.attached_block_position.y == 1) {
                    System.out.println("Bot " + state.agent_name + " fully rotated");
                    state.stateMachine = StateMachine.Submit;
                }
            }
            case Submit -> {
                if (perception.last_action_success && perception.last_action.equals(myLiterals.action_submit)) {
                    System.out.println("Bot " + state.agent_name + "submitted task");
                    state.stateMachine = StateMachine.Idle;
                }
            }
        }
    }
}
