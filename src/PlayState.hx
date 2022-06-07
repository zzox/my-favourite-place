import actors.Boss;
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
import flixel.text.FlxBitmapText;
import flixel.text.FlxText.FlxTextAlign;
import flixel.text.FlxText.FlxTextBorderStyle;
import flixel.tile.FlxBaseTilemap.FlxTilemapAutoTiling;
import flixel.tile.FlxTilemap;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.util.FlxTimer;
import objects.Explosion;
import objects.Powerup;
import objects.Projectile;
import openfl.filters.ShaderFilter;
import util.LdtkWorld;
import util.Utils;

class NamedMap extends FlxTilemap {
    public var name:Null<String>;
    public function new (?name:String) {
        super();
        this.name = name;
    }
}

typedef Room = {
    var point:IntPoint;
    var collide:FlxTilemap;
    var inPlugs:FlxTilemap;
    var outPlugs:FlxTilemap;
    var spikes:FlxTypedGroup<NamedMap>;
    var enemies:Array<Enemy>;
    var ?powerupItems:FlxGroup;
}

typedef PlayerSkills = {
    var jumps:Int;
    var dashes:Int;
    var dashVel:Float;
}

class PlayState extends FlxState {
    static inline final BULLET_POOL_SIZE:Int = 100;
    static inline final ROOM_HEIGHT:Int = 96;
    static inline final CAMERA_DIFF:Int = 2000;
    static inline final CAMERA_START_DIFF:Int = -90;
    static inline final MAX_DASHES:Int = 5; // can be changed, fine to go way over
    static inline final OVERLAP_CHECK_DISTANCE:Int = 5;

    public var skills:PlayerSkills;
    var currentWorld:Worlds;
    var currentRoom:Int;
    var rooms:Array<Room> = [];

    var player:Player;
    var enemies:FlxTypedGroup<FlxSprite>;
    var projectiles:FlxTypedGroup<Projectile>;
    var explosions:FlxTypedGroup<Explosion>;
    var powerups:FlxTypedGroup<Powerup>;
    var boss:Boss;
    var aimer:FlxSprite;
    var spritesGroup:SpritesGroup;
    var menuGroup:FlxGroup;
    var dashCounters:Array<FlxSprite>;

    var crtShader:CrtShader;
    var screenPoint:IntPoint;

    var cameraXScale:Float = 0.0;
    var cameraYScale:Float = 0.0;
    var stoppedTime:Float = 0.0;
    var levelTime:Float = 0.0;

    var numEnemiesKilled:Int = 0;
    public var transitioning:Bool = true;

    var timer:FlxBitmapText;
    var roomNumber:FlxBitmapText;

    // TEMP:
    final SHOOT_VEL = 250;

