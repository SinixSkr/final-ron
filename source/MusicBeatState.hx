package;

import important.Conductor.BPMChangeEvent;
import important.PlayerSettings;
import openfl.filters.ShaderFilter;
import flixel.FlxCamera;
import misc.DynamicShaderHandler;
import flixel.FlxG;
import flixel.addons.ui.FlxUIState;
import flixel.math.FlxRect;
import flixel.util.FlxTimer;
import flixel.addons.transition.FlxTransitionableState;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.FlxSprite;
import flixel.util.FlxColor;
import flixel.util.FlxGradient;
import flixel.FlxState;
import flixel.FlxBasic;

class MusicBeatState extends FlxUIState
{

	public static var animatedShaders:Map<String, DynamicShaderHandler> = new Map<String, DynamicShaderHandler>();
	public static var allShaders:Array<DynamicShaderHandler> = [];
	public var luaShaders:Map<String, DynamicShaderHandler> = new Map<String, DynamicShaderHandler>();

	public var Shaders = animatedShaders;

	private var lastBeat:Float = 0;
	private var lastStep:Float = 0;

	private var curStep:Int = 0;
	private var curBeat:Int = 0;

	private var controls(get, never):Controls;

	inline function get_controls():Controls
		return PlayerSettings.player1.controls;

	override function create() {
		allShaders = [];
		var skip:Bool = FlxTransitionableState.skipNextTransOut;
		super.create();

		if(!skip) {
			openSubState(new misc.CustomFadeTransition(0.7, true));
		}
		FlxTransitionableState.skipNextTransOut = false;
	}
	public function addShader(camera:FlxCamera, shader:String)
	{
		if (animatedShaders[shader] == null) new DynamicShaderHandler(shader);
		if (ClientPrefs.shaders)
			camera.filters.push(new ShaderFilter(animatedShaders[shader].shader));
		
	}
	public function clearShader(camera:FlxCamera)
	{
		camera.setFilters([]);
		allShaders = [];
	}
	
	#if (VIDEOS_ALLOWED && windows)
	override public function onFocus():Void
	{
		misc.FlxVideo.onFocus();
		super.onFocus();
	}
	
	override public function onFocusLost():Void
	{
		misc.FlxVideo.onFocusLost();
		super.onFocusLost();
	}
	#end

	override function update(elapsed:Float)
	{
		if(ClientPrefs.shaders)
		{
			for (shader in animatedShaders)
			{
				shader.update(elapsed);
			}
			#if LUA_ALLOWED
			for (key => value in luaShaders)
			{
				value.update(elapsed);
			}
			#end
		}

		//everyStep();
		var oldStep:Int = curStep;

		updateCurStep();
		updateBeat();

		if (oldStep != curStep && curStep > 0)
			stepHit();

		if(FlxG.save.data != null) FlxG.save.data.fullscreen = FlxG.fullscreen;

		super.update(elapsed);
		if(ClientPrefs.shaders) Shaders = animatedShaders;
	}

	private function updateBeat():Void
	{
		curBeat = Math.floor(curStep / 4);
	}

	private function updateCurStep():Void
	{
		var lastChange:BPMChangeEvent = {
			stepTime: 0,
			songTime: 0,
			bpm: 0
		}
		for (i in 0...Conductor.bpmChangeMap.length)
		{
			if (Conductor.songPosition >= Conductor.bpmChangeMap[i].songTime)
				lastChange = Conductor.bpmChangeMap[i];
		}

		curStep = lastChange.stepTime + Math.floor(((Conductor.songPosition - ClientPrefs.noteOffset) - lastChange.songTime) / Conductor.stepCrochet);
	}

	public static function switchState(nextState:FlxState) {
		// Custom made Trans in
		var curState:Dynamic = FlxG.state;
		var leState:MusicBeatState = curState;
		if(!FlxTransitionableState.skipNextTransIn) {
			leState.openSubState(new misc.CustomFadeTransition(0.6, false));
			if(nextState == FlxG.state) {
				misc.CustomFadeTransition.finishCallback = function() {
					FlxG.resetState();
				};
				//trace('resetted');
			} else {
				misc.CustomFadeTransition.finishCallback = function() {
					FlxG.switchState(nextState);
				};
				//trace('changed state');
			}
			return;
		}
		FlxTransitionableState.skipNextTransIn = false;
		FlxG.switchState(nextState);
	}
#if android
	public var trackedinputsUI:Array<FlxActionInput> = [];
	public var trackedinputsNOTES:Array<FlxActionInput> = [];

	public function addbuttonNOTES(action:FlxActionDigital, button:FlxButton, state:FlxInputState)
	{
		var input:FlxActionInputDigitalIFlxInput = new FlxActionInputDigitalIFlxInput(button, state);
		trackedinputsNOTES.push(input);
		action.add(input);
	}

