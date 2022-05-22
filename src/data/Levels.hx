package data;

import actors.Enemy;
import data.Constants;

typedef EnemyPlacement = {
    var type:EnemyType;
    var pos:IntPoint;
    var vel:IntPoint;
}

enum abstract Choices(String) to String {
    var Faster = 'Faster';
    var Higher = 'Higher';
    var LongerDash = 'Long Dash';
    var FasterDash = 'Fast Dash';
    var PlusOneJump = '+1 Jump';
    var PlusOneDash = '+1 Dash';
    var MinusOneJump = '-1 Jump';
    var MinusOneDash = '-1 Dash';
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
    choices: [PlusOneJump, PlusOneDash]
}, {
    enemies: [{
        type: Saucer,
        pos: { x: 168, y: 16 },
        vel: { x: -120, y: 0 }
    }, {
        type: Saucer,
        pos: { x: 200, y: 40 },
        vel: { x: -120, y: 0 }
    }, {
        type: Saucer,
        pos: { x: 232, y: 64 },
        vel: { x: -120, y: 0 }
    }],
    choices: [LongerDash, FasterDash]
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
}];
