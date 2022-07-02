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

        flipX = velocity.x > 0;

        if (!inWorldBounds() && timeAlive > MIN_TIME_ALIVE) {
            kill();
        }
    }

    public function shoot (x:Float, y:Float, vel:IntPoint, acc:IntPoint) {
        final size = { x: 8, y: 8 };

        exists = true;
        alive = true;
        timeAlive = 0.0;
        angle = 0.0;
        setSize(size.x, size.y);
        offset.set(8 - size.x / 2, 8 - size.y / 2);
        setPosition(x, y);
        velocity.set(vel.x, vel.y);
        acceleration.set(acc.x, acc.y);
    }
}
