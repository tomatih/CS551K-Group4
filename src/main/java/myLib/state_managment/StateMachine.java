package myLib.state_managment;

public enum StateMachine {
    Lost, // exploring to find landmarks -> move random
    Idle, // waiting to pick up a task -> skip
    Going_to_dispenser, // task picked on way to pick up resource -> move direction
    At_dispenser, // waiting on dispense -> request block
    About_to_attach, // attaching to block -> attach
    Going_to_goal, // move to goal -> move direction
    Rotating, // rotate to match pattern -> rotate
    Submit, //is this one necessary -> submit
}
