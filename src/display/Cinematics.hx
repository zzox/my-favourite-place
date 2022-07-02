package display;

import data.Constants;
import flixel.FlxSprite;
import flixel.tweens.FlxTween;
import flixel.util.FlxTimer;

typedef AnimData = {
    var name:String;
    var frames:Array<Int>;
    var speed:Int;
}

class CinematicSprite extends FlxSprite {
    public function new (start:IntPoint, graphic:String, anims:Array<AnimData>) {
        super(start.x, start.y);

        final size = graphic == AssetPaths.king_boss__png ? { x: 32, y: 32 } : { x: 16, y: 16 };

        loadGraphic(graphic, true, size.x, size.y);

        for (anim in anims) {
            animation.add(anim.name, anim.frames, anim.speed);
        }
    }
}

// TODO: needed?
function runTimer (callback:Void -> Void, time:Float) {
    new FlxTimer().start(time, (_:FlxTimer) -> {
        callback();
    });
}

function runUpCinematic (scene:PlayState, callback:Void -> Void) {
    final king = new CinematicSprite(
        { x: -32, y: -620 },
        AssetPaths.king_boss__png,
        [{ name: 'play', frames: [1], speed: 1 }]
    );
    king.animation.play('play');
    king.flipX = true;
    scene.add(king);

    FlxTween.tween(king, { x: 160 }, 3, {
        onComplete: (_:FlxTween) -> {
            callback();
        },
        startDelay: 3
    });
}

function runOverCinematic (scene:PlayState, callback:Void -> Void) {
    callback();
}
