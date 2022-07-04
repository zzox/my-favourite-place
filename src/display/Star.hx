package display;

import flixel.FlxSprite;

class Star extends FlxSprite {
    static final COLORS:Array<Int> = [0xff5ba8ff, 0xffff3737, 0xff58dd32, 0xffff82c3];

    public function new (x:Int, y:Int) {
        super(x, y);

        loadGraphic(AssetPaths.star__png, true, 7, 7);

        var anim = 'single';
        if (Math.random() < 0.25) {
            anim = 'x';
        } else if (Math.random() < 0.25) {
            anim = 'plus';
        } else if (Math.random() < 0.25) {
            anim = 'twinkle';
        }

        final twinkleSpace = Math.floor(Math.random() * 32 + 32);
        final twinkleSpaceArray = [for (i in 0...twinkleSpace) 0];

        scrollFactor.set(0, 0.1);

        animation.add('single', [0]);
        animation.add('x', [1]);
        animation.add('plus', [2]);
        animation.add('twinkle', twinkleSpaceArray.concat([2, 3, 4, 5, 6, 5, 4, 3, 2]));

        if (Math.random() < 0.2) {
            color = COLORS[Math.floor(Math.random() * COLORS.length)];
        }

        flipX = Math.random() < 0.5;

        // alpha = Math.random() * 0.8 + 0.2;

        trace(anim);
        trace(flipX);
        trace(alpha);
        trace(color);

        animation.play(anim);
    }
}
