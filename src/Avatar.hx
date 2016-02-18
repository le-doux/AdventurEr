import luxe.Visual;
import luxe.Vector;
import luxe.utils.Maths;

class Avatar extends Visual {
	public var curTerrain : Terrain;
	public var terrainPos : Float = 0;
	public var velocity : Vector = new Vector(0,0);

	override function update(dt:Float) {
		if (curTerrain != null) {
			//update terrain pos
			terrainPos += velocity.x * dt;
			terrainPos = Maths.clamp(terrainPos, 0, curTerrain.length); //terain length is slow right now, because it always goes through a loop

			//update world pos
			var groundPos = curTerrain.worldPosFromTerrainPos(terrainPos);
			pos = groundPos.subtract(new Vector(size.x * 0.5, size.y));
		}
	}
}