package actors;

import PlayState;
import flixel.FlxG;
import flixel.FlxObject;
import flixel.FlxSprite;
import flixel.addons.effects.FlxTrail;
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
    static inline final MAX_X_VEL:Int = 90;
    static inline final MAX_Y_VEL:Int = 180;
    static inline final JUMP_VELOCITY:Int = 90;
    static inline final DASH_TIME:Float = 0.125;

    static inline final DASH_BUFFER:Float = 0.1;

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

    var dashPressedTime:Float = DASH_BUFFER;
    public var dashes:Int = 0;
    public var dashing:Bool = false;
    public var dashTime:Float = 0.0;
    public var postDashTime:Float = 0.0;

    public var dead:Bool = false;

    var aimerDegree:Float = 45.0;

    var trail:FlxTrail;

    public var body:FlxSprite;
    public var leftFoot:FlxSprite;
    public var rightFoot:FlxSprite;

    public var leftFootColliding:Bool = false;
    public var rightFootColliding:Bool = false;

    public function new (x:Float, y:Float, scene:PlayState, spritePath:String) {
        super(x, y);
        this.scene = scene;

        loadGraphic(spritePath, true, 16, 16);
        offset.set(5, 3);
        setSize(6, 12);

        body = new FlxSprite();
        body.makeGraphic(6, 8, 0xffff00ff);
        // body.alpha = 0.7;
        body.visible = false;

        leftFoot = new FlxSprite();
        leftFoot.makeGraphic(3, 6, 0xff0000ff);
        // leftFoot.alpha = 0.5;
        leftFoot.visible = false;

        rightFoot = new FlxSprite();
        rightFoot.makeGraphic(3, 6, 0xffff0000);
        // rightFoot.alpha = 0.5;
        rightFoot.visible = false;

        animation.add('stand', [0]);
        animation.add('run', [0, 1, 1, 2, 2], 24);
        animation.add('in-air', [1, 1, 2, 2, 2], 12);
        animation.add('teetering', [3, 4], 4);

        stretchDownSnapper = new Snapper(
            this,
            { 'scale.x': 1, 'scale.y': 1 },
            { 'scale.x': 0.75, 'scale.y': 1.33 },
            0.025
        );

        maxVelocity.set(MAX_X_VEL, MAX_Y_VEL);
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
                    FlxG.sound.play(AssetPaths.choose_low_clip__mp3, 0.05);
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
                maxVelocity.y = MAX_Y_VEL * 2;
                // only strech if we are heading downwards
                if (velocity.y > 0) {
                    stretchDownSnapper.push();
                }
            } else {
                maxVelocity.y = MAX_Y_VEL;
                stretchDownSnapper.pull();
            }

            acceleration.set(lrAcc * MAX_X_VEL * 10, downAcc);

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
                FlxG.sound.play(AssetPaths.choose_jump__mp3, 0.1);
                scene.generateExplosion(midpoint.x, y + height, 'jump');
                jumps++;
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
                velocity.y = -JUMP_VELOCITY;

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
        body.setPosition(x, y);
        leftFoot.setPosition(x, y + 7);
        rightFoot.setPosition(x + 3, y + 7);
    }

    function dash () {
        FlxG.sound.play(AssetPaths.choose_dash__mp3, 0.25);
        final dashVel = FlxVelocity.velocityFromAngle(aimerDegree, scene.skills.dashVel);
        velocity.set(dashVel.x, dashVel.y);
        acceleration.set(0, 0);
        drag.set(0, 0);
        maxVelocity.set(0, 0);
        dashTime = DASH_TIME;
        dashing = true;
        trail = new FlxTrail(this, null, 10, 2, 0.5);
        scene.add(trail);
        elasticity = 0.8;
        dashes++;
    }

    public function stopDash () {
        dashing = false;
        velocity.set(velocity.x, velocity.y / 4);
        maxVelocity.set(MAX_X_VEL, MAX_Y_VEL);
        colorTransform = new ColorTransform();
        if (trail != null) {
            scene.remove(trail);
            trail.destroy();
            trail = null;
        }
        postDashTime = POST_DASH_TIME;
        elasticity = 0;
    }

    public function cancelDash () {
        dashPressedTime = DASH_BUFFER;
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
        if (velocity.x == 0 && velocity.y == 0) {
            if (leftFootColliding && !rightFootColliding) {
                flipX = false;
                animation.play('teetering');
                return;
            }

            if (!leftFootColliding && rightFootColliding) {
                flipX = true;
                animation.play('teetering');
                return;
            }
        }

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
