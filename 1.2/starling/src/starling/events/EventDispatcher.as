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
    import flash.utils.Dictionary;
    
    import starling.core.starling_internal;
    import starling.display.DisplayObject;
    
    use namespace starling_internal;
    
    /** EventDispatcher类是所有具备调度事件能力的类的基类。这是传统Flash里的EventDispatcher在Starling中的对应实现。
     *  
     *  <p>事件机制也是Starling架构的一个关键特性。通过事件对象可以互相通信。相比传统Flash的事件系统，Starling的事件
     *  系统是经过简化的。 主要区别在于，Starling事件没有“捕捉”的阶段。这些事件只是简单的被一个对象派发，并可以选择
     *  冒泡。他们不能向相反的方向传递。</p>  
     *  <p>就像传统的Flash类那样，显示对象只要继承EventDispatcher就可以派发事件。但要小心， 
     *  <em>Starling中的事件不能和传统Flash的事件混用。</em>  Starling的显示对象会派发Starling事件，冒泡也是在Starling
     *  显示对象中进行-但是他们不能派发或冒泡传统Flash显示对象的事件。</p>
     *  
     *  @see Event
     *  @see starling.display.DisplayObject DisplayObject
     */
    public class EventDispatcher
    {
        private var mEventListeners:Dictionary;
        
        /** Helper object. */
        private static var sBubbleChains:Array = [];
        
        /** 创建一个EventDispatcher实例。 */
        public function EventDispatcher()
        {  }
        
        /** 在指定的对象上注册一个事件侦听器。 */
        public function addEventListener(type:String, listener:Function):void
        {
            if (mEventListeners == null)
                mEventListeners = new Dictionary();
            
            var listeners:Vector.<Function> = mEventListeners[type];
            if (listeners == null)
                mEventListeners[type] = new <Function>[listener];
            else if (listeners.indexOf(listener) == -1) // check for duplicates
                listeners.push(listener);
        }
        
        /** 在指定的对象上删除一个事件侦听器。 */
        public function removeEventListener(type:String, listener:Function):void
        {
            if (mEventListeners)
            {
                var listeners:Vector.<Function> = mEventListeners[type];
                if (listeners)
                {
                    var numListeners:int = listeners.length;
                    var remainingListeners:Vector.<Function> = new <Function>[];
                    
                    for (var i:int=0; i<numListeners; ++i)
                        if (listeners[i] != listener) remainingListeners.push(listeners[i]);
                    
                    mEventListeners[type] = remainingListeners;
                }
            }
        }
        
        /** 根据指定的事件类型删除所有与这个事件类型有关的侦听器，如果传递null则删除所有的侦听器。 
         *  要小心进行删除所有侦听器的操作：您永远不知道还有谁在侦听。 */
        public function removeEventListeners(type:String=null):void
        {
            if (type && mEventListeners)
                delete mEventListeners[type];
            else
                mEventListeners = null;
        }
        
        /** 派发一个事件到所有注册了同一个事件类型侦听器的对象。 */
        public function dispatchEvent(event:Event):void
        {
            var bubbles:Boolean = event.bubbles;
            
            if (!bubbles && (mEventListeners == null || !(event.type in mEventListeners)))
                return; // no need to do anything
            
            // we save the current target and restore it later;
            // this allows users to re-dispatch events without creating a clone.
            
            var previousTarget:EventDispatcher = event.target;
            event.setTarget(this);
            
            if (bubbles && this is DisplayObject) bubble(event);
            else                                  invoke(event);
            
            if (previousTarget) event.setTarget(previousTarget);
        }
        
        private function invoke(event:Event):Boolean
        {
            var listeners:Vector.<Function> = mEventListeners ? mEventListeners[event.type] : null;
            var numListeners:int = listeners == null ? 0 : listeners.length;
            
            if (numListeners)
            {
                event.setCurrentTarget(this);
                
                // we can enumerate directly over the vector, because:
                // when somebody modifies the list while we're looping, "addEventListener" is not
                // problematic, and "removeEventListener" will create a new Vector, anyway.
                
                for (var i:int=0; i<numListeners; ++i)
                {
                    var listener:Function = listeners[i] as Function;
                    var numArgs:int = listener.length;
                    
                    if (numArgs == 0) listener();
                    else if (numArgs == 1) listener(event);
                    else listener(event, event.data);
                    
                    if (event.stopsImmediatePropagation)
                        return true;
                }
                
                return event.stopsPropagation;
            }
            else
            {
                return false;
            }
        }
        
        private function bubble(event:Event):void
        {
            // we determine the bubble chain before starting to invoke the listeners.
            // that way, changes done by the listeners won't affect the bubble chain.
            
            var chain:Vector.<EventDispatcher>;
            var element:DisplayObject = this as DisplayObject;
            var length:int = 1;
            
            if (sBubbleChains.length > 0) { chain = sBubbleChains.pop(); chain[0] = element; }
            else chain = new <EventDispatcher>[element];
            
            while (element = element.parent)
                chain[length++] = element;

            for (var i:int=0; i<length; ++i)
            {
                var stopPropagation:Boolean = chain[i].invoke(event);
                if (stopPropagation) break;
            }
            
            chain.length = 0;
            sBubbleChains.push(chain);
        }
        
        /** Dispatches an event with the given parameters to all objects that have registered for 
         *  events of the given type. The method uses an internal pool of event objects to avoid 
         *  allocations. */
        public function dispatchEventWith(type:String, bubbles:Boolean=false, data:Object=null):void
        {
            if (bubbles || hasEventListener(type)) 
            {
                var event:Event = Event.fromPool(type, bubbles, data);
                dispatchEvent(event);
                Event.toPool(event);
            }
        }
        
        /** 判断是否具备指定的事件类型的侦听器。 */
        public function hasEventListener(type:String):Boolean
        {
            var listeners:Vector.<Function> = mEventListeners ? mEventListeners[type] : null;
            return listeners ? listeners.length != 0 : false;
        }
    }
}