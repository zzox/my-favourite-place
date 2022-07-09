package display;

import data.Constants;
import flixel.FlxCamera;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.util.FlxTimer;

typedef AnimData = {
    var name:String;
    var frames:Array<Int>;
    var speed:Int;
}

class CinematicSprite extends FlxSprite {
    public function new (start:IntPoint, graphic:String, anims:Array<AnimData>) {
        super(start.x, start.y);

        final size = graphic == AssetPaths.king_boss__png ? { x: 32, y: 32 } : { x: 16, y: 16 };

        loadGraphic(graphic, true, size.x, size.y);

        for (anim in anims) {
            animation.add(anim.name, anim.frames, anim.speed);
        }
    }
}

function runTimer (time:Float, callback:Void -> Void) {
    new FlxTimer().start(time, (_:FlxTimer) -> {
        callback();
    });
}

function runUpCinematic (scene:PlayState, callback:Void -> Void) {
    final king = new CinematicSprite(
        { x: -32, y: -620 },
        AssetPaths.king_boss__png,
        [{ name: 'play', frames: [1], speed: 1 }]
    );
    king.animation.play('play');
    king.flipX = true;
    scene.add(king);

    FlxTween.tween(king, { x: 160 }, 3, {
        onComplete: (_:FlxTween) -> {
            callback();
        },
        startDelay: 3
    });
}

function runOverCinematic (scene:PlayState, camera:FlxCamera, callback:Void -> Void) {
    final player = new CinematicSprite(
        { x: 648, y: 73 },
        AssetPaths.player_light__png,
        [
            { name: 'stand', frames: [0], speed: 1 },
            { name: 'run', frames: [0, 1, 1, 2, 2], speed: 24 },
        ]
    );
    player.animation.play('stand');
    player.flipX = true;

    final otherPlayer = new CinematicSprite(
        { x: 760, y: 73 },
        AssetPaths.player_light__png,
        [
            { name: 'sit', frames: [5], speed: 1 },
            { name: 'stand', frames: [6], speed: 1 },
            { name: 'run', frames: [6, 7, 7, 8, 8], speed: 24 },
        ]
    );
    otherPlayer.animation.play('sit');

    scene.add(player);
    scene.add(otherPlayer);

    FlxTween.tween(
        camera,
        { 'scroll.x': 640, 'scroll.y': 6 },
        1,
        { ease: FlxEase.quadInOut, startDelay: 1 }
    );

    runTimer(1, () -> {
        scene.timer.destroy();
    });

    runTimer(4, () -> {
        otherPlayer.animation.play('stand');
    });

    runTimer(6, () -> {
        player.animation.play('run');
        otherPlayer.animation.play('run');
    });

    FlxTween.tween(player, { x: 664 }, 0.5, { startDelay: 6, onComplete:
        (_:FlxTween) -> {
            player.animation.play('stand');
        }
    });

    FlxTween.tween(otherPlayer, { x: 670 }, 1.5, { startDelay: 6, onComplete:
        (_:FlxTween) -> {
            player.destroy();
            otherPlayer.destroy();
            FlxG.sound.play(AssetPaths.choose_blip__mp3, 0.5);
            FlxG.camera.shake(0.01, 0.05);

            // generate hearts
            for (i in 0...6) {
                final heart = new FlxSprite(674, 78, AssetPaths.heart__png);
                FlxTween.tween(
                    heart,
                    { x: (heart.x + i * 8) - 24, y: heart.y - (Math.random() * 32 + 16) },
                    0.5,
                    { ease: FlxEase.cubeOut, startDelay: 0.5 * Math.random(), onComplete:
                        (_:FlxTween) -> {
                            new FlxTimer().start(Math.random() * 1, (_:FlxTimer) -> {
                                heart.destroy();
                            });
                        }
                    }
                );
                scene.add(heart);
            }

            scene.add(new FlxSprite(664, 73, AssetPaths.player_collide__png));
        }
    });

    runTimer(10, () -> {
        callback();
    });
}
