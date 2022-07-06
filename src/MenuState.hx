import data.Game;
import data.Levels;
import display.Font;
import display.MenuButton;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.system.FlxSound;
import flixel.text.FlxBitmapText;
import flixel.tweens.FlxTween;
import flixel.util.FlxTimer;
import util.Utils;

class MenuState extends GameState {
    var buttons:Array<MenuButton>;
    var deathText:FlxBitmapText;
    var timeText:FlxBitmapText;
    var totalTimeText:FlxBitmapText;
    var opened:Bool = false;

    var sound1:FlxSound;
    var sound2:FlxSound;

    override public function create () {
        super.create();

        final bg = new FlxSprite(0, 0);
        bg.makeGraphic(160, 90, 0xffffe9c5);
        add(bg);

        final bgItem = new FlxSprite(0, 18, AssetPaths.castle_bg_1__png);
        bgItem.alpha = 0.5;
        add(bgItem);

        // clouds
        for (i in 0...3) {
            final cloud = new FlxSprite(i * 40 + Math.random() * 40, 48 + Math.random() * 16, AssetPaths.cloud__png);
            cloud.color = i % 2 == 0 ? 0xffa8a8a8 : 0xff7b7b7b;
            cloud.flipX = Math.random() < 0.5;
            FlxTween.tween(
                cloud,
                { x: cloud.x + 3 + Math.random() * 3 },
                2 + Math.random() * 2,
                { type: FlxTweenType.PINGPONG }
            );
            add(cloud);
        }

        buttons = [];
        for (i in 0...levelList.length) {
            final item = levelList[i];

            if (i <= Game.inst.levelCleared + 1) {
                final button = new MenuButton(
                    i % 2 == 0 ? 16 : 82,
                    Math.floor(i / 2) * 20 + 8,
                    i,
                    item,
                    (world) -> {
                        if (opened) {
                            selectWorld(world);
                        }
                    }
                );
                add(button);
                add(button.text);
                buttons.push(button);
            }
        }

        deathText = makeText('', { x: 16, y: 64 });
        add(deathText);
        totalTimeText = makeText('', { x: 16, y: 71 });
        add(totalTimeText);
        timeText = makeText('', { x: 16, y: 78 });
        add(timeText);

        addAimer();

        new FlxTimer().start(0.75, (_:FlxTimer) -> {
            opened = true;
        });

        sound1 = FlxG.sound.play(AssetPaths.choose_1_noise__mp3, 0.0, true);
        sound2 = FlxG.sound.play(AssetPaths.choose_1_synth1__mp3, 0.0, true);

        FlxTween.tween(sound1, { volume: 1.0 }, 0.5);
        FlxTween.tween(sound2, { volume: 1.0 }, 0.5);
    }

    override public function update (elapsed:Float) {
        super.update(elapsed);

        var found = false;
        for (button in buttons) {
            if (button.overlapping) {
                found = true;
                final world = Game.inst.worlds[button.world];

                deathText.text = world.deaths + ' death' + (world.deaths == 1 ? '' : 's');
                totalTimeText.text = 'total: ' + timeToString(world.totalTime);

                if (world.complete) {
                    timeText.text = 'best: ' + timeToString(world.bestTime);
                } else {
                    timeText.text = '';
                }
            }
        }

        if (FlxG.keys.pressed.SHIFT && FlxG.keys.pressed.R && FlxG.keys.pressed.T) {
            reset();
        }

        if (FlxG.keys.pressed.SHIFT && FlxG.keys.pressed.H) {
            launchHardcore();
        }

        if (!found) {
            deathText.text = '';
            totalTimeText.text = '';
            timeText.text = '';
        }
    }

    function selectWorld (world:Worlds) {
        fadeOut(() -> {
            Game.inst.currentWorld = world;
            Game.inst.isHardcore = false;
            FlxG.switchState(new PlayState());
            FlxTween.tween(sound1, { volume: 0.0 }, 0.5);
            FlxTween.tween(sound2, { volume: 0.0 }, 0.5);
        });
    }

    function reset () {
        fadeOut(() -> {
            FlxG.switchState(new TitleState());
            Game.inst.clearSaveData();
            FlxTween.tween(sound1, { volume: 0.0 }, 0.5);
            FlxTween.tween(sound2, { volume: 0.0 }, 0.5);
        });
    }

    function launchHardcore () {
        fadeOut(() -> {
            Game.inst.currentWorld = LOut;
            Game.inst.isHardcore = true;
            Game.inst.hardcoreTimeTotal = 0;
            FlxG.switchState(new PlayState());
            FlxTween.tween(sound1, { volume: 0.0 }, 0.5);
            FlxTween.tween(sound2, { volume: 0.0 }, 0.5);
        });
    }
}
