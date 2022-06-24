import actors.Boss;
import actors.BossOne;
import actors.BossThree;
import actors.BossTwo;
import actors.Enemy;
import actors.Player;
import actors.Shooter;
import actors.SpritesGroup;
import data.Constants;
import data.Game;
import data.Levels;
import display.Button;
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
    var shooters:Array<Shooter>;
    var textItems:Array<FlxBitmapText>;
    var ?powerupItems:FlxGroup;
}

typedef PlayerSkills = {
    var jumps:Int;
    var dashes:Int;
    var dashVel:Float;
}

class PlayState extends GameState {
    static inline final BULLET_POOL_SIZE:Int = 100;
    static inline final ROOM_HEIGHT:Int = 96;
    static inline final MAX_DASHES:Int = 5; // can be changed, fine to go way over
    static inline final OVERLAP_CHECK_DISTANCE:Int = 5;
    static inline final BOUNDS_DISTANCE:Int = 4;

    public var skills:PlayerSkills;
    var currentWorld:Worlds;
    var currentRoom:Null<Int>;
    var rooms:Array<Room> = [];

    public var player:Player;
    var enemies:FlxTypedGroup<FlxSprite>;
    var projectiles:FlxTypedGroup<Projectile>;
    var explosions:FlxTypedGroup<Explosion>;
    var powerups:FlxTypedGroup<Powerup>;
    var boss:Boss;
    var spritesGroup:SpritesGroup;
    var menuGroup:FlxGroup;
    var dashCounters:Array<FlxSprite>;

    public var screenPoint:IntPoint;

    var stoppedTime:Float = 0.0;
    var levelTime:Float = 0.0;

    var numEnemiesKilled:Int = 0;
    public var transitioning:Bool = true;
    var over:Bool = false;

    var timer:FlxBitmapText;
    var roomNumber:FlxBitmapText;

    override public function create() {
        super.create();

        currentWorld = Game.inst.currentWorld;

        final levelData = worldData[currentWorld];

        skills = {
            jumps: 1,
            dashes: currentWorld == LOut ? 0 : 1,
            dashVel: 250.0 // TODO: make 240 and test?
        }

        final bg = new FlxSprite(0, 0);
        bg.makeGraphic(160, 90, levelData.bgColor);
        bg.scrollFactor.set(0, 0);
        add(bg);

        spritesGroup = new SpritesGroup();

        final cameraDiff = getScrollFromDir(levelData.fromStartDir);
        camera.scroll.set(cameraDiff.x, cameraDiff.y + GLOBAL_Y_OFFSET);

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
        // positionAimer();
        super.update(elapsed);

        // TODO: add other moving Flx items to `spritesGroup`
        stoppedTime -= elapsed;
        if (stoppedTime < 0) {
            spritesGroup.updateParent(elapsed);
        }

        if (player != null && !player.dead) {
            levelTime += elapsed;
            timer.text = timeToString(levelTime);
            updateDashCounter();
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

            for (s in rooms[currentRoom].shooters) {
                s.update(elapsed);
            }

            FlxG.collide(projectiles, player.body, projHitPlayer);
            player.leftFootColliding = overlapCheck(player.leftFoot);
            player.rightFootColliding = overlapCheck(player.rightFoot);
            FlxG.collide(projectiles, player.body, projHitPlayer);
            FlxG.overlap(enemies, player.body, enemyHitPlayer);
            FlxG.overlap(boss, player.body, bossHitPlayer);
            FlxG.overlap(powerups, player.body, playerGetPowerup);

            checkRooms();
        }

        // HACK: delete this!
        if (FlxG.keys.justPressed.G) {
            if (currentWorld == LDown) {
                player.setPosition(72, 688);
                currentRoom = 8;
                moveRoom(Down);
            } else if (currentWorld == LRight) {
                player.setPosition(1120, 72);
                currentRoom = 6;
                moveRoom(Right);
            } else if (currentWorld == LUp) {
                player.setPosition(76, -570);
                currentRoom = 6;
                moveRoom(Up);
            }
        }

        if (FlxG.keys.justPressed.ESCAPE && !over) {
            loseLevel();
        }
    }

