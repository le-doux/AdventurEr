
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
	- edge springy bump (for camera)
	- pull up / down
	- add back slope resistance
	- get screen view constant stuff working
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
	var cameraSpeedMult : Float = 2.0;
	var cameraMaxDistAheadOfPlayer : Float = 200.0;

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
    		//player.velocity.x = scrollInput.touchDelta.x / dt;
    		player.changeVelocity(scrollInput.touchDelta.x / dt); //force velocity to match scrolling
    	}
    	else {
    		//player.velocity.x = 0;
    	}

    	//move camera
    	Luxe.camera.pos.x += player.velocity.x * cameraSpeedMult * dt;
    	var centerX = player.pos.x - 10 - (Luxe.screen.w/2);
    	Luxe.camera.pos.x = Maths.clamp(Luxe.camera.pos.x, centerX - cameraMaxDistAheadOfPlayer, centerX + cameraMaxDistAheadOfPlayer);
    } //update


} //Main
