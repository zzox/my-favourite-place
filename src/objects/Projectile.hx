package objects;

import data.Constants;
import flixel.FlxSprite;
import flixel.math.FlxVelocity;

class Projectile extends FlxSprite {
    static inline final MIN_TIME_ALIVE:Float = 1.0;
    var timeAlive:Float = 0.0;

    public function new () {
        super(0, 0);
        loadGraphic(AssetPaths.projectiles__png, true, 16, 16);
        animation.add('spin', [0, 1, 2], 16);
        animation.play('spin');
    }

    override public function update (elapsed:Float) {
        super.update(elapsed);
        timeAlive += elapsed;
        if (!inWorldBounds() && timeAlive > MIN_TIME_ALIVE) {
            kill();
        }
    }

    public function shoot (x:Float, y:Float, vel:IntPoint, acc:IntPoint) {
        // MD: ???
        final size = { x: 8, y: 8 };

        exists = true;
        alive = true; // needed?
        timeAlive = 0.0;
        angle = 0.0;
        setSize(size.x, size.y);
        // TODO: change if bigger than 16x16 sprite sizes
        offset.set(8 - size.x / 2, 8 - size.y / 2);
        setPosition(x, y);
        velocity.set(vel.x, vel.y);
        acceleration.set(acc.x, acc.y);
    }

    public function shootAngled (x:Float, y:Float, angle:Float, shootVel:Float) {
        // MD: ???
        final size = { x: 4, y: 2 };

        exists = true;
        alive = true; // needed?
        timeAlive = 0.0;
        this.angle = angle;
        setSize(size.x, size.y);
        // TODO: change if bigger than 16x16 sprite sizes
        offset.set(8 - size.x / 2, 8 - size.y / 2);
        setPosition(x, y);
        final vel = FlxVelocity.velocityFromAngle(angle, shootVel);
        velocity.set(vel.x, vel.y);
    }
}
