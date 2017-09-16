typedef Ship = {
    var velocity:Float;
    var display:h2d.Bitmap;
    var behaviours:Array<Behaviour>;
}

typedef Behaviour = Main -> Ship -> Float -> Bool;

@:access(Main)
class ShipBehaviours {

    public static function moving(env:Main, ship:Ship, dt:Float):Bool {
        ship.display.x += ship.velocity * dt;
        return false;
    }

    public static function rotateAlways(env:Main, ship:Ship, dt:Float):Bool {
        if (((ship.velocity < 0) && (ship.display.x <= 0)) ||
            ((ship.velocity > 0) && (ship.display.x >= 2100)))
        {
            ship.display.scaleX *= -1;
            ship.velocity *= -1; 
        }
        return false;
    }
}

class Config {

    public static inline var MAX_PERISCOPE_VEL:Float = 3.0;
    public static inline var DEPLOY_X_LEFT :Float = 0.0;
    public static inline var DEPLOY_X_RIGHT:Float = 2000.0;
    public static inline var DEPLOY_Y:Float = 360.0;
    public static inline var CONTROLLER_SENSIVITY:Float = 10.0;
    public static inline var PERISCOPE_MIN:Float = -300.0;
    public static inline var PERISCOPE_MAX:Float = 300.0;
    public static inline var TORPEDOE_VELOCITY:Float = 1.0;

    public static function shipTypes():Array<{tileId:Int, velocity:Float, behaviours:Array<Behaviour>}> {
        return [
            for (i in 1...31)
            {
                tileId: i,
                velocity: (i + 1.0) * 0.2,
                behaviours:[ShipBehaviours.moving, ShipBehaviours.rotateAlways]
            }
        ];
    }
}

class Main extends hxd.App {

    var shipsTexture:h3d.mat.Texture;
    var ships:Array<Ship> = [];
    var aiming:Null<{x0:Float, y0:Float, cx:Float, cy:Float}>;
    var torpedoe:Null<{x:Float, y:Float}>;
    var touchPoint:h3d.Vector;
    var sea:h2d.Sprite;
    var maxShips:Int = 1;
    var lastShipTime:Float = 0.0;
    var shipDeployRate:Float = 1.0;

    override function init() {
        engine.backgroundColor = 0xffffff;
        shipsTexture = hxd.Res.ships.toTexture();
        sea = new h2d.Sprite(s2d);
        var back = new h2d.Bitmap(hxd.Res.sea.toTile(), sea);
        back.scaleX = s2d.width * 1.5 / back.tile.width;
        back.setPos(Config.PERISCOPE_MIN, s2d.height - back.tile.height);

        var interactive = new h2d.Interactive(s2d.width, s2d.height, s2d);
        interactive.onPush= function(e) {
            aiming = {x0:e.relX, y0:e.relY, cx:e.relX, cy:e.relY};
        };

        interactive.onRelease = function(_) {
            aiming = null;
            torpedoe = {y:0.0};
        };

        interactive.onMove = function(e) {
            if (aiming != null) {
                aiming.cx = e.relX;
                aiming.cy = e.relY;
            }
        }
    }

    override function update(dt:Float) {
        updatePeriscope(dt);
        updateShips(dt);
        updateTorpedoe(dt);
    }

    function updateTorpedoe(dt:Float) {
        if (torpedoe != null){
            torpedoe.y -= dt*Config.TORPEDOE_VELOCITY;
            if (torpedoe.y < getHorizon())
            {
                if (torpedoe)
            }
        }
    }

    function updatePeriscope(dt:Float) {
        if (aiming != null) {
            var d = (aiming.x0 - aiming.cx) / Config.CONTROLLER_SENSIVITY;
            var sign = (d > 0) ? 1 : -1;
            var v = sign * Math.min(Config.MAX_PERISCOPE_VEL, Math.abs(d));
            var newX = Math.floor(Math.max(Config.PERISCOPE_MIN, Math.min(Config.PERISCOPE_MAX, sea.x + v)));
            sea.setPos(newX, sea.y);
        }
    }

    function updateShips(dt:Float) {
        var t = haxe.Timer.stamp();
        if (isTimeToDeploy(t) && (ships.length < maxShips)) {
            deployNewShip();
        }

        for (ship in ships) {
            for (b in ship.behaviours) {
                b(this, ship, dt);
            }
        }
    }

    inline function isTimeToDeploy(t:Float):Bool {
        return ((t - lastShipTime) >= shipDeployRate);
    }

    function deployNewShip() {
        var shipTypes = Config.shipTypes();
        var shipConfig = shipTypes[Math.floor(Math.random() * shipTypes.length)];
        shipConfig.velocity = 1.0;
        var tileW = shipsTexture.width / 4;
        var tileH = shipsTexture.height / 8;
        var tileX = (shipConfig.tileId % 4) * tileW; 
        var tileY = (shipConfig.tileId % 8) * tileH; 
        var tile = h2d.Tile.fromTexture(shipsTexture);
        tile.setPos(Math.floor(tileX), Math.floor(tileY));
        tile.setSize(Math.floor(tileW), Math.floor(tileH));
        tile = tile.center();

        var sign = (Math.random() < 0.5) ? -1.0 : 1.0;
        
        var ship:Ship = {
            velocity : shipConfig.velocity * sign,
            display : new h2d.Bitmap(tile, sea),
            behaviours : shipConfig.behaviours
        };
        ship.display.x = (sign < 0) ? Config.DEPLOY_X_RIGHT : Config.DEPLOY_X_LEFT;
        ship.display.y = getHorizon();
        ship.display.scaleX = sign;
        ships.push(ship);

        lastShipTime = haxe.Timer.stamp();
    }

    private inline function getHorizon():Float{
        return s2d.height - Config.DEPLOY_Y;
    }

    static function main() {
		hxd.Res.initEmbed();
		new Main();
    }
}
