import actors.Player;
import data.Constants;
import display.CrtShader;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.FlxState;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.tile.FlxBaseTilemap.FlxTilemapAutoTiling;
import flixel.tile.FlxTilemap;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import objects.Projectile;
import openfl.filters.ShaderFilter;
import util.LdtkWorld;

class NamedMap extends FlxTilemap {
    public var name:Null<String>;
    public function new (?name:String) {
        super();
        this.name = name;
    }
}

typedef Room = {
    var collide:FlxTilemap;
    var spikes:FlxTypedGroup<FlxTilemap>;
}

class PlayState extends FlxState {
    static inline final BULLET_POOL_SIZE:Int = 100;
    static inline final ROOM_HEIGHT:Int = 96;

    var currentRoom:Int = 0;
    var rooms:Array<Room> = [];

    var player:Player;
    var projectiles:FlxTypedGroup<Projectile>;
    var aimer:FlxSprite;

    var crtShader:CrtShader;
    var screenPoint:IntPoint;

    var cameraXScale:Float = 0;
    var cameraYScale:Float = 0;

    public var transitioning:Bool = false;

    // TEMP:
    final SHOOT_VEL = 120;

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

        var point = { x: 0, y: 0 };
        for (i in 0...3) {
            // TODO: shuffle rooms

            // position
            final spikes = new FlxTypedGroup<FlxTilemap>();
            // final spikesUp = createTileLayer(map, 'spikes-up', startPoint.x, startPoint.y + 4);
            // final spikesDown = createTileLayer(map, 'spikes-down', startPoint.x, startPoint.y - 4);

            final collide = createTileLayer(world, 'Level_$i', 'Ground', point);
            trace(collide);
            rooms[i] = {
                collide: collide,
                spikes: spikes,
            };

            point.y += ROOM_HEIGHT;
        }

        player = new Player(25, 25, this);
        add(player);

        projectiles = new FlxTypedGroup<Projectile>(BULLET_POOL_SIZE);
        for (_ in 0...BULLET_POOL_SIZE) {
            final proj = new Projectile();
            proj.kill();
            projectiles.add(proj);
        }
        add(projectiles);

        screenPoint = { x: 0, y: GLOBAL_Y_OFFSET };

        aimer = new FlxSprite(0, 0, AssetPaths.aimer__png);
        aimer.offset.set(4, 4);
        aimer.setSize(1, 1);
        add(aimer);
        positionAimer();

        camera.scroll.x = screenPoint.x;
        camera.scroll.y = screenPoint.y;
        setBounds();

        // crtShader = new CrtShader();
        // FlxG.camera.setFilters([new ShaderFilter(crtShader)]);

        camera.setScale(0, 0);
        FlxTween.tween(this, { cameraXScale: 1.0 }, 0.5, { ease: FlxEase.circIn });
        FlxTween.tween(this, { cameraYScale: 1.0 }, 0.75, { ease: FlxEase.quintIn });
    }

    override public function update(elapsed:Float) {
        positionAimer();
        super.update(elapsed);

        FlxG.collide(rooms[currentRoom].collide, player);

        trace(currentRoom);

        if (player.y + player.height > screenPoint.y + 90) {
            moveRoom();
        }

        if (camera.scaleX != 1.0 || camera.scaleY != 1.0) {
            camera.setScale(cameraXScale, cameraYScale);
        }

        if (FlxG.keys.justPressed.P) {
            if (crtShader == null) {
                crtShader = new CrtShader();
                FlxG.camera.setFilters([new ShaderFilter(crtShader)]);
            } else {
                crtShader = null;
                FlxG.camera.setFilters([]);
            }
        }
    }

    function moveRoom () {
        transitioning = true;

        // currentRoom = worlds[currentWorld].rooms[currentRoom].exits[dir];
        screenPoint.y += ROOM_HEIGHT;
        currentRoom++;

        FlxTween.tween(player, { y: player.y + 24 }, 0.5);
        FlxTween.tween(
            camera.scroll,
            { y: screenPoint.y },
            0.5,
            { ease: FlxEase.circInOut, onComplete: (_:FlxTween) -> finishMovingRoom() }
        );
    }

    function finishMovingRoom () {
        transitioning = false;
        setBounds();
    }

    public function generateProjectile (owner:FlxSprite, angle:Float) {
        final proj = projectiles.getFirstAvailable();
        final point = owner.getMidpoint();
        proj.shoot(point.x + 4, point.y, angle, SHOOT_VEL);
        // final kb = projMap[type].knockback;
        // FlxG.camera.shake(
        //     0.01 + (0.025 * kb / 1000),
        //     0.05 + (0.1 * kb / 1000)
        // );
        // POTENTIALLY:
        // just very large knockback has a tiny screenshake
        // FlxG.camera.shake(0.01, 0.05);
    }

    function positionAimer () {
        aimer.x = FlxG.camera.scroll.x + FlxG.mouse.screenX;
        aimer.y = FlxG.camera.scroll.y + FlxG.mouse.screenY;
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
