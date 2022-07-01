import display.CrtShader;
import display.Font;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.system.scaleModes.PixelPerfectScaleMode;
import flixel.util.FlxTimer;
import openfl.filters.ShaderFilter;

class TitleState extends GameState {
    var started:Bool = false;
    var leaving:Bool = false;

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

        final bgItem = new FlxSprite(0, 18, AssetPaths.castle_bg_1__png);
        bgItem.alpha = 0.5;
        add(bgItem);

        final title = new FlxSprite(0, 0, AssetPaths.title__png);
        title.color = 0xff0d2030;
        add(title);

        new FlxTimer().start(1.5, (_:FlxTimer) -> {
            add(makeText('click', { x: 12, y: 54 }));
            add(makeText('to', { x: 12, y: 60 }));
            add(makeText('start', { x: 12, y: 66 }));
            started = true;
        });

        addAimer();
    }

    override public function update (elapsed:Float) {
        super.update(elapsed);

        if (FlxG.mouse.justPressed && started && !leaving) {
            leaving = true;
            fadeOut(() -> {
                FlxG.switchState(new MenuState());
            });
        }
    }
}
