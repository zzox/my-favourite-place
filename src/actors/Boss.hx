package actors;

import flixel.FlxSprite;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;

class Boss extends FlxSprite {
    static inline final HURT_FRAMES:Float = 3;

    var scene:PlayState;
    var hurtFrame:Int;
    public var hurtTime:Float = 0.0;
    public var dead:Bool = false;
    var hp:Int = 8;

    public function new (scene:PlayState) {
        super(1000, 1000);

        active = false;
        visible = false;
        this.scene = scene;
    }

    override public function update (elapsed:Float) {
        hurtTime -= elapsed;
        if (hurtTime > 0) {
            hurtFrame++;
            visible = Math.floor(hurtFrame / HURT_FRAMES) % 2 != 0;
        } else {
            visible = true;
        }

        super.update(elapsed);
    }

    public function hit () {
        hurtTime = 3.0;
        hurtFrame = 0;
        hp--;

        if (hp <= 0) {
            die();
        }
    }

    function die () {
        dead = true;
        velocity.set(0, 0);
        // TODO: generate explosions
        FlxTween.tween(this, { 'scale.x': 0.0 }, 0.2, { ease: FlxEase.backIn });
        FlxTween.tween(
            this,
            { 'scale.y': 2 },
            0.14,
            { ease: FlxEase.quintIn, startDelay: 0.06 }
        );
        scene.bossDie();
    }
}