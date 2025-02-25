package myLib.helpers;

import jason.asSyntax.LiteralImpl;
import jason.asSyntax.Term;

public class myLiterals {
    static final public LiteralImpl action_result_success = new LiteralImpl("success");

    static final public LiteralImpl action_move = new LiteralImpl("move");
    static final public LiteralImpl action_request = new LiteralImpl("request");
    static final public LiteralImpl action_attach = new LiteralImpl("attach");
    static final public LiteralImpl action_submit = new LiteralImpl("submit");
    static final public LiteralImpl action_rotate = new LiteralImpl("rotate");

    static final public LiteralImpl direction_n = new LiteralImpl("n");
    static final public LiteralImpl direction_e = new LiteralImpl("e");
    static final public LiteralImpl direction_s = new LiteralImpl("s");
    static final public LiteralImpl direction_w = new LiteralImpl("w");

    static final public LiteralImpl direction_clockwise = new LiteralImpl("cw");
    static final public LiteralImpl direction_counterclockwise = new LiteralImpl("ccw");

    static final public LiteralImpl dispenser_type_0 = new LiteralImpl("b0");
    static final public LiteralImpl dispenser_type_1 = new LiteralImpl("b1");

    static final public LiteralImpl choice_move = new LiteralImpl("m");
    static final public LiteralImpl choice_skip = new LiteralImpl("s");
    static final public LiteralImpl choice_request = new LiteralImpl("r");
    static final public LiteralImpl choice_attach = new LiteralImpl("a");
    static final public LiteralImpl choice_submit = new LiteralImpl("p");
    static final public LiteralImpl choice_rotate = new LiteralImpl("t");

    static final public LiteralImpl block_type_0 = new LiteralImpl("b0");
    static final public LiteralImpl block_type_1 = new LiteralImpl("b1");
}
