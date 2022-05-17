import actors.Player;
import data.Constants;
import display.CrtShader;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.FlxState;
import flixel.tile.FlxBaseTilemap.FlxTilemapAutoTiling;
import flixel.tile.FlxTilemap;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import openfl.filters.ShaderFilter;
import util.LdtkWorld;

class NamedMap extends FlxTilemap {
    public var name:Null<String>;
    public function new (?name:String) {
        super();
        this.name = name;
    }
}

class PlayState extends FlxState {
    var player:Player;

    var crtShader:CrtShader;
    var screenPoint:IntPoint;

    var cameraXScale:Float = 0;
    var cameraYScale:Float = 0;

    // TEMP: collision
    var collide:FlxTilemap;

    override public function create() {
        super.create();

        // TODO: doesn't look great, turn on later?
        // camera.pixelPerfectRender = true;

        final world = new LdtkWorld(AssetPaths.world1__ldtk);
        var point = { x: 0, y: 0 };

        final bg = new FlxSprite(0, 0);
        bg.makeGraphic(160, 90, 0xffffe9c5);
        bg.scrollFactor.set(0, 0);
        add(bg);

        collide = createTileLayer(world, 'Level_0', 'Ground', point);
        add(collide);

        player = new Player(25, 25, this);
        add(player);

        screenPoint = { x: 0, y: GLOBAL_Y_OFFSET };
        camera.scroll.x = screenPoint.x;
        camera.scroll.y = screenPoint.y;
        setBounds();

        camera.setScale(0, 0);
        FlxTween.tween(this, { cameraXScale: 1.0 }, 0.5, { ease: FlxEase.circIn });
        FlxTween.tween(this, { cameraYScale: 1.0 }, 0.75, { ease: FlxEase.quintIn });
    }

    override public function update(elapsed:Float) {
        super.update(elapsed);

        FlxG.collide(collide, player);
        // FlxG.collide(rooms[currentRoom].collide, player);

        if (FlxG.keys.justPressed.P) {
            if (crtShader == null) {
                crtShader = new CrtShader();
                FlxG.camera.setFilters([new ShaderFilter(crtShader)]);
            } else {
                crtShader = null;
                FlxG.camera.setFilters([]);
            }
        }

        if (cameraXScale != 1.0 || cameraYScale != 1.0) {
            camera.setScale(cameraXScale, cameraYScale);
        }
    }

    function createTileLayer (world:LdtkWorld, levelName:String, layerName:String, offset:IntPoint):Null<NamedMap> {
        final layerData = world.levels[levelName][layerName];
        if (layerData != null) {
            final layer = new NamedMap(layerName);
            layer.loadMapFromArray(layerData.tileArray, layerData.width, layerData.height,
                AssetPaths.tiles__png, layerData.tileSize, layerData.tileSize, FlxTilemapAutoTiling.OFF, 1, 1, 1)
                .setPosition(offset.x, offset.y);

            layer.useScaleHack = false;
            add(layer);

            return layer;
        }
        return null;
    }

    function setBounds () {
        // TEMP: static
        FlxG.worldBounds.set(screenPoint.x, screenPoint.y, 160, 90);
    }
}
