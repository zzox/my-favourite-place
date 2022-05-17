package util;

import flixel.tweens.FlxTween.TweenOptions;
import flixel.tweens.FlxTween;

enum SnapperState {
    Pushing;
    Pulling;
    Pushed;
    Pulled;
}
// TODO: better name?
// tweener?
// slider?

// used to move tween between two different values without duplicating tweens
class Snapper {
    var state:SnapperState;
    var pullTween:Null<FlxTween>;
    var pushTween:Null<FlxTween>;

    var target:Any;
    var time:Float;
    var pullValues:Any;
    var pushValues:Any;
    var options:Null<TweenOptions>;

    public function new (target:Any, pullValues:Any, pushValues:Any, time:Float, ?options:TweenOptions) {
        state = Pulled;

        this.target = target;
        this.time = time;
        this.pullValues = pullValues;
        this.pushValues = pushValues;
        this.options = options;
    }

    public function push () {
        var t = time;
        if (state == Pulling || state == Pulled) {
            if (state == Pulling) {
                t = pullTween.percent * time;
                pullTween.cancel();
            }

            pushTween = FlxTween.tween(target, pushValues, t, options);
            pushTween.onComplete = (_:FlxTween) -> state = Pushed;
            state = Pushing;
        }
    }

    public function pull () {
        var t = time;
        if (state == Pushing || state == Pushed) {
            if (state == Pushing) {
                t = pushTween.percent * time;
                pushTween.cancel();
            }

            pullTween = FlxTween.tween(target, pullValues, t, options);
            pullTween.onComplete = (_:FlxTween) -> state = Pulled;
            state = Pulling;
        }
    }
}
