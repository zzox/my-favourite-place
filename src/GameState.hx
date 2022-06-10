import flixel.FlxState;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;

class GameState extends FlxState {
    var cameraXScale:Float = 0.0;
    var cameraYScale:Float = 0.0;

    override public function create () {
        super.create();

        camera.setScale(0, 0);
        FlxTween.tween(this, { cameraXScale: 1.0 }, 0.5, { ease: FlxEase.circIn });
        FlxTween.tween(this, { cameraYScale: 1.0 }, 0.75, { ease: FlxEase.quintIn });
    }

    override public function update (elapsed:Float) {
        super.update(elapsed);

        if (camera.scaleX != 1.0 || camera.scaleY != 1.0 || cameraXScale != 1.0 || cameraYScale != 1.0) {
            camera.setScale(cameraXScale, cameraYScale);
        }
    }

    function fadeOut (callback:Void -> Void) {
        FlxTween.tween(this, { cameraXScale: 0 }, 0.75, { ease: FlxEase.circIn, onComplete:
            (_:FlxTween) -> {
                callback();
            }
        });
        FlxTween.tween(this, { cameraYScale: 0 }, 0.5, { ease: FlxEase.quintIn, onComplete:
            (_:FlxTween) -> {
                callback();
            }
        });
    }
}
