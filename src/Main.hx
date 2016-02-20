
import luxe.Input;
import luxe.Color;
import luxe.Camera;
import luxe.Vector;
import luxe.utils.Maths;

//file IO
import sys.io.File;
import sys.io.FileOutput;
import sys.io.FileInput;
import haxe.Json;

using ColorExtender;

/*
	TODO:
	- BUG: why is player so jittery???
	- edge springy bump (for camera)
	- add back slope resistance
	- pull up / down
	- get screen view constant stuff working
	- create camera control class that wraps camera stuffs
	- need shared lib / classes
	- need to share file IO stuff
	- need to create a shared "level" class that wraps some things
	- UPDATE LUXE STUFF (get up to date w/ community???)
*/

class Main extends luxe.Game {

	//level
	var curTerrain : Terrain;
	var scenery : Array<Polystroke> = [];

	//input
	var scrollInput : ScrollInputHandler;
	var maxScrollSpeed = 1200;

	//player
	var player : Avatar;

	//camera
	var camera = {
		offsetX : 0.0,
		speedMult : 2.0,
		maxDistAheadOfPlayer : 200.0,
		edgeSpring : {
			maxDist : 200.0,
			springConstant : 50.0,
			velocityX : 0.0
		}
	};

	//screen ratio stuff
	var wRatio = 16.0;
	var hRatio = 9.0;
	var widthInWorldPixels = 800.0;
	var widthToHeight : Float; //calculated
	var heightInWorldPixels : Float; //calculated (expected = 450px)
	var zoomForCorrectWidth : Float;

	override function ready() {
		scrollInput = new ScrollInputHandler();

		player = new Avatar({
			size : new Vector(20, 60),
			color : new Color(1,0,0),
			depth : 100
		});
		player.pos = new Vector(0,0);

		widthToHeight = hRatio / wRatio;
		heightInWorldPixels = widthInWorldPixels * widthToHeight;
		zoomForCorrectWidth = Luxe.screen.width / widthInWorldPixels;

		/*
		trace(widthInWorldPixels + " x " + heightInWorldPixels);
		trace(Luxe.screen.width);
		trace(zoomForCorrectWidth);
		Luxe.camera.zoom = zoomForCorrectWidth;

		//Luxe.camera.size = Luxe.screen.size;
		Luxe.camera.size_mode = SizeMode.contain;
		Luxe.camera.size = new Vector(widthInWorldPixels, heightInWorldPixels);
		trace(Luxe.camera.size_mode);
		*/
	} //ready

	override function onkeyup( e:KeyEvent ) {

		if(e.keycode == Key.escape) {
			Luxe.shutdown();
		}

	} //onkeyup

	override function onwindowresized(e) {
		/*
		trace(e);
		//trace(Luxe.screen.width);
		//trace(Luxe.camera.viewport.w);
		zoomForCorrectWidth = Luxe.screen.width / widthInWorldPixels;
		//Luxe.camera.zoom = zoomForCorrectWidth;
		
		var newW = Luxe.screen.w;
		var newH = Luxe.screen.w * widthToHeight;
		Luxe.camera.viewport.w = newW;
		Luxe.camera.viewport.h = Luxe.screen.h;

		var playerH = 0.0;
		if (curTerrain != null) {
			playerH = curTerrain.points[0].y;
		}
		var heightAbovePlayer = newH * 0.66;
		//Luxe.camera.pos.y = newH;
		//Luxe.camera.pos.y = -(Luxe.screen.h) + newH;
		trace(Luxe.camera.pos.y);
		*/
	}


	override function onkeydown( e:KeyEvent ) {

		//open file [THIS NEEDS TO BE SHARED]
		if (e.keycode == Key.key_o && e.mod.meta ) {
			var path = Luxe.core.app.io.module.dialog_open();
			var fileStr = File.getContent(path);
			var json = Json.parse(fileStr);

			//rehydrate colors
			var backgroundColor = (new Color()).fromJson(json.backgroundColor);
			var terrainColor = (new Color()).fromJson(json.terrainColor);
			var sceneryColor = (new Color()).fromJson(json.sceneryColor);
			Luxe.renderer.clear_color = backgroundColor;

			//rehydrate terrain
			if (curTerrain != null) curTerrain.clear();
			curTerrain = new Terrain();
			curTerrain.fromJson(json.terrain);
			curTerrain.draw(terrainColor);

			//rehydrate scenery
			for (s in scenery) {
				s.destroy();
			}
			scenery = [];
			for (s in cast(json.scenery, Array<Dynamic>)) {
				var p = new Polystroke({color : sceneryColor, batcher : Luxe.renderer.batcher}, []);
				p.fromJson(s);
				scenery.push(p); //feels hacky
			}

			Luxe.camera.pos.x = curTerrain.points[0].x;

			player.curTerrain = curTerrain;
		}
	}

