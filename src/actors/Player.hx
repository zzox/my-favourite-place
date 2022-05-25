package actors;

import PlayState;
import flixel.FlxG;
import flixel.FlxObject;
import flixel.FlxSprite;
import flixel.addons.effects.FlxTrail;
import flixel.math.FlxPoint;
import flixel.math.FlxVelocity;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.util.FlxTimer;
import openfl.geom.ColorTransform;
import util.Snapper;
import util.Utils;

typedef HoldsObj = {
    var left:Float;
    var right:Float;
    var jump:Float;
}
final FLASH_COLORS = [0xff82ce, 0xcc69a4, 0x8cd612];

class Player extends FlxSprite {
    static inline final GRAVITY:Float = 400.0;
    static inline final JUMP_START_TIME:Float = 0.15;
    static inline final JUMP_BUFFER:Float = 0.075;
    static inline final HANG_START_TIME:Float = 0.08;
    static inline final AIR_TIME_BUFFER:Float = 0.05;
    static inline final POST_DASH_TIME:Float = 0.05;

    static inline final DASH_BUFFER:Float = 0.05;

    var scene:PlayState;
    var holds:HoldsObj = {
        left: 0,
        right: 0,
        jump: 0
    };

    var jumping:Bool = false;
    var jumpTime:Float = 0.0;
    var jumpPressedTime:Float = JUMP_BUFFER;
    var jumps:Int = 0;
    var hanging:Bool = false;
    var hangTime:Float = 0.0;
    var hasHung:Bool = false;
    var airTime:Float = 0.0;
    var stretchDownSnapper:Snapper;

    var reloadTime:Float = 0.5;
    var lastShotTime:Float = 0.0;

    var dashes:Int = 0;
    var dashPressedTime:Float = DASH_BUFFER;
    public var dashing:Bool = false;
    public var dashTime:Float = 0.0;
    public var postDashTime:Float = 0.0;

    public var dead:Bool = false;

    var aimerDegree:Float = 45.0;

    var trail:FlxTrail;

    public function new (x:Float, y:Float, scene:PlayState) {
        super(x, y);
        this.scene = scene;

        loadGraphic(AssetPaths.player__png, true, 16, 16);
        offset.set(5, 3);
        setSize(6, 12);

        animation.add('stand', [0]);
        animation.add('stand-shoot', [1]);
        animation.add('run', [0, 2, 2, 3, 3], 24);
        animation.add('in-air', [2, 2, 3, 3, 3], 12);
        animation.add('in-air-shoot', [4]);

        stretchDownSnapper = new Snapper(
            this,
            { 'scale.x': 1, 'scale.y': 1 },
            { 'scale.x': 0.75, 'scale.y': 1.33 },
            0.025
        );

        maxVelocity.set(scene.skills.xVel, scene.skills.yVel);
        highDrag();
    }

    override public function update (elapsed:Float) {
        if (scene.transitioning) {
            return;
        }

        if (dead) {
            super.update(elapsed);
            return;
        }

        var lrAcc = handleInputs(elapsed);
        final touchingFloor = isTouching(FlxObject.DOWN);
        final jumpPressed = FlxG.keys.anyPressed([Z, SPACE, UP, W]);
        final downPressed = FlxG.keys.anyPressed([DOWN, S]);

        // time since jump was last pressed down
        jumpPressedTime += elapsed;
        // time into the jump, how long have we been jumping
        jumpTime -= elapsed;

        // time until we can shoot again.
        lastShotTime -= elapsed;

        dashPressedTime += elapsed;
        dashTime -= elapsed;
        postDashTime -= elapsed;

        if (dashing) {
            colorTransform = new ColorTransform();
            colorTransform.color = FLASH_COLORS[Math.floor(dashTime / 0.01) % FLASH_COLORS.length];

            trail.colorTransform = new ColorTransform();
            trail.colorTransform.color = FLASH_COLORS[Math.floor(dashTime / 0.01) % FLASH_COLORS.length];

            if (dashTime <= 0.0) {
                stopDash();
            }
        } else {
            final midpoint = getMidpoint();
            if (touchingFloor) {
                if (airTime != 0) {
                    scene.generateExplosion(midpoint.x, y + height, 'land');
                }
                airTime = 0;
                highDrag();
                jumps = 0;
                dashes = 0;
            } else {
                // give the first jump away if falling
                if (airTime > AIR_TIME_BUFFER && jumps == 0) {
                    jumps++;
                }
                airTime += elapsed;
                lrAcc = lrAcc * 2 / 3;
                lowDrag();
            }

            var downAcc = GRAVITY;
            // if we are pressing down, we double max velocity and double gravity
            if (downPressed && !touchingFloor) {
                downAcc *= 2;
                maxVelocity.y = scene.skills.yVel * 2;
                // only strech if we are heading downwards
                if (velocity.y > 0) {
                    stretchDownSnapper.push();
                }
            } else {
                maxVelocity.y = scene.skills.yVel;
                stretchDownSnapper.pull();
            }

            acceleration.set(lrAcc * scene.skills.xVel * 10, downAcc);

            // we hang in y=0 velocity space.  Used to make jumps feel more floaty,
            // but also at the end of a dash.
            if (hanging) {
                velocity.y = 0;
                acceleration.y = 0;
                hangTime -= elapsed;
                if (hangTime <= 0 || !jumpPressed) {
                    hanging = false;
                    hasHung = true;
                }
            }

            // if we pressed jump and are touching the floor
            // (or if we are within coyote time/air buffer time)
            if (jumpPressedTime < JUMP_BUFFER && !jumping && scene.skills.jumps > 0 &&
                (jumps < scene.skills.jumps || airTime < AIR_TIME_BUFFER)
            ) {
                jumping = true;
                jumpTime = JUMP_START_TIME;
                scene.generateExplosion(midpoint.x, y + height, 'jump');
                jumps++;
                // jumpSound.play();
            }

            if (!touchingFloor) {
                // at the peak of a jump, trigger a hang, unless the user still isn't pressing jump
                if (velocity.y > 0 && velocity.y < 20 && !hasHung && !hanging && jumpPressed) {
                    hanging = true;
                    hangTime = HANG_START_TIME;
                }
            }

            // if the jumping flag is set, we add the jump velocity
            if (jumping) {
                velocity.y = -scene.skills.jumpVel;

                // if we let go of jump, run out of jump time, or are touching the ground,
                // (and haven't just immediately set the flag) we end the jump
                if (!jumpPressed || jumpTime <= 0 || (touchingFloor && jumpTime != JUMP_START_TIME)) {
                    jumping = false;
                    hasHung = false;
                    jumpTime = 0;
                }
            }

            if (dashPressedTime < DASH_BUFFER && dashes < scene.skills.dashes) {
                dash();
            }
        }

        handleAnimation(touchingFloor);

        super.update(elapsed);
    }

