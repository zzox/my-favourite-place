import data.Game;
import display.CrtShader;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.FlxState;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import openfl.filters.ShaderFilter;

class GameState extends FlxState {
    var cameraXScale:Float = 0.0;
    var cameraYScale:Float = 0.0;
    var aimer:FlxSprite;
    var crtShader:CrtShader;

    override public function create () {
        super.create();

        // FlxG.mouse.visible = false;
        // FlxG.mouse.useSystemCursor = true;

        camera.setScale(0, 0);
        FlxTween.tween(this, { cameraXScale: 1.0 }, 0.5, { ease: FlxEase.circIn });
        FlxTween.tween(this, { cameraYScale: 1.0 }, 0.75, { ease: FlxEase.quintIn });

        if (Game.inst.options.crtFilter) {
            crtShader = new CrtShader();
            FlxG.camera.setFilters([new ShaderFilter(crtShader)]);
        }
    }

    override public function update (elapsed:Float) {
        if (aimer != null) {
            aimer.setPosition(
                FlxG.camera.scroll.x + FlxG.mouse.screenX,
                FlxG.camera.scroll.y + FlxG.mouse.screenY
            );
        }

        super.update(elapsed);

        if (FlxG.keys.justPressed.P) {
            if (crtShader != null) {
                crtShader = null;
                FlxG.camera.setFilters([]);
                Game.inst.options.crtFilter = false;
            } else {
                crtShader = new CrtShader();
                FlxG.camera.setFilters([new ShaderFilter(crtShader)]);
                Game.inst.options.crtFilter = true;
            }
        }

        if (camera.scaleX != 1.0 || camera.scaleY != 1.0 || cameraXScale != 1.0 || cameraYScale != 1.0) {
            camera.setScale(cameraXScale, cameraYScale);
        }

        if (FlxG.mouse.justPressed && aimer != null) {
            final aimerAnim = new FlxSprite(0, 0);
            aimerAnim.loadGraphic(AssetPaths.aimer_anim__png, true, 7, 7);
            aimerAnim.animation.add('play', [0, 1, 2, 3], 24, false);
            aimerAnim.scrollFactor.set(0, 0);
            aimerAnim.animation.finishCallback = (_:String) -> {
                aimerAnim.destroy();
            };
            add(aimerAnim);
            aimerAnim.animation.play('play');
            final pos = aimer.getScreenPosition();
            aimerAnim.setPosition(pos.x - 3, pos.y - 3);
        }
    }

    // so the child classes can add the aimer after other items
    function addAimer () {
        aimer = new FlxSprite(0, 0, AssetPaths.aimer__png);
        aimer.offset.set(4, 4);
        aimer.setSize(1, 1);
        add(aimer);
    }

    function fadeOut (callback:Void -> Void) {
        FlxTween.tween(this, { cameraXScale: 0 }, 0.75, { ease: FlxEase.circIn, onComplete:
            (_:FlxTween) -> {
                callback();
            }
        });
        FlxTween.tween(this, { cameraYScale: 0 }, 0.5, { ease: FlxEase.quintIn });
    }
}
