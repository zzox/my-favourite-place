package objects;

import flixel.FlxSprite;

class Explosion extends FlxSprite {
    public function new () {
        super();

        loadGraphic(AssetPaths.explosions__png, true, 16, 16);
        animation.add('pop-blue', [0, 1, 2, 3, 4], 16, false);
        animation.add('pop-grey', [5, 6, 7, 8, 9], 16, false);
        animation.add('pop-aqua', [10, 11, 12, 13, 14], 16, false);
        animation.add('warn', [15, 16, 17, 18, 19], 16, false);
        animation.add('jump', [20, 21, 22, 23, 24, 25], 24, false);
        animation.add('land', [26, 27, 28, 29], 24, false);
        animation.finishCallback = (animName:String) -> {
            kill();
        }
    }

    public function play (x:Float, y:Float, anim:String) {
        exists = true;
        alive = true;
        angle = 0;
        this.x = x - 8;
        this.y = y - 8;
        animation.play(anim);
        if (anim.split('-')[0] == 'pop') {
            angularVelocity = 100;
        } else {
            angularVelocity = 0;
        }
    }
}
