// =================================================================================================
//
//	Starling Framework
//	Copyright 2011 Gamua OG. All Rights Reserved.
//
//	This program is free software. You can redistribute and/or modify it
//	in accordance with the terms of the accompanying license agreement.
//
// =================================================================================================


package starling.animation
{
    import starling.core.starling_internal;
    import starling.events.Event;
    import starling.events.EventDispatcher;

	/** 一个Tween实例，将使用补间动画的方式，"运动"某个对象的属性(比如改变x坐标值，从1,2,3...一直到N，从而形成视觉上的动画效果)。 它可以使用不同的过渡方法，来实现不同的动画方式。
	 *  
	 *  <p>这个类的主要用途是实现标准的动画，比如移动，透明度渐变，旋转等等。但是"动画"的范围远远不止于此。只要您想"运动"的对象的属性值是数字 (int, uint, Number), Tween就能搞定它。
	 *  要了解Tween可以使用的过渡方法的列表，请参阅"Transitions"类。</p> 
	 *  
	 *  <p>下面是一个实例，展示了tween移动一个对象到右侧，旋转它，然后让它透明度逐渐降低而消失:</p>
	 *  
	 *  <pre>
	 *  var tween:Tween = new Tween(object, 2.0, Transitions.EASE_IN_OUT);
	 *  tween.animate("x", object.x + 50);
	 *  tween.animate("rotation", deg2rad(45));
	 *  tween.fadeTo(0);    // 您也可以使用'animate("alpha", 0)'来代替
	 *  Starling.juggler.add(tween); 
	 *  </pre> 
	 *  
	 *  <p>注意在上面的代码的最后，tween的实例被添加到了juggler。这是因为，只有tween自己的"advanceTime"方法被实际执行的时候，tween才会起作用。
	 *  这个工作juggler会帮您做的，而且它会自动在tween执行完毕的时候删除它。</p>
	 *  
	 *  @see Juggler
	 *  @see Transitions
	 */ 
    public class Tween extends EventDispatcher implements IAnimatable
    {
        private var mTarget:Object;
        private var mTransitionFunc:Function;
        private var mTransitionName:String;
        
        private var mProperties:Vector.<String>;
        private var mStartValues:Vector.<Number>;
        private var mEndValues:Vector.<Number>;

        private var mOnStart:Function;
        private var mOnUpdate:Function;
        private var mOnRepeat:Function;
        private var mOnComplete:Function;  
        
        private var mOnStartArgs:Array;
        private var mOnUpdateArgs:Array;
        private var mOnRepeatArgs:Array;
        private var mOnCompleteArgs:Array;
        
        private var mTotalTime:Number;
        private var mCurrentTime:Number;
        private var mDelay:Number;
        private var mRoundToInt:Boolean;
        private var mNextTween:Tween;
        private var mRepeatCount:int;
        private var mRepeatDelay:Number;
        private var mReverse:Boolean;
        private var mCurrentCycle:int;
        
		/**
		 * 创建一个tween的实例， 同时设置目标对象, 时间 (单位是秒) 和过渡方式.
		 * @param target 目标
		 * @param time 时间
		 * @param transition 过渡方式，默认linear
		 */   
        public function Tween(target:Object, time:Number, transition:Object="linear")        
        {
             reset(target, time, transition);
        }

		/**
		 * 把tween恢复到它的初始值. 对pooling tweens有用.
		 * @param target 目标
		 * @param time 时间
		 * @param transition 过渡方式，默认linear
		 * @return Tween实例
		 */
        public function reset(target:Object, time:Number, transition:Object="linear"):Tween
        {
            mTarget = target;
            mCurrentTime = 0;
            mTotalTime = Math.max(0.0001, time);
            mDelay = mRepeatDelay = 0.0;
            mOnStart = mOnUpdate = mOnComplete = null;
            mOnStartArgs = mOnUpdateArgs = mOnCompleteArgs = null;
            mRoundToInt = mReverse = false;
            mRepeatCount = 1;
            mCurrentCycle = -1;
            
            if (transition is String)
                this.transition = transition as String;
            else if (transition is Function)
                this.transitionFunc = transition as Function;
            else 
                throw new ArgumentError("Transition must be either a string or a function");
            
            if (mProperties)  mProperties.length  = 0; else mProperties  = new <String>[];
            if (mStartValues) mStartValues.length = 0; else mStartValues = new <Number>[];
            if (mEndValues)   mEndValues.length   = 0; else mEndValues   = new <Number>[];
            
            return this;
        }
        
		/**
		 * "运动"某个对象的属性到目标值。您可以在一个tween上多次调用这个方法。
		 * @param property 属性值
		 * @param targetValue 目标值
		 */  
        public function animate(property:String, targetValue:Number):void
        {
            if (mTarget == null) return; // tweening null just does nothing.
                   
            mProperties.push(property);
            mStartValues.push(Number.NaN);
            mEndValues.push(targetValue);
        }
        
		/**
		 * 同时"运动"目标对象的'scaleX' 和 'scaleY'两个值。用这个方法放大或缩小对象。
		 * @param factor 缩放值
		 */
        public function scaleTo(factor:Number):void
        {
            animate("scaleX", factor);
            animate("scaleY", factor);
        }
        
		/**
		 * 同时"运动"目标对象的'x' 和 'y'两个值。用这个方法移动对象。
		 * @param x X坐标值
		 * @param y Y坐标值
		 */
        public function moveTo(x:Number, y:Number):void
        {
            animate("x", x);
            animate("y", y);
        }
        
		/**
		 * "运动"目标对象的'alpha'值，直到达到目标值。
		 * @param alpha 透明度的目标值
		 */ 
        public function fadeTo(alpha:Number):void
        {
            animate("alpha", alpha);
        }
        
        /** @inheritDoc */
        public function advanceTime(time:Number):void
        {
            if (time == 0 || (mRepeatCount == 1 && mCurrentTime == mTotalTime)) return;
            
            var i:int;
            var previousTime:Number = mCurrentTime;
            var restTime:Number = mTotalTime - mCurrentTime;
            var carryOverTime:Number = time > restTime ? time - restTime : 0.0;
            
            mCurrentTime = Math.min(mTotalTime, mCurrentTime + time);
            
            if (mCurrentTime <= 0) return; // the delay is not over yet

            if (mCurrentCycle < 0 && previousTime <= 0 && mCurrentTime > 0)
            {
                mCurrentCycle++;
                if (mOnStart != null) mOnStart.apply(null, mOnStartArgs);
            }

            var ratio:Number = mCurrentTime / mTotalTime;
            var reversed:Boolean = mReverse && (mCurrentCycle % 2 == 1);
            var numProperties:int = mStartValues.length;

            for (i=0; i<numProperties; ++i)
            {                
                if (isNaN(mStartValues[i])) 
                    mStartValues[i] = mTarget[mProperties[i]] as Number;
                
                var startValue:Number = mStartValues[i];
                var endValue:Number = mEndValues[i];
                var delta:Number = endValue - startValue;
                var transitionValue:Number = reversed ?
                    mTransitionFunc(1.0 - ratio) : mTransitionFunc(ratio);
                
                var currentValue:Number = startValue + transitionValue * delta;
                if (mRoundToInt) currentValue = Math.round(currentValue);
                mTarget[mProperties[i]] = currentValue;
            }

            if (mOnUpdate != null) 
                mOnUpdate.apply(null, mOnUpdateArgs);
            
            if (previousTime < mTotalTime && mCurrentTime >= mTotalTime)
            {
                if (mRepeatCount == 0 || mRepeatCount > 1)
                {
                    mCurrentTime = -mRepeatDelay;
                    mCurrentCycle++;
                    if (mRepeatCount > 1) mRepeatCount--;
                    if (mOnRepeat != null) mOnRepeat.apply(null, mOnRepeatArgs);
                }
                else
                {
                    // save callback & args: they might be changed through an event listener
                    var onComplete:Function = mOnComplete;
                    var onCompleteArgs:Array = mOnCompleteArgs;
                    
                    // in the 'onComplete' callback, people might want to call "tween.reset" and
                    // add it to another juggler; so this event has to be dispatched *before*
                    // executing 'onComplete'.
                    dispatchEventWith(Event.REMOVE_FROM_JUGGLER);
                    if (onComplete != null) onComplete.apply(null, onCompleteArgs);
                }
            }
            
            if (carryOverTime) 
                advanceTime(carryOverTime);
        }
        
		/** 动画是否播放完毕 */
        public function get isComplete():Boolean 
        { 
            return mCurrentTime >= mTotalTime && mRepeatCount == 1; 
        }        
        
		/** 当前"动画"要执行的对象 */
        public function get target():Object { return mTarget; }
        
		/** 动画过程中用到的过渡方法. @see Transitions */
        public function get transition():String { return mTransitionName; }
        public function set transition(value:String):void 
        { 
            mTransitionName = value;
            mTransitionFunc = Transitions.getTransition(value);
            
            if (mTransitionFunc == null)
                throw new ArgumentError("Invalid transiton: " + value);
        }
        
		/**可以传递一个方法来实现自定义的过渡过程*/
        public function get transitionFunc():Function { return mTransitionFunc; }
        public function set transitionFunc(value:Function):void
        {
            mTransitionName = "custom";
            mTransitionFunc = value;
        }
        
		/** 动画执行的总时间 (秒). */
        public function get totalTime():Number { return mTotalTime; }
        
        /** 已经执行的时间(秒) */
        public function get currentTime():Number { return mCurrentTime; }
        
		/** 动画需要延迟多长时间才开始.默认是0 */
        public function get delay():Number { return mDelay; }
        public function set delay(value:Number):void 
        { 
            mCurrentTime = mCurrentTime + mDelay - value;
            mDelay = value;
        }
        
        /** 动画需要被执行的次数.0代表永不停止. 默认是1 */
        public function get repeatCount():int { return mRepeatCount; }
        public function set repeatCount(value:int):void { mRepeatCount = value; }
        
        /** 重复执行动画的时候，中间的时间间隔，单位是秒. 默认是0 */
        public function get repeatDelay():Number { return mRepeatDelay; }
        public function set repeatDelay(value:Number):void { mRepeatDelay = value; }
        
        /** 设置当动画重复播放的时候，是否翻转执行. 如果设置为true，则重复的时候一直是翻转的. 默认是false */
        public function get reverse():Boolean { return mReverse; }
        public function set reverse(value:Boolean):void { mReverse = value; }
        
		/** 表示数字是否会被截取为整型. @default false */
        public function get roundToInt():Boolean { return mRoundToInt; }
        public function set roundToInt(value:Boolean):void { mRoundToInt = value; }        
        
		/** 当tween开始动画的时候会执行的方法 (如果有延迟的话，则在延迟之后).*/
        public function get onStart():Function { return mOnStart; }
        public function set onStart(value:Function):void { mOnStart = value; }
        
		/** 动画过程中的每一帧都会执行的方法. */
        public function get onUpdate():Function { return mOnUpdate; }
        public function set onUpdate(value:Function):void { mOnUpdate = value; }
        
        /** 当Tween完成每一次执行的时候，会调用的方法。
         *  (除了最后一次调用，因为它会触发'onComplete'). */
        public function get onRepeat():Function { return mOnRepeat; }
        public function set onRepeat(value:Function):void { mOnRepeat = value; }
        
		/** 当tween执行完毕的时候会调用的方法. */
        public function get onComplete():Function { return mOnComplete; }
        public function set onComplete(value:Function):void { mOnComplete = value; }
        
		/** 需要传递给 'onStart' 方法的参数. */
        public function get onStartArgs():Array { return mOnStartArgs; }
        public function set onStartArgs(value:Array):void { mOnStartArgs = value; }
        
		/** 需要传递给'onUpdate' 方法的参数. */
        public function get onUpdateArgs():Array { return mOnUpdateArgs; }
        public function set onUpdateArgs(value:Array):void { mOnUpdateArgs = value; }
        
        /** 需要传递给'onRepeat' 方法的参数. */
        public function get onRepeatArgs():Array { return mOnRepeatArgs; }
        public function set onRepeatArgs(value:Array):void { mOnRepeatArgs = value; }
        
		/** 需要传递给'onComplete' 方法的参数. */
        public function get onCompleteArgs():Array { return mOnCompleteArgs; }
        public function set onCompleteArgs(value:Array):void { mOnCompleteArgs = value; }
        
        /** 当这个tween完成的时候，立刻开始执行下一个tween */
        public function get nextTween():Tween { return mNextTween; }
        public function set nextTween(value:Tween):void { mNextTween = value; }
        
        // tween的缓存对象池
        
        private static var sTweenPool:Vector.<Tween> = new <Tween>[];
        
        /** @private */
        starling_internal static function fromPool(target:Object, time:Number, 
                                                   transition:Object="linear"):Tween
        {
            if (sTweenPool.length) return sTweenPool.pop().reset(target, time, transition);
            else return new Tween(target, time, transition);
        }
        
        /** @private */
        starling_internal static function toPool(tween:Tween):void
        {
            // reset any object-references, to make sure we don't prevent any garbage collection
            tween.mOnStart = tween.mOnUpdate = tween.mOnRepeat = tween.mOnComplete = null;
            tween.mOnStartArgs = tween.mOnUpdateArgs = tween.mOnRepeatArgs = tween.mOnCompleteArgs = null;
            tween.mTarget = null;
            tween.mTransitionFunc = null;
            tween.removeEventListeners();
            sTweenPool.push(tween);
        }
    }
}
