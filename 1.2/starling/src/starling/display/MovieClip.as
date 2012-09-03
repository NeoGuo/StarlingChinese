// =================================================================================================
//
//	Starling Framework
//	Copyright 2011 Gamua OG. All Rights Reserved.
//
//	This program is free software. You can redistribute and/or modify it
//	in accordance with the terms of the accompanying license agreement.
//
// =================================================================================================

package starling.display
{
    import flash.errors.IllegalOperationError;
    import flash.media.Sound;
    
    import starling.animation.IAnimatable;
    import starling.events.Event;
    import starling.textures.Texture;
    
    /** 当影片剪辑播放完最后一帧时进行分派。 */
    [Event(name="complete", type="starling.events.Event")]
    
    /** 一个影片剪辑(MovieClip)根据一个纹理集合来显示动画。
     *  
     *  <p>传入包含纹理的集合给MovieClip的构造函数作为影片剪辑的帧。影片剪辑会根据第一帧的纹理来确定影片的宽度和高度。
	 * 如果你使用纹理图集<code>TextureAtlas</code>（推荐使用此方法）来组织你的帧，请使用纹理图集的<code>getTextures</code>方法
	 * 获取正确(按字母次序的)的纹理顺序。</p> 
     *  
     *  <p>你可以在构造函数中指定一个特定的帧频，如果需要，你还可以设置每一帧的执行时间，或者在某一帧执行时播放一个声音。</p>
     *  
     *  <p><code>play</code> 和 <code>pause</code> 方法可以控制影片的播放，当影片播放完毕时，你会接受到一个<code>Event.MovieCompleted</code>
	 * 事件。如果影片是循环播放的，这个事件会在每一次循环都分派。</p>
     *  
     *  <p>同其他动画对象一样，一个影片剪辑必须添加到一个juggler（或者是一个拥有自己的定时执行的<code>advanceTime</code>方法的对象）里来运行。
	 * 当影片剪辑播放完最后一帧时，会分派"Event.COMPLETE"事件。</p>
     *  
     *  @see starling.textures.TextureAtlas
     */    
    public class MovieClip extends Image implements IAnimatable
    {
        private var mTextures:Vector.<Texture>;
        private var mSounds:Vector.<Sound>;
        private var mDurations:Vector.<Number>;
        private var mStartTimes:Vector.<Number>;
        
        private var mDefaultFrameDuration:Number;
        private var mTotalTime:Number;
        private var mCurrentTime:Number;
        private var mCurrentFrame:int;
        private var mLoop:Boolean;
        private var mPlaying:Boolean;
        
        /**
         * 根据传入的纹理集合和帧频来创建一个影片剪辑。
		 * 影片剪辑会根据传入的第一帧纹理来确定自己的尺寸。
         * @param textures		纹理集合
         * @param fps			帧频，默认为：12
         * @throws ArgumentError
         */
        public function MovieClip(textures:Vector.<Texture>, fps:Number=12)
        {
            if (textures.length > 0)
            {
                super(textures[0]);
                init(textures, fps);
            }
            else
            {
                throw new ArgumentError("Empty texture array");
            }
        }
        
        private function init(textures:Vector.<Texture>, fps:Number):void
        {
            if (fps <= 0) throw new ArgumentError("Invalid fps: " + fps);
            var numFrames:int = textures.length;
            
            mDefaultFrameDuration = 1.0 / fps;
            mLoop = true;
            mPlaying = true;
            mCurrentTime = 0.0;
            mCurrentFrame = 0;
            mTotalTime = mDefaultFrameDuration * numFrames;
            mTextures = textures.concat();
            mSounds = new Vector.<Sound>(numFrames);
            mDurations = new Vector.<Number>(numFrames);
            mStartTimes = new Vector.<Number>(numFrames);
            
            for (var i:int=0; i<numFrames; ++i)
            {
                mDurations[i] = mDefaultFrameDuration;
                mStartTimes[i] = i * mDefaultFrameDuration;
            }
        }
        
        // frame manipulation
        
        /**
         * 为影片剪辑添加一帧，可以传递声音和执行时间（可选）。
		 * 如果没有指定执行时间或者执行时间为负值，则使用默认帧频（构造函数里确定的帧频）。
         * @param texture	纹理
         * @param sound		声音
         * @param duration	执行时间
         */
        public function addFrame(texture:Texture, sound:Sound=null, duration:Number=-1):void
        {
            addFrameAt(numFrames, texture, sound, duration);
        }
        
        /**
         * 根据指定的索引添加一帧，可以传递声音和执行时间（可选）。
         * @param frameID	索引
         * @param texture	纹理
         * @param sound		声音
         * @param duration	执行时间
         * @throws ArgumentError
         */
        public function addFrameAt(frameID:int, texture:Texture, sound:Sound=null, 
                                   duration:Number=-1):void
        {
            if (frameID < 0 || frameID > numFrames) throw new ArgumentError("Invalid frame id");
            if (duration < 0) duration = mDefaultFrameDuration;
            
            mTextures.splice(frameID, 0, texture);
            mSounds.splice(frameID, 0, sound);
            mDurations.splice(frameID, 0, duration);
            mTotalTime += duration;
            
            if (frameID > 0 && frameID == numFrames) 
                mStartTimes[frameID] = mStartTimes[frameID-1] + mDurations[frameID-1];
            else
                updateStartTimes();
        }
        
        /**
         * 从指定的索引处删除一帧。此帧后面的所有帧将前移。
         * @param frameID	索引
         * @throws ArgumentError
         * @throws IllegalOperationError
         */
        public function removeFrameAt(frameID:int):void
        {
            if (frameID < 0 || frameID >= numFrames) throw new ArgumentError("Invalid frame id");
            if (numFrames == 1) throw new IllegalOperationError("Movie clip must not be empty");
            
            mTotalTime -= getFrameDuration(frameID);
            mTextures.splice(frameID, 1);
            mSounds.splice(frameID, 1);
            mDurations.splice(frameID, 1);
            
            updateStartTimes();
        }
        
        /**
         * 根据帧索引返回其相对应的纹理。
         * @param frameID	索引
         * @return 
         * @throws ArgumentError
         */
        public function getFrameTexture(frameID:int):Texture
        {
            if (frameID < 0 || frameID >= numFrames) throw new ArgumentError("Invalid frame id");
            return mTextures[frameID];
        }
        
        /**
         * 设置指定索引的帧的纹理。
         * @param frameID	索引
         * @param texture	纹理
         * @throws ArgumentError
         */
        public function setFrameTexture(frameID:int, texture:Texture):void
        {
            if (frameID < 0 || frameID >= numFrames) throw new ArgumentError("Invalid frame id");
            mTextures[frameID] = texture;
        }
        
        /**
         * 根据帧索引返回其相对应的声音。
         * @param frameID	索引
         * @return 
         * @throws ArgumentError
         */
        public function getFrameSound(frameID:int):Sound
        {
            if (frameID < 0 || frameID >= numFrames) throw new ArgumentError("Invalid frame id");
            return mSounds[frameID];
        }
        
        /**
         * 设置指定索引的帧的声音，当此帧显示时，声音就会播放。
         * @param frameID	索引
         * @param sound		声音
         * @throws ArgumentError
         */
        public function setFrameSound(frameID:int, sound:Sound):void
        {
            if (frameID < 0 || frameID >= numFrames) throw new ArgumentError("Invalid frame id");
            mSounds[frameID] = sound;
        }
        
        /**
         * 返回指定索引的帧的执行时间（单位：秒）。
         * @param frameID	索引
         * @return 
         * @throws ArgumentError
         */
        public function getFrameDuration(frameID:int):Number
        {
            if (frameID < 0 || frameID >= numFrames) throw new ArgumentError("Invalid frame id");
            return mDurations[frameID];
        }
        
        /**
         * 设置指定索引的帧的执行时间（单位：秒）。
         * @param frameID	索引
         * @param duration	执行时间
         * @throws ArgumentError
         */
        public function setFrameDuration(frameID:int, duration:Number):void
        {
            if (frameID < 0 || frameID >= numFrames) throw new ArgumentError("Invalid frame id");
            mTotalTime -= getFrameDuration(frameID);
            mTotalTime += duration;
            mDurations[frameID] = duration;
            updateStartTimes();
        }
        
        // playback methods
        
        /** 开始播放影片剪辑， 请确保影片已被添加到了juggler！ */
        public function play():void
        {
            mPlaying = true;
        }
        
        /** 暂停播放。 */
        public function pause():void
        {
            mPlaying = false;
        }
        
        /** 停止播放, 重置 "currentFrame" 为0。 */
        public function stop():void
        {
            mPlaying = false;
            currentFrame = 0;
        }
        
        // helpers
        
        private function updateStartTimes():void
        {
            var numFrames:int = this.numFrames;
            
            mStartTimes.length = 0;
            mStartTimes[0] = 0;
            
            for (var i:int=1; i<numFrames; ++i)
                mStartTimes[i] = mStartTimes[i-1] + mDurations[i-1];
        }
        
        // IAnimatable
        
        /** @inheritDoc */
        public function advanceTime(passedTime:Number):void
        {
            var finalFrame:int;
            var previousFrame:int = mCurrentFrame;
            
            if (mLoop && mCurrentTime == mTotalTime) { mCurrentTime = 0.0; mCurrentFrame = 0; }
            if (!mPlaying || passedTime == 0.0 || mCurrentTime == mTotalTime) return;
            
            mCurrentTime += passedTime;
            finalFrame = mTextures.length - 1;
            
            while (mCurrentTime >= mStartTimes[mCurrentFrame] + mDurations[mCurrentFrame])
            {
                if (mCurrentFrame == finalFrame)
                {
                    if (hasEventListener(Event.COMPLETE))
                    {
                        var restTime:Number = mCurrentTime - mTotalTime;
                        mCurrentTime = mTotalTime;
                        dispatchEventWith(Event.COMPLETE);
                        
                        // user might have changed movie clip settings, so we restart the method
                        advanceTime(restTime);
                        return;
                    }
                    
                    if (mLoop)
                    {
                        mCurrentTime -= mTotalTime;
                        mCurrentFrame = 0;
                    }
                    else
                    {
                        mCurrentTime = mTotalTime;
                        break;
                    }
                }
                else
                {
                    mCurrentFrame++;
                    
                    var sound:Sound = mSounds[mCurrentFrame];
                    if (sound) sound.play();
                }
            }
            
            if (mCurrentFrame != previousFrame)
                texture = mTextures[mCurrentFrame];
        }
        
        /** 判断一个不循环的影片剪辑是否已经播完最后一帧。 */
        public function get isComplete():Boolean 
        {
            return !mLoop && mCurrentTime >= mTotalTime;
        }
        
        // properties  
        
        /** 影片剪辑总共需要播放的秒数。 */
        public function get totalTime():Number { return mTotalTime; }
        
        /** 影片剪辑的总帧数。 */
        public function get numFrames():int { return mTextures.length; }
        
        /** 影片剪辑是否可以循环播放。 */
        public function get loop():Boolean { return mLoop; }
        public function set loop(value:Boolean):void { mLoop = value; }
        
        /** 当前正在播放的帧的索引。 */
        public function get currentFrame():int { return mCurrentFrame; }
        public function set currentFrame(value:int):void
        {
            mCurrentFrame = value;
            mCurrentTime = 0.0;
            
            for (var i:int=0; i<value; ++i)
                mCurrentTime += getFrameDuration(i);
            
            texture = mTextures[mCurrentFrame];
            if (mSounds[mCurrentFrame]) mSounds[mCurrentFrame].play();
        }
        
		/** 每秒播放的帧的默认数量。 不同的帧可以有不同的执行时间。如果你改变fps,所有帧的执行时间将会相对于原来的值增加或减少。*/
        public function get fps():Number { return 1.0 / mDefaultFrameDuration; }
        public function set fps(value:Number):void
        {
            if (value <= 0) throw new ArgumentError("Invalid fps: " + value);
            
            var newFrameDuration:Number = 1.0 / value;
            var acceleration:Number = newFrameDuration / mDefaultFrameDuration;
            mCurrentTime *= acceleration;
            mDefaultFrameDuration = newFrameDuration;
            
            for (var i:int=0; i<numFrames; ++i)
                setFrameDuration(i, getFrameDuration(i) * acceleration);
        }
        
        /** 判断影片剪辑是否正在播放。播放完毕时返回<code>false</code>。 */
        public function get isPlaying():Boolean 
        {
            if (mPlaying)
                return mLoop || mCurrentTime < mTotalTime;
            else
                return false;
        }
    }
}