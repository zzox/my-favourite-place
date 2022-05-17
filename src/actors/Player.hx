package actors;

import PlayState;
import flixel.FlxG;
import flixel.FlxObject;
import flixel.FlxSprite;
import flixel.math.FlxPoint;
import util.Snapper;

typedef HoldsObj = {
    var left:Float;
    var right:Float;
    var up:Float; // remove?
    var down:Float; // remove?
    var jump:Float;
}

class Player extends FlxSprite {
    static inline final RUN_ACCELERATION:Float = 800.0;
    static inline final GRAVITY:Float = 400.0;
    static inline final JUMP_START_TIME:Float = 0.15;
    static inline final JUMP_VELOCITY:Float = 90.0;
    static inline final JUMP_BUFFER_WINDOW:Float = 0.075;
    static inline final HANG_START_TIME:Float = 0.08;
    static inline final AIR_TIME_BUFFER:Float = 0.1;
    static final MAX_VELOCITY:FlxPoint = new FlxPoint(90, 180);

    var scene:PlayState;
    var holds:HoldsObj;

    var jumping:Bool;
    var jumpTime:Float;
    var jumpPressedTime:Float;
    var hanging:Bool;
    var hangTime:Float;
    var hasHung:Bool;
    var stretchDownSnapper:Snapper;
    var airTime:Float;
    public var dead:Bool;

    public function new (x:Float, y:Float, scene:PlayState) {
        super(x, y);
        this.scene = scene;

        loadGraphic(AssetPaths.player__png, true, 16, 16);
        offset.set(5, 3);
        setSize(6, 12);

        animation.add('stand', [0]);
        animation.add('stand-shoot', [1]);
        animation.add('run', [2, 2, 3, 3, 0], 24);
        animation.add('in-air', [2, 2, 3, 3, 3], 12);
        animation.add('in-air-shoot', [4]);

        holds = {
            left: 0,
            right: 0,
            up: 0,
            down: 0,
            jump: 0
        };

        hanging = false;
        hasHung = false;
        hangTime = 0;
        jumping = false;
        jumpTime = 0;
        jumpPressedTime = JUMP_BUFFER_WINDOW;
        airTime = 0;
        dead = false;

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
        // if (scene.transitioning) {
        //     return;
        // }

        final touchingFloor = isTouching(FlxObject.DOWN);
        var lrAcc = handleInputs(elapsed);

        var downPressed = FlxG.keys.anyPressed([DOWN, S]);

        if (touchingFloor) {
            airTime = 0;
            highDrag();
        } else {
            airTime += elapsed;
            lrAcc = lrAcc * 2 / 3;
            lowDrag();
        }

        // time since jump was last pressed down
        jumpPressedTime += elapsed;
        // time into the jump, how long have we been jumping
        jumpTime -= elapsed;

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
            if (hangTime <= 0) {
                hanging = false;
                hasHung = true;
            }
        }

        // if we pressed jump and are touching the floor
        // (or if we are within coyote time/air buffer time)
        if (jumpPressedTime < JUMP_BUFFER_WINDOW && airTime < AIR_TIME_BUFFER && !jumping) {
            jumping = true;
            jumpTime = JUMP_START_TIME;
            // jumpSound.play();
        }

        if (!touchingFloor) {
            // at the peak of a jump, trigger a hang
            if (velocity.y > 0 && !hasHung && !hanging) {
                hanging = true;
                hangTime = HANG_START_TIME;
            }
        }

        // if the jumping flag is set, we add the jump velocity
        if (jumping) {
            velocity.y = -JUMP_VELOCITY;

            // if we let go of jump, run out of jump time, or are touching the ground,
            // (and haven't just immediately set the flag) we end the jump
            if (!FlxG.keys.anyPressed([Z, SPACE, UP, W]) || jumpTime <= 0 || (touchingFloor && jumpTime != JUMP_START_TIME)) {
                jumping = false;
                hasHung = false;
                jumpTime = 0;
            }
        }

        handleAnimation(touchingFloor);

        super.update(elapsed);
    }

    // checks inputs and updates state.
    // returns left/right velocity
    function handleInputs (elapsed:Float):Float {
        var vel:Float = 0.0;
        if (FlxG.keys.anyPressed([LEFT, A])) {
            vel = -1;
            holds.left += elapsed;
        } else {
            holds.left = 0;
        }

        if (FlxG.keys.anyPressed([RIGHT, D])) {
            vel = 1;
            holds.right += elapsed;
        } else {
            holds.right = 0;
        }

        if (FlxG.keys.anyPressed([Z, SPACE, UP])) {
            holds.jump += elapsed;
        } else {
            holds.jump = 0;
        }

        if (FlxG.keys.anyPressed([LEFT, A]) && FlxG.keys.anyPressed([RIGHT, D])) {
            if (holds.right > holds.left) {
                vel = -1;
            } else {
                vel = 1;
            }
        }

        // if jump is just pressed, we set the buffer time to 0
        if (FlxG.keys.anyJustPressed([Z, SPACE, UP, W])) {
            jumpPressedTime = 0;
        }

        return vel;
    }

    function addMaxVel () {
        maxVelocity = MAX_VELOCITY;
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
