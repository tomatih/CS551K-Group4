package myLib.actions;

import jason.JasonException;
import jason.asSemantics.DefaultInternalAction;
import jason.asSemantics.InternalAction;
import jason.asSemantics.TransitionSystem;
import jason.asSemantics.Unifier;
import jason.asSyntax.LiteralImpl;
import jason.asSyntax.StringTermImpl;
import jason.asSyntax.Term;
import myLib.helpers.Position;
import myLib.helpers.myLiterals;
import myLib.state_managment.StateSingleton;

import java.util.Random;

public class myAction extends DefaultInternalAction {
    private static InternalAction singleton = null;

    public static InternalAction create() {
        if (singleton == null)
            singleton = new myAction();
        return singleton;
    }

    private final Random rand = new Random();

    @Override
    public Object execute(TransitionSystem ts, Unifier un, Term[] args) throws Exception {
        // sanitize argument
        if (args.length != 1) {
            throw new JasonException("Need exactly one argument");
        }
        if (!args[0].isVar()) {
            throw new JasonException("Variable argument mustn't be a variable");
        }

        var state = StateSingleton.getInstance().get_agent_state(ts.getAg());
        // should never trigger but better be safe
        if (state.agent_name == null) {
            return true;
        }

        switch (state.stateMachine) {
            case Lost -> {
                // move randomly to explore
                LiteralImpl base_literal = (LiteralImpl) myLiterals.choice_move.copy();
                LiteralImpl direction = null;
                switch (rand.nextInt(4)) {
                    case 0 -> {
                        direction = myLiterals.direction_n;
                    }
                    case 1 -> {
                        direction = myLiterals.direction_s;
                    }
                    case 2 -> {
                        direction = myLiterals.direction_w;
                    }
                    case 3 -> {
                        direction = myLiterals.direction_e;
                    }
                }
                base_literal.addTerm(direction);
                return un.unifies(args[0], base_literal);
            }
            case Idle -> {
                return un.unifies(args[0], myLiterals.choice_skip);
            }
            case Going_to_dispenser -> {
                // first align vertical
                LiteralImpl direction = null;
                if(state.position.y != state.moveGoal.y ){
                    if(state.moveGoal.y > state.position.y){
                        direction = myLiterals.direction_s;
                    }
                    else {
                        direction = myLiterals.direction_n;
                    }
                }
                // then align horizontal
                else if(state.position.x != state.moveGoal.x) {
                    if(state.moveGoal.x > state.position.x){
                        direction = myLiterals.direction_e;
                    }
                    else {
                        direction = myLiterals.direction_w;
                    }
                }
                // onm top but for some reason sensing hasn't activated yet
                else {
                    return un.unifies(args[0], myLiterals.choice_skip);
                }
                LiteralImpl base_literal = (LiteralImpl) myLiterals.choice_move.copy();
                base_literal.addTerm(direction);
                return un.unifies(args[0], base_literal);
            }
            case At_dispenser -> {
                LiteralImpl base_literal = (LiteralImpl) myLiterals.choice_request.copy();
                LiteralImpl direction = null;
                Position dispenser = null;
                if(state.current_task.is_type_0){
                    dispenser = state.closest_dispenser_0;
                }
                else {
                    dispenser = state.closest_dispenser_1;
                }
                if(dispenser.y > state.position.y){
                    direction = myLiterals.direction_s;
                }
                else if(dispenser.y < state.position.y){
                    direction = myLiterals.direction_n;
                }
                else if(dispenser.x > state.position.x){
                    direction = myLiterals.direction_e;
                } else if (dispenser.x < state.position.x) {
                    direction = myLiterals.direction_w;
                }
                else {
                    System.out.println("PANIC TOO CLOSE TO A DISPENSER");
                    return false;
                }
                base_literal.addTerm(direction);
                return un.unifies(args[0], base_literal);
            }
            case About_to_attach -> {
                LiteralImpl base_literal = (LiteralImpl) myLiterals.choice_attach.copy();
                LiteralImpl direction = null;
                Position dispenser = null;
                if(state.current_task.is_type_0){
                    dispenser = state.closest_dispenser_0;
                }
                else {
                    dispenser = state.closest_dispenser_1;
                }
                if(dispenser.y > state.position.y){
                    direction = myLiterals.direction_s;
                }
                else if(dispenser.y < state.position.y){
                    direction = myLiterals.direction_n;
                }
                else if(dispenser.x > state.position.x){
                    direction = myLiterals.direction_e;
                } else if (dispenser.x < state.position.x) {
                    direction = myLiterals.direction_w;
                }
                else {
                    System.out.println("PANIC ON TOP OF DISPENSER");
                    return false;
                }
                base_literal.addTerm(direction);
                return un.unifies(args[0], base_literal);
            }
            case Going_to_goal -> {
                Position goal = state.chosen_goal;

                // first align vertical
                LiteralImpl direction = null;
                if(state.position.y != goal.y ){
                    if(goal.y > state.position.y){
                        direction = myLiterals.direction_s;
                    }
                    else {
                        direction = myLiterals.direction_n;
                    }
                }
                else if(state.position.x != goal.x) {
                    if(goal.x > state.position.x){
                        direction = myLiterals.direction_e;
                    }
                    else {
                        direction = myLiterals.direction_w;
                    }
                }
                else {
                    return un.unifies(args[0], myLiterals.choice_skip);
                }
                LiteralImpl base_literal = (LiteralImpl) myLiterals.choice_move.copy();
                base_literal.addTerm(direction);
                return un.unifies(args[0], base_literal);
            }
            case Rotating -> {
            }
            case Submit -> {
                LiteralImpl base_literal = (LiteralImpl) myLiterals.choice_submit.copy();
                base_literal.addTerm(new StringTermImpl(state.current_task.id));
                System.out.println("Bot "+state.agent_name+" attempting to submit "+state.current_task.id);
                return un.unifies(args[0], base_literal);
            }
        }

        return true;
    }
}