    // TODO: remove
    // function shoot () {
    //     // MD: 250
    //     final knockbackVel = FlxVelocity.velocityFromAngle(aimerDegree + 180, 250);
    //     scene.generateProjectile(this, aimerDegree);
    //     // TODO: remove knockback?
    //     velocity.x += knockbackVel.x;
    //     velocity.y += knockbackVel.y / 4;
    //     // shootTime = projMap[projType].reloadTime;
    // }

    function dash () {
        final dashVel = FlxVelocity.velocityFromAngle(aimerDegree, scene.skills.dashVel);
        velocity.set(dashVel.x, dashVel.y);
        acceleration.set(0, 0);
        drag.set(0, 0);
        maxVelocity.set(0, 0);
        dashTime = scene.skills.dashTime;
        dashing = true;
        trail = new FlxTrail(this, null, 10, 2, 0.5);
        scene.add(trail);
        elasticity = 1;
        dashes++;
    }

    public function stopDash () {
        dashing = false;
        velocity.set(velocity.x, velocity.y / 4);
        maxVelocity.set(scene.skills.xVel, scene.skills.yVel);
        colorTransform = new ColorTransform();
        if (trail != null) {
            scene.remove(trail);
            trail.destroy();
            trail = null;
        }
        postDashTime = POST_DASH_TIME;
        elasticity = 0;
    }

    // checks inputs and updates state.
    // returns left/right velocity
    function handleInputs (elapsed:Float):Float {
        final leftPressed = FlxG.keys.anyPressed([LEFT, A]);
        final rightPressed = FlxG.keys.anyPressed([RIGHT, D]);

        var vel:Float = 0.0;

        if (leftPressed) {
            vel = -1;
            holds.left += elapsed;
        } else {
            holds.left = 0;
        }

        if (rightPressed) {
            vel = 1;
            holds.right += elapsed;
        } else {
            holds.right = 0;
        }

        if (FlxG.keys.anyPressed([UP, W, SPACE])) {
            holds.jump += elapsed;
        } else {
            holds.jump = 0;
        }

        if (leftPressed && rightPressed) {
            if (holds.right > holds.left) {
                vel = -1;
            } else {
                vel = 1;
            }
        }

        final midPoint = getMidpoint();
        midPoint.y -= 4;
        aimerDegree = angleBetweenMouse(midPoint, 2, true);

        if (FlxG.mouse.justPressed || FlxG.mouse.justPressedRight) {
            dashPressedTime = 0;
        }

        // disabled for now?
        // TODO: remove
        // if (FlxG.mouse.pressed && !dashing && lastShotTime < 0) {
        //     shoot();
        //     lastShotTime = reloadTime;
        // }

        // if jump is just pressed, we set the buffer time to 0
        if (FlxG.keys.anyJustPressed([UP, W, SPACE])) {
            jumpPressedTime = 0;
        }

        return vel;
    }

    function highDrag () {
        drag.set(2000, 0);
    }

    function lowDrag () {
        drag.set(1000, 0);
    }

    function handleAnimation (touchingFloor:Bool) {
        if (touchingFloor) {
            if (acceleration.x != 0) {
                animation.play('run');
            } else {
                animation.play('stand');
            }
        } else {
            animation.play('in-air');
        }

        flipX = FlxG.mouse.x > getMidpoint().x;
    }

    public function die () {
        dead = true;
        stopDash();
        animation.pause();
        acceleration.set(0, 0);
        velocity.set(0, 0);
        new FlxTimer().start(0.25, (_:FlxTimer) -> {
            FlxTween.tween(this, { 'scale.x': 0.0 }, 0.25, { ease: FlxEase.backIn });
            FlxTween.tween(
                this,
                { 'scale.y': 2 },
                0.17,
                { ease: FlxEase.quintIn, startDelay: 0.08 }
            );
        });
    }
}
