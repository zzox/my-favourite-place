import data.Constants;
import data.Game;
import display.Font;
import display.Star;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.FlxSubState;
import flixel.text.FlxBitmapText;
import flixel.text.FlxText.FlxTextAlign;
import flixel.util.FlxTimer;
import util.Utils;

class FinalSubstate extends FlxSubState {
    static inline final TEXT_COLOR:Int = 0xffd7d7d7;
    var bufferTime:Float = 3.0;
    var callback:Void -> Void;
    var menustepped:Bool = false;
    var point:IntPoint;

    var title:FlxSprite;
    var timeText:FlxBitmapText;
    var bestTimesText:FlxBitmapText;
    var deathsText:FlxBitmapText;
    var reallyThanksText:FlxBitmapText;
    var thanksText1:FlxBitmapText;
    var thanksText2:FlxBitmapText;

    public function new (callback:Void -> Void, point:IntPoint) {
        super(null);

        this.callback = callback;
        this.point = { x: Std.int(point.x), y: Std.int(point.y) };
    }

    override public function create () {
        add(makeText('B', { x: point.x, y: point.y }));

        for (_ in 0...20) {
            add(
                new Star(
                    Std.int(Math.random() * 160),
                    Std.int(Math.random() * -85) - 5
                )
            );
        }

        title = new FlxSprite(point.x, point.y, AssetPaths.title__png);
        title.color = TEXT_COLOR;
        add(title);

        final deaths:Int = Lambda.fold(
            Game.inst.worlds, (world:CompleteData, total:Int) -> {
                return world.deaths + total;
            },
            0
        );
        deathsText = makeLevelText(
            Game.inst.isHardcore ? 'deaths: 0' : 'deaths: $deaths',
            { x: point.x, y: point.y + 12 }
        );
        add(deathsText);

        final totalTime:Float = Lambda.fold(
            Game.inst.worlds, (world:CompleteData, total:Float) -> {
                return world.totalTime + total;
            },
            0
        );
        final timeString = Game.inst.isHardcore ? timeToString(Game.inst.hardcoreTimeTotal) : timeToString(totalTime);
        timeText = makeLevelText('Total time: $timeString', { x: point.x, y: point.y + 20 });
        add(timeText);

        final bestTime:Float = Lambda.fold(
            Game.inst.worlds, (world:CompleteData, total:Float) -> {
                return world.bestTime + total;
            },
            0
        );
        final bestsString = timeToString(bestTime);
        bestTimesText = makeLevelText(
            Game.inst.isHardcore ? 'HARDCORE MODE' : 'Sum of Bests: $bestsString',
            { x: point.x, y: point.y + 28 }
        );
        add(bestTimesText);

        thanksText1 = makeLevelText('Thank you so much', { x: point.x, y: point.y + 54 });
        thanksText2 = makeLevelText('for playing', { x: point.x, y: point.y + 62 });
        add(thanksText1);
        add(thanksText2);

        reallyThanksText = makeLevelText('I can\'t belive you made it', { x: point.x, y: point.y + 76 });
        add(reallyThanksText);
    }

    function makeLevelText (string:String, point:IntPoint):FlxBitmapText {
        final text = makeText(string, point);
        text.autoSize = false;
        text.width = text.fieldWidth = 160;
        text.alignment = FlxTextAlign.CENTER;
        text.color = TEXT_COLOR;
        text.visible = false;
        return text;
    }

    override public function update (elapsed:Float) {
        super.update(elapsed);

        bufferTime -= elapsed;
        if (FlxG.mouse.justPressed) {
            handleClick();
        }
    }

    function handleClick () {
        if (bufferTime < 0) {
            if (!menustepped) {
                FlxG.sound.play(AssetPaths.isle_menu_one__mp3, 0.5);
                title.visible = false;

                new FlxTimer().start(1.0, (_:FlxTimer) -> {
                    deathsText.visible = true;
                    FlxG.sound.play(AssetPaths.isle_menu_one__mp3, 0.5);
                });

                new FlxTimer().start(2.0, (_:FlxTimer) -> {
                    timeText.visible = true;
                    FlxG.sound.play(AssetPaths.isle_menu_one__mp3, 0.5);
                });

                new FlxTimer().start(3.0, (_:FlxTimer) -> {
                    bestTimesText.visible = true;
                    FlxG.sound.play(AssetPaths.isle_menu_one__mp3, 0.5);
                });

                new FlxTimer().start(6.0, (_:FlxTimer) -> {
                    thanksText1.visible = true;
                    thanksText2.visible = true;
                    FlxG.sound.play(AssetPaths.isle_menu_one__mp3, 0.5);
                });

                if (Game.inst.isHardcore) {
                    new FlxTimer().start(9.0, (_:FlxTimer) -> {
                        reallyThanksText.visible = true;
                        FlxG.sound.play(AssetPaths.isle_menu_one__mp3, 0.5);
                    });
                }

                bufferTime = Game.inst.isHardcore ? 9.0 : 6.0;
                menustepped = true;
            } else {
                // play sound
                FlxG.sound.play(AssetPaths.isle_menu_two__mp3, 0.5);
                callback();
            }
        }
    }
}
