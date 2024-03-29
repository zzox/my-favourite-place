package util;

import data.Constants;
import haxe.Json;
import openfl.Assets;

typedef LdtkLevel = {
    var point:IntPoint;
    var layers:Map<String, LdtkMap>;
}

typedef LdtkMap = {
    var tileArray:Array<Int>;
    var width:Int;
    var height:Int;
    var tileSize:Int;
}

class LdtkWorld {
    public var levels:Map<String, LdtkLevel> = [];

    public function new (mapPath:String) {
        final json:Dynamic = Json.parse(Assets.getText(mapPath));
        for (level in cast(json.levels, Array<Dynamic>)) {
            for (layer in cast(level.layerInstances, Array<Dynamic>)) {
                final width = layer.__cWid;
                final height = layer.__cHei;
                final tileArray = parseGridTiles(Std.int(width * height), layer.gridTiles);

                if (levels[level.identifier] == null) {
                    levels[level.identifier] = {
                        point: { x: level.worldX, y: level.worldY },
                        layers: new Map()
                    }
                }

                levels[level.identifier].layers[layer.__identifier] = {
                    tileArray: tileArray,
                    width: width,
                    height: height,
                    tileSize: layer.__gridSize
                };
            }
        }
    }
}

function parseGridTiles (arrayLength:Int, gridTiles:Array<Dynamic>):Array<Int> {
    final array = [for (_ in 0...arrayLength) 0];
    for (tile in gridTiles) array[tile.d[0]] = tile.t + 1;
    return array;
}
