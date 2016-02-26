import luxe.Color;
import luxe.Vector;
import phoenix.geometry.*;
import luxe.tween.Actuate;
import luxe.tween.actuators.GenericActuator.IGenericActuator;

using ColorExtender;
using VectorExtender;

enum Direction {
	Left;
	Right;
	Up;
	Down;
}

enum OutroAnimation {
	Disappear;
	FillScreen;
	Emphasize;
}

class ActionButton {
	//saveable data (extract into its own struct-like object?)
	var backgroundColor : Color;
	var illustrationColor : Color;
	public var terrainPos : Float;
	public var height : Float;
	public var startSize : Float;
	public var endSizeMult : Float;
	public var pullDir : Direction;
	public var outro : OutroAnimation;

	public var terrain : Terrain;
	var geo : Array<Geometry> = [];

	public var curSize : Float;
	public var curState = 0; //0 - start, 1 - end

	public var isVisible = false;
	public var isActivated = false;

	public function new() {

	}

	public function triggerTouch(pos : Vector) {
		if (!isActivated) {
			var worldPos = terrain.worldPosFromTerrainPos(terrainPos);
			worldPos.y -= height;

			/*
			trace(worldPos);
			trace(worldPos.distance(pos));
			trace(curSize);
			trace("---");
			*/

			if (worldPos.distance(pos) < curSize) {
				isActivated = true;
				animatePullSequence();
			}
		}
	}

	//hacky  as fuck
	public function triggerAppear() {
		if (!isVisible && !isActivated) {
			isVisible = true;
			animateAppear();
		}
	}

	//as fuuuuuck
	public function triggerDisappear() {
		if (isVisible && !isActivated) {
			isVisible = false;
			animateDisappear2(); //wtf ok
		}
	}

	public function animateAppear() : IGenericActuator {
		curSize = 0;
		return Actuate.tween(this, 1.0, {curSize: startSize})
					.ease(luxe.tween.easing.Bounce.easeOut)
					.onComplete(function(){
						updateCurSize();
					});
	}

	//for normal dismiss
	function animateDisappear2() {
		curSize = startSize;
		return Actuate.tween(this, 1.0, {curSize: 0})
				.ease(luxe.tween.easing.Quad.easeIn);
	}

	public function animatePull() {
		curSize = startSize;
		return Actuate.tween(this, 3.0, {curSize: startSize*endSizeMult})
					.ease(luxe.tween.easing.Quad.easeOut)
					.onComplete(function(){
						updateCurSize();
					});
	}

	public function animateOutro() { //returning this will be tricky
		switch outro {
			case OutroAnimation.Disappear:
				animateDisappear();
			case OutroAnimation.FillScreen:
				animateFillScreen();
			case OutroAnimation.Emphasize:
				animateEmphasize();
		}
	}

	function animateDisappear() {
		curSize = startSize * endSizeMult;
		return Actuate.tween(this, 1.0, {curSize: 0})
				.ease(luxe.tween.easing.Elastic.easeIn);
	}

	function animateFillScreen() {
		curSize = startSize * endSizeMult;
		return Actuate.tween(this, 1.0, {curSize: Luxe.screen.width})
				.ease(luxe.tween.easing.Quad.easeIn);
	}

	function animateEmphasize() { //how to return? (we could use a callback)
		curSize = startSize * endSizeMult;
		Actuate.tween(this, 0.6, {curSize: startSize * (endSizeMult * 1.5)})
				.ease(luxe.tween.easing.Bounce.easeOut)
				.onComplete(function() {
					Actuate.tween(this, 0.2, {curSize: 0})
							.delay(0.4)
							.ease(luxe.tween.easing.Quad.easeIn);
				});
	}

	public function animateSequence() {
		animateAppear()
			.onComplete(function() {
				animatePull()
					.onComplete(function(){
							animateOutro();
						});
			});
	}

