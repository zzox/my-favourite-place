import actors.Enemy;
import actors.Player;
import actors.SpritesGroup;
import data.Constants;
import data.Levels;
import display.Button;
import display.CrtShader;
import display.Font;
import flixel.FlxG;
import flixel.FlxObject;
import flixel.FlxSprite;
import flixel.FlxState;
import flixel.group.FlxGroup;
import flixel.tile.FlxBaseTilemap.FlxTilemapAutoTiling;
import flixel.tile.FlxTilemap;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.util.FlxTimer;
import objects.Explosion;
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
    var downPlugs:FlxTilemap;
    var upPlugs:FlxTilemap;
    var spikes:FlxTypedGroup<NamedMap>;
    var enemies:Array<Enemy>;
    var choiceItems:FlxGroup;
}

typedef PlayerSkills = {
    var xVel:Float;
    var yVel:Float;
    var jumps:Int;
    var jumpVel:Float;
    var dashes:Int;
    var dashTime:Float;
    var dashVel:Float;
}

class PlayState extends FlxState {
    static inline final BULLET_POOL_SIZE:Int = 100;
    static inline final ROOM_HEIGHT:Int = 96;
    static inline final CAMERA_DIFF:Int = 2000;
    static inline final CAMERA_START_DIFF:Int = -90;

    public var skills:PlayerSkills;
    var currentRoom:Int;
    var rooms:Array<Room> = [];

    var player:Player;
    var enemies:FlxTypedGroup<Enemy>;
    var projectiles:FlxTypedGroup<Projectile>;
    var explosions:FlxTypedGroup<Explosion>;
    var aimer:FlxSprite;
    var spritesGroup:SpritesGroup;

    var crtShader:CrtShader;
    var screenPoint:IntPoint;

    var cameraXScale:Float = 0.0;
    var cameraYScale:Float = 0.0;
    var stoppedFrames:Int = 0;

    var numEnemiesKilled:Int = 0;
    public var transitioning:Bool = true;

    // TEMP:
    final SHOOT_VEL = 250;

    override public function create() {
        super.create();

        // TODO: doesn't look great, turn on later?
        // camera.pixelPerfectRender = true;

        skills = {
            xVel: 90.0,
            yVel: 180.0,
            jumps: 1,
            jumpVel: 90.0,
            dashes: 1,
            dashTime: 0.125,
            dashVel: 250.0
        }

        final bg = new FlxSprite(0, 0);
        bg.makeGraphic(160, 90, 0xffffe9c5);
        bg.scrollFactor.set(0, 0);
        add(bg);

        spritesGroup = new SpritesGroup();

        crtShader = new CrtShader();
        FlxG.camera.setFilters([new ShaderFilter(crtShader)]);

        camera.setScale(0, 0);
        FlxTween.tween(this, { cameraXScale: 1.0 }, 0.5, { ease: FlxEase.circIn });
        FlxTween.tween(this, { cameraYScale: 1.0 }, 0.75, { ease: FlxEase.quintIn });

        // MD;
        camera.scroll.y = CAMERA_START_DIFF;
        new FlxTimer().start(0.75, (_:FlxTimer) -> {
            createWorld();

            FlxTween.tween(
                camera,
                { 'scroll.x': screenPoint.x, 'scroll.y': screenPoint.y },
                0.5,
                { ease: FlxEase.quadInOut,
                    onComplete: (_:FlxTween) -> {
                        transitioning = false;
                    }
                }
            );
            setBounds();
        });
    }