	override function onmouseup(e:MouseEvent) {
		if (Math.abs(scrollInput.releaseVelocity.x) > 0) {
			var scrollSpeed = Maths.clamp(scrollInput.releaseVelocity.x, -maxScrollSpeed, maxScrollSpeed);
			player.coast(scrollSpeed, 0.75); //on release, coast for 3/4 of a second
		}
	}

	override function update(dt:Float) {
		//connect input to player
		if (Luxe.input.mousedown(1)) {
			player.changeVelocity(scrollInput.touchDelta.x / dt); //force velocity to match scrolling
		}


		//cases
		/*
			- not moving
			- moving: player isn't blocked & camera isn't blocked
			- moving: player isn't blocked, but camera is
			- moving: player is blocked, but camera is moving in opposite direction
			- pushing spring: player is blocked, and camera is moving in that direction
			- moving away from spring: player is blocked, but camera is moving in opposite direction
			- springing back: camera is overextended & the player isn't touching the screen
		*/

		/*
		//move camera offset
		var camDist = player.velocity.x * camera.speedMult * dt;
		var camStartOffsetX = camera.offsetX;
		camera.offsetX += camDist;

		//lock camera if player isn't blocked
		if (!player.blocked.left) {
			camera.offsetX = Math.max(camera.offsetX, -camera.maxDistAheadOfPlayer);
		}
		if (!player.blocked.right) {
			camera.offsetX = Math.min(camera.offsetX, camera.maxDistAheadOfPlayer);
		}

		//if player IS blocked, & the camera is moving in that direction, you can push the offset further
		if (player.movingBlockedDirection()) {
			var camDistRemainder = camDist - (camera.offsetX - camStartOffsetX);

			var distPastEdge = Math.max(0, Math.abs(Luxe.camera.pos.x - centerX) - camera.maxDistAheadOfPlayer);
			var resistanceFactor = Math.max(0, 1 - Math.pow(distPastEdge / camera.edgeSpring.maxDist, 2));

			camera.offsetX += camDistRemainder * resistanceFactor;
		}

		//if there is a spring offset & the player's finger is off, spring back

		var centerX = player.pos.x - 10 - (Luxe.screen.w/2);
		*/

		var centerX = player.pos.x - 10 - (Luxe.screen.w/2);
		//need function like player.movingBlockedDirection()
		if (player.blocked.left && player.velocity.x <= 0) { //blocked left
			var distPastEdge = Math.max(0, Math.abs(Luxe.camera.pos.x - centerX) - camera.maxDistAheadOfPlayer);
			var resistanceFactor = Math.max(0, 1 - Math.pow(distPastEdge / camera.edgeSpring.maxDist, 2));
			Luxe.camera.pos.x += player.velocity.x * camera.speedMult * resistanceFactor * dt;
		}
		else if (player.blocked.right && player.velocity.x >= 0) { //blocked right
			var distPastEdge = Math.max(0, Math.abs(Luxe.camera.pos.x - centerX) - camera.maxDistAheadOfPlayer);
			var resistanceFactor = Math.max(0, 1 - Math.pow(distPastEdge / camera.edgeSpring.maxDist, 2));
			Luxe.camera.pos.x += player.velocity.x * camera.speedMult * resistanceFactor * dt;
		}
		else { //default
			Luxe.camera.pos.x += player.velocity.x * camera.speedMult * dt;
			var centerX = player.pos.x - 10 - (Luxe.screen.w/2);
			Luxe.camera.pos.x = Maths.clamp(Luxe.camera.pos.x, centerX - camera.maxDistAheadOfPlayer, centerX + camera.maxDistAheadOfPlayer);
		}

		//TODO spring camera back!
	} //update


} //Main