	public function addbuttonUI(action:FlxActionDigital, button:FlxButton, state:FlxInputState)
	{
		var input:FlxActionInputDigitalIFlxInput = new FlxActionInputDigitalIFlxInput(button, state);
		trackedinputsUI.push(input);
		action.add(input);
	}

	public function setHitBox(Hitbox:FlxHitbox) 
	{
		inline forEachBound(Control.NOTE_UP, (action, state) -> addbuttonNOTES(action, Hitbox.buttonUp, state));
		inline forEachBound(Control.NOTE_DOWN, (action, state) -> addbuttonNOTES(action, Hitbox.buttonDown, state));
		inline forEachBound(Control.NOTE_LEFT, (action, state) -> addbuttonNOTES(action, Hitbox.buttonLeft, state));
		inline forEachBound(Control.NOTE_RIGHT, (action, state) -> addbuttonNOTES(action, Hitbox.buttonRight, state));
	}

	public function setVirtualPadUI(VirtualPad:FlxVirtualPad, DPad:FlxDPadMode, Action:FlxActionMode)
	{
		switch (DPad)
		{
			case UP_DOWN:
				inline forEachBound(Control.UI_UP, (action, state) -> addbuttonUI(action, VirtualPad.buttonUp, state));
				inline forEachBound(Control.UI_DOWN, (action, state) -> addbuttonUI(action, VirtualPad.buttonDown, state));
			case LEFT_RIGHT:
				inline forEachBound(Control.UI_LEFT, (action, state) -> addbuttonUI(action, VirtualPad.buttonLeft, state));
				inline forEachBound(Control.UI_RIGHT, (action, state) -> addbuttonUI(action, VirtualPad.buttonRight, state));
			case UP_LEFT_RIGHT:
				inline forEachBound(Control.UI_UP, (action, state) -> addbuttonUI(action, VirtualPad.buttonUp, state));
				inline forEachBound(Control.UI_LEFT, (action, state) -> addbuttonUI(action, VirtualPad.buttonLeft, state));
				inline forEachBound(Control.UI_RIGHT, (action, state) -> addbuttonUI(action, VirtualPad.buttonRight, state));
			case LEFT_FULL | RIGHT_FULL:
				inline forEachBound(Control.UI_UP, (action, state) -> addbuttonUI(action, VirtualPad.buttonUp, state));
				inline forEachBound(Control.UI_DOWN, (action, state) -> addbuttonUI(action, VirtualPad.buttonDown, state));
				inline forEachBound(Control.UI_LEFT, (action, state) -> addbuttonUI(action, VirtualPad.buttonLeft, state));
				inline forEachBound(Control.UI_RIGHT, (action, state) -> addbuttonUI(action, VirtualPad.buttonRight, state));
			case BOTH_FULL:
				inline forEachBound(Control.UI_UP, (action, state) -> addbuttonUI(action, VirtualPad.buttonUp, state));
				inline forEachBound(Control.UI_DOWN, (action, state) -> addbuttonUI(action, VirtualPad.buttonDown, state));
				inline forEachBound(Control.UI_LEFT, (action, state) -> addbuttonUI(action, VirtualPad.buttonLeft, state));
				inline forEachBound(Control.UI_RIGHT, (action, state) -> addbuttonUI(action, VirtualPad.buttonRight, state));
				inline forEachBound(Control.UI_UP, (action, state) -> addbuttonUI(action, VirtualPad.buttonUp2, state));
				inline forEachBound(Control.UI_DOWN, (action, state) -> addbuttonUI(action, VirtualPad.buttonDown2, state));
				inline forEachBound(Control.UI_LEFT, (action, state) -> addbuttonUI(action, VirtualPad.buttonLeft2, state));
				inline forEachBound(Control.UI_RIGHT, (action, state) -> addbuttonUI(action, VirtualPad.buttonRight2, state));
			case NONE: // do nothing
		}

		switch (Action)
		{
			case A:
				inline forEachBound(Control.ACCEPT, (action, state) -> addbuttonUI(action, VirtualPad.buttonA, state));
			case B:
				inline forEachBound(Control.BACK, (action, state) -> addbuttonUI(action, VirtualPad.buttonB, state));
			case A_B | A_B_C | A_B_E | A_B_X_Y | A_B_C_X_Y | A_B_C_X_Y_Z | A_B_C_D_V_X_Y_Z:
				inline forEachBound(Control.ACCEPT, (action, state) -> addbuttonUI(action, VirtualPad.buttonA, state));
				inline forEachBound(Control.BACK, (action, state) -> addbuttonUI(action, VirtualPad.buttonB, state));
			case NONE: // do nothing
		}
	}

