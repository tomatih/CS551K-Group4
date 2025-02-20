package myLib;

import jason.asSyntax.Term;

import java.util.ArrayList;

public class PerceptionResults {
    public boolean last_action_success;
    public Term last_action;
    public Term last_action_arg;
    public ArrayList<Position> goals = new ArrayList<Position>();
}
