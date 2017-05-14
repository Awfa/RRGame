package level;

import pause_options_menu.PauseOptionsMenu;
import logging.LoggingSystem;
import audio.AudioSystemTop;
import bus.UniversalBus;
import board.BoardSystemTop;
import board.Player;
import controls.ControlsSystemTop;
import domain.Displacement;
import flixel.FlxState;
import flixel.FlxG;
import flixel.math.FlxPoint;
import flixel.FlxSprite;
import flixel.text.FlxText;
import flixel.tweens.*;
import flixel.group.FlxSpriteGroup;
import hubworld.HubWorldState;
import timing.TimingSystemTop;

class PlayLevelState extends FlxState {
	private var levelData:LevelData;
	private var levelIndex:Int;
	private var timingSystemTop:TimingSystemTop;
	private var trackGroup:FlxSpriteGroup;
	private var universalBus:UniversalBus;
	private var logger:LoggingSystem;
	private var player:Player;

	public function new(levelData:LevelData,
						levelIndex:Int,
						universalBus:UniversalBus,
						logger:LoggingSystem) {
		super();
		this.levelData = levelData;
		this.levelIndex = levelIndex;
		this.trackGroup = new FlxSpriteGroup();
		for (trackAction in levelData.trackActions) {
			if (Std.is(trackAction, FlxSprite)) {
				this.trackGroup.add(cast(trackAction, FlxSprite));
			}
		}
		this.universalBus = universalBus;
		this.logger = logger;
	}

	override public function create():Void {
		super.create();
		FlxG.mouse.visible = false;

		// System initialization
		new Referee(universalBus);
		add(new AudioSystemTop(universalBus));
		add(new ControlsSystemTop(universalBus));
		var board = new BoardSystemTop(0, 0, universalBus);
		add(board);
		player = board.player;
		timingSystemTop = new TimingSystemTop(universalBus);
		add(timingSystemTop);
		add(trackGroup);

		Juicer.juiceLevel(universalBus);
		var levelRunner = new LevelRunner(universalBus);

		// Camera
		FlxG.camera.focusOn(new FlxPoint(0, 0));

		// Pause
		universalBus.pause.subscribe(this, pauseGame);
		universalBus.unpause.subscribe(this, unpauseGame);

		// Win/Lose conditions
		universalBus.playerDie.subscribe(this, handlePlayerDie);
		universalBus.levelOutOfBeats.subscribe(this, handleOutOfBeats);

		levelRunner.runLevel(levelData);
	}

	override public function update(elapsed:Float):Void {
		super.update(elapsed);
	}

	public function handlePlayerDie(whereTheyDied : Displacement) {
		universalBus.gameOver.broadcast(0);
		trackGroup.alpha = 0;
		
		var message = new BeatText(universalBus, "You lose!", 50, 1.1);
		message.x = -message.width / 2;
		message.y = -120;
		add(message);

		handleGameOver();
	}

	public function handleOutOfBeats(_) {
		universalBus.gameOver.broadcast(player.hp);
		trackGroup.alpha = 0;

		var message = new BeatText(universalBus, "You win!", 50, 1.1);
		message.x = -message.width / 2;
		message.y = -120;
		add(message);

		var stats = new BeatText(universalBus, "HP Left:" + player.hp, 30, 1.1);
		stats.y = -stats.height / 2;
		add(stats);

		handleGameOver();
	}

	private function handleGameOver() {
		var instructions = new BeatText(universalBus, "[ Press R to retry ] [ Press Space to return to Level Select ]", 20, 1.05);
		instructions.x = -instructions.width / 2;
		instructions.y = 60;
		add(instructions);

		// Music Track Credits
		var attributionText = new BeatText(universalBus, levelData.title + ", by " + levelData.author, 15, 1.05);
		attributionText.x = -attributionText.width / 2;
		attributionText.y = 150;
		add(attributionText);

		universalBus.retry.subscribe(this, function(_) {
			FlxG.switchState(new HubWorldState(logger, {
				level: levelIndex,
				score: player.hp
			}, true));
		});

		universalBus.returnToHub.subscribe(this, function(_) {
			FlxG.switchState(new HubWorldState(logger, {
				level: levelIndex,
				score: player.hp
			}));
		});
	}

	public function pauseGame(pauseEvent) {
		var menu = new PauseOptionsMenu();
		FlxTween.globalManager.active = false;
		menu.closeCallback = function() {
			universalBus.unpause.broadcast(true);
		}
		openSubState(menu);
	}

	public function unpauseGame(unpauseEvent) {
		FlxTween.globalManager.active = true;
	}

	override public function onFocus() {
		super.onFocus();
		logger.focusGained();
		// TODO hook focus up to pausing and unpausing?
	}

	override public function onFocusLost() {
		super.onFocusLost();
		logger.focusLost();
	}
}

private class BeatText extends FlxText {
	var oldBeat : Float;
	public function new(universalBus : UniversalBus, text : String, size : Int, beatScale : Float) {
		super(0, 0, 0, text);
		setFormat(AssetPaths.GlacialIndifference_Regular__ttf, size, flixel.util.FlxColor.WHITE, CENTER);

		oldBeat = 0.0;

		universalBus.beat.subscribe(this, function(beat) {
			if (Math.round(oldBeat) >= oldBeat && Math.round(beat.beat) <= beat.beat) {
				scale.x = beatScale;
				scale.y = beatScale;

				FlxTween.tween(scale, {
					x : 1.0,
					y : 1.0
				}, 0.2, {
					ease : FlxEase.quadOut
				});
			}
			oldBeat = beat.beat;
		});
	}
}