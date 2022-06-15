import data.Game;
import data.Levels;
import display.MenuButton;
import flixel.FlxG;
import flixel.FlxSprite;

class MenuState extends GameState {
    var buttons:Array<MenuButton>;

    override public function create () {
        super.create();

        final bg = new FlxSprite(0, 0);
        bg.makeGraphic(160, 90, 0xffffe9c5);
        add(bg);

        buttons = [];
        for (i in 0...levelList.length) {
            final item = levelList[i];

            // check if the level before is complete,
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

        addAimer();
    }

    override public function update (elapsed:Float) {
        super.update(elapsed);

        for (button in buttons) {
            if (button.overlapping) {
                trace(Game.inst.worlds[button.world]);
            }
        }
    }

    function selectWorld (world:Worlds) {
        fadeOut(() -> {
            Game.inst.currentWorld = world;
            FlxG.switchState(new PlayState());
        });
    }
}
