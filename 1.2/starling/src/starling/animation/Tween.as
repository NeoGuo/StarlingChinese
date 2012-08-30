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
        private var mTransition:String;
        private var mProperties:Vector.<String>;
        private var mStartValues:Vector.<Number>;
        private var mEndValues:Vector.<Number>;

        private var mOnStart:Function;
        private var mOnUpdate:Function;
        private var mOnComplete:Function;  
        
        private var mOnStartArgs:Array;
        private var mOnUpdateArgs:Array;
        private var mOnCompleteArgs:Array;
        
        private var mTotalTime:Number;
        private var mCurrentTime:Number;
        private var mDelay:Number;
        private var mRoundToInt:Boolean;
        
		/**
		 * 创建一个tween的实例， 同时设置目标对象, 时间 (单位是秒) 和过渡方式.
		 * @param target 目标
		 * @param time 时间
		 * @param transition 过渡方式，默认linear
		 * 
		 */        
        public function Tween(target:Object, time:Number, transition:String="linear")        
        {
             reset(target, time, transition);
        }

		/**
		 * 把tween恢复到它的初始值. 对pooling tweens有用.
		 * @param target 目标
		 * @param time 时间
		 * @param transition 过渡方式，默认linear
		 * @return Tween实例
		 * 
		 */		
        public function reset(target:Object, time:Number, transition:String="linear"):Tween
        {
            mTarget = target;
            mCurrentTime = 0;
            mTotalTime = Math.max(0.0001, time);
            mDelay = 0;
            mTransition = transition;
            mRoundToInt = false;
            mOnStart = mOnUpdate = mOnComplete = null;
            mOnStartArgs = mOnUpdateArgs = mOnCompleteArgs = null; 
            
            if (mProperties)  mProperties.length  = 0; else mProperties  = new <String>[];
            if (mStartValues) mStartValues.length = 0; else mStartValues = new <Number>[];
            if (mEndValues)   mEndValues.length   = 0; else mEndValues   = new <Number>[];
            
            return this;
        }
        
		/**
		 * "运动"某个对象的属性到目标值。您可以在一个tween上多次调用这个方法。
		 * @param property 属性值
		 * @param targetValue 目标值
		 * 
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
		 * 
		 */        
        public function moveTo(x:Number, y:Number):void
        {
            animate("x", x);
            animate("y", y);
        }
        
		/**
		 * "运动"目标对象的'alpha'值，直到达到目标值。
		 * @param alpha 透明度的目标值
		 * 
		 */        
        public function fadeTo(alpha:Number):void
        {
            animate("alpha", alpha);
        }
        
        /** @inheritDoc */
        public function advanceTime(time:Number):void
        {
            if (time == 0) return;
            
            var previousTime:Number = mCurrentTime;
            mCurrentTime += time;
            
            if (mCurrentTime < 0 || previousTime >= mTotalTime) 
                return;

            if (mOnStart != null && previousTime <= 0 && mCurrentTime >= 0) 
                mOnStart.apply(null, mOnStartArgs);

            var ratio:Number = Math.min(mTotalTime, mCurrentTime) / mTotalTime;
            var numAnimatedProperties:int = mStartValues.length;

            for (var i:int=0; i<numAnimatedProperties; ++i)
            {                
                if (isNaN(mStartValues[i])) 
                    mStartValues[i] = mTarget[mProperties[i]] as Number;
                
                var startValue:Number = mStartValues[i];
                var endValue:Number = mEndValues[i];
                var delta:Number = endValue - startValue;
                
                var transitionFunc:Function = Transitions.getTransition(mTransition);                
                var currentValue:Number = startValue + transitionFunc(ratio) * delta;
                if (mRoundToInt) currentValue = Math.round(currentValue);
                mTarget[mProperties[i]] = currentValue;
            }

            if (mOnUpdate != null) 
                mOnUpdate.apply(null, mOnUpdateArgs);
            
            if (previousTime < mTotalTime && mCurrentTime >= mTotalTime)
            {
                dispatchEventWith(Event.REMOVE_FROM_JUGGLER);
                if (mOnComplete != null) mOnComplete.apply(null, mOnCompleteArgs);
            }
        }
        
        /** 动画是否播放完毕 */
        public function get isComplete():Boolean { return mCurrentTime >= mTotalTime; }        
        
        /** 当前"动画"要执行的对象 */
        public function get target():Object { return mTarget; }
        
        /** 动画过程中用到的过渡方法. @see Transitions */
        public function get transition():String { return mTransition; }
        
        /** 动画执行的总时间 (秒). */
        public function get totalTime():Number { return mTotalTime; }
        
        /** 已经执行的时间(秒) */
        public function get currentTime():Number { return mCurrentTime; }
        
        /** 动画需要延迟多长时间才开始. */
        public function get delay():Number { return mDelay; }
        public function set delay(value:Number):void 
        { 
            mCurrentTime = mCurrentTime + mDelay - value;
            mDelay = value;
        }
        
        /** 表示数字是否会被截取为整型. @default false */
        public function get roundToInt():Boolean { return mRoundToInt; }
        public function set roundToInt(value:Boolean):void { mRoundToInt = value; }        
        
        /** 当tween开始动画的时候会执行的方法 (如果有延迟的话，则在延迟之后).*/
        public function get onStart():Function { return mOnStart; }
        public function set onStart(value:Function):void { mOnStart = value; }
        
        /** 动画过程中的每一帧都会执行的方法. */
        public function get onUpdate():Function { return mOnUpdate; }
        public function set onUpdate(value:Function):void { mOnUpdate = value; }
        
        /** 当tween执行完毕的时候会调用的方法. */
        public function get onComplete():Function { return mOnComplete; }
        public function set onComplete(value:Function):void { mOnComplete = value; }
        
        /** 需要传递给 'onStart' 方法的参数. */
        public function get onStartArgs():Array { return mOnStartArgs; }
        public function set onStartArgs(value:Array):void { mOnStartArgs = value; }
        
        /** 需要传递给'onUpdate' 方法的参数. */
        public function get onUpdateArgs():Array { return mOnUpdateArgs; }
        public function set onUpdateArgs(value:Array):void { mOnUpdateArgs = value; }
        
        /** 需要传递给'onComplete' 方法的参数. */
        public function get onCompleteArgs():Array { return mOnCompleteArgs; }
        public function set onCompleteArgs(value:Array):void { mOnCompleteArgs = value; }
    }
}
