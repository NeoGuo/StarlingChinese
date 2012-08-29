// =================================================================================================
//
//	Starling Framework
//	Copyright 2011 Gamua OG. All Rights Reserved.
//
//	This program is free software. You can redistribute and/or modify it
//	in accordance with the terms of the accompanying license agreement.
//
// =================================================================================================

package starling.events
{
    import flash.utils.getQualifiedClassName;
    
    import starling.core.starling_internal;
    import starling.utils.formatString;
    
    use namespace starling_internal;

    /** 当事件派发时，事件对象会作为参数传递给事件侦听器。这是Flash Event类的Starling版本。
     *
     *  <p>EventDispatcher对象会创建这个类的实例并将它派发到一个已注册的事件侦听器。 
     *  一个事件对象包含了作为这个事件特征的信息，其中非常重要的是事件类型，如果事件冒泡的话。
     *  事件的目标(target)是派发这个事件的对象。</p>
     * 
     *  <p>对于某些类型的事件，这些信息就足够了，其他事件可能需要更多的信息来传递给侦听器。 
     *  在这种情况下，您可以创建“事件”的子类，并添加您所需要的所有信息作为事件的属性。 
     *  “EnterFrameEvent”是这种做法的一个例子，它增加了一个属性用来表示已经执行的时间值。</p>
     * 
     *  <p>此外，事件类包含的方法可以中断事件的派发，阻止事件被其它的侦听器接受。（ 包括完全阻止
     *  或只是阻止进入下一个冒泡阶段）</p>
     * 
     *  @see EventDispatcher
     */
    public class Event
    {
        /** Event type for a display object that is added to a parent. */
        public static const ADDED:String = "added";
        /** Event type for a display object that is added to the stage */
        public static const ADDED_TO_STAGE:String = "addedToStage";
        /** Event type for a display object that is entering a new frame. */
        public static const ENTER_FRAME:String = "enterFrame";
        /** Event type for a display object that is removed from its parent. */
        public static const REMOVED:String = "removed";
        /** Event type for a display object that is removed from the stage. */
        public static const REMOVED_FROM_STAGE:String = "removedFromStage";
        /** Event type for a triggered button. */
        public static const TRIGGERED:String = "triggered";
        /** Event type for a display object that is being flattened. */
        public static const FLATTEN:String = "flatten";
        /** Event type for a resized Flash Player. */
        public static const RESIZE:String = "resize";
        /** Event type that may be used whenever something finishes. */
        public static const COMPLETE:String = "complete";
        /** Event type for a (re)created stage3D rendering context. */
        public static const CONTEXT3D_CREATE:String = "context3DCreate";
        /** Event type that indicates that the root DisplayObject has been created. */
        public static const ROOT_CREATED:String = "rootCreated";
        /** Event type for an animated object that requests to be removed from the juggler. */
        public static const REMOVE_FROM_JUGGLER:String = "removeFromJuggler";
        
        private static var sEventPool:Vector.<Event> = new <Event>[];
        
        private var mTarget:EventDispatcher;
        private var mCurrentTarget:EventDispatcher;
        private var mType:String;
        private var mBubbles:Boolean;
        private var mStopsPropagation:Boolean;
        private var mStopsImmediatePropagation:Boolean;
        private var mData:Object;
        
        /** Creates an event object that can be passed to listeners. */
        public function Event(type:String, bubbles:Boolean=false, data:Object=null)
        {
            mType = type;
            mBubbles = bubbles;
            mData = data;
        }
        
        /** Prevents listeners at the next bubble stage from receiving the event. */
        public function stopPropagation():void
        {
            mStopsPropagation = true;            
        }
        
        /** Prevents any other listeners from receiving the event. */
        public function stopImmediatePropagation():void
        {
            mStopsPropagation = mStopsImmediatePropagation = true;
        }
        
        /** Returns a description of the event, containing type and bubble information. */
        public function toString():String
        {
            return formatString("[{0} type=\"{1}\" bubbles={2}]", 
                getQualifiedClassName(this).split("::").pop(), mType, mBubbles);
        }
        
        /** Indicates if event will bubble. */
        public function get bubbles():Boolean { return mBubbles; }
        
        /** The object that dispatched the event. */
        public function get target():EventDispatcher { return mTarget; }
        
        /** The object the event is currently bubbling at. */
        public function get currentTarget():EventDispatcher { return mCurrentTarget; }
        
        /** A string that identifies the event. */
        public function get type():String { return mType; }
        
        /** Arbitrary data that is attached to the event. */
        public function get data():Object { return mData; }
        
        // properties for internal use
        
        /** @private */
        internal function setTarget(value:EventDispatcher):void { mTarget = value; }
        
        /** @private */
        internal function setCurrentTarget(value:EventDispatcher):void { mCurrentTarget = value; } 
        
        /** @private */
        internal function get stopsPropagation():Boolean { return mStopsPropagation; }
        
        /** @private */
        internal function get stopsImmediatePropagation():Boolean { return mStopsImmediatePropagation; }
        
        // event pooling
        
        /** @private */
        starling_internal static function fromPool(type:String, bubbles:Boolean=false, data:Object=null):Event
        {
            if (sEventPool.length) return sEventPool.pop().reset(type, bubbles, data);
            else return new Event(type, bubbles, data);
        }
        
        /** @private */
        starling_internal static function toPool(event:Event):void
        {
            event.mData = event.mTarget = event.mCurrentTarget = null;
            sEventPool.push(event);
        }
        
        /** @private */
        starling_internal function reset(type:String, bubbles:Boolean=false, data:Object=null):Event
        {
            mType = type;
            mBubbles = bubbles;
            mData = data;
            mTarget = mCurrentTarget = null;
            mStopsPropagation = mStopsImmediatePropagation = false;
            return this;
        }
    }
}