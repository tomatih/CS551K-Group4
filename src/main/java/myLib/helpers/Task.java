package myLib.helpers;

public class Task {
    public Position offset;
    public boolean is_type_0;
    public String id;

    public Task(String id, Position offset, boolean is_type_0) {
        this.id = id;
        this.offset = offset;
        this.is_type_0 = is_type_0;
    }
}