    public function shoot (x:Float, y:Float, vel:IntPoint, acc:IntPoint) {
        final proj = projectiles.getFirstAvailable();
        proj.shoot(x, y, vel, acc);
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

    function projHitPlayer (proj:Projectile, playerBody:FlxSprite) {
        if (!player.dead) {
            loseLevel();
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
                    generateExplosion(midpoint.x, midpoint.y, 'pop');
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
        var graphic:String = '';
        if (powerup.type == PlusOneDash) {
            graphic = AssetPaths.plus_dash_modal__png;
        }

        final modal = new FlxSprite(-160, 90, graphic);
        modal.scrollFactor.set(0, 0);
        add(modal);

        FlxTween.tween(modal, { x: -80, y: 32 }, 0.75, { ease: FlxEase.quartInOut }).then(
            FlxTween.tween(
                modal,
                { x: 0, y: -16 },
                0.6,
                {
                    ease: FlxEase.quartInOut,
                    onComplete: (_:FlxTween) -> {
                        modal.destroy();
                    }
                }
            )
        );

        final midpoint = powerup.getMidpoint();
        generateExplosion(midpoint.x, midpoint.y, 'pop');
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
        We slide around corners on the y axis more aggressively, hence the `i <= 3` check for x vals.
    **/
    function dashOverlapCheck () {
        // TODO: if this doesn't work, collideCheck() works ok
        if (overlapCheck(player)) {
            final origPlayerPos = { x: player.x, y: player.y };
            // xMajor is moving more on the x axis than the y
            final xMajor = Math.abs(player.velocity.x) > Math.abs(player.velocity.y);

            if (
                Math.abs(player.velocity.x) / Math.abs(player.velocity.y) < 0.75 ||
                Math.abs(player.velocity.y) / Math.abs(player.velocity.x) < 0.75
            ) {
                // trace('\n\nchecking!!!', xMajor ? 'on y' : 'on x');
                for (i in 1...OVERLAP_CHECK_DISTANCE) {
                    if (xMajor) {
                        player.y = origPlayerPos.y + i;
                    } else if (i <= 3) {
                        player.x = origPlayerPos.x + i;
                    }

                    if (!overlapCheck(player)) {
                        // trace('overlaps plus', i, xMajor ? 'on y' : 'on x');
                        return;
                    }

                    if (xMajor) {
                        player.y = origPlayerPos.y - i;
                    } else if (i <= 3) {
                        player.x = origPlayerPos.x - i;
                    }

                    if (!overlapCheck(player)) {
                        // trace('overlaps minus ', i, xMajor ? 'on y' : 'on x');
                        return;
                    }
                }

                player.setPosition(origPlayerPos.x, origPlayerPos.y);
            } else {
                trace('not checking!!', Math.abs(player.velocity.x) / Math.abs(player.velocity.y), Math.abs(player.velocity.y) / Math.abs(player.velocity.x));
            }

            collideCheck();
        }
    }

    function overlapCheck (sprite:FlxSprite):Bool {
        return sprite != null && (rooms[currentRoom].collide.overlaps(sprite) ||
            (rooms[currentRoom].inPlugs.alive && rooms[currentRoom].inPlugs.overlaps(sprite)) ||
            (rooms[currentRoom].outPlugs.alive && rooms[currentRoom].outPlugs.overlaps(sprite)));
    }

    function collideCheck () {
        FlxG.collide(rooms[currentRoom].collide, player, playerCollideGround);
        FlxG.collide(rooms[currentRoom].inPlugs, player, playerCollideGround);
        FlxG.collide(rooms[currentRoom].outPlugs, player, playerCollideGround);
    }

    public function enemyDie () {
        numEnemiesKilled++;
        if (numEnemiesKilled == rooms[currentRoom].enemies.length) {
            if (currentWorld == LUp) {
                generateExplosion(80, screenPoint.y + 10, 'warn', 180);
            } else if (currentWorld == LDown) {
                generateExplosion(80, screenPoint.y + 84, 'warn');
            }

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
        hitStop(1.0, () -> {
            rooms[currentRoom].outPlugs.destroy();
            rooms[currentRoom].outPlugs.alive = false;
            for (i in 0...16) {
                new FlxTimer().start(i / 8, (_:FlxTimer) -> {
                    generateExplosion(
                        Math.random() * boss.width + boss.x,
                        Math.random() * boss.width + boss.y,
                        'pop'
                    );
                });
            }

            new FlxTimer().start(2, (_:FlxTimer) -> {
                FlxTween.tween(boss, { 'scale.x': 0.0 }, 0.2, { ease: FlxEase.backIn });
                FlxTween.tween(
                    boss,
                    { 'scale.y': 2 },
                    0.14,
                    { ease: FlxEase.quintIn, startDelay: 0.06 }
                );
            });
        });
    }

    function loseLevel () {
        player.die();
        over = true;
        transitioning = true;
        Game.inst.loseLevel(currentWorld, levelTime);
        hitStop(0.5, () -> {
            final midpoint = player.getMidpoint();
            generateExplosion(midpoint.x, midpoint.y, 'pop');
            final toPos = getScrollFromDir(worldData[currentWorld].postLoseDir);
            toPos.x *= 10;
            toPos.y *= 10;
            toPos.x += Std.int(camera.scroll.x);
            toPos.y += Std.int(camera.scroll.y);
            for (c in dashCounters) {
                c.destroy();
            }
            createMenu(toPos, false);
            FlxTween.tween(
                camera,
                { 'scroll.x': toPos.x, 'scroll.y': toPos.y },
                1,
                { ease: FlxEase.quadInOut, startDelay: 0.5 }
            );
        });
    }

    function winLevel () {
        player.die();
        over = true;
        transitioning = true;
        // TODO: show star for new best?
        Game.inst.winLevel(currentWorld, levelTime);
        final toPos = getScrollFromDir(worldData[currentWorld].postWinDir);
        toPos.x += Std.int(camera.scroll.x);
        toPos.y += Std.int(camera.scroll.y);
        for (c in dashCounters) {
            c.destroy();
        }
        roomNumber.visible = false;
        createMenu(toPos, true);
        FlxTween.tween(
            camera,
            { 'scroll.x': toPos.x, 'scroll.y': toPos.y },
            1,
            { ease: FlxEase.quadInOut, startDelay: 0.5 }
        );
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

    function checkRooms () {
        if (transitioning) {
            return;
        }

        if (player.x < screenPoint.x) {
            moveRoom(Left);
            player.flipX = false;
            return;
        }

        if (player.x + player.width > screenPoint.x + 160) {
            moveRoom(Right);
            player.flipX = true;
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

    function checkBounds (dir:Dir):Bool {
        switch (dir) {
            case Left:
                if (player.x + player.width + BOUNDS_DISTANCE < screenPoint.x) {
                    return true;
                }
            case Right:
                if (player.x > screenPoint.x + 160 + BOUNDS_DISTANCE) {
                    return true;
                }
            case Up:
                if (player.y + player.height + BOUNDS_DISTANCE < screenPoint.y) {
                    return true;
                }
            case Down:
                if (player.y > screenPoint.y + 90 + BOUNDS_DISTANCE) {
                    return true;
                }
        }

        return false;
    }

    function moveRoom (dir:Dir) {
        final isFinalRoom = worldData[currentWorld].winDir == dir && currentRoom == rooms.length - 1;
        if (worldData[currentWorld].deathDirs.contains(dir) || isFinalRoom) {
            if (checkBounds(dir)) {
                if (isFinalRoom) {
                    winLevel();
                } else {
                    loseLevel();
                }
            }
            return;
        }

        for (shooter in rooms[currentRoom].shooters) {
            shooter.active = false;
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
            case Down: newY += 24;
        }

        FlxTween.tween(player, { x: newX, y: newY }, 0.5);
    }

    function finishMovingRoom () {
        transitioning = false;
        setBounds();
        player.cancelDash();
        numEnemiesKilled = 0;
        for (enemy in rooms[currentRoom].enemies) {
            enemy.active = true;
            enemy.visible = true;
        }
        for (shooter in rooms[currentRoom].shooters) {
            shooter.active = true;
        }
        rooms[currentRoom].inPlugs.visible = true;
        roomNumber.text = 'Room ' + currentRoom;
        if (currentWorld != LOut && currentRoom == rooms.length - 1) {
            boss.active = true;
            boss.visible = true;
        }
    }

    public function generateExplosion (x:Float, y:Float, anim:String, ?angle = 0.0) {
        final expl = explosions.getFirstAvailable();
        if (anim == 'pop') {
            if (currentWorld == LRight) {
                anim = 'pop-grey';
            } else {
                anim = 'pop-aqua';
            }
        }
        expl.play(x, y, anim, angle);
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

    function createMenu (point:IntPoint, win:Bool) {
        final resultTitle = new FlxSprite(
            point.x,
            point.y,
            win ? AssetPaths.escape_title__png : AssetPaths.defeat_title__png
        );
        resultTitle.color = worldData[currentWorld].titleColor;
        menuGroup.add(resultTitle);

        FlxTween.tween(roomNumber, { x: 64, y: 44 });
        FlxTween.tween(timer, { x: 20, y: 52 });

        menuGroup.add(new Button(Std.int(point.x + 45), point.y + 68, win ? Next : Retry, () -> {
            fadeOut(() -> {
                FlxG.switchState(new PlayState());
            });
        }));
        menuGroup.add(new Button(Std.int(point.x + 82), point.y + 68, Quit, () -> {
            fadeOut(() -> {
                FlxG.switchState(new MenuState());
            });
        }));
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

            final spikesLeft = createTileLayer(map, 'Level_$i', 'Spikes_left', { x: point.x + 3, y: point.y });
            if (spikesLeft != null) {
                spikesLeft.offset.set(3, 0);
                spikes.add(spikesLeft);
            }

            final spikesRight = createTileLayer(map, 'Level_$i', 'Spikes_right', { x: point.x - 3, y: point.y });
            if (spikesRight != null) {
                spikesRight.offset.set(-3, 0);
                spikes.add(spikesRight);
            }

            final spikesUp = createTileLayer(map, 'Level_$i', 'Spikes_up', { x: point.x, y: point.y + 3 });
            if (spikesUp != null) {
                spikesUp.offset.set(0, 3);
                spikes.add(spikesUp);
            }

            final spikesDown = createTileLayer(map, 'Level_$i', 'Spikes_down', { x: point.x, y: point.y - 3 });
            if (spikesDown != null) {
                spikesDown.offset.set(0, -3);
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

            final textItems = [];
            if (roomData.text != null) {
                for (t in roomData.text) {
                    final text = makeText(t.text, { x: point.x + t.pos.x, y: point.y + t.pos.y });
                    text.color = 0xff7b7b7b;
                    add(text);
                    textItems.push(text);
                }
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

            final shooters = [];
            if (roomData.shooters != null) {
                for (s in roomData.shooters) {
                    shooters.push(
                        new Shooter(
                            s.time,
                            s.offset,
                            { x: point.x + s.position.x, y: point.y + s.position.y },
                            s.velocity,
                            s.acceleration,
                            this
                        )
                    );
                }
            }

            rooms[i] = {
                point: point,
                collide: collide,
                inPlugs: inPlugs,
                outPlugs: outPlugs,
                spikes: spikes,
                enemies: roomEnemies,
                shooters: shooters,
                textItems: textItems
            };
        }

        if (currentWorld == LDown) {
            boss = new BossOne(this);
        } else if (currentWorld == LRight) {
            boss = new BossTwo(this);
        } else if (currentWorld == LUp) {
            boss = new BossThree(this);
        }

        spritesGroup.add(powerups);
        spritesGroup.add(enemies);
        spritesGroup.add(boss);

        player = new Player(world.start.x, world.start.y, this, worldData[currentWorld].playerPath);
        spritesGroup.add(player);
        spritesGroup.add(player.body);
        spritesGroup.add(player.leftFoot);
        spritesGroup.add(player.rightFoot);

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

        addAimer();
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
