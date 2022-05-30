package objects;

import flixel.FlxSprite;
import flixel.math.FlxVelocity;

class Projectile extends FlxSprite {
    public function new () {
        super(0, 0);
        // loadGraphic(AssetPaths.bullets__png, true, 16, 16);
        animation.add('small', [0]);
    }

    override public function update (elapsed:Float) {
        super.update(elapsed);
        if (!inWorldBounds()) {
            kill();
        }
    }

    public function shoot (x:Float, y:Float, angle:Float, shootVel:Float) {
        // MD: ???
        final size = { x: 4, y: 2 };

        exists = true;
        alive = true; // needed?
        this.angle = angle;
        setSize(size.x, size.y);
        // TODO: change if bigger than 16x16 sprite sizes
        offset.set(8 - size.x / 2, 8 - size.y / 2);
        setPosition(x, y);
        final vel = FlxVelocity.velocityFromAngle(angle, shootVel);
        velocity.set(vel.x, vel.y);
    }
}
