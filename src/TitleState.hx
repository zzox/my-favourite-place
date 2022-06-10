import display.CrtShader;
import display.Font;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.system.scaleModes.PixelPerfectScaleMode;
import flixel.util.FlxTimer;
import openfl.filters.ShaderFilter;

class TitleState extends GameState {
    var starting:Bool = false;

    override public function create () {
        super.create();

        // PROD: remove
        // requires `-debug` flag
        FlxG.debugger.visible = true;
        FlxG.debugger.drawDebug = true;

        FlxG.mouse.visible = false;
        FlxG.mouse.useSystemCursor = true;

        // options
        // FlxG.autoPause = false;
        // FlxG.sound.muteKeys = null;
        // FlxG.sound.volumeUpKeys = null;
        // FlxG.sound.volumeDownKeys = null;
        // camera.pixelPerfectRender = true;

        FlxG.scaleMode = new PixelPerfectScaleMode();

        final bg = new FlxSprite(0, 0);
        bg.makeGraphic(160, 90, 0xffffe9c5);
        bg.scrollFactor.set(0, 0);
        add(bg);

        add(new FlxSprite(0, 0, AssetPaths.title__png));

        new FlxTimer().start(1.0, (_:FlxTimer) -> {
            add(makeText('click', { x: 12, y: 54 }));
            add(makeText('to', { x: 12, y: 60 }));
            add(makeText('start', { x: 12, y: 66 }));
        });

        final crtShader = new CrtShader();
        FlxG.camera.setFilters([new ShaderFilter(crtShader)]);
    }

    override public function update (elapsed:Float) {
        super.update(elapsed);

        if (FlxG.mouse.justPressed && !starting) {
            fadeOut(() -> {
                FlxG.switchState(new PlayState());
            });
        }
    }
}
