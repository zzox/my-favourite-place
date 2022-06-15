package data;

import data.Levels;

class Game {
    public static final inst:GameInstance = new GameInstance();
}

typedef CompleteData = {
    var complete:Bool;
    var bestTime:Float;
    var totalTime:Float;
}

class GameInstance {
    public var isHardcore:Bool = false;
    public var currentWorld:Worlds;
    public var worlds:Map<Worlds, CompleteData> = new Map();

    public function new () {
        for (item in levelList) {
            worlds[item] = {
                complete: false,
                bestTime: 0.0,
                totalTime: 0.0
            }
        }
    }
}
