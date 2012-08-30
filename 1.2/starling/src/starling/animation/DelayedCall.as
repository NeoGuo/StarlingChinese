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

    /** DelayedCall类允许您在一定的时间间隔之后去执行某个方法(和setTimeout有些类似)。由于这个类实现了IAnimatable接口，您可以把一个DelayedCall实例添加到juggler中。
	 *  在大部分情况下，您不需要直接使用这个类；Juggler类包含了一个方法来直接实现延迟调用这个功能。
	 *  <p>当方法调用完毕之后，DelayedCall对象会派发一个类型是“Event.REMOVE_FROM_JUGGLER”的事件，然后如果不再需要它了，Juggler会自动将它删除。</p>
     *  @see Juggler
     */ 
    public class DelayedCall extends EventDispatcher implements IAnimatable
    {
        private var mCurrentTime:Number = 0;
        private var mTotalTime:Number;
        private var mCall:Function;
        private var mArgs:Array;
        private var mRepeatCount:int = 1;
        
        /** 创建一个延迟调用对象(DelayedCall的实例)
		 * @param call 需要延迟调用的方法
		 * @param delay 延迟时间(秒为单位)
		 * @param args 传递给call这个方法的参数
		 **/
        public function DelayedCall(call:Function, delay:Number, args:Array=null)
        {
            mCall = call;
            mTotalTime = Math.max(delay, 0.0001);
            mArgs = args;
        }
        
        /** @inheritDoc */
        public function advanceTime(time:Number):void
        {
            var previousTime:Number = mCurrentTime;
            mCurrentTime = Math.min(mTotalTime, mCurrentTime + time);
            
            if (previousTime < mTotalTime && mCurrentTime >= mTotalTime)
            {                
                mCall.apply(null, mArgs);
                
                if (mRepeatCount > 1)
                {
                    mRepeatCount -= 1;
                    mCurrentTime = 0;
                    advanceTime((previousTime + time) - mTotalTime);
                }
                else
                {
                    dispatchEventWith(Event.REMOVE_FROM_JUGGLER);
                }
            }
        }
        
        /** 用来确定调用是否已经完成，如果为true则代表已经过去了足够的时间，调用已经完成了 */
        public function get isComplete():Boolean 
        { 
            return mRepeatCount == 1 && mCurrentTime >= mTotalTime; 
        }
        
        /** 要延迟的总时间 (单位是秒). */
        public function get totalTime():Number { return mTotalTime; }
        
        /** 目前已经消逝的时间(单位是秒). */
        public function get currentTime():Number { return mCurrentTime; }
        
        /** 方法调用将被重复的次数 */
        public function get repeatCount():int { return mRepeatCount; }
        public function set repeatCount(value:int):void { mRepeatCount = value; }
    }
}