	//second half of the sequence
	public function animatePullSequence() {
		animatePull()
			.onComplete(function(){
					animateOutro();
				});
	}

	public function showStart() {
		curSize = startSize;
		curState = 0;
	}

	public function showEnd() {
		curSize = startSize * endSizeMult;
		curState = 1;
	}

	public function updateCurSize() { //the worst kind of hack
		if (curState == 0) curSize = startSize;
		if (curState == 1) curSize = startSize * endSizeMult;
	}

	//do I need a dynamic draw too? (especially for the arrows)
	public function draw() {
		var worldPos = terrain.worldPosFromTerrainPos(terrainPos);
		worldPos.y -= height; //height above the terrain
		geo.push(
			Luxe.draw.circle({
				x : worldPos.x, y : worldPos.y,
				r : startSize,
				color : backgroundColor,
				depth : 0
			})
		);

		geo.push(
			Luxe.draw.ring({
				x : worldPos.x, y : worldPos.y,
				r : startSize,
				color : illustrationColor,
				depth : 1
			})
		);

		/*
		//draw final size too
		geo.push(
			Luxe.draw.ring({
				x : worldPos.x, y : worldPos.y,
				r : startSize * endSizeMult,
				color : illustrationColor,
				depth : 1
			})
		);
		*/

		//this is a ridiculous switch statement (remove as soon as possible)
		switch pullDir {
			case Direction.Left:
				geo.push(
					Luxe.draw.line({
						p0 : new Vector(worldPos.x - startSize - 30, worldPos.y),
						p1 : new Vector(worldPos.x - startSize - 10, worldPos.y - 10),
						color : illustrationColor
					})
				);
				geo.push(
					Luxe.draw.line({
						p0 : new Vector(worldPos.x - startSize - 30, worldPos.y),
						p1 : new Vector(worldPos.x - startSize - 10, worldPos.y + 10),
						color : illustrationColor
					})
				);
			case Direction.Right:
				geo.push(
					Luxe.draw.line({
						p0 : new Vector(worldPos.x + startSize + 30, worldPos.y),
						p1 : new Vector(worldPos.x + startSize + 10, worldPos.y - 10),
						color : illustrationColor
					})
				);
				geo.push(
					Luxe.draw.line({
						p0 : new Vector(worldPos.x + startSize + 30, worldPos.y),
						p1 : new Vector(worldPos.x + startSize + 10, worldPos.y + 10),
						color : illustrationColor
					})
				);
			case Direction.Up:
				geo.push(
					Luxe.draw.line({
						p0 : new Vector(worldPos.x, worldPos.y - startSize - 10),
						p1 : new Vector(worldPos.x - 10, worldPos.y - startSize - 30),
						color : illustrationColor
					})
				);
				geo.push(
					Luxe.draw.line({
						p0 : new Vector(worldPos.x, worldPos.y - startSize - 10),
						p1 : new Vector(worldPos.x + 10, worldPos.y - startSize - 30),
						color : illustrationColor
					})
				);
			case Direction.Down:
				geo.push(
					Luxe.draw.line({
						p0 : new Vector(worldPos.x, worldPos.y + startSize + 30),
						p1 : new Vector(worldPos.x - 10, worldPos.y + startSize + 10),
						color : illustrationColor
					})
				);
				geo.push(
					Luxe.draw.line({
						p0 : new Vector(worldPos.x, worldPos.y + startSize + 30),
						p1 : new Vector(worldPos.x + 10, worldPos.y + startSize + 10),
						color : illustrationColor
					})
				);
		}
	}

