import luxe.Visual;
import luxe.Vector;
import luxe.utils.Maths;
import luxe.tween.*;

class Avatar extends Visual {
	public var curTerrain : Terrain;
	public var terrainPos : Float = 0;
	public var velocity : Vector = new Vector(0,0);
	private var isCoasting = false;

	override function update(dt:Float) {
		if (curTerrain != null) {
			//update terrain pos
			terrainPos += velocity.x * dt;
			terrainPos = Maths.clamp(terrainPos, 0, curTerrain.length); //terain length is slow right now, because it always goes through a loop

			//trace(terrainPos);

			//update world pos
			var groundPos = curTerrain.worldPosFromTerrainPos(terrainPos);
			pos = groundPos.subtract(new Vector(size.x * 0.5, size.y));
		}
	}

	public function coast(velocityX : Float, time : Float) {
		velocity.x = velocityX;
		isCoasting = true;
		Actuate.tween(velocity, time, {x: 0}).ease(luxe.tween.easing.Quad.easeOut).onComplete(function() { isCoasting = false; });
	}

	//replace with velocity setter?
	public function changeVelocity(velocityX) {
		if (isCoasting) {
			isCoasting = false;
			Actuate.stop(velocity); //stop "animating" the velocity
		}
		velocity.x = velocityX;
	}
}