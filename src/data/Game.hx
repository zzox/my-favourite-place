package data;

import data.Levels;

class Game {
    public static final inst:GameInstance = new GameInstance();
}

typedef CompleteData = {
    var complete:Bool;
    var bestTime:Float;
    var totalTime:Float;
    var deaths:Int;
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
                totalTime: 0.0,
                deaths: 0
            }
        }
    }

    public function winLevel (world:Worlds, time:Float):Bool {
        worlds[world].totalTime += time;
        worlds[world].complete = true;
        final newBest = time < worlds[world].bestTime;
        worlds[world].bestTime = newBest ? time : worlds[world].bestTime;
        return newBest;
    }

    public function loseLevel (world:Worlds, time:Float) {
        worlds[world].totalTime += time;
        worlds[world].deaths++;
    }
}
