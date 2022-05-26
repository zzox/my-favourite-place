package;

import display.CrtShader;
import display.Font;
import flixel.FlxG;
import flixel.FlxState;
import flixel.system.scaleModes.PixelPerfectScaleMode;
import flixel.text.FlxBitmapText;
import openfl.filters.ShaderFilter;

class PreState extends FlxState {
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

        bgColor = 0xff000000;

        final fontAngelCode = getFont();

        var text = new FlxBitmapText(fontAngelCode);
        text.color = 0xffffffff;
        text.text = 'Click to focus window';
        text.letterSpacing = -1;
        text.setPosition((FlxG.width - text.width) / 2, 40);
        add(text);

        final crtShader = new CrtShader();
        FlxG.camera.setFilters([new ShaderFilter(crtShader)]);
    }

    override public function update (elapsed:Float) {
        super.update(elapsed);
        if (FlxG.mouse.justPressed) {
            FlxG.switchState(new PlayState());
        }
    }
}
