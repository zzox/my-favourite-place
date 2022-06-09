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

typedef ShooterPlacement = {
    var time:Float;
    var offset:Float;
    var position:IntPoint;
    var velocity:IntPoint;
    var acceleration:IntPoint;
}

typedef WorldData = {
    var bgColor:Int;
    var path:String;
    var start:IntPoint;
    var playerPath:String;
    var deathDirs:Array<Dir>;
    var winDir:Dir;
    // var hudColors:Array<Int>;
    var levels:Array<LevelData>;
}

typedef LevelData = {
    var isOpen:Bool;
    var exits:Map<Dir, Int>;
    var roomNumber:String;
    var ?enemies:Array<EnemyPlacement>;
    var ?powerups:Array<PowerupData>;
    var ?shooters:Array<ShooterPlacement>;
}

enum abstract Powerups(String) to String {
    var FasterDash = 'Fast Dash';
    var PlusOneJump = '+1 Jump';
    var PlusOneDash = '+1 Dash';
}

typedef PowerupData = {
    var type:Powerups;
    var pos:IntPoint;
}

final outLevels = [{
    roomNumber: '0',
    isOpen: true,
    exits: [Right => 1]
}, {
    roomNumber: '1',
    isOpen: false,
    exits: [Down => 2],
    powerups: [{
        type: PlusOneDash,
        pos: { x: 12, y: 68 }
    }]
}, {
    roomNumber: '2',
    isOpen: true,
    exits: [Left => 3]
}, {
    roomNumber: '3',
    isOpen: true,
    exits: new Map()
}];

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
    exits: [Left => 2],
    powerups: [{
        type: PlusOneJump,
        pos: { x: 120, y: 24 }
    }]
}, {
    roomNumber: '3',
    isOpen: true,
    exits: [Down => 5]
}, {
    roomNumber: '4',
    isOpen: false,
    exits: [Down => 6],
    enemies: [{
        type: Gremlin,
        pos: { x: 168, y: 24 },
        vel: { x: -120, y: 15 }
    }, {
        type: Gremlin,
        pos: { x: -32, y: 24 },
        vel: { x: 120, y: 15 }
    }]
}, {
    roomNumber: '5',
    isOpen: false,
    exits: [Down => 8, Right => 7],
    enemies: [{
        type: FastGremlin,
        pos: { x: 168, y: 72 },
        vel: { x: -180, y: 0 }
    }, {
        type: Gremlin,
        pos: { x: -32, y: 24 },
        vel: { x: 120, y: 0 }
    }]
}, {
    roomNumber: 'Bonus - 2',
    isOpen: true,
    exits: [Left => 6],
    powerups: [{
        type: PlusOneDash,
        pos: { x: 108, y: 40 }
    }]
}, {
    roomNumber: '6',
    isOpen: false,
    exits: [Down => 9],
    enemies: [{
        type: FastGremlin,
        pos: { x: -144, y: 32 },
        vel: { x: 180, y: 0 }
    }, {
        type: FastGremlin,
        pos: { x: 240, y: 48 },
        vel: { x: -180, y: 0 }
    }]
}, {
    roomNumber: '7',
    isOpen: false,
    exits: new Map()
}];

final rightLevels = [{
    roomNumber: '0',
    isOpen: true,
    exits: [Right => 1]
}, {
    roomNumber: '1',
    isOpen: true,
    exits: [Right => 2]
}, {
    roomNumber: '2',
    isOpen: true,
    exits: [Right => 3]
}, {
    roomNumber: '3',
    isOpen: true,
    exits: [Right => 4],
    shooters: [{
        time: 1.5,
        offset: 0.5,
        position: { x: 100, y: 96 },
        velocity: { x: 0, y: -240 },
        acceleration: { x: 0, y: 480 },
    }, {
        time: 1.5,
        offset: 1.25,
        position: { x: 60, y: 96 },
        velocity: { x: 0, y: -240 },
        acceleration: { x: 0, y: 480 },
    }]
}, {
    roomNumber: '4',
    isOpen: true,
    exits: [Right => 5]
}, {
    roomNumber: '5',
    isOpen: true,
    exits: [Right => 6]
}, {
    roomNumber: '6',
    isOpen: true,
    exits: [Right => 7]
}, {
    roomNumber: '7',
    isOpen: true,
    exits: new Map()
}];

final worldData:Map<Worlds, WorldData> = [
    LOut => {
        bgColor: 0xffd7d7d7,
        path: AssetPaths.out__ldtk,
        start: { x: 48, y: 24 },
        levels: outLevels,
        playerPath: AssetPaths.player__png,
        deathDirs: [],
        winDir: Down
    },
    LDown => {
        bgColor: 0xffffe9c5,
        path: AssetPaths.down__ldtk,
        start: { x: 24, y: 24 },
        levels: downLevels,
        playerPath: AssetPaths.player__png,
        deathDirs: [],
        winDir: Down
    },
    LRight => {
        bgColor: 0xff0d2030,
        // bgColor: 0xff7b7b7b,
        path: AssetPaths.right__ldtk,
        start: { x: 24, y: 24 },
        levels: rightLevels,
        playerPath: AssetPaths.player_light__png,
        deathDirs: [Down],
        winDir: Right
    }
];
