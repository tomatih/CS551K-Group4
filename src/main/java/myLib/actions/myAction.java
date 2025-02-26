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
                return un.unifies(args[0], get_move_direction(state.position, state.dispenser_access_position));
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
                return un.unifies(args[0], get_move_direction(state.position, state.chosen_goal));
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

    LiteralImpl get_move_direction(Position position, Position goal) {
        // first align vertical
        LiteralImpl direction = null;
        if (position.y != goal.y) {
            if (goal.y > position.y) {
                direction = myLiterals.direction_s;
            } else {
                direction = myLiterals.direction_n;
            }
        }
        // then align horizontal
        else if (position.x != goal.x) {
            if (goal.x > position.x) {
                direction = myLiterals.direction_e;
            } else {
                direction = myLiterals.direction_w;
            }
        }
        // onm top but for some reason sensing hasn't activated yet
        else {
            return myLiterals.choice_skip;
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
