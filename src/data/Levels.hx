package data;

import actors.Enemy;
import data.Constants;

enum Worlds {
    LOut;
    LDown;
    LRight;
    LUp;
    LThrough;
    LOver;
}

typedef EnemyPlacement = {
    var type:EnemyType;
    var pos:IntPoint;
    var vel:IntPoint;
}

enum abstract Powerups(String) to String {
    var Faster = 'Faster';
    var Higher = 'Higher';
    var LongerDash = 'Long Dash';
    var FasterDash = 'Fast Dash';
    var PlusOneJump = '+1 Jump';
    var PlusOneDash = '+1 Dash';
    var MinusOneJump = '-1 Jump';
    var MinusOneDash = '-1 Dash';
}

typedef WorldData = {
    var bgColor:Int;
    var path:String;
    var levels:Array<LevelData>;
}

typedef LevelData = {
    var ?enemies:Array<EnemyPlacement>;
    var ?powerup:Array<Powerups>;
    var exits:Map<Dir, Int>;
}

final downLevels = [{
    exits: [Down => 1]
},{
    exits: [Down => 2]
},{
    exits: [Down => 4, Right => 3]
},{
    exits: [Left => 2]
},{
    exits: [Down => 5]
},{
    exits: [Down => 6]
},{
    exits: [Down => 8, Right => 7]
},{
    exits: [Left => 6]
},{
    exits: [Down => 9]
},{
    exits: new Map()
}];

final worldData:Map<Worlds, WorldData> = [
    LDown => {
        bgColor: 0xffffe9c5,
        path: AssetPaths.down__ldtk,
        levels: downLevels
    }
];

final downLevelsOld = [{
}, {
    enemies: [{
        type: Saucer,
        pos: { x: 168, y: 64 },
        vel: { x: -120, y: 0 }
    }, {
        type: Saucer,
        pos: { x: -32, y: 24 },
        vel: { x: 120, y: 0 }
    }]
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
    powerup: [LongerDash, FasterDash]
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
    powerup: [PlusOneJump, PlusOneDash]
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
    powerup: [LongerDash, FasterDash]
}, {
    enemies: [{
        type: Saucer,
        pos: { x: 168, y: 64 },
        vel: { x: -120, y: 0 }
    }, {
        type: Saucer,
        pos: { x: -32, y: 24 },
        vel: { x: 120, y: 0 }
    }]
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
    powerup: [MinusOneJump, MinusOneDash]
}];
