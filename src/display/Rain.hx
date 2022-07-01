package display;

import flixel.FlxSprite;
import flixel.group.FlxGroup;

class Rain extends FlxTypedGroup<FlxSprite> {
    public function new () {
        super();

        for (_ in 0...30) {
            final drop = new FlxSprite(
                Math.random() * 157,
                Math.random() * 84,
                AssetPaths.raindrop__png
            );
            drop.alpha = 0.7;
            drop.scrollFactor.set(0, 0);
            drop.velocity.set(-60, 120);
            add(drop);
        }
    }

    override public function update (elapsed:Float) {
        super.update(elapsed);

        forEach((drop:FlxSprite) -> {
            if (drop.x < 0) {
                drop.x += 157;
            }

            if (drop.y > 84) {
                drop.y -= 84;
            }
        });
    }
}
