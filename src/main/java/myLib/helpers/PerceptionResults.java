package myLib.helpers;

import jason.asSyntax.Term;

import java.util.ArrayList;

public class PerceptionResults {
    public boolean last_action_success;
    public Term last_action;
    public Term last_action_arg;
    public Term last_action_result;
    public ArrayList<Position> goals = new ArrayList<Position>();
    public ArrayList<Position> dispensers_0 = new ArrayList<>();
    public ArrayList<Position> dispensers_1 = new ArrayList<>();
    public ArrayList<Task> available_tasks = new ArrayList<>();
    public Position attached_block_position = null;
}
