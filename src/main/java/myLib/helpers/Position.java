package myLib.helpers;

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

    public int distance(Position other){
        return Math.abs(x - other.x) + Math.abs(y - other.y);
    }

    @Override
    public String toString() {
        return "(" + x + ", " + y + ")";
    }
}
