package actors;

import flixel.tweens.FlxTween;
import flixel.util.FlxTimer;

enum BossFourState {
    Scrolling;
    Attacking;
    Reversing;
}
final attackPositions = [];

// behavior
// scroll speed depends on room
// if final room, we use attack positions
// otherwise we move to a good y poss
    // speed depends on the level
    // if we are hit we set inactive

class BossFour extends Boss {
    static inline final HURT_FRAMES:Float = 3;
    static inline final SHOOT_VEL:Int = 240;

    var state:BossFourState = Scrolling;

    public function new (scene:PlayState) {
        super(scene);

        loadGraphic(AssetPaths.king_boss__png, true, 32, 32);
        offset.set(4, 2);
        setSize(24, 29);

        animation.add('normal', [0]);
        animation.add('mad', [1]);
        animation.add('shoot', [2]);
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

        if (state == Scrolling) {
            final ySpeed = scene.currentRoom * 30;

            if (scene.player.y < y) {
                velocity.y = -ySpeed;
            } else if (scene.player.y > y + 20) {
                velocity.y = ySpeed;
            } else {
                velocity.y = 0;
            }
        }

        if (y < -160 || y > 320) {
            if (state == Reversing) {
                active = false;
            } else {
                startAttack();
            }
        }

        super.update(elapsed);
    }

    override public function enable () {
        active = true;
        startAttack();
    }

    function startAttack () {
        trace('starting attack');
        hurtTime = 0;
        velocity.set(0, 0);
        flipX = x < 80;
        animation.play('normal');

        setPosition(x > 80 ? 168 : -32, scene.screenPoint.y + 30);

        FlxTween.tween(this, { x: x > 80 ? 152 : -16 }, 1, { onComplete:
            (_:FlxTween) -> {
                trace('scrolling');
                state = Scrolling;
            }
        });

        new FlxTimer().start(1 + (3 * (scene.currentRoom - 7)), (_:FlxTimer) -> {
            animation.play('shoot');
            trace('shooting');

            // TODO: if in last level, we shoot three

            final xVel = x > 80 ? -SHOOT_VEL : SHOOT_VEL;
            scene.shoot(
                x + 12,
                y + 18,
                { x: xVel, y: 0 },
                { x: 0, y: 0 }
            );

            new FlxTimer().start(1, (_:FlxTimer) -> {
                animation.play('mad');
            });

            new FlxTimer().start(1.5, (_:FlxTimer) -> {
                trace('flinging');
                velocity.set(xVel, 0);
                state = Attacking;
            });
        });
        // tween, scroll, shoot, sprint
    }

    override function hit () {
        if (scene.currentRoom != 7) {
            // HACK: lol
            hp++;
        }

        super.hit();

        state = Reversing;
        velocity.set(-velocity.x, -velocity.y);
        animation.play('normal');
    }
}