    override public function update(elapsed:Float) {
        positionAimer();
        super.update(elapsed);

        // TODO: add other moving Flx items to `spritesGroup`
        if (--stoppedFrames < 0) {
            spritesGroup.updateParent(elapsed);
        }

        if (camera.scaleX != 1.0 || camera.scaleY != 1.0 || cameraXScale != 1.0 || cameraYScale != 1.0) {
            // TODO: this needs to be sized to the game and centered, not scale.
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

        if (currentRoom == null) {
            return;
        }

        FlxG.collide(rooms[currentRoom].collide, player, playerCollideGround);
        FlxG.collide(rooms[currentRoom].downPlugs, player, playerCollideGround);
        FlxG.collide(rooms[currentRoom].upPlugs, player, playerCollideGround);
        FlxG.collide(rooms[currentRoom].spikes, player, collideSpikes);
        FlxG.collide(rooms[currentRoom].collide, projectiles, projHitGroud);
        FlxG.overlap(enemies, player, enemyHitPlayer);

        if (player.y + player.height > screenPoint.y + 90) {
            moveRoom();
        }
    }

    function updateSkills (skill:Choices) {
        switch (skill) {
            case Faster: skills.xVel += 45;
            case Higher: skills.jumpVel += 45;
            case LongerDash: skills.dashTime += 0.0625;
            case FasterDash: skills.dashVel += 125;
            case PlusOneDash: skills.dashes++;
            case PlusOneJump: skills.jumps++;
            case MinusOneDash: skills.dashes--;
            case MinusOneJump: skills.jumps--;
        }
    }

    function playerCollideGround (_:FlxTilemap, player:Player) {
        if (player.dashing) {
            FlxG.camera.shake(0.01, 0.05);
            stoppedFrames = 3;
        }
    }

    function collideSpikes (spikes:NamedMap, player:Player) {
        if (!player.dead && (
            (player.isTouching(FlxObject.DOWN) && !player.isTouching(FlxObject.LEFT) &&
            !player.isTouching(FlxObject.RIGHT) && spikes.name == 'Spikes_up') ||
            // TODO: handle ^^^ for all other directions
            (player.isTouching(FlxObject.UP) && spikes.name == 'Spikes_down') ||
            (player.isTouching(FlxObject.LEFT) && spikes.name == 'Spikes_down') ||
            (player.isTouching(FlxObject.RIGHT) && spikes.name == 'Spikes_down'))) {
            loseLevel();
        }
    }

    function projHitGroud (_:FlxTilemap, proj:Projectile) {
        final midpoint = proj.getMidpoint();
        generateExplosion(midpoint.x, midpoint.y, 'pop');
        proj.kill();
    }

    function old_projHitEnemy (proj:Projectile, enemy:Enemy) {
        if (!enemy.dead) {
            final midpoint = proj.getMidpoint();
            generateExplosion(midpoint.x, midpoint.y, 'pop');
            proj.kill();
            enemy.hit();
        }
    }

    function enemyHitPlayer (enemy:Enemy, player:Player) {
        if (!enemy.dead && !player.dead) {
            if (player.dashing || player.postDashTime > 0) {
                enemy.hit();
                stoppedFrames = 10;
                FlxG.camera.shake(0.01, 0.05);
                if (player.postDashTime > 0) {
                    trace('here!!!!!!');
                }
            } else {
                loseLevel();
                FlxG.camera.shake(0.001, 0.5);
            }
        }
    }

    public function enemyDie () {
        numEnemiesKilled++;
        if (numEnemiesKilled == rooms[currentRoom].enemies.length) {
            generateExplosion(48, screenPoint.y + 84, 'warn');
            generateExplosion(112, screenPoint.y + 84, 'warn');
            new FlxTimer().start(1, (_:FlxTimer) -> {
                rooms[currentRoom].downPlugs.destroy();
            });
            rooms[currentRoom].choiceItems.visible = true;
        }
    }

    function loseLevel () {
        stoppedFrames = 30;
        player.die();
        final midpoint = player.getMidpoint();
        generateExplosion(midpoint.x, midpoint.y, 'pop');
        final yPos = Std.int(FlxG.camera.y - CAMERA_DIFF);
        createMenu(yPos);
        FlxTween.tween(
            camera,
            { 'scroll.y': yPos },
            1,
            { ease: FlxEase.quadInOut, startDelay: 0.5 }
        );
    }

    function moveRoom () {
        if (player.x < 90) {
            updateSkills(levels[currentRoom].choices[0]);
        } else {
            updateSkills(levels[currentRoom].choices[1]);
        }

        transitioning = true;
        player.stopDash();

        screenPoint.y += ROOM_HEIGHT;
        currentRoom++;

        FlxTween.tween(player, { y: player.y + 32 }, 0.5);
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
        numEnemiesKilled = 0;
        for (enemy in rooms[currentRoom].enemies) {
            enemy.active = true;
        }
        rooms[currentRoom].upPlugs.visible = true;
    }

    // TODO: remove
    public function old_generateProjectile (owner:FlxSprite, angle:Float) {
        final proj = projectiles.getFirstAvailable();
        final point = owner.getMidpoint();
        proj.shoot(point.x - 1, point.y - 4, angle, SHOOT_VEL);
    }

    public function generateExplosion (x:Float, y:Float, anim:String) {
        final expl = explosions.getFirstAvailable();
        expl.play(x, y, anim);
    }

    function positionAimer () {
        if (aimer != null) {
            aimer.x = FlxG.camera.scroll.x + FlxG.mouse.screenX;
            aimer.y = FlxG.camera.scroll.y + FlxG.mouse.screenY;
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

    function createMenu (yPos:Int) {
        // space for title
        // fade out if clicked
        add(new Button(63, yPos + 50, Retry, () -> {
            fadeOut(() -> {
                FlxG.switchState(new PlayState());
            });
        }));
        add(new Button(63, yPos + 66, Quit, () -> {
            fadeOut(() -> {
                FlxG.switchState(new PlayState());
            });
        }));
    }

    function fadeOut (callback:Void -> Void) {
        FlxTween.tween(this, { cameraXScale: 0 }, 0.75, { ease: FlxEase.circIn, onComplete:
            (_:FlxTween) -> {
                callback();
            }
        });
        FlxTween.tween(this, { cameraYScale: 0 }, 0.5, { ease: FlxEase.quintIn, onComplete:
            (_:FlxTween) -> {
                callback();
            }
        });
    }

    function createWorld () {
        final world = new LdtkWorld(AssetPaths.world1__ldtk);
        currentRoom = 0;

        enemies = new FlxTypedGroup<Enemy>();

        var point = { x: 0, y: 0 };
        for (i in 0...7) {
            // TODO: shuffle rooms
            final roomData = levels[i];

            final spikes = new FlxTypedGroup<NamedMap>();

            final spikesUp = createTileLayer(world, 'Level_$i', 'Spikes_up', { x: point.x, y: point.y + 4 });
            if (spikesUp != null) {
                spikesUp.offset.set(0, 4);
                spikes.add(spikesUp);
            }

            final spikesDown = createTileLayer(world, 'Level_$i', 'Spikes_down', { x: point.x, y: point.y - 4 });
            if (spikesDown != null) {
                spikesDown.offset.set(0, 4);
                spikes.add(spikesDown);
            }

            final collide = createTileLayer(world, 'Level_$i', 'Ground', point);
            final downPlugs = createTileLayer(world, 'Level_$i', 'Plugs_down', point);
            if (i == 0) {
                downPlugs.destroy();
            }

            final upPlugs = createTileLayer(world, 'Level_$i', 'Plugs_up', point);
            upPlugs.visible = false;

            final roomEnemies = [];
            if (roomData.enemies != null) {
                for (e in roomData.enemies) {
                    final enemy = new Enemy(
                        point.x + e.pos.x,
                        point.y + e.pos.y,
                        this,
                        e.type,
                        e.vel
                    );
                    roomEnemies.push(enemy);
                    enemies.add(enemy);
                }
            }

            final choiceItems = new FlxGroup();

            final textItem1 = makeText(
                roomData.choices[0],
                { x: 0, y: point.y + 62 }
            );
            textItem1.x = 40 - textItem1.width / 2;

            final textItem2 = makeText(
                roomData.choices[1],
                { x: 80, y: point.y + 62 }
            );
            textItem2.x = 120 - textItem2.width / 2;

            final arrowItem1 = new FlxSprite(40, point.y + 72, AssetPaths.down_arrow__png);
            final arrowItem2 = new FlxSprite(104, point.y + 72, AssetPaths.down_arrow__png);

            choiceItems.add(textItem1);
            choiceItems.add(textItem2);
            choiceItems.add(arrowItem1);
            choiceItems.add(arrowItem2);

            choiceItems.visible = i == 0;
            add(choiceItems);

            rooms[i] = {
                collide: collide,
                spikes: spikes,
                enemies: roomEnemies,
                upPlugs: upPlugs,
                downPlugs: downPlugs,
                choiceItems: choiceItems
            };

            point.y += ROOM_HEIGHT;
        }

        spritesGroup.add(enemies);

        player = new Player(25, 25, this);
        spritesGroup.add(player);

        projectiles = new FlxTypedGroup<Projectile>(BULLET_POOL_SIZE);
        for (_ in 0...BULLET_POOL_SIZE) {
            final proj = new Projectile();
            proj.kill();
            projectiles.add(proj);
        }
        spritesGroup.add(projectiles);

        explosions = new FlxTypedGroup<Explosion>(BULLET_POOL_SIZE);
        for (_ in 0...BULLET_POOL_SIZE) {
            final expl = new Explosion();
            expl.kill();
            explosions.add(expl);
        }
        spritesGroup.add(explosions);

        add(spritesGroup);

        screenPoint = { x: 0, y: GLOBAL_Y_OFFSET };

        aimer = new FlxSprite(0, 0, AssetPaths.aimer__png);
        aimer.offset.set(4, 4);
        aimer.setSize(1, 1);
        add(aimer);
        positionAimer();
    }
}
