package myLib.helpers;

import jason.asSyntax.NumberTermImpl;
import jason.asSyntax.Term;

public class Position {
    public int x;
    public int y;

    public Position(int x, int y) {
        this.x = x;
        this.y = y;
    }

    public void add(Position other){
        x += other.x;
        y += other.y;
    }

    //TODO: fix delta 1 on corners
    public int distance(Position other){
        return Math.abs(x - other.x) + Math.abs(y - other.y);
    }

    @Override
    public String toString() {
        return "(" + x + ", " + y + ")";
    }

    static public Position from_direction(Term direction){
        if(direction.equals(myLiterals.direction_n)){
            return new Position(0,-1);
        }
        else if(direction.equals(myLiterals.direction_s)){
            return new Position(0,1);
        }
        else if(direction.equals(myLiterals.direction_w)){
            return new Position(-1,0);
        }
        else if(direction.equals(myLiterals.direction_e)){
            return new Position(1,0);
        }
        else {
            return null;
        }
    }

    static public Position from_terms(Term x, Term y){
        int pos_x = (int)((NumberTermImpl)x).solve();
        int pos_y = (int)((NumberTermImpl)y).solve();
        return new Position(pos_x, pos_y);
    }
}


/*
Coordinate system is

. → x
↓
y

Percepts are given in the (x,y) order
 */