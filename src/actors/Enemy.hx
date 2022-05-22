package actors;

import data.Constants;
import flixel.FlxSprite;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;

typedef EnemyData = {
    var path:String;
    var hp:Int;
}

enum EnemyType {
    Saucer;
}
final enemyData:Map<EnemyType, EnemyData> = [
    Saucer => {
        path: AssetPaths.enemies__png,
        hp: 1,
    }
];

class Enemy extends FlxSprite {
    var scene:PlayState;
    var type:EnemyType;
    var hp:Int;
    public var dead:Bool = false;

    public function new (x:Float, y:Float, scene:PlayState, type:EnemyType, ?vel:IntPoint) {
        super(x, y);

        final enemyData = enemyData[type];
        loadGraphic(enemyData.path, true, 16, 16);
        offset.set(4, 4);
        setSize(8, 8);

        if (vel != null) {
            velocity.set(vel.x, vel.y);
        }

        active = false;
        hp = enemyData.hp;
        this.type = type;
        this.scene = scene;
    }

    override public function update (elapsed:Float) {
        super.update(elapsed);

        switch (type) {
            case Saucer:
                if (velocity.x < 0) {
                    if (x < -32) {
                        x += 196;
                    }

                    angle -= 5;
                } else if (velocity.x > 0) {
                    if (x > 176) {
                        x -= 196;
                    }

                    angle += 5;
                }

                angle = angle % 360;
        }
    }

    public function hit () {
        hp--;
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
