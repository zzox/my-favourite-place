package data;

import actors.Enemy;
import data.Constants;

enum abstract Worlds(String) to String {
    var LOut = 'Out';
    var LDown = 'Down';
    var LRight = 'Right';
    var LUp = 'Up';
    var LThrough = 'Through';
    var LOver = 'Over';
}
final levelList = [LOut, LDown, LRight, LUp, LThrough, LOver];

typedef EnemyPlacement = {
    var type:EnemyType;
    var pos:IntPoint;
    var vel:IntPoint;
}

typedef TextPlacement = {
    var text:String;
    var pos:IntPoint;
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
    var titleColor:Int;
    var path:String;
    var start:IntPoint;
    var playerPath:String;
    var deathDirs:Array<Dir>;
    var winDir:Dir;
    var fromStartDir:Dir;
    var postWinDir:Dir;
    var postLoseDir:Dir;
    // var hudColors:Array<Int>;
    var levels:Array<LevelData>;
}

typedef LevelData = {
    var isOpen:Bool;
    var exits:Map<Dir, Int>;
    var ?enemies:Array<EnemyPlacement>;
    var ?powerups:Array<PowerupData>;
    var ?shooters:Array<ShooterPlacement>;
    var ?text:Array<TextPlacement>;
}

enum abstract Powerups(String) to String {
    var UnlimitedDashes = 'Unlimited Dashes';
    var PlusOneDash = '+1 Dash';
}

typedef PowerupData = {
    var type:Powerups;
    var pos:IntPoint;
}

final outLevels = [{
    isOpen: true,
    exits: [Right => 1],
    text: [{
        text: 'A/D or LEFT/RIGHT: move',
        pos: { x: 12, y: 16 }
    }, {
        text: 'W or Up or SPACE: jump',
        pos: { x: 18, y: 28 }
    }]
}, {
    isOpen: false,
    exits: [Down => 2],
    powerups: [{
        type: PlusOneDash,
        pos: { x: 12, y: 68 }
    }],
    text: [{
        text: 'Click: dash',
        pos: { x: 36, y: 72 }
    }]
}, {
    isOpen: true,
    exits: [Left => 3],
    text: [{
        text: 'S or DOWN: fall',
        pos: { x: 24, y: 16 }
    }]
}, {
    isOpen: true,
    exits: new Map(),
    text: [{
        text: 'good luck',
        pos: { x: 16, y: 40 }
    }, {
        text: 'on your journey',
        pos: { x: 24, y: 48 }
    }]
}];

final downLevels = [{
    isOpen: true,
    exits: [Down => 1]
}, {
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
    isOpen: false,
    exits: [Down => 3],
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
    isOpen: true,
    exits: [Down => 4]
}, {
    isOpen: false,
    exits: [Down => 5],
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
    isOpen: false,
    exits: [Down => 6],
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
    isOpen: false,
    exits: [Down => 7],
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
    isOpen: false,
    exits: new Map()
}];

final rightLevels = [{
    isOpen: true,
    exits: [Right => 1]
}, {
    isOpen: true,
    exits: [Right => 2],
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
    isOpen: false,
    exits: [Right => 3],
    enemies: [{
        type: Bird,
        pos: { x: 168, y: 0 },
        vel: { x: -120, y: 30 }
    }]
}, {
    isOpen: true,
    exits: [Right => 4],
    shooters: [{
        time: 1.5,
        offset: 0.0,
        position: { x: 48, y: 96 },
        velocity: { x: 0, y: -240 },
        acceleration: { x: 0, y: 480 },
    }, {
        time: 1.5,
        offset: 0.25,
        position: { x: 64, y: 96 },
        velocity: { x: 0, y: -240 },
        acceleration: { x: 0, y: 480 },
    }, {
        time: 1.5,
        offset: 0.5,
        position: { x: 80, y: 96 },
        velocity: { x: 0, y: -240 },
        acceleration: { x: 0, y: 480 },
    }, {
        time: 1.5,
        offset: 0.75,
        position: { x: 96, y: 96 },
        velocity: { x: 0, y: -240 },
        acceleration: { x: 0, y: 480 },
    }, {
        time: 1.5,
        offset: 1.0,
        position: { x: 112, y: 96 },
        velocity: { x: 0, y: -240 },
        acceleration: { x: 0, y: 480 },
    }]
}, {
    isOpen: false,
    exits: [Right => 5],
    enemies: [{
        type: Bird,
        pos: { x: -24, y: 0 },
        vel: { x: 120, y: 30 }
    }]
}, {
    isOpen: true,
    exits: [Right => 6]
}, {
    isOpen: false,
    exits: [Right => 7],
    enemies: [{
        type: Bird,
        pos: { x: 168, y: 0 },
        vel: { x: -120, y: 30 }
    }, {
        type: Bird,
        pos: { x: -24, y: 0 },
        vel: { x: 120, y: 30 }
    }],
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
    isOpen: false,
    exits: new Map()
}];

