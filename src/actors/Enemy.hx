package actors;

import data.Constants;
import flixel.FlxSprite;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;

typedef EnemyData = {
    var path:String;
    var hp:Int;
}

enum abstract EnemyType(String) to String {
    var Gremlin;
}
final enemyData:Map<EnemyType, EnemyData> = [
    Gremlin => {
        path: AssetPaths.enemies__png,
        hp: 1,
    }
];

class Enemy extends FlxSprite {
    static inline final HURT_FRAMES:Float = 3;

    var scene:PlayState;
    var type:EnemyType;
    var hp:Int;
    var hurtFrame:Int;
    var hurtTime:Float = 0.0;
    public var dead:Bool = false;

    public function new (x:Float, y:Float, scene:PlayState, type:EnemyType, ?vel:IntPoint) {
        super(x, y);

        final enemyData = enemyData[type];
        loadGraphic(enemyData.path, true, 16, 16);
        offset.set(2, 2);
        setSize(12, 12);

        animation.add(Gremlin, [0, 1], 2);

        if (vel != null) {
            velocity.set(vel.x, vel.y);
            flipX = vel.x > 0;
        }

        active = false;
        hp = enemyData.hp;
        this.type = type;
        this.scene = scene;
        animation.play(type);
    }

    override public function update (elapsed:Float) {
        super.update(elapsed);

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
        }

        hurtTime -= elapsed;
        if (hurtTime > 0) {
            hurtFrame++;
            visible = Math.floor(hurtFrame / HURT_FRAMES) % 2 != 0;
        } else {
            visible = true;
        }
    }

    public function hit () {
        hp--;
        hurtTime = 1.0;
        hurtFrame = 0;
        if (hp == 0) {
            die();
        }
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
