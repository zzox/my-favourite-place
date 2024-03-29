package actors;

import flixel.group.FlxGroup;

// Group of sprites to control separately from main game update
class SpritesGroup extends FlxGroup {
    public function new () {
        super ();
    }

    // do nothing with regular update
    override public function update (_:Float) {}

    // update with a different time schedule
    public function updateParent (time:Float) {
        super.update(time);
    }
}
