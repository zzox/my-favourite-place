package display;

import data.Constants;
import flixel.graphics.frames.FlxBitmapFont;
import flixel.text.FlxBitmapText;
import openfl.Assets;

function getFont () {
    final textBytes = Assets.getText(AssetPaths.triple_zero_webfont__fnt);
    final XMLData = Xml.parse(textBytes);
    return FlxBitmapFont.fromAngelCode(AssetPaths.triple_zero_webfont__png, XMLData);
}

function makeText (string:String, pos:IntPoint):FlxBitmapText {
    final text = new FlxBitmapText(getFont());
    text.color = 0xff0d2030;
    text.text = string;
    text.letterSpacing = -1;
    text.setPosition(pos.x, pos.y);
    return text;
}
