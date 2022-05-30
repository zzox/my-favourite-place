package util;

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

function toFixed (places:Int, num:Float):String {
    final str = (num + '');
    final i = str.indexOf('.');
    if (i == -1) return str;
    return str.substring(0, i + places + 1);
}
