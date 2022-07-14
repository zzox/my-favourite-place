package objects;

import data.Levels;
import flixel.FlxSprite;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;

class Powerup extends FlxSprite {
    public var type:Powerups;

    public function new (x:Float, y:Float, type:Powerups) {
        super(x, y);

        loadGraphic(AssetPaths.powerups__png, true, 16, 16);
        animation.add(PlusOneDash, [0]);
        animation.add(UnlimitedDashes, [1]);
        animation.play(type);

        FlxTween.tween(this, { y: y + 2 }, 0.5, { type: FlxTweenType.PINGPONG, ease: FlxEase.quadInOut });

        this.type = type;
    }
}
