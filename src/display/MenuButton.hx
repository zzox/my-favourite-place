package display;

import data.Levels.Worlds;
import display.Font;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.text.FlxBitmapText;
import flixel.text.FlxText.FlxTextAlign;

class MenuButton extends FlxSprite {
    static inline final TEXT_COLOR:Int = 0xff0d2030;
    static inline final PRESSED_COLOR:Int = 0xffa8a8a8;

    public var overlapping:Bool;
    public var world:Worlds;
    public var text:FlxBitmapText;
    var pressed:Bool = false;
    var callback:Worlds -> Void;

    public function new (x:Int, y:Int, num:Int, world:Worlds, callback:Worlds -> Void) {
        super(x, y);

        this.world = world;
        this.callback = callback;

        loadGraphic(AssetPaths.menu_button__png, true, 60, 16);
        animation.add('normal', [0]);
        animation.add('hover', [1]);
        animation.add('down', [2]);

        text = makeText('$num: $world', { x: x, y: y + 1 });
        text.autoSize = false;
        text.width = text.fieldWidth = 60;
        text.alignment = FlxTextAlign.CENTER;
        text.letterSpacing = -1;
        text.color = TEXT_COLOR;
    }

    override public function update (elapsed:Float) {
        super.update(elapsed);

        overlapping = FlxG.mouse.overlaps(this);
        if (overlapping) {
            animation.play('hover');
            text.color = PRESSED_COLOR;

            if (pressed) {
                animation.play('down');
                if (!FlxG.mouse.pressed) {
                    callback(world);
                }
            }

            if (FlxG.mouse.justPressed) {
                pressed = true;
            }
        } else {
            text.color = TEXT_COLOR;
            animation.play('normal');
        }

        if (!FlxG.mouse.pressed) {
            pressed = false;
        }
    }
}
