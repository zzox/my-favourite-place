package actors;

import data.Constants;
import flixel.FlxSprite;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;

enum abstract EnemyType(String) to String {
    var Gremlin;
    var FastGremlin;
    var Bird;
}

class Enemy extends FlxSprite {
    static inline final HURT_FRAMES:Float = 3;

    var scene:PlayState;
    var type:EnemyType;
    var hurtFrame:Int;
    var hurtTime:Float = 0.0;
    public var dead:Bool = false;
    var startingPoint:Point;
    var startingVel:Point;
    var attacking:Bool = false;

    public function new (x:Float, y:Float, scene:PlayState, type:EnemyType, vel:IntPoint) {
        super(x, y);
        startingPoint = { x: x, y: y };
        startingVel = { x: vel.x, y: vel.y };

        loadGraphic(AssetPaths.enemies__png, true, 16, 16);
        offset.set(1, 1);
        setSize(14, 14);

        animation.add(Gremlin, [0, 1], 2);
        animation.add(FastGremlin, [2, 3], 4);
        animation.add(Bird, [4, 4, 5], 4);
        animation.add('$Bird-attack', [6]);

        velocity.set(vel.x, vel.y);

        active = false;
        visible = false;
        this.type = type;
        this.scene = scene;
        animation.play(type);
    }

    override public function update (elapsed:Float) {
        switch (type) {
            case Gremlin:
                if (velocity.x < 0) {
                    if (x < -32) {
                        x += 196;
                    }
                } else if (velocity.x > 0) {
                    if (x > 176) {
                        x -= 196;
                    }
                }
            case FastGremlin:
                if (velocity.x < 0) {
                    if (x < -160) {
                        velocity.x = -velocity.x;
                    }
                } else if (velocity.x > 0) {
                    if (x > 320) {
                        velocity.x = -velocity.x;
                    }
                }
            case Bird:
                if (Math.abs(y - scene.player.y) < 12 && !attacking) {
                    velocity.x = 2 * velocity.x;
                    velocity.y = 0;
                    attacking = true;
                }
                if (velocity.x < 0) {
                    if (x < scene.screenPoint.x - 32) {
                        attacking = false;
                        velocity.set(-startingVel.x, startingVel.y);
                    }
                } else if (velocity.x > 0) {
                    if (x > scene.screenPoint.x + 192) {
                        attacking = false;
                        velocity.set(-startingVel.x, startingVel.y);
                    }
                }
        }

        flipX = velocity.x > 0;
        if (y > startingPoint.y + 90) {
            setPosition(startingPoint.x, startingPoint.y);
            velocity.set(startingVel.x, startingVel.y);
            attacking = false;
        }

        hurtTime -= elapsed;
        if (hurtTime > 0) {
            hurtFrame++;
            visible = Math.floor(hurtFrame / HURT_FRAMES) % 2 != 0;
        } else {
            visible = true;
        }

        if (attacking) {
            animation.play(type + '-attack');
        } else {
            animation.play(type);
        }

        super.update(elapsed);
    }

    public function hit () {
        hurtTime = 1.0;
        hurtFrame = 0;
        die();
    }

    function die () {
        dead = true;
        acceleration.set(0, 0);
        velocity.set(0, 0);
        FlxTween.tween(this, { 'scale.x': 0.0 }, 0.2, { ease: FlxEase.backIn });
        FlxTween.tween(
            this,
            { 'scale.y': 2 },
            0.14,
            { ease: FlxEase.quintIn, startDelay: 0.06 }
        );
        scene.enemyDie();
    }
}
