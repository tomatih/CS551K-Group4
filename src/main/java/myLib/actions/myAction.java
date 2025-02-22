package myLib.actions;

import jason.JasonException;
import jason.asSemantics.DefaultInternalAction;
import jason.asSemantics.InternalAction;
import jason.asSemantics.TransitionSystem;
import jason.asSemantics.Unifier;
import jason.asSyntax.LiteralImpl;
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
                //TODO: obstacle avoidance and better navigation

                Position dispenser = null;
                if(state.current_task.is_type_0){
                    dispenser = state.closest_dispenser_0;
                }
                else {
                    dispenser = state.closest_dispenser_1;
                }
                System.out.println("Bot "+state.agent_name+" at "+state.position+" going to "+dispenser);
                // first align vertical
                LiteralImpl direction = null;
                if(state.position.y != dispenser.y ){
                    if(dispenser.y > state.position.y){
                        direction = myLiterals.direction_n;
                    }
                    else {
                        direction = myLiterals.direction_s;
                    }
                }
                else {
                    if(dispenser.x > state.position.x){
                        direction = myLiterals.direction_e;
                    }
                    else {
                        direction = myLiterals.direction_w;
                    }
                }
                LiteralImpl base_literal = (LiteralImpl) myLiterals.choice_move.copy();
                base_literal.addTerm(direction);
                return un.unifies(args[0], base_literal);
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