	public function setVirtualPadNOTES(VirtualPad:FlxVirtualPad, DPad:FlxDPadMode, Action:FlxActionMode) 
	{
		switch (DPad)
		{
			case UP_DOWN:
				inline forEachBound(Control.NOTE_UP, (action, state) -> addbuttonNOTES(action, VirtualPad.buttonUp, state));
				inline forEachBound(Control.NOTE_DOWN, (action, state) -> addbuttonNOTES(action, VirtualPad.buttonDown, state));
			case LEFT_RIGHT:
				inline forEachBound(Control.NOTE_LEFT, (action, state) -> addbuttonNOTES(action, VirtualPad.buttonLeft, state));
				inline forEachBound(Control.NOTE_RIGHT, (action, state) -> addbuttonNOTES(action, VirtualPad.buttonRight, state));
			case UP_LEFT_RIGHT:
				inline forEachBound(Control.NOTE_UP, (action, state) -> addbuttonNOTES(action, VirtualPad.buttonUp, state));
				inline forEachBound(Control.NOTE_LEFT, (action, state) -> addbuttonNOTES(action, VirtualPad.buttonLeft, state));
				inline forEachBound(Control.NOTE_RIGHT, (action, state) -> addbuttonNOTES(action, VirtualPad.buttonRight, state));
			case LEFT_FULL | RIGHT_FULL:
				inline forEachBound(Control.NOTE_UP, (action, state) -> addbuttonNOTES(action, VirtualPad.buttonUp, state));
				inline forEachBound(Control.NOTE_DOWN, (action, state) -> addbuttonNOTES(action, VirtualPad.buttonDown, state));
				inline forEachBound(Control.NOTE_LEFT, (action, state) -> addbuttonNOTES(action, VirtualPad.buttonLeft, state));
				inline forEachBound(Control.NOTE_RIGHT, (action, state) -> addbuttonNOTES(action, VirtualPad.buttonRight, state));
			case BOTH_FULL:
				inline forEachBound(Control.NOTE_UP, (action, state) -> addbuttonNOTES(action, VirtualPad.buttonUp, state));
				inline forEachBound(Control.NOTE_DOWN, (action, state) -> addbuttonNOTES(action, VirtualPad.buttonDown, state));
				inline forEachBound(Control.NOTE_LEFT, (action, state) -> addbuttonNOTES(action, VirtualPad.buttonLeft, state));
				inline forEachBound(Control.NOTE_RIGHT, (action, state) -> addbuttonNOTES(action, VirtualPad.buttonRight, state));
				inline forEachBound(Control.NOTE_UP, (action, state) -> addbuttonNOTES(action, VirtualPad.buttonUp2, state));
				inline forEachBound(Control.NOTE_DOWN, (action, state) -> addbuttonNOTES(action, VirtualPad.buttonDown2, state));
				inline forEachBound(Control.NOTE_LEFT, (action, state) -> addbuttonNOTES(action, VirtualPad.buttonLeft2, state));
				inline forEachBound(Control.NOTE_RIGHT, (action, state) -> addbuttonNOTES(action, VirtualPad.buttonRight2, state));
			case NONE: // do nothing
		}

		switch (Action)
		{
			case A:
				inline forEachBound(Control.ACCEPT, (action, state) -> addbuttonNOTES(action, VirtualPad.buttonA, state));
			case B:
				inline forEachBound(Control.BACK, (action, state) -> addbuttonNOTES(action, VirtualPad.buttonB, state));
			case A_B | A_B_C | A_B_E | A_B_X_Y | A_B_C_X_Y | A_B_C_X_Y_Z | A_B_C_D_V_X_Y_Z:
				inline forEachBound(Control.ACCEPT, (action, state) -> addbuttonNOTES(action, VirtualPad.buttonA, state));
				inline forEachBound(Control.BACK, (action, state) -> addbuttonNOTES(action, VirtualPad.buttonB, state));
			case NONE: // do nothing
		}
	}

	public function removeFlxInput(Tinputs:Array<FlxActionInput>)
	{
		for (action in this.digitalActions)
		{
			var i = action.inputs.length;
			while (i-- > 0)
			{
				var x = Tinputs.length;
				while (x-- > 0)
				{
					if (Tinputs[x] == action.inputs[i])
						action.remove(action.inputs[i]);
				}
			}
		}
	}
	#end
	public static function resetState() {
		MusicBeatState.switchState(FlxG.state);
	}

	public static function getState():MusicBeatState {
		var curState:Dynamic = FlxG.state;
		var leState:MusicBeatState = curState;
		return leState;
	}

	public function stepHit():Void
	{
		if (curStep % 4 == 0)
			beatHit();
	}

	public function beatHit():Void
	{
		//do literally nothing dumbass
	}

		
	public function setBlockSize(bs:Float):Void
		//ShadersHandler.setBlockSize(bs);
	return;
}
