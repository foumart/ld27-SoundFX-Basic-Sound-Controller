/*
  Copyright (c) 24-AUG-2013 by Noncho Savov | Foumart Games | http://www.foumartgames.com
  All rights reserved.

  Redistribution and use in collection and binary forms, with or without 
  modification, are permitted provided that the following conditions are
  met:

  * Redistributions of collection code must retain the above copyright notice, 
    this list of conditions and the following disclaimer.
  
  * Redistributions in binary form must reproduce the above copyright
    notice, this list of conditions and the following disclaimer in the 
    documentation and/or other materials provided with the distribution.
  
  * Neither the name of Adobe Systems Incorporated nor the names of its 
    contributors may be used to endorse or promote products derived from 
    this software without specific prior written permission.

  THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS
  IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO,
  THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR
  PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR 
  CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL,
  EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
  PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR
  PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF
  LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING
  NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
  SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
*/

package ld27 {
	
	/**
	* 	SoundFX - Basic Sound Controller prepared for LD27
	*	
	* 	@langversion ActionScript 3.0
	*	@playerversion Flash 9.0
	*	@tiptext
	*/		
	
	import flash.events.Event;
	
	import flash.utils.getQualifiedClassName;
	import flash.utils.getDefinitionByName;
	import flash.utils.setTimeout;
	import flash.utils.clearTimeout;
	
	import flash.media.Sound;
	import flash.media.SoundMixer;
	import flash.media.SoundTransform;
	import flash.media.SoundChannel;
	
	public class SoundFX {
		
		public static const REPLAY:String = "replay";
		public static const NEXT:String = "next";
		public static const ONCE:String = "once";
		
		public static var channel:SoundChannel; 
		public static var soundFX:Object;
		public static var soundMixer:Array;
		public static var soundCollection:Array;
		public static var musicCollection:Array;
		
		public static var onInit:Function;
		
		public static var onMusicComplete:String = "replay"; // behaviour
		public static var musicID:uint;
		
		private static var check:SoundCheck;
		private static var instance:SoundFX;
		
		public static var isStatic:Boolean;
		
		private var _timeout:uint;
		
		/**
		*	SoundFX - Sound Controller and Music Player. Can be used as both singleton and object.
		* 
		* 	@param sound_collection Initialized Sounds held in an array.
		*
		* 	@param music_collection Initialized Songs held in an array. example: SoundFX.add([new Sound_1(), ...], [new Music_1(), ...]);
		*
		*
		* 	@langversion ActionScript 3.0
		*	@playerversion Flash 9.0
		*	@tiptext
		*/
		
		public static function add(sound_collection:Array = null, music_collection:Array = null):void {
			if( instance == null ) {
				check = new SoundCheck(sound_collection, music_collection);
				instance = new SoundFX(check);
			} else {
				instance.init(check, sound_collection, music_collection);
			}
		}
		
		public static function playSound(sound:*):void {//trace(sound, soundFX)
			var newSound:Sound;
			if(sound is Sound) newSound = sound else newSound = soundFX[sound];
			if(!newSound) throw new Error("ClassName::SoundFX(static); Function::playSound @param sound must be an initialized Sound object or a string name from sound_collection.")
			var newChannel:SoundChannel = new SoundChannel();
			newChannel.soundTransform = new SoundTransform(1);
			newChannel = newSound.play();
			newChannel.addEventListener(Event.SOUND_COMPLETE, soundCompleted);
			soundMixer.push(newChannel);
		}
		
		public static function playMusic(music:*, on_music_complete:String = null):void {//trace(music, soundFX)
			if(on_music_complete) onMusicComplete = on_music_complete;
			var newMusic:Sound;
			if(music is Sound) newMusic = music else newMusic = soundFX[music];
			musicID = musicCollection.indexOf(newMusic);//trace("musicID",musicID)
			if(!newMusic) throw new Error("ClassName::SoundFX(static); Function::playMusic @param music must be an initialized Sound object or a string name from music_collection.")
			var newChannel:SoundChannel = new SoundChannel();
			newChannel.soundTransform = new SoundTransform(1);
			newChannel = newMusic.play();
			newChannel.addEventListener(Event.SOUND_COMPLETE, musicCompleted);
			soundMixer.push(newChannel);
		}
		
		public static function soundCompleted(evt:Event):void{
			evt.target.removeEventListener(Event.SOUND_COMPLETE, soundCompleted);
			removeFromMixer(evt.target as SoundChannel);
		}
		
		public static function musicCompleted(evt:Event):void{
			evt.target.removeEventListener(Event.SOUND_COMPLETE, musicCompleted);
			removeFromMixer(evt.target as SoundChannel);
			if(onMusicComplete == REPLAY){
				playMusic(musicCollection[musicID]);
			} else if(onMusicComplete == NEXT){
				musicID ++;
				if(musicID >= musicCollection.length){
					musicID = 0;
				}
				playMusic(musicCollection[musicID]);
			}
		}
		
		public static function removeFromMixer(channel:SoundChannel):void {
			for(var i:int = soundMixer.length - 1; i >= 0; i--) {
				if(soundMixer.indexOf(channel) >= 0) {
					soundMixer.splice(i,1);
				}
			}
		}
		
		
		
		public function SoundFX(sound_collection:* = null, music_collection:Array = null) {
			if(sound_collection is SoundCheck) {
				trace("SoundFX::Initialized as Singleton");
				isStatic = true;
				_timeout = setTimeout(
					function():void{
						init(sound_collection, sound_collection.soundCollection, sound_collection.musicCollection);
					}, 1
				);
			} else if(isStatic){
				init(sound_collection, sound_collection.soundCollection, sound_collection.musicCollection);
			} else {
				trace("SoundFX::Initialized as dynamic Object");
				init(null, sound_collection, music_collection);
			}
		}
		
		
		
		
		public function init(sound_object:* = null, sound_collection:Array = null, music_collection:Array = null):void{//trace("init:",sound_object,sounds_collection);
			if(sound_object is SoundCheck) {
				soundCollection = sound_collection;
				musicCollection = music_collection;
			} else {
				soundCollection = sound_collection;
				musicCollection = music_collection;
			}
			musicID = 0;
			soundFX = {};
			soundMixer = [];
			SoundMixer.soundTransform = new SoundTransform(1);
			
			for each(var fx:Sound in soundCollection){
				soundFX[getQualifiedClassName(fx)] = fx;
			}
			for each(var song:Sound in musicCollection){
				soundFX[getQualifiedClassName(song)] = song;
			}
			if(sound_object is SoundCheck) onInit();
		}
		
		
		public function playSound(sound:*):void {//trace("dynamic playSound:",sound, soundFX)
			var newSound:Sound;
			if(sound is Sound) newSound = sound else newSound = soundFX[sound];
			if(!newSound) throw new Error("ClassName::SoundFX(dynamic); Function::playSound @param sound must be an initialized Sound object or a string name from sound_collection.")
			var newChannel:SoundChannel = new SoundChannel();
			newChannel.soundTransform = new SoundTransform(1);
			newChannel = newSound.play();
			newChannel.addEventListener(Event.SOUND_COMPLETE, soundCompleted);
			soundMixer.push(newChannel);
		}
		
		public function playMusic(music:*, on_music_complete:String = null):void {//trace(music, soundFX)
			if(on_music_complete) onMusicComplete = on_music_complete;
			var newMusic:Sound;
			if(music is Sound) newMusic = music else newMusic = soundFX[music];
			if(!newMusic) throw new Error("ClassName::SoundFX(dynamic); Function::playMusic @param music must be an initialized Sound object or a string name from music_collection.")
			var newChannel:SoundChannel = new SoundChannel();
			newChannel.soundTransform = new SoundTransform(1);
			newChannel = newMusic.play();
			newChannel.addEventListener(Event.SOUND_COMPLETE, musicCompleted);
			soundMixer.push(newChannel);
		}
	}
}


internal class SoundCheck{
	
	public var soundCollection:Array;
	public var musicCollection:Array;
	
	public function SoundCheck(	_soundCollection:Array, _musicCollection:Array ) {
		soundCollection = _soundCollection;
		musicCollection = _musicCollection;
	}
}
