package actors;

import data.Constants;
import flixel.FlxSprite;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.util.FlxTimer;

enum BossState {
    Attacking;
    Reversing;
}
final attackPositions = [
    { startPos: { x: -32, y: 728 }, vel: { x: 240, y: 0 }, dir: Right },
    { startPos: { x: 160, y: 728 }, vel: { x: -240, y: 0 }, dir: Left },
    { startPos: { x: -32, y: 696 }, vel: { x: 240, y: 60 }, dir: Right },
    { startPos: { x: 160, y: 696 }, vel: { x: -240, y: 60 }, dir: Left },
];

class Boss extends FlxSprite {
    static inline final HURT_FRAMES:Float = 3;

    var scene:PlayState;
    var hurtFrame:Int;
    public var hurtTime:Float = 0.0;
    public var dead:Bool = false;
    var hp:Int = 8;
    var currentChargeDirection:Dir;
    var state:BossState;

    public function new (scene:PlayState) {
        super(1000, 1000);

        loadGraphic(AssetPaths.bosses__png, true, 32, 32);
        offset.set(4, 1);
        setSize(24, 28);

        animation.add('grin', [0]);
        animation.add('chomp', [0, 0, 0, 1, 1, 1, 1, 1], 24);

        active = false;
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

        if (state != Reversing) {
            if (velocity.x < 0 && flipX) {
                flipX = false;
            }

            if (velocity.x > 0 && !flipX) {
                flipX = true;
            }
        }

        if (x < -160 || x > 320) {
            startAttack();
        }

        super.update(elapsed);
    }

    function startAttack () {
        hurtTime = 0;
        velocity.set(0, 0);
        final attackChoice = attackPositions[Math.floor(Math.random() * attackPositions.length)];

        flipX = attackChoice.dir == Right;
        setPosition(attackChoice.startPos.x, attackChoice.startPos.y);

        final chargeDelay = hp > 4 ? 1.0 : Math.random() < 0.5 ? 0.5 : 2.0;

        state = Attacking;
        FlxTween.tween(
            this,
            { x: x + (flipX ? 12 : -12) },
            hp > 4 ? 1.0 : 0.5,
            { onComplete:
                (_:FlxTween) -> {
                    new FlxTimer().start(chargeDelay, (_:FlxTimer) -> {
                        animation.play('chomp');
                        velocity.set(attackChoice.vel.x, attackChoice.vel.y);
                    });
                }
            }
        );
    }

    public function hit () {
        hurtTime = 3.0;
        hurtFrame = 0;
        hp--;
        state = Reversing;

        if (hp <= 0) {
            die();
        } else {
            velocity.set(-velocity.x, 0);
            animation.play('grin');
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
