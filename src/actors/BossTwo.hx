package actors;

import data.Constants;
import flixel.FlxG;
import flixel.util.FlxTimer;

enum BossTwoState {
    Scanning;
    Attacking;
}
final scanPositions = [
    { startPos: { x: 1088, y: 24 }, vel: { x: 240, y: 0 } },
    { startPos: { x: 1280, y: 24 }, vel: { x: -240, y: 0 } },
];
final attackPositions = [
    { startPos: { x: 1088, y: 56 }, vel: { x: 300, y: 0 }, dir: Right },
    { startPos: { x: 1280, y: 56 }, vel: { x: -300, y: 0 }, dir: Left },
];

class BossTwo extends Boss {
    static inline final HURT_FRAMES:Float = 3;

    var currentAttackDirection:Dir;
    var currentScanPosition:Int = 0;
    var currentAttack:BossTwoState = Scanning;
    var state:BossTwoState;
    var reversing:Bool = false;

    public function new (scene:PlayState) {
        super(scene);

        loadGraphic(AssetPaths.bird_boss__png, true, 32, 32);
        offset.set(4, 1);
        setSize(24, 28);

        animation.add('flap', [0, 1, 1], 12);
        animation.add('attack', [2]);
        startScan();
    }

    override public function update (elapsed:Float) {
        if (!reversing) {
            if (velocity.x < 0 && flipX) {
                flipX = false;
            }

            if (velocity.x > 0 && !flipX) {
                flipX = true;
            }
        }

        if (reversing) {
            if (x < 1088 || x > 1280) {
                if (state == Scanning) {
                    startAttack();
                } else {
                    startScan();
                }
            }
        } else {
            if (state == Attacking) {
                if ((x < 1088 && currentAttackDirection == Left) ||
                    (x > 1280 && currentAttackDirection == Right)
                ) {
                    currentScanPosition = ++currentScanPosition % 2;
                    startScan();
                } else if ((x < 1088 && currentAttackDirection == Right) ||
                    (x > 1280 && currentAttackDirection == Left)
                ) {
                    velocity.x = -velocity.x;
                }
            } else if (x < 1088 || x > 1280) {
                startAttack();
            }
        }

        super.update(elapsed);
    }

    function startScan () {
        setPosition(1200, -100);
        velocity.set(0, 0);

        new FlxTimer().start(1.0, (_:FlxTimer) -> {
            animation.play('flap');
            state = Scanning;
            reversing = false;
            hurtTime = 0;

            final pos = scanPositions[currentScanPosition];
            currentScanPosition = ++currentScanPosition % 2;

            setPosition(pos.startPos.x, pos.startPos.y);
            velocity.set(pos.vel.x, pos.vel.y);
        });
    }

    function startAttack () {
        setPosition(1200, -100);
        velocity.set(0, 0);

        new FlxTimer().start(1.0, (_:FlxTimer) -> {
            animation.play('attack');
            state = Attacking;
            reversing = false;
            hurtTime = 0;

            final pos = attackPositions[currentScanPosition];

            setPosition(pos.startPos.x, pos.startPos.y);
            velocity.set(pos.vel.x, pos.vel.y);
            FlxG.sound.play(AssetPaths.choose_land__mp3, 0.2);
            currentAttackDirection = pos.dir;
        });
    }

    override public function hit () {
        super.hit();

        reversing = true;
        velocity.x = -velocity.x;
        if (state == Scanning) {
            currentScanPosition = Std.int(Math.abs(--currentScanPosition % 2));
        }
    }
}
