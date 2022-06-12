package actors;

import data.Constants;

class Shooter {
    public var active:Bool = false;
    var shootTime:Float;
    var nextShootTime:Float;
    var pos:IntPoint;
    var shootVel:IntPoint;
    var shootAcc:IntPoint;
    var scene:PlayState;

    public function new (
        shootTime:Float,
        offset:Float,
        pos:IntPoint,
        shootVel:IntPoint,
        shootAcc:IntPoint,
        scene:PlayState
    ) {
        this.shootTime = shootTime;
        this.nextShootTime = offset;
        this.shootVel = shootVel;
        this.shootAcc = shootAcc;
        this.pos = pos;
        this.scene = scene;
    }

    public function update (elapsed:Float) {
        if (active) {
            nextShootTime -= elapsed;
            if (nextShootTime < 0) {
                scene.shoot(pos.x, pos.y, shootVel, shootAcc);
                nextShootTime += shootTime;
            }
        }
    }
}
