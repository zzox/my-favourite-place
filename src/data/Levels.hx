package data;

import actors.Enemy;
import data.Constants;

typedef EnemyPlacement = {
    var type:EnemyType;
    var pos:IntPoint;
    var vel:IntPoint;
}

enum Choices {
    PlusOneJump;
    PlusOneDash;
    Faster;
    Higher;
}

typedef LevelData = {
    var ?enemies:Array<EnemyPlacement>;
    var choices:Array<Choices>;
}

final levels:Array<LevelData> = [{
    choices: [Faster, Higher]
}, {
    enemies: [{
        type: Saucer,
        pos: { x: 168, y: 64 },
        vel: { x: -120, y: 0 }
    }, {
        type: Saucer,
        pos: { x: -32, y: 24 },
        vel: { x: 120, y: 0 }
    }],
    choices: [Faster, Higher]
}, {
    choices: [Faster, Higher]
}, {
    choices: [Faster, Higher]
}];
