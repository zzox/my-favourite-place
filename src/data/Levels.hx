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
    var start:IntPoint;
    var levels:Array<LevelData>;
}

typedef LevelData = {
    var isOpen:Bool;
    var exits:Map<Dir, Int>;
    var roomNumber:String;
    var ?enemies:Array<EnemyPlacement>;
    var ?powerup:Array<Powerups>;
}

final downLevels = [{
    roomNumber: '0',
    isOpen: true,
    exits: [Down => 1]
}, {
    roomNumber: '1',
    isOpen: false,
    exits: [Down => 2],
    enemies: [{
        type: Gremlin,
        pos: { x: 168, y: 64 },
        vel: { x: -120, y: 0 }
    }, {
        type: Gremlin,
        pos: { x: -32, y: 24 },
        vel: { x: 120, y: 0 }
    }]
}, {
    roomNumber: '2',
    isOpen: false,
    exits: [Down => 4, Right => 3],
    enemies: [{
        type: Gremlin,
        pos: { x: 232, y: 24 },
        vel: { x: -120, y: 0 }
    }, {
        type: Gremlin,
        pos: { x: 200, y: 48 },
        vel: { x: -120, y: 0 }
    }, {
        type: Gremlin,
        pos: { x: 168, y: 72 },
        vel: { x: -120, y: 0 }
    }]
}, {
    roomNumber: 'Bonus - 1',
    isOpen: true,
    exits: [Left => 2]
}, {
    roomNumber: '3',
    isOpen: true,
    exits: [Down => 5]
}, {
    roomNumber: '4',
    isOpen: false,
    exits: [Down => 6]
}, {
    roomNumber: '5',
    isOpen: false,
    exits: [Down => 8, Right => 7]
}, {
    roomNumber: 'Bonus - 2',
    isOpen: false,
    exits: [Left => 6]
}, {
    roomNumber: '6',
    isOpen: false,
    exits: [Down => 9]
}, {
    roomNumber: '7',
    isOpen: false,
    exits: new Map()
}];

final worldData:Map<Worlds, WorldData> = [
    LDown => {
        bgColor: 0xffffe9c5,
        path: AssetPaths.down__ldtk,
        start: { x: 24, y: 50 },
        levels: downLevels
    }
];

final downLevelsOld = [{
}, {
    enemies: [{
        type: Gremlin,
        pos: { x: 168, y: 64 },
        vel: { x: -120, y: 0 }
    }, {
        type: Gremlin,
        pos: { x: -32, y: 24 },
        vel: { x: 120, y: 0 }
    }]
}, {
    enemies: [{
        type: Gremlin,
        pos: { x: 168, y: 16 },
        vel: { x: -120, y: 0 }
    }, {
        type: Gremlin,
        pos: { x: 200, y: 40 },
        vel: { x: -120, y: 0 }
    }, {
        type: Gremlin,
        pos: { x: 232, y: 64 },
        vel: { x: -120, y: 0 }
    }],
    powerup: [LongerDash, FasterDash]
}, {
    enemies: [{
        type: Gremlin,
        pos: { x: 168, y: 64 },
        vel: { x: -120, y: 0 }
    }, {
        type: Gremlin,
        pos: { x: -32, y: 24 },
        vel: { x: 120, y: 0 }
    }],
    powerup: [PlusOneJump, PlusOneDash]
}, {
    enemies: [{
        type: Gremlin,
        pos: { x: 168, y: 64 },
        vel: { x: -120, y: 0 }
    }, {
        type: Gremlin,
        pos: { x: -32, y: 24 },
        vel: { x: 120, y: 0 }
    }],
    powerup: [LongerDash, FasterDash]
}, {
    enemies: [{
        type: Gremlin,
        pos: { x: 168, y: 64 },
        vel: { x: -120, y: 0 }
    }, {
        type: Gremlin,
        pos: { x: -32, y: 24 },
        vel: { x: 120, y: 0 }
    }]
}, {
    enemies: [{
        type: Gremlin,
        pos: { x: 168, y: 64 },
        vel: { x: -120, y: 0 }
    }, {
        type: Gremlin,
        pos: { x: -32, y: 24 },
        vel: { x: 120, y: 0 }
    }],
    powerup: [MinusOneJump, MinusOneDash]
}];
