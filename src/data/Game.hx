package data;

import data.Constants;
import data.Levels;
import flixel.FlxG;

class Game {
    public static final inst:GameInstance = new GameInstance();
}

typedef CompleteData = {
    var complete:Bool;
    var bestTime:Float;
    var totalTime:Float;
    var deaths:Int;
}

typedef Options = {
    var crtFilter:Bool;
}

class GameInstance {
    public var isHardcore:Bool = false;
    public var currentWorld:Worlds;

    public var worlds:Map<Worlds, CompleteData> = new Map();
    public var options:Options = { crtFilter: true };
    public var levelCleared:Int = -1;
    public var hasMenuOptions:Bool = false;

    public var hardcoreTimeTotal:Float;

    public function new () {
        // for some strange reason I can't call `newWorldsData()` here
        for (item in levelList) {
            worlds[item] = {
                complete: false,
                bestTime: 0.0,
                totalTime: 0.0,
                deaths: 0
            }
        }

        FlxG.save.bind(MFP_KEY, 'zzox');
        if (FlxG.save.data.levelCleared != null) {
            hasMenuOptions = true;
            loadData();
        }
    }

    public function winLevel (world:Worlds, time:Float):Bool {
        if (isHardcore) {
            hardcoreTimeTotal += time;
        }

        worlds[world].totalTime += time;
        worlds[world].complete = true;

        final newBest = worlds[world].bestTime == 0 || time < worlds[world].bestTime;
        worlds[world].bestTime = newBest ? time : worlds[world].bestTime;

        // increment world
        final levelIndex = levelList.indexOf(world);
        if (levelIndex > levelCleared) {
            levelCleared = levelIndex;
        }
        currentWorld = levelList[levelIndex + 1];

        saveData();

        return newBest;
    }

    public function loseLevel (world:Worlds, time:Float) {
        worlds[world].totalTime += time;
        worlds[world].deaths++;

        saveData();
    }

    function saveData () {
        FlxG.save.bind(MFP_KEY, 'zzox');
        FlxG.save.data.levelCleared = levelCleared;
        FlxG.save.data.worlds = worlds;
        FlxG.save.data.options = options;
        FlxG.save.flush();
    }

    function loadData () {
        FlxG.save.bind(MFP_KEY, 'zzox');
        levelCleared = FlxG.save.data.levelCleared;
        worlds = FlxG.save.data.worlds;
        options = FlxG.save.data.options;
    }

    function newWorldsData () {
        for (item in levelList) {
            worlds[item] = {
                complete: false,
                bestTime: 0.0,
                totalTime: 0.0,
                deaths: 0
            }
        }
    }

    public function clearSaveData () {
        FlxG.save.bind(MFP_KEY, 'zzox');
        FlxG.save.erase();
        newWorldsData();
        levelCleared = -1;
        hasMenuOptions = false;
    }
}
