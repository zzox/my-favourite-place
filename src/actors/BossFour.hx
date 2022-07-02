package actors;

import flixel.tweens.FlxTween;
import flixel.util.FlxTimer;

enum BossFourState {
    Scrolling;
    Attacking;
    Reversing;
    Waiting;
}
final attackPositions = [];

class BossFour extends Boss {
    static inline final HURT_FRAMES:Float = 3;
    static inline final SHOOT_VEL:Int = 180;
    static inline final ATTACK_VEL:Int = 300;

    var state:BossFourState = Scrolling;
    var timers:Array<FlxTimer> = [];

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

            if (scene.player.y - 4 < y) {
                velocity.y = -ySpeed;
            } else if (scene.player.y > y + 20 && y < scene.screenPoint.y + 60 && !scene.transitioning) {
                velocity.y = ySpeed;
            } else {
                velocity.y = 0;
            }
        }

        if (x < -160 || x > 320) {
            if (state == Reversing) {
                if (scene.currentRoom == 7) {
                    startAttack();
                } else {
                    active = false;
                }
            } else if (state != Waiting) {
                startAttack();
            }
        }

        super.update(elapsed);
    }

    override public function enable () {
        active = true;
        startAttack();
    }

    override public function cancel () {
        for (t in timers) {
            t.cancel();
        }
    }

    function startAttack () {
        state = Waiting;
        hurtTime = 0;
        velocity.set(0, 0);
        flipX = x < 80;
        animation.play('normal');

        setPosition(x > 80 ? 168 : -32, scene.screenPoint.y + 30);

        FlxTween.tween(this, { x: x > 80 ? 156 : -20 }, 0.5, { onComplete:
            (_:FlxTween) -> {
                state = Scrolling;
            }
        });

        timers[0] = new FlxTimer().start(0.75 + (3 * (1 - (scene.currentRoom / 7))), (_:FlxTimer) -> {
            velocity.set(0, 0);
            animation.play('shoot');
            state = Attacking;

            final xVel = x > 80 ? -SHOOT_VEL : SHOOT_VEL;
            timers[1] = new FlxTimer().start(0.5, (_:FlxTimer) -> {
                if (scene.currentRoom == 7) {
                    if (hp % 2 == 0) {
                        scene.shoot(
                            x + 12,
                            y + 18,
                            { x: xVel, y: 0 },
                            { x: 0, y: 0 }
                        );

                        new FlxTimer().start(0.2, (_:FlxTimer) -> {
                            scene.shoot(
                                x + 12,
                                y + 18,
                                { x: xVel, y: 0 },
                                { x: 0, y: 0 }
                            );
                        });

                        if (hp <= 4) {
                            new FlxTimer().start(0.4, (_:FlxTimer) -> {
                                scene.shoot(
                                    x + 12,
                                    y + 18,
                                    { x: xVel, y: 0 },
                                    { x: 0, y: 0 }
                                );
                            });
                        }
                    } else {
                        scene.shoot(
                            x + 12,
                            y + 18,
                            { x: xVel, y: hp <= 4 ? 45 : 30 },
                            { x: 0, y: 0 }
                        );
                        scene.shoot(
                            x + 12,
                            y + 18,
                            { x: xVel, y: hp <= 4 ? -45 : -30 },
                            { x: 0, y: 0 }
                        );
                        if (hp <= 4) {
                            scene.shoot(
                                x + 12,
                                y + 18,
                                { x: xVel, y: 0 },
                                { x: 0, y: 0 }
                            );
                        }
                    }
                } else {
                    scene.shoot(
                        x + 12,
                        y + 18,
                        { x: xVel, y: 0 },
                        { x: 0, y: 0 }
                    );
                }
            });

            timers[2] = new FlxTimer().start(1.0, (_:FlxTimer) -> {
                animation.play('mad');
            });

            timers[3] = new FlxTimer().start(1.5, (_:FlxTimer) -> {
                velocity.set(x > 80 ? -ATTACK_VEL : ATTACK_VEL, 0);
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
