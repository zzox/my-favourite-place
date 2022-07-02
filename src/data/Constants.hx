package data;

final GLOBAL_Y_OFFSET = 6;
final MFP_KEY = 'my-favorite-place-key';

enum Dir {
    Left;
    Right;
    Up;
    Down;
}

typedef Point = {
    var x:Float;
    var y:Float;
}

typedef IntPoint = {
    var x:Int;
    var y:Int;
}
