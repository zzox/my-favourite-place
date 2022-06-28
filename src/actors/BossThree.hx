package actors;

import data.Constants;
import flixel.FlxG;
import flixel.math.FlxPoint;
import flixel.math.FlxVelocity;
import flixel.tweens.FlxTween;
import flixel.util.FlxTimer;
import util.Utils;

enum BossThreeState {
    Attacking;
    Reversing;
}
final attackPositions = shuffle([
    { startPos: { x: -52, y: -616 }, attackPos: { x: -20, y: -616 }, dir: Right },
    { startPos: { x: -52, y: -648 }, attackPos: { x: -20, y: -648 }, dir: Right },
    { startPos: { x: 188, y: -648 }, attackPos: { x: 156, y: -648 }, dir: Left },
    { startPos: { x: 188, y: -616 }, attackPos: { x: 156, y: -616 }, dir: Left },
    { startPos: { x: 16, y: -720 }, attackPos: { x: 16, y: -688 }, dir: Right },
    { startPos: { x: 112, y: -720 }, attackPos: { x: 112, y: -688 }, dir: Left },
    { startPos: { x: 48, y: -720 }, attackPos: { x: 48, y: -688 }, dir: Right },
    { startPos: { x: 80, y: -720 }, attackPos: { x: 80, y: -688 }, dir: Left },
]);

class BossThree extends Boss {
    var currentAttackPos:Int = 0;
    var currentChargeDirection:Dir;
    var state:BossThreeState;
    var fakeIndex:Int = 0;

    public function new (scene:PlayState) {
        super(scene);

        loadGraphic(AssetPaths.king_boss_blue__png, true, 32, 32);
        offset.set(4, 2);
        setSize(24, 29);

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

        if (x < -80 || x > 240 || y < -752 || y > -480) {
            startAttack();
        }

        super.update(elapsed);
    }

    function startAttack () {
        var fakeAttack = false;
        if (hp <= 4) {
            if (fakeIndex == 0) {
                fakeAttack = true;
            }

            fakeIndex = ++fakeIndex % 3;
        }

        hurtTime = 0;
        velocity.set(0, 0);
        final attackChoice = attackPositions[currentAttackPos];
        flipX = attackChoice.dir == Right;
        animation.play('normal');

        state = Attacking;
        setPosition(attackChoice.startPos.x, attackChoice.startPos.y);

        final startDelay = (hp / 8) + 0.25;

        FlxTween.tween(
            this,
            { x: attackChoice.attackPos.x, y: attackChoice.attackPos.y },
            hp > 4 ? 1.0 : 0.5,
            { onComplete:
                (_:FlxTween) -> {
                    new FlxTimer().start(startDelay - 0.25, (_:FlxTimer) -> {
                        animation.play('mad');
                    });
                    new FlxTimer().start(startDelay, (_:FlxTimer) -> {
                        if (fakeAttack) {
                            FlxTween.tween(
                                this,
                                { x: attackChoice.startPos.x, y: attackChoice.startPos.y },
                                hp > 4 ? 1.0 : 0.5,
                                {
                                    onComplete: (_:FlxTween) -> {
                                        startAttack();
                                    }
                                }
                            );
                        } else {
                            FlxG.sound.play(AssetPaths.choose_land__mp3, 0.2);
                            FlxVelocity.moveTowardsPoint(
                                this,
                                new FlxPoint(scene.player.x, scene.player.y),
                                240
                            );
                        }
                    });
                }
            }
        );

        currentAttackPos = ++currentAttackPos % 8;
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
