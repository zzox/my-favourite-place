package util;

import data.Constants;
import flixel.FlxG;
import flixel.math.FlxPoint;

// changed from: https://github.com/HaxeFlixel/flixel/blob/dev/flixel/math/FlxAngle.hx
function angleBetweenMouse(point:FlxPoint, offset:Float = 0, asDegrees:Bool = false):Float {
    final dx:Float = FlxG.camera.scroll.x + FlxG.mouse.screenX - point.x;
    final dy:Float = FlxG.camera.scroll.y + FlxG.mouse.screenY - point.y;

    final val = Math.atan2(dy, dx);

    if (asDegrees) {
        return val * 180 / Math.PI;
    }

    return val;
}

function displaySeconds (seconds:Int):String {
    return seconds < 10 ? '0' + seconds : '' + seconds;
}

function toDecimal (time:Float):String {
    return (time + '').split('.')[1].substring(0, 2);
}

function secondsToMinutes (time:Float):String {
    final seconds = Std.int(time);
    final minutes = Math.floor(seconds / 60);
    if (minutes == 0) {
        return displaySeconds(seconds % 60);
    }

    return minutes + ':' + displaySeconds(seconds % 60);
}

function timeToString (time:Float):String {
    return secondsToMinutes(time) + '.' + toDecimal(time);
}

function getScrollFromDir (dir:Dir):IntPoint {
    return switch (dir) {
        case Left: { x: -160, y: 0 };
        case Right: { x: 160, y: 0 };
        case Up: { x: 0, y: -90 };
        case Down: { x: 0, y: 90 };
    }
}

function shuffle<T> (items:Array<T>): Array<T> {
    for (i in 0...items.length) {
        final index = Math.floor(Math.random() * items.length);
        final temp = items[i];
        items[i] = items[index];
        items[index] = temp;
    }

    return items;
}