	public function drawImmediate() {
		var worldPos = new Vector(Luxe.screen.width/2, Luxe.screen.height/2); //ugly hack
		if (terrain != null) { //even uglier hack?
			worldPos = terrain.worldPosFromTerrainPos(terrainPos);
			worldPos.y -= height; 
		}

		Luxe.draw.circle({
			x : worldPos.x, y : worldPos.y,
			r : curSize,
			color : backgroundColor,
			depth : 0,
			immediate : true
		});

		Luxe.draw.ring({
			x : worldPos.x, y : worldPos.y,
			r : curSize,
			color : illustrationColor,
			depth : 1,
			immediate : true
		});

		if (curSize >= startSize) {
			//this is a ridiculous switch statement (remove as soon as possible)
			switch pullDir {
				case Direction.Left:
					Luxe.draw.line({
						p0 : new Vector(worldPos.x - curSize - 30, worldPos.y),
						p1 : new Vector(worldPos.x - curSize - 10, worldPos.y - 10),
						color : illustrationColor,
						immediate : true
					});
					Luxe.draw.line({
						p0 : new Vector(worldPos.x - curSize - 30, worldPos.y),
						p1 : new Vector(worldPos.x - curSize - 10, worldPos.y + 10),
						color : illustrationColor,
						immediate : true
					});
				case Direction.Right:
					Luxe.draw.line({
						p0 : new Vector(worldPos.x + curSize + 30, worldPos.y),
						p1 : new Vector(worldPos.x + curSize + 10, worldPos.y - 10),
						color : illustrationColor,
						immediate : true
					});
					Luxe.draw.line({
						p0 : new Vector(worldPos.x + curSize + 30, worldPos.y),
						p1 : new Vector(worldPos.x + curSize + 10, worldPos.y + 10),
						color : illustrationColor,
						immediate : true
					});
				case Direction.Up:
					Luxe.draw.line({
						p0 : new Vector(worldPos.x, worldPos.y - curSize - 30),
						p1 : new Vector(worldPos.x - 10, worldPos.y - curSize - 10),
						color : illustrationColor,
						immediate : true
					});
					Luxe.draw.line({
						p0 : new Vector(worldPos.x, worldPos.y - curSize - 30),
						p1 : new Vector(worldPos.x + 10, worldPos.y - curSize - 10),
						color : illustrationColor,
						immediate : true
					});
				case Direction.Down:
					Luxe.draw.line({
						p0 : new Vector(worldPos.x, worldPos.y + curSize + 30),
						p1 : new Vector(worldPos.x - 10, worldPos.y + curSize + 10),
						color : illustrationColor,
						immediate : true
					});
					Luxe.draw.line({
						p0 : new Vector(worldPos.x, worldPos.y + curSize + 30),
						p1 : new Vector(worldPos.x + 10, worldPos.y + curSize + 10),
						color : illustrationColor,
						immediate : true
					});
			}
		}

	}

	public function clear() {
		//Luxe.renderer.batcher.remove(circle);
		for (g in geo) {
			Luxe.renderer.batcher.remove(g);
		}
	}

	//immediate mode drawing
	public function drawUI() {
		var worldPos = terrain.worldPosFromTerrainPos(terrainPos);
		worldPos.y -= height; //height above the terrain

		Luxe.draw.ring({
			x : worldPos.x, y : worldPos.y,
			r : startSize * endSizeMult,
			color : illustrationColor,
			depth : 1,
			immediate : true
		});
	}

	public function toJson() {
		return {
			type : "action",
			backgroundColor : backgroundColor.toJson(),
			illustrationColor : illustrationColor.toJson(),
			terrainPos : terrainPos,
			height : height,
			startSize : startSize,
			endSizeMult : endSizeMult,
			pullDir : pullDir.getName(),
			outro : outro.getName()
		};
	}

	public function fromJson(json : Dynamic) : ActionButton {
		backgroundColor = (new Color()).fromJson(json.backgroundColor);
		illustrationColor = (new Color()).fromJson(json.illustrationColor);
		terrainPos = json.terrainPos;
		height = json.height;
		startSize = json.startSize;
		endSizeMult = json.endSizeMult;
		pullDir = Direction.createByName(json.pullDir);
		outro = OutroAnimation.createByName(json.outro);

		curSize = startSize;

		return this;
	}
}