    override public function create() {
        super.create();

        currentWorld = LDown;

        skills = {
            jumps: 1,
            dashes: currentWorld == LOut ? 0 : 1,
            dashVel: 250.0
        }

        final bg = new FlxSprite(0, 0);
        bg.makeGraphic(160, 90, worldData[currentWorld].bgColor);
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
        stoppedTime -= elapsed;
        if (stoppedTime < 0) {
            spritesGroup.updateParent(elapsed);
        }

        if (camera.scaleX != 1.0 || camera.scaleY != 1.0 || cameraXScale != 1.0 || cameraYScale != 1.0) {
            camera.setScale(cameraXScale, cameraYScale);
        }

        if (player != null && !player.dead) {
            levelTime += elapsed;
            timer.text = timeToString(levelTime);
            updateDashCounter();
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

        // don't do checks during a hitstop
        if (stoppedTime < 0) {
            if (player.dashing) {
                dashOverlapCheck();
            } else {
                collideCheck();
            }

            rooms[currentRoom].spikes.forEach((m:NamedMap) -> {
                if (m.overlaps(player.body) && !player.dead) {
                    loseLevel();
                    // TODO: remove following collide method and definition?
                    // FlxG.collide(rooms[currentRoom].spikes, player, collideSpikes);
                }
            });

            // FlxG.collide(rooms[currentRoom].collide, projectiles, projHitGroud);
            FlxG.overlap(enemies, player.body, enemyHitPlayer);
            FlxG.overlap(boss, player.body, bossHitPlayer);
            FlxG.overlap(powerups, player.body, playerGetPowerup);

            checkRooms();
        }

        // HACK: delete this!
        if (FlxG.keys.justPressed.G) {
            player.setPosition(72, 688);
            currentRoom = 8;
            moveRoom(Down);
        }
    }

    function playerCollideGround (_:FlxTilemap, player:Player) {
        if (player.dashing) {
            hitStop(0.1, () -> {
                FlxG.camera.shake(0.01, 0.05);
            });
        }
    }

    function old_collideSpikes (spikes:NamedMap, player:Player) {
        if (!player.dead && (
            (player.isTouching(FlxObject.LEFT) && !player.isTouching(FlxObject.UP) &&
            !player.isTouching(FlxObject.DOWN) && spikes.name == 'Spikes_right') ||

            (player.isTouching(FlxObject.RIGHT) && !player.isTouching(FlxObject.UP) &&
            !player.isTouching(FlxObject.DOWN) && spikes.name == 'Spikes_left') ||

            (player.isTouching(FlxObject.DOWN) && !player.isTouching(FlxObject.LEFT) &&
            !player.isTouching(FlxObject.RIGHT) && spikes.name == 'Spikes_up') ||

            (player.isTouching(FlxObject.UP) && !player.isTouching(FlxObject.LEFT) &&
            !player.isTouching(FlxObject.RIGHT) && spikes.name == 'Spikes_down'))) {
            loseLevel();
        }
    }

    function old_projHitGroud (_:FlxTilemap, proj:Projectile) {
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

    function enemyHitPlayer (enemy:Enemy, playerBody:Player) {
        if (!enemy.dead && !player.dead) {
            if (player.dashing || player.postDashTime > 0) {
                enemy.hit();
                hitStop(0.2, () -> {
                    player.dashes--;
                    if (player.dashes < 0) {
                        player.dashes = 0;
                    }
                    final midpoint = enemy.getMidpoint();
                    generateExplosion(midpoint.x, midpoint.y, 'pop-aqua');
                    FlxG.camera.shake(0.01, 0.05);
                });
            } else {
                loseLevel();
                FlxG.camera.shake(0.001, 0.5);
            }
        }
    }

    function bossHitPlayer (boss:Boss, playerBody:Player) {
        if (!boss.dead && !player.dead && boss.hurtTime < 0) {
            if (player.dashing || player.postDashTime > 0) {
                boss.hit();
                hitStop(0.2, () -> {
                    player.dashes--;
                    if (player.dashes < 0) {
                        player.dashes = 0;
                    }
                    FlxG.camera.shake(0.01, 0.05);
                });
            } else {
                loseLevel();
                FlxG.camera.shake(0.001, 0.5);
            }
        }
    }

    function playerGetPowerup (powerup:Powerup, _:Player) {
        final midpoint = powerup.getMidpoint();
        generateExplosion(midpoint.x, midpoint.y, 'pop-blue');
        doPowerup(powerup.type);
        powerups.remove(powerup);
        remove(powerup);
        powerup.destroy();
    }

    function doPowerup (skill:Powerups) {
        switch (skill) {
            case FasterDash: skills.dashVel += 125;
            case PlusOneDash: skills.dashes++;
            case PlusOneJump: skills.jumps++;
        }
    }

    function hitStop (time:Float, callback:Void -> Void) {
        stoppedTime = time;
        new FlxTimer().start(time, (_:FlxTimer) -> {
            callback();
        });
    }

    /**
        When dashing, we fan out from 0 on the opposite axis that we are going
        in order to slide around corners.  This may need some tweaking to feel right.
    **/
    function dashOverlapCheck () {
        // TODO: if this doesn't work, collideCheck() works ok
        if (overlapCheck()) {
            final origPlayerPos = { x: player.x, y: player.y };
            // xMajor is moving more on the x axis than the y
            final xMajor = Math.abs(player.velocity.x) > Math.abs(player.velocity.y);

            if (
                Math.abs(player.velocity.x) / Math.abs(player.velocity.y) < 3 ||
                Math.abs(player.velocity.y) / Math.abs(player.velocity.x) < 3
            ) {
                // trace('\n\nchecking!!!', xMajor ? 'on y' : 'on x');
                for (i in 1...OVERLAP_CHECK_DISTANCE) {
                    if (xMajor) {
                        player.y = origPlayerPos.y + i;
                    } else if (i <= 3) {
                        player.x = origPlayerPos.x + i;
                    }

                    if (!overlapCheck()) {
                        // trace('overlaps plus', i, xMajor ? 'on y' : 'on x');
                        return;
                    }

                    if (xMajor) {
                        player.y = origPlayerPos.y - i;
                    } else if (i <= 3) {
                        player.x = origPlayerPos.x - i;
                    }

                    if (!overlapCheck()) {
                        // trace('overlaps minus ', i, xMajor ? 'on y' : 'on x');
                        return;
                    }
                }

                player.setPosition(origPlayerPos.x, origPlayerPos.y);
            } else {
                // trace('not checking!!', Math.abs(player.velocity.x) / Math.abs(player.velocity.y), Math.abs(player.velocity.y) / Math.abs(player.velocity.x));
            }

            collideCheck();
        }
    }

    function overlapCheck ():Bool {
        return rooms[currentRoom].collide.overlaps(player) ||
        (rooms[currentRoom].inPlugs.alive && rooms[currentRoom].inPlugs.overlaps(player)) ||
        (rooms[currentRoom].outPlugs.alive && rooms[currentRoom].outPlugs.overlaps(player));
    }

    function collideCheck () {
        FlxG.collide(rooms[currentRoom].collide, player, playerCollideGround);
        FlxG.collide(rooms[currentRoom].inPlugs, player, playerCollideGround);
        FlxG.collide(rooms[currentRoom].outPlugs, player, playerCollideGround);
    }

    public function enemyDie () {
        numEnemiesKilled++;
        if (numEnemiesKilled == rooms[currentRoom].enemies.length) {
            generateExplosion(80, screenPoint.y + 84, 'warn');
            new FlxTimer().start(1, (_:FlxTimer) -> {
                rooms[currentRoom].outPlugs.destroy();
                rooms[currentRoom].outPlugs.alive = false;
            });
            if (rooms[currentRoom].powerupItems != null) {
                rooms[currentRoom].powerupItems.visible = true;
            }
        }
    }

    public function bossDie () {
        generateExplosion(80, screenPoint.y + 84, 'warn');
        new FlxTimer().start(1, (_:FlxTimer) -> {
            rooms[currentRoom].outPlugs.destroy();
        });
    }

    function loseLevel () {
        player.die();
        hitStop(0.5, () -> {
            final midpoint = player.getMidpoint();
            generateExplosion(midpoint.x, midpoint.y, 'pop-grey');
            final yPos = Std.int(FlxG.camera.y - CAMERA_DIFF);
            for (c in dashCounters) {
                c.destroy();
            }
            createMenu(yPos);
            FlxTween.tween(
                camera,
                {  'scroll.y': yPos },
                1,
                { ease: FlxEase.quadInOut, startDelay: 0.5 }
            );
        });
    }

    function updateDashCounter () {
        for (i in 0...dashCounters.length) {
            final dashItem = dashCounters[i];
            dashItem.visible = i < skills.dashes;

            if (i < skills.dashes - player.dashes) {
                dashItem.animation.play('solid');
            } else if (dashItem.animation.curAnim.name == 'solid') {
                dashItem.animation.play('pop');
            }
        }
    }

    // ugly - returns prevent multiple room moves
    function checkRooms () {
        if (transitioning) return;

        if (player.x < screenPoint.x) {
            moveRoom(Left);
            return;
        }

        if (player.x + player.width > screenPoint.x + 160) {
            moveRoom(Right);
            return;
        }

        if (player.y < screenPoint.y) {
            moveRoom(Up);
            return;
        }

        if (player.y + player.height > screenPoint.y + 90) {
            moveRoom(Down);
        }
    }

    function moveRoom (dir:Dir) {
        if (currentRoom == rooms.length - 1) {
            trace('victory!!!');
            return;
        }

        transitioning = true;
        player.stopDash();
        currentRoom = worldData[currentWorld].levels[currentRoom].exits[dir];
        final newPoint = rooms[currentRoom].point;

        screenPoint = { x: newPoint.x, y: newPoint.y + GLOBAL_Y_OFFSET };

        movePlayer(dir);
        FlxTween.tween(
            camera.scroll,
            { x: screenPoint.x, y: screenPoint.y },
            0.5,
            { ease: FlxEase.circInOut, onComplete: (_:FlxTween) -> finishMovingRoom() }
        );
    }

    function movePlayer (dir:Dir) {
        final newX = player.x;
        final newY = player.y;

        switch (dir) {
            case Left: newX -= 16;
            case Right: newX += 16;
            case Up: newY -= 32;
            case Down: newY += 32;
        }

        FlxTween.tween(player, { x: newX, y: newY }, 0.5);
    }

    function finishMovingRoom () {
        transitioning = false;
        setBounds();
        numEnemiesKilled = 0;
        for (enemy in rooms[currentRoom].enemies) {
            enemy.active = true;
        }
        rooms[currentRoom].inPlugs.visible = true;
        roomNumber.text = 'Room ' + worldData[currentWorld].levels[currentRoom].roomNumber;
        if (currentWorld != LOut && currentRoom == rooms.length - 1) {
            boss.active = true;
        }
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
        final layerData = world.levels[levelName].layers[layerName];
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
        menuGroup.add(new Button(Std.int(camera.scroll.x + 45), yPos + 56, Retry, () -> {
            fadeOut(() -> {
                FlxG.switchState(new PlayState());
            });
        }));
        menuGroup.add(new Button(Std.int(camera.scroll.x + 82), yPos + 56, Quit, () -> {
            fadeOut(() -> {
                FlxG.switchState(new PreState());
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
        currentRoom = 0;

        final world = worldData[currentWorld];
        final map = new LdtkWorld(world.path);

        powerups = new FlxTypedGroup<Powerup>();
        enemies = new FlxTypedGroup<FlxSprite>();

        for (i in 0...world.levels.length) {
            final roomData = world.levels[i];

            final spikes = new FlxTypedGroup<NamedMap>();

            final point = map.levels['Level_$i'].point;

            final spikesLeft = createTileLayer(map, 'Level_$i', 'Spikes_left', { x: point.x + 4, y: point.y });
            if (spikesLeft != null) {
                spikesLeft.offset.set(4, 0);
                spikes.add(spikesLeft);
            }

            final spikesRight = createTileLayer(map, 'Level_$i', 'Spikes_right', { x: point.x - 4, y: point.y });
            if (spikesRight != null) {
                spikesRight.offset.set(-4, 0);
                spikes.add(spikesRight);
            }

            final spikesUp = createTileLayer(map, 'Level_$i', 'Spikes_up', { x: point.x, y: point.y + 4 });
            if (spikesUp != null) {
                spikesUp.offset.set(0, 4);
                spikes.add(spikesUp);
            }

            final spikesDown = createTileLayer(map, 'Level_$i', 'Spikes_down', { x: point.x, y: point.y - 4 });
            if (spikesDown != null) {
                spikesDown.offset.set(0, -4);
                spikes.add(spikesDown);
            }

            final collide = createTileLayer(map, 'Level_$i', 'Ground', point);
            final inPlugs = createTileLayer(map, 'Level_$i', 'Plugs_in', point);
            inPlugs.visible = false;

            final outPlugs = createTileLayer(map, 'Level_$i', 'Plugs_out', point);
            if (roomData.isOpen) {
                outPlugs.destroy();
                outPlugs.alive = false;
            }

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

            if (roomData.powerups != null) {
                for (p in roomData.powerups) {
                    powerups.add(new Powerup(point.x + p.pos.x, point.y + p.pos.y, p.type));
                }
            }

            rooms[i] = {
                point: point,
                collide: collide,
                inPlugs: inPlugs,
                outPlugs: outPlugs,
                spikes: spikes,
                enemies: roomEnemies,
            };
        }

        if (currentWorld != LOut) {
            boss = new Boss(this);
        }

        spritesGroup.add(powerups);
        spritesGroup.add(enemies);
        spritesGroup.add(boss);

        player = new Player(world.start.x, world.start.y, this);
        spritesGroup.add(player);
        spritesGroup.add(player.body);

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

        createHud();

        aimer = new FlxSprite(0, 0, AssetPaths.aimer__png);
        aimer.offset.set(4, 4);
        aimer.setSize(1, 1);
        add(aimer);
        positionAimer();
    }

    function createHud () {
        menuGroup = new FlxGroup();
        add(menuGroup);

        timer = makeText('0.00', { x: 80, y: -1 });
        timer.setBorderStyle(FlxTextBorderStyle.OUTLINE, 0xff0d2030);
        timer.scrollFactor.set(0, 0);
        timer.autoSize = false;
        timer.width = timer.fieldWidth = 71;
        timer.alignment = FlxTextAlign.RIGHT;
        timer.letterSpacing = -1;
        timer.color = 0xffa8a8a8;
        menuGroup.add(timer);

        roomNumber = makeText('Room 0', { x: 9, y: -1 });
        roomNumber.setBorderStyle(FlxTextBorderStyle.OUTLINE, 0xff0d2030);
        roomNumber.scrollFactor.set(0, 0);
        roomNumber.letterSpacing = -1;
        roomNumber.color = 0xffa8a8a8;

        dashCounters = [];
        for (i in 0...MAX_DASHES) {
            final counter = new FlxSprite(i * 10 + 2, 82);
            counter.scrollFactor.set(0, 0);
            counter.loadGraphic(AssetPaths.dash_counter__png, true, 8, 8);
            counter.animation.add('solid', [0]);
            counter.animation.add('pop', [1, 2, 3], 24, false);
            counter.animation.play('solid');
            counter.visible = false;
            menuGroup.add(counter);
            dashCounters.push(counter);
        }

        menuGroup.add(roomNumber);
    }
}
