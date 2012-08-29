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
        /** 事件类型：一个显示对象被添加到了它的父级容器上。 */
        public static const ADDED:String = "added";
        /** 事件类型：一个显示对象被添加到了舞台上。 */
        public static const ADDED_TO_STAGE:String = "addedToStage";
        /** 事件类型：一个显示对象进入了新的一帧。 */
        public static const ENTER_FRAME:String = "enterFrame";
        /** 事件类型：一个显示对象从它的父级删除 */
        public static const REMOVED:String = "removed";
        /** 事件类型：一个显示对象从舞台上删除。 */
        public static const REMOVED_FROM_STAGE:String = "removedFromStage";
        /** 事件类型：按钮点击。 */
        public static const TRIGGERED:String = "triggered";
        /** 事件类型：一个即将被扁平化的对象派发。 */
        public static const FLATTEN:String = "flatten";
        /** 事件类型：Flash Player尺寸改变。 */
        public static const RESIZE:String = "resize";
        /** 事件类型：可以用在一些表示“完成”的场合。 */
        public static const COMPLETE:String = "complete";
        /** 事件类型：表示创建(或重建)了Context3D实例。 */
        public static const CONTEXT3D_CREATE:String = "context3DCreate";
        /** 事件类型：表示最顶层的显示对象已被创建。 */
        public static const ROOT_CREATED:String = "rootCreated";
        /** 事件类型：当一个动画对象需要被Juggler删除的时候派发 */
        public static const REMOVE_FROM_JUGGLER:String = "removeFromJuggler";
        
        private static var sEventPool:Vector.<Event> = new <Event>[];
        
        private var mTarget:EventDispatcher;
        private var mCurrentTarget:EventDispatcher;
        private var mType:String;
        private var mBubbles:Boolean;
        private var mStopsPropagation:Boolean;
        private var mStopsImmediatePropagation:Boolean;
        private var mData:Object;
        
        /** 创建一个作为参数传递给事件侦听器的 Event 对象。 */
        public function Event(type:String, bubbles:Boolean=false, data:Object=null)
        {
            mType = type;
            mBubbles = bubbles;
            mData = data;
        }
        
        /** 阻止事件进入下一个冒泡阶段，从而阻止它被下一个对象接收。 */
        public function stopPropagation():void
        {
            mStopsPropagation = true;            
        }
        
        /** 阻止其他任何侦听器接收事件。 */
        public function stopImmediatePropagation():void
        {
            mStopsPropagation = mStopsImmediatePropagation = true;
        }
        
        /** 返回事件的描述，包括类型及是否冒泡。 */
        public function toString():String
        {
            return formatString("[{0} type=\"{1}\" bubbles={2}]", 
                getQualifiedClassName(this).split("::").pop(), mType, mBubbles);
        }
        
        /** 表示事件是否冒泡 */
        public function get bubbles():Boolean { return mBubbles; }
        
        /** 派发这个事件的对象。 */
        public function get target():EventDispatcher { return mTarget; }
        
        /** 当前事件已经冒泡到的对象。 */
        public function get currentTarget():EventDispatcher { return mCurrentTarget; }
        
        /** 这个事件的字符串类型。 */
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