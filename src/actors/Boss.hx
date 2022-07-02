package actors;

import flixel.FlxG;
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

        FlxG.sound.play(AssetPaths.choose_enemy_hit__mp3, 0.5);

        if (hp <= 0) {
            die();
        }
    }

    function die () {
        dead = true;
        velocity.set(0, 0);
        scene.bossDie();
    }

    public function enable () {}

    public function cancel () {}
}