final upLevels = [{
    isOpen: true,
    exits: [Up => 1],
    powerups: [{
        type: PlusOneDash,
        pos: { x: 136, y: 66 }
    }]
}, {
    isOpen: false,
    exits: [Up => 2],
    powerups: [], // this is needed for some insane haxe reason
    enemies: [{
        type: OutdoorGremlin,
        pos: { x: -32, y: 0 },
        vel: { x: 240, y: 15 }
    }, {
        type: OutdoorGremlin,
        pos: { x: 240, y: 0 },
        vel: { x: -240, y: 15 }
    }]
}, {
    isOpen: true,
    exits: [Up => 3]
}, {
    isOpen: true,
    exits: [Up => 4],
    shooters: [{
        time: 2.0,
        offset: 0.5,
        position: { x: 192, y: 72 },
        velocity: { x: -120, y: -240 },
        acceleration: { x: 0, y: 480 },
    }, {
        time: 2.0,
        offset: 1.5,
        position: { x: -32, y: 72 },
        velocity: { x: 120, y: -240 },
        acceleration: { x: 0, y: 480 },
    }]
}, {
    isOpen: false,
    exits: [Up => 5],
    enemies: [{
        type: OutdoorGremlin,
        pos: { x: -32, y: -16 },
        vel: { x: 240, y: 120 }
    }, {
        type: OutdoorGremlin,
        pos: { x: 216, y: -36 },
        vel: { x: -240, y: 120 }
    }]
}, {
    isOpen: true,
    exits: [Up => 6],
    shooters: [{
        time: 2.0,
        offset: 0.5,
        position: { x: 192, y: 80 },
        velocity: { x: -90, y: -240 },
        acceleration: { x: 0, y: 480 }
    }, {
        time: 2.0,
        offset: 1.5,
        position: { x: -32, y: 80 },
        velocity: { x: 90, y: -240 },
        acceleration: { x: 0, y: 480 }
    }]
}, {
    isOpen: false,
    exits: [Up => 7],
    enemies: [{
        type: OutdoorGremlin,
        pos: { x: -32, y: 0 },
        vel: { x: 240, y: 15 }
    }, {
        type: OutdoorGremlin,
        pos: { x: 240, y: 0 },
        vel: { x: -240, y: 15 }
    }]
}, {
    isOpen: false,
    exits: new Map()
}];

final throughLevels = [{
    isOpen: true,
    exits: [Down => 1]
}, {
    isOpen: false,
    exits: [Down => 2],
}, {
    isOpen: false,
    exits: [Down => 3]
}, {
    isOpen: true,
    exits: [Down => 4]
}, {
    isOpen: true,
    exits: [Down => 5]
}, {
    isOpen: true,
    exits: [Down => 6]
}, {
    isOpen: true,
    exits: [Down => 7]
}, {
    isOpen: false,
    exits: new Map()
}];

final overLevels = [{
    isOpen: true,
    exits: [Up => 1],
    powerups: [{
        type: UnlimitedDashes,
        pos: { x: 116, y: 66 }
    }]
}, {
    isOpen: true,
    exits: [Right => 2]
}, {
    isOpen: true,
    exits: [Up => 3]
}, {
    isOpen: true,
    exits: [Right => 4]
}, {
    isOpen: true,
    exits: [Down => 5]
}, {
    isOpen: true,
    exits: [Right => 6]
}, {
    isOpen: true,
    exits: [Down => 7]
}, {
    isOpen: true,
    exits: new Map()
}];

final worldData:Map<Worlds, WorldData> = [
    LOut => {
        bgColor: 0xffd7d7d7,
        titleColor: 0xff0d2030,
        path: AssetPaths.out__ldtk,
        start: { x: 16, y: 80 },
        levels: outLevels,
        playerPath: AssetPaths.player__png,
        deathDirs: [],
        winDir: Down,
        fromStartDir: Up,
        postWinDir: Down,
        postLoseDir: Up
    },
    LDown => {
        bgColor: 0xffffe9c5,
        titleColor: 0xff0d2030,
        path: AssetPaths.down__ldtk,
        start: { x: 24, y: 24 },
        levels: downLevels,
        playerPath: AssetPaths.player__png,
        deathDirs: [],
        winDir: Down,
        fromStartDir: Up,
        postWinDir: Right,
        postLoseDir: Up
    },
    LRight => {
        bgColor: 0xff0d2030,
        titleColor: 0xffd7d7d7,
        // bgColor: 0xff7b7b7b,
        path: AssetPaths.right__ldtk,
        start: { x: 24, y: 24 },
        levels: rightLevels,
        playerPath: AssetPaths.player_light__png,
        deathDirs: [Down],
        winDir: Right,
        fromStartDir: Up,
        postWinDir: Right,
        postLoseDir: Left
    },
    LUp => {
        bgColor: 0xff9ba0ef,
        titleColor: 0xff0d2030,
        path: AssetPaths.up__ldtk,
        start: { x: 24, y: 66 },
        levels: upLevels,
        playerPath: AssetPaths.player__png,
        deathDirs: [],
        winDir: Right,
        fromStartDir: Left,
        postWinDir: Up,
        postLoseDir: Left
    },
    LThrough => {
        bgColor: 0xff000000,
        titleColor: 0xffd7d7d7,
        path: AssetPaths.through__ldtk,
        start: { x: 24, y: 24 },
        levels: throughLevels,
        playerPath: AssetPaths.player_light__png,
        deathDirs: [],
        winDir: Right,
        fromStartDir: Left,
        postWinDir: Right,
        postLoseDir: Up
    },
    LOver => {
        bgColor: 0xff211640,
        titleColor: 0xffd7d7d7,
        path: AssetPaths.over__ldtk,
        start: { x: 18, y: 72 },
        levels: overLevels,
        playerPath: AssetPaths.player_light__png,
        deathDirs: [],
        winDir: Right,
        fromStartDir: Left,
        postWinDir: Up,
        postLoseDir: Left
    }
];
