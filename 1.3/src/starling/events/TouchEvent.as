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
    import starling.core.starling_internal;
    import starling.display.DisplayObject;
    
    use namespace starling_internal;
    
	/** 一个TouchEvent是被手指触碰或鼠标输入来触发的。  
	 *  
	 *  <p>在Starling中，无论是触碰事件还是鼠标事件，都统一封装为一个类：TouchEvent。
	 *  要处理用户在一个可触碰的屏幕或使用鼠标完成的输入， 您需要注册一个事件侦听器，来侦听类型是<code>TouchEvent.TOUCH</code>的事件。
	 *  这是唯一的您需要捕获的事件类型； 原有Flash里面的那个很长的事件类型列表，全都被映射到一个"TouchPhases"里面。</p> 
	 * 
	 *  <p>鼠标输入和触摸屏输入的区别是：</p>
	 *  
	 *  <ul>
	 *    <li>在某一时刻只有一个鼠标光标可以呈现</li>
	 *    <li>只有鼠标才可以"hover",即在没有按下按键的情况下滑过一个对象。</li>
	 *  </ul> 
	 *  
	 *  <strong>哪些对象能够接收触碰事件？</strong>
	 * 
	 *  <p>在Starling中，任何一个显示对象都可以接受触碰事件，只要它的 
	 *  <code>touchable</code> 属性，以及它的父级都是可用状态(true)。 在Starling中是没有"InteractiveObject"这个类的。</p>
	 *  
	 *  <strong>如何使用单个触碰对象</strong>
	 *  
	 *  <p>T事件包含了一个包括所有的触碰对象的列表。每一个独立的触碰都被保存在一个类型是"Touch"的对象里。
	 *  既然您通常只对在特定对象上发生的触碰感兴趣，您可以查询事件，传入一个具体的目标：</p>
	 * 
	 *  <code>var touches:Vector.&lt;Touch&gt; = touchEvent.getTouches(this);</code>
	 *  
	 *  <p>这会返回附加在"this"或 它的子级上的所有触碰对象。如果您没有使用多点触碰，您也可以直接访问触碰对象，就像这样：</p>
	 * 
	 *  <code>var touch:Touch = touchEvent.getTouch(this);</code>
	 *  
	 *  @see Touch
	 *  @see TouchPhase
	 */ 
    public class TouchEvent extends Event
    {
		/** 触碰或鼠标输入的事件类型。 */
        public static const TOUCH:String = "touch";
        
        private var mShiftKey:Boolean;
        private var mCtrlKey:Boolean;
        private var mTimestamp:Number;
        private var mVisitedObjects:Vector.<EventDispatcher>;
        
        /** Helper object. */
        private static var sTouches:Vector.<Touch> = new <Touch>[];
        
		/**
		 * 创建一个新的TouchEvent实例。
		 * @param type 事件类型
		 * @param touches 触碰对象数组
		 * @param shiftKey 是否按下了shift键
		 * @param ctrlKey 是否按下了ctrl键
		 * @param bubbles 是否冒泡
		 */        
        public function TouchEvent(type:String, touches:Vector.<Touch>, shiftKey:Boolean=false, 
                                   ctrlKey:Boolean=false, bubbles:Boolean=true)
        {
            super(type, bubbles, touches);
            
            mShiftKey = shiftKey;
            mCtrlKey = ctrlKey;
            mTimestamp = -1.0;
            mVisitedObjects = new <EventDispatcher>[];
            
            var numTouches:int=touches.length;
            for (var i:int=0; i<numTouches; ++i)
                if (touches[i].timestamp > mTimestamp)
                    mTimestamp = touches[i].timestamp;
        }
        
		/**
		 * 返回附加在指定的对象上的触碰对象数组。如果你传递一个'result'数组，那么会将touch对象添加到这个数组中来代替创建一个新的数组。
		 * @param target 目标对象
		 * @param phase 阶段
		 * @param result 传递数组
		 * @return Vector.<Touch>
		 */		
        public function getTouches(target:DisplayObject, phase:String=null,
                                   result:Vector.<Touch>=null):Vector.<Touch>
        {
            if (result == null) result = new <Touch>[];
            var allTouches:Vector.<Touch> = data as Vector.<Touch>;
            var numTouches:int = allTouches.length;
            
            for (var i:int=0; i<numTouches; ++i)
            {
                var touch:Touch = allTouches[i];
                var correctTarget:Boolean = touch.isTouching(target);
                var correctPhase:Boolean = (phase == null || phase == touch.phase);
                    
                if (correctTarget && correctPhase)
                    result.push(touch);
            }
            return result;
        }
        
		/** 返回附加到指定对象上的一个触碰对象。
		 * @param target 目标对象
		 * @param phase 阶段
		 **/
        public function getTouch(target:DisplayObject, phase:String=null):Touch
        {
            getTouches(target, phase, sTouches);
            if (sTouches.length) 
            {
                var touch:Touch = sTouches[0];
                sTouches.length = 0;
                return touch;
            }
            else return null;
        }
        
		/** 判断目标显示对象是否正在被触碰或被鼠标滑过。 */
        public function interactsWith(target:DisplayObject):Boolean
        {
            if (getTouch(target) == null)
                return false;
            else
            {
                var touches:Vector.<Touch> = getTouches(target);
                
                for (var i:int=touches.length-1; i>=0; --i)
                    if (touches[i].phase != TouchPhase.ENDED)
                        return true;
                
                return false;
            }
        }

        // custom dispatching
        
        /** @private
         *  Dispatches the event along a custom bubble chain. During the lifetime of the event,
         *  each object is visited only once. */
        starling_internal function dispatch(chain:Vector.<EventDispatcher>):void
        {
            if (chain && chain.length)
            {
                var chainLength:int = bubbles ? chain.length : 1;
                var previousTarget:EventDispatcher = target;
                setTarget(chain[0] as EventDispatcher);
                
                for (var i:int=0; i<chainLength; ++i)
                {
                    var chainElement:EventDispatcher = chain[i] as EventDispatcher;
                    if (mVisitedObjects.indexOf(chainElement) == -1)
                    {
                        var stopPropagation:Boolean = chainElement.invokeEvent(this);
                        mVisitedObjects.push(chainElement);
                        if (stopPropagation) break;
                    }
                }
                
                setTarget(previousTarget);
            }
        }
        
        // properties
        
		/** 事件发生的时间（单位是秒，自应用启动时算起）。 */
        public function get timestamp():Number { return mTimestamp; }
        
		/** 当前可用的所有触碰对象。 */
        public function get touches():Vector.<Touch> { return (data as Vector.<Touch>).concat(); }
        
		/** 表示，事件发生时shift键是否被按下。 */
        public function get shiftKey():Boolean { return mShiftKey; }
        
		/** 表示，事件发生时ctrl键是否被按下。 (Mac OS: Cmd 或 Ctrl) */
        public function get ctrlKey():Boolean { return mCtrlKey; }
    }
}