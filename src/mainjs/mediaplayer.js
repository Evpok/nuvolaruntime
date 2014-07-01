/*
 * Copyright 2014 Jiří Janoušek <janousek.jiri@gmail.com>
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions are met: 
 * 
 * 1. Redistributions of source code must retain the above copyright notice, this
 *    list of conditions and the following disclaimer. 
 * 2. Redistributions in binary form must reproduce the above copyright notice,
 *    this list of conditions and the following disclaimer in the documentation
 *    and/or other materials provided with the distribution. 
 * 
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
 * ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
 * WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
 * DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR
 * ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
 * (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
 * LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
 * ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 * (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
 * SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

require("prototype");
require("notification");
require("launcher");
require("actions");
require("mediakeys");
require("storage");
require("browser");
require("core");


var PlayerAction = {
	PLAY: "play",
	TOGGLE_PLAY: "toggle-play",
	PAUSE: "pause",
	STOP: "stop",
	PREV_SONG: "prev-song",
	NEXT_SONG: "next-song",
}

var PlaybackState = {
	UNKNOWN: 0,
	PAUSED: 1,
	PLAYING: 2,
}

var MediaPlayer = $prototype(null);

MediaPlayer.$init = function()
{
	this._state = PlaybackState.UNKNOWN;
	this._artworkFile = null;
	this._canGoPrev = null;
	this._canGoNext = null;
	this._canPlay = null;
	this._canPause = null;
	this._extraActions = [];
	this._artworkLoop = 0;
	this._baseActions = [PlayerAction.TOGGLE_PLAY, PlayerAction.PLAY, PlayerAction.PAUSE, PlayerAction.PREV_SONG, PlayerAction.NEXT_SONG];
	this._notification = Nuvola.Notifications.getNamedNotification("mediaplayer", true);
	Nuvola.Core.connect("init-app-runner", this, "_onInitAppRunner");
	Nuvola.Core.connect("init-web-worker", this, "_onInitWebWorker");
}

MediaPlayer._BACKGROUND_PLAYBACK = "player.background_playback";

MediaPlayer._onInitAppRunner = function(emitter, values, entries)
{
	Nuvola.Launcher.setActions(["quit"]);
	Nuvola.Actions.addAction("playback", "win", PlayerAction.PLAY, "Play", null, "media-playback-start", null);
	Nuvola.Actions.addAction("playback", "win", PlayerAction.PAUSE, "Pause", null, "media-playback-pause", null);
	Nuvola.Actions.addAction("playback", "win", PlayerAction.TOGGLE_PLAY, "Toggle play/pause", null, null, null);
	Nuvola.Actions.addAction("playback", "win", PlayerAction.STOP, "Stop", null, "media-playback-stop", null);
	Nuvola.Actions.addAction("playback", "win", PlayerAction.PREV_SONG, "Previous song", null, "media-skip-backward", null);
	Nuvola.Actions.addAction("playback", "win", PlayerAction.NEXT_SONG, "Next song", null, "media-skip-forward", null);
	this._notification.setActions([PlayerAction.PLAY, PlayerAction.PAUSE, PlayerAction.PREV_SONG, PlayerAction.NEXT_SONG]);
	Nuvola.Config.setDefault(this._BACKGROUND_PLAYBACK, true);
	this._updateMenu();
	Nuvola.Core.connect("append-preferences", this, "_onAppendPreferences");
}

MediaPlayer._onInitWebWorker = function(emitter)
{
	Nuvola.Config.connect("config-changed", this, "_onConfigChanged");
	Nuvola.MediaKeys.connect("key-pressed", this, "_onMediaKeyPressed");
	this._track = {
		"title": undefined,
		"artist": undefined,
		"album": undefined,
		"artLocation": undefined
	};
	this._setActions();
}

MediaPlayer.setTrack = function(track)
{
	var changed = Nuvola.objectDiff(this._track, track);
	this._track = track;
	
	if (!changed.length)
		return;
		
	if (!track.artLocation)
		this._artworkFile = null;
	
	if (Nuvola.inArray(changed, "artLocation") && track.artLocation)
	{
		this._artworkFile = null;
		var artworkId = this._artworkLoop++;
		if (this._artworkLoop > 9)
			this._artworkLoop = 0;
		Nuvola.Browser.downloadFileAsync(track.artLocation, "player.artwork." + artworkId, this._onArtworkDownloaded.bind(this), changed);
		this._sendDevelInfo();
	}
	else
	{
		this._updateTrackInfo(changed);
	}
}

MediaPlayer.setPlaybackState = function(state)
{
	if (this._state !== state)
	{
		this._state = state;
		this._setHideOnClose();
		this._setActions();
		this._updateTrackInfo(["state"]);
	}
}

MediaPlayer.setCanGoNext = function(canGoNext)
{
	if (this._canGoNext !== canGoNext)
	{
		this._canGoNext = canGoNext;
		Nuvola.Actions.setEnabled(PlayerAction.NEXT_SONG, !!canGoNext);
		this._sendDevelInfo();
	}
}

MediaPlayer.setCanGoPrev = function(canGoPrev)
{
	if (this._canGoPrev !== canGoPrev)
	{
		this._canGoPrev = canGoPrev;
		Nuvola.Actions.setEnabled(PlayerAction.PREV_SONG, !!canGoPrev);
		this._sendDevelInfo();
	}
}

MediaPlayer.setCanPlay = function(canPlay)
{
	if (this._canPlay !== canPlay)
	{
		this._canPlay = canPlay;
		Nuvola.Actions.setEnabled(PlayerAction.PLAY, !!canPlay);
		Nuvola.Actions.setEnabled(PlayerAction.TOGGLE_PLAY, !!(this._canPlay || this._canPause));
		this._sendDevelInfo();
	}
}

MediaPlayer.setCanPause = function(canPause)
{
	if (this._canPause !== canPause)
	{
		this._canPause = canPause;
		Nuvola.Actions.setEnabled(PlayerAction.PAUSE, !!canPause);
		Nuvola.Actions.setEnabled(PlayerAction.TOGGLE_PLAY, !!(this._canPlay || this._canPause));
		this._sendDevelInfo();
	}
}

MediaPlayer._setActions = function()
{
	var actions = [this._state === PlaybackState.PLAYING ? PlayerAction.PAUSE : PlayerAction.PLAY, PlayerAction.PREV_SONG, PlayerAction.NEXT_SONG];
	actions = actions.concat(this._extraActions);
	actions.push("quit");
	Nuvola.Launcher.setActions(actions);
}

MediaPlayer._sendDevelInfo = function()
{
	Nuvola._sendMessageAsync("Nuvola.MediaPlayer._sendDevelInfo", {
		"title": this._track.title,
		"artist": this._track.artist,
		"album": this._track.album,
		"artLocation": this._track.artLocation,
		"artworkFile": this._artworkFile,
		"baseActions": this._baseActions,
		"extraActions": this._extraActions,
		"state": ["unknown", "paused", "playing"][this._state],
	});
}

MediaPlayer._onArtworkDownloaded = function(res, changed)
{
	if (!res.result)
	{
		this._artworkFile = null;
		console.log(Nuvola.format("Artwork download failed: {1} {2}.", res.statusCode, res.statusText));
	}
	else
	{
		this._artworkFile = res.filePath;
	}
	this._updateTrackInfo(changed);
}

MediaPlayer._updateTrackInfo = function(changed)
{
	this._sendDevelInfo();
	var track = this._track;
	
	if (track.title)
	{
		var title = track.title;
		var message;
		if (!track.artist && !track.album)
			message = "by unknown artist";
		else if(!track.artist)
			message = Nuvola.format("from {1}", track.album);
		else if(!track.album)
			message = Nuvola.format("by {1}", track.artist);
		else
			message = Nuvola.format("by {1} from {2}", track.artist, track.album);
		
		this._notification.update(title, message, this._artworkFile ? null : "nuvolaplayer", this._artworkFile);
		if (this._state === PlaybackState.PLAYING)
			this._notification.show();
		
		var tooltip = track.artist ? Nuvola.format("{1} by {2}", track.title, track.artist) : track.title;
		Nuvola.Launcher.setTooltip(tooltip);
	}
	else
	{
		Nuvola.Launcher.setTooltip("Nuvola Player");
	}
}

MediaPlayer.addExtraActions = function(actions)
{
	var update = false;
	for (var i = 0; i < actions.length; i++)
	{
		var action = actions[i];
		if (!Nuvola.inArray(this._extraActions, action))
		{
			this._extraActions.push(action);
			update = true;
		}
	}
	if (update)
		this._updateMenu();
}

MediaPlayer._updateMenu = function()
{
	Nuvola.MenuBar.setMenu("playback", "_Control", this._baseActions.concat(this._extraActions));
}

MediaPlayer._setHideOnClose = function()
{
	if (this._state === PlaybackState.PLAYING)
		Nuvola.Core.setHideOnClose(Nuvola.Config.get(this._BACKGROUND_PLAYBACK));
	else
		Nuvola.Core.setHideOnClose(false);
}

MediaPlayer._onAppendPreferences = function(object, values, entries)
{
	values[this._BACKGROUND_PLAYBACK] = Nuvola.Config.get(this._BACKGROUND_PLAYBACK);
	entries.push(["bool", this._BACKGROUND_PLAYBACK, "Keep playing in background when window is closed"]);
}

MediaPlayer._onConfigChanged = function(emitter, key)
{
	switch (key)
	{
	case this._BACKGROUND_PLAYBACK:
		this._setHideOnClose();
		break;
	}
}

MediaPlayer._onMediaKeyPressed = function(emitter, key)
{
	var A = Nuvola.Actions;
	switch (key)
	{
	case MediaKey.PLAY:
	case MediaKey.PAUSE:
		A.activate(PlayerAction.TOGGLE_PLAY);
		break;
	case MediaKey.STOP:
		A.activate(PlayerAction.STOP);
		break;
	case MediaKey.NEXT:
		A.activate(PlayerAction.NEXT_SONG);
		break;
	case MediaKey.PREV:
		A.activate(PlayerAction.PREV_SONG);
		break;
	default:
		console.log(Nuvola.format("Unknown media key '{1}'.", key));
		break;
	}
}

// export public items
Nuvola.PlayerAction = PlayerAction;
Nuvola.PlaybackState = PlaybackState;
Nuvola.MediaPlayer = MediaPlayer;
