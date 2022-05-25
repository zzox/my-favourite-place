package display;

import flixel.FlxG;
import flixel.FlxSprite;
import haxe.Constraints.Function;

enum ButtonType {
    Retry;
    Quit;
}

// TODO: convert to group for dynamic buttons?
// TODO: focus from gamepad
class Button extends FlxSprite {
    var callback:Function;
    var pressed:Bool = false;

    public function new (x:Int, y:Int, type:ButtonType, callback:Function) {
        super(x, y);

        loadGraphic(AssetPaths.buttons__png, true, 33, 13);
        if (type == Retry) {
            animation.add('normal', [0]);
            animation.add('hover', [1]);
            animation.add('down', [2]);
        } else {
            animation.add('normal', [3]);
            animation.add('hover', [4]);
            animation.add('down', [5]);
        }

        this.callback = callback;
    }

    override public function update (elapsed:Float) {
        super.update(elapsed);

        if (FlxG.mouse.overlaps(this)) {
            animation.play('hover');
            if (pressed) {
                animation.play('down');
                if (!FlxG.mouse.pressed) {
                    click();
                }
            }

            if (FlxG.mouse.justPressed) {
                pressed = true;
            }
        } else {
            animation.play('normal');
        }

        if (!FlxG.mouse.pressed) {
            pressed = false;
        }
    }

    function click () {
        callback();
    }
}
