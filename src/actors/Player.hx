package actors;

import PlayState;
import flixel.FlxG;
import flixel.FlxObject;
import flixel.FlxSprite;
import flixel.math.FlxPoint;
import flixel.math.FlxVelocity;
import util.Snapper;
import util.Utils;

typedef HoldsObj = {
    var left:Float;
    var right:Float;
    var jump:Float;
}

class Player extends FlxSprite {
    static inline final RUN_ACCELERATION:Float = 800.0;
    static inline final GRAVITY:Float = 400.0;
    static inline final JUMP_START_TIME:Float = 0.15;
    static inline final JUMP_VELOCITY:Float = 90.0;
    static inline final JUMP_BUFFER:Float = 0.075;
    static inline final HANG_START_TIME:Float = 0.08;
    static inline final AIR_TIME_BUFFER:Float = 0.1;
    static final MAX_VELOCITY:FlxPoint = new FlxPoint(90, 180);

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
    var hanging:Bool = false;
    var hangTime:Float = 0.0;
    var hasHung:Bool = false;
    var airTime:Float = 0.0;
    var stretchDownSnapper:Snapper;
    var reloadTime:Float = 0.5;
    var lastShotTime:Float = 0.0;
    var dashPressedTime:Float = DASH_BUFFER;

    public var dead:Bool = false;

    var aimerDegree:Float = 45.0;

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

        maxVelocity.set(MAX_VELOCITY.x, MAX_VELOCITY.y);
        highDrag();
    }

    override public function update (elapsed:Float) {
        if (scene.transitioning) {
            return;
        }

        if (dead) {
            super.update(elapsed);
            trace('dead');
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

        if (touchingFloor) {
            airTime = 0;
            highDrag();
        } else {
            airTime += elapsed;
            lrAcc = lrAcc * 2 / 3;
            lowDrag();
        }

        var downAcc = GRAVITY;
        // if we are pressing down, we double max velocity and double gravity
        if (downPressed && !touchingFloor) {
            downAcc *= 2;
            maxVelocity.y = MAX_VELOCITY.y * 2;
            // only strech if we are heading downwards
            if (velocity.y > 0) {
                stretchDownSnapper.push();
            }
        } else {
            maxVelocity.y = MAX_VELOCITY.y;
            stretchDownSnapper.pull();
        }

        acceleration.set(lrAcc * RUN_ACCELERATION, downAcc);

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
        if (jumpPressedTime < JUMP_BUFFER && airTime < AIR_TIME_BUFFER && !jumping) {
            jumping = true;
            jumpTime = JUMP_START_TIME;
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
            velocity.y = -JUMP_VELOCITY;

            // if we let go of jump, run out of jump time, or are touching the ground,
            // (and haven't just immediately set the flag) we end the jump
            if (!jumpPressed || jumpTime <= 0 || (touchingFloor && jumpTime != JUMP_START_TIME)) {
                jumping = false;
                hasHung = false;
                jumpTime = 0;
            }
        }

        if (dashPressedTime < DASH_BUFFER) {
            dash();
        }

        handleAnimation(touchingFloor);

        super.update(elapsed);
    }

    function shoot () {
        // MD: 100
        final knockbackVel = FlxVelocity.velocityFromAngle(aimerDegree + 180, 100);
        trace('kbvel $knockbackVel');
        scene.generateProjectile(this, aimerDegree);
        final muzzleFlash = FlxVelocity.velocityFromAngle(aimerDegree, 2);
        // scene.makeExplosion(
        //     new FlxPoint(
        //         getMidpoint().x + muzzleFlash.x, getMidpoint().y + muzzleFlash.y
        //     ),
        //     'tiny' // small ring
        // );
        // velocity.x += knockbackVel.x;
        // velocity.y += knockbackVel.y;
        // shootTime = projMap[projType].reloadTime;
    }

    function dash () {
        trace('dashing!!');
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

        aimerDegree = angleBetweenMouse(getMidpoint(), 2, true);

        var dashing = false;
        if (FlxG.mouse.justPressedRight || FlxG.mouse.justPressed && FlxG.keys.pressed.CONTROL) {
            dashPressedTime = 0;
            dashing = true;
        }

        if (FlxG.mouse.pressed && !dashing && lastShotTime < 0) {
            shoot();
            lastShotTime = reloadTime;
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
        if (touchingFloor) {
            if (acceleration.x != 0) {
                animation.play('run');
            } else {
                animation.play('stand');
            }
        } else {
            animation.play('in-air');
        }

        if (acceleration.x < 0 && flipX) {
            flipX = false;
        }

        if (acceleration.x > 0 && !flipX) {
            flipX = true;
        }
    }
}
