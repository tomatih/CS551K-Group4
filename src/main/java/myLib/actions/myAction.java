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

import java.util.HashSet;
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

        //TODO: navigation sometimes is off by 1 especially on diagonal corners
        //TODO: remove all panics
        switch (state.stateMachine) {
            case Lost -> {
                return un.unifies(args[0], get_explore_direction());
            }
            case Idle -> {
                return un.unifies(args[0], myLiterals.choice_skip);
            }
            case Going_to_dispenser -> {
                return un.unifies(args[0], get_move_direction(state.position, state.dispenser_access_position, state.map));
            }
            case At_dispenser -> {
                LiteralImpl base_literal = (LiteralImpl) myLiterals.choice_request.copy();
                base_literal.addTerm(state.dispenser_access_direction);
                return un.unifies(args[0], base_literal);
            }
            case About_to_attach -> {
                LiteralImpl base_literal = (LiteralImpl) myLiterals.choice_attach.copy();
                base_literal.addTerm(state.dispenser_access_direction);
                return un.unifies(args[0], base_literal);
            }
            case Going_to_goal -> {
                return un.unifies(args[0], get_move_direction(state.position, state.chosen_goal, state.map));
            }
            case Rotating -> {
                // Fun fact rotation isn't blocked by terrain so this is all that is necessary
                LiteralImpl base_literal = (LiteralImpl) myLiterals.choice_rotate.copy();
                if (state.dispenser_access_direction.equals(myLiterals.direction_w)) {
                    base_literal.addTerm(myLiterals.direction_counterclockwise);
                } else {
                    base_literal.addTerm(myLiterals.direction_clockwise);
                }
                return un.unifies(args[0], base_literal);
            }
            case Submit -> {
                LiteralImpl base_literal = (LiteralImpl) myLiterals.choice_submit.copy();
                base_literal.addTerm(new StringTermImpl(state.current_task.id));
                System.out.println("Bot " + state.agent_name + " attempting to submit " + state.current_task.id);
                return un.unifies(args[0], base_literal);
            }
        }

        return true;
    }

    LiteralImpl get_move_direction(Position position, Position goal, HashSet<Position> obstacles) {

        if(position.equals(goal)){
            return myLiterals.choice_skip;
        }

        Position look_position = position.clone();

        look_position.add(0,-1);
        boolean n_free = !obstacles.contains(look_position);
        look_position.add(0,2);
        boolean s_free = !obstacles.contains(look_position);
        look_position.add(-1,-2);
        boolean w_free = !obstacles.contains(look_position);
        look_position.add(2,0);
        boolean e_free = !obstacles.contains(look_position);


        LiteralImpl direction = null;
        if(direction == null && (position.y < goal.y) && s_free) {
            direction = myLiterals.direction_s;
        }

        if(direction == null && (position.y > goal.y) && n_free) {
            direction = myLiterals.direction_n;
        }

        if(direction == null && (position.x > goal.x) && w_free) {
            direction = myLiterals.direction_w;
        }

        if(direction == null && (position.x < goal.x) && e_free) {
            direction = myLiterals.direction_e;
        }

        if(direction == null){
            System.out.println("Bot failed to find direction");
            if(n_free){
                direction = myLiterals.direction_n;
            } else if (s_free) {
                direction = myLiterals.direction_s;
            } else if (w_free) {
                direction = myLiterals.direction_w;
            } else if (e_free) {
                direction = myLiterals.direction_e;
            }
            else {
                System.out.println("PANIC BOT STUCK!!");
                return myLiterals.choice_skip;
            }
        }


        LiteralImpl base_literal = (LiteralImpl) myLiterals.choice_move.copy();
        base_literal.addTerm(direction);
        return base_literal;
    }


    LiteralImpl get_explore_direction() {
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
        return base_literal;
    }
}
