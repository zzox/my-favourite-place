package actors;

import data.Constants;
import flixel.tweens.FlxTween;
import flixel.util.FlxTimer;

enum BossThreeState {
    Attacking;
    Reversing;
}
// final attackPositions = [
//     { startPos: { x: -32, y: 728 }, dir: Right },
//     { startPos: { x: 160, y: 728 }, dir: Left },
//     { startPos: { x: -32, y: 696 }, dir: Right },
//     { startPos: { x: 160, y: 696 }, dir: Left },
// ];
//

// quick appear and attack.
// six different positions.
// timer differs throughout the hit process.

class BossThree extends Boss {
    static inline final HURT_FRAMES:Float = 3;

    var currentChargeDirection:Dir;
    var state:BossThreeState;

    public function new (scene:PlayState) {
        super(scene);

        loadGraphic(AssetPaths.king_boss_blue__png, true, 32, 32);
        offset.set(4, 1);
        setSize(24, 28);

        animation.add('normal', [0]);
        animation.add('mad', [1]);
    }

    override public function update (elapsed:Float) {
        if (state != Reversing) {
            if (velocity.x < 0 && flipX) {
                flipX = false;
            }

            if (velocity.x > 0 && !flipX) {
                flipX = true;
            }
        }

        // if (x < -160 || x > 320) {
        //     startAttack();
        // }

        super.update(elapsed);
    }

    function startAttack () {
        // animation.play('grin');
        // hurtTime = 0;
        // velocity.set(0, 0);
        // final attackChoice = attackPositions[Math.floor(Math.random() * attackPositions.length)];

        // flipX = attackChoice.dir == Right;
        // setPosition(attackChoice.startPos.x, attackChoice.startPos.y);

        // final chargeDelay = hp > 4 ? 1.0 : hp % 2 == 0 ? 2.0 : 0.5;

        state = Attacking;
        // FlxTween.tween(
        //     this,
        //     { x: x + (flipX ? 12 : -12) },
        //     hp > 4 ? 1.0 : 0.5,
        //     { onComplete:
        //         (_:FlxTween) -> {
        //             new FlxTimer().start(chargeDelay, (_:FlxTimer) -> {
        //                 animation.play('chomp');
        //                 velocity.set(attackChoice.vel.x, attackChoice.vel.y);
        //             });
        //         }
        //     }
        // );
    }

    override public function hit () {
        super.hit();

        state = Reversing;
        if (hp > 0) {
            velocity.set(-velocity.x, -velocity.y);
            animation.play('normal');
        }
    }
}
