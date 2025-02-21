package myLib.actions;

import jason.JasonException;
import jason.asSemantics.*;
import jason.asSyntax.*;

import java.util.Random;

public class moveRandom extends DefaultInternalAction {
    private static InternalAction singleton = null;
    private final Random rand = new Random();
    private final String[] directions = {"n", "e", "s", "w"};

    public static InternalAction create() {
        if (singleton == null)
            singleton = new moveRandom();
        return singleton;
    }

    @Override
    public Object execute(TransitionSystem ts, Unifier un, Term[] args) throws Exception {
        if (args.length != 1) {
            throw new JasonException("Need exactly one argument");
        }
        if (!args[0].isVar()) {
            throw new JasonException("Variable argument mustn't be a variable");
        }
        int direction = rand.nextInt(directions.length);
        return un.unifies(args[0], new StringTermImpl(directions[direction]));
    }
}
