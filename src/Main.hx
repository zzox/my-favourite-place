import flixel.FlxGame;
import openfl.display.Sprite;

class Main extends Sprite {
    public function new() {
        super();
        addChild(new FlxGame(160, 90, PreState, 1, 60, 60, true));
    }
}
