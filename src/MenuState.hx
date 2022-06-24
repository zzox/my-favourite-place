import data.Game;
import data.Levels;
import display.Font;
import display.MenuButton;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.text.FlxBitmapText;
import util.Utils;

class MenuState extends GameState {
    var buttons:Array<MenuButton>;
    var deathText:FlxBitmapText;
    var timeText:FlxBitmapText;
    var totalTimeText:FlxBitmapText;

    override public function create () {
        super.create();

        final bg = new FlxSprite(0, 0);
        bg.makeGraphic(160, 90, 0xffffe9c5);
        add(bg);

        buttons = [];
        for (i in 0...levelList.length) {
            final item = levelList[i];

            // TODO:
            // check if the level before is complete,
            // move buttons down?
            final button = new MenuButton(
                i % 2 == 0 ? 16 : 82,
                Math.floor(i / 2) * 20 + 8,
                i,
                item,
                (world) -> selectWorld(world)
            );
            add(button);
            add(button.text);
            buttons.push(button);
        }

        deathText = makeText('', { x: 16, y: 64 });
        add(deathText);
        totalTimeText = makeText('', { x: 16, y: 71 });
        add(totalTimeText);
        timeText = makeText('', { x: 16, y: 78 });
        add(timeText);

        addAimer();
    }

    override public function update (elapsed:Float) {
        super.update(elapsed);

        var found = false;
        for (button in buttons) {
            if (button.overlapping) {
                found = true;
                final world = Game.inst.worlds[button.world];

                deathText.text = world.deaths + ' deaths';
                totalTimeText.text = 'total: ' + timeToString(world.totalTime);

                if (world.complete) {
                    timeText.text = 'best: ' + timeToString(world.bestTime);
                }
            }
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
            FlxG.switchState(new PlayState());
        });
    }
}
