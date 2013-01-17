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
    import flash.geom.Point;
    
    import starling.core.starling_internal;
    import starling.events.EnterFrameEvent;
    import starling.events.Event;
    
    use namespace starling_internal;
    
	/** 当Flash容器的尺寸发生改变时进行派发。 */
	[Event(name="resize", type="starling.events.ResizeEvent")]
	
	/** 当键盘按键松开时进行派发。 */
	[Event(name="keyUp", type="starling.events.KeyboardEvent")]
	
	/** 当键盘按键按下时进行派发。 */
	[Event(name="keyDown", type="starling.events.KeyboardEvent")]
    
	/** Stage是显示列表树的根节点，只有直接或者间接放置到stage上的显示对象才会被渲染。
	 *
	 *  <p>这个类相当于Starling版本的Stage，注意不要和传统的Flash里的Stage混淆。
	 *  传统的Flash里的Stage只能包含类型为<code>flash.display.DisplayObject</code>的对象，
	 *  而Starling里的Stage只能包含类型为<code>starling.display.DisplayObject</code>的对象，
	 *  由于Starling显示列表并不等同于传统Flash显示列表，所以这些类并不兼容，不能混用，也不能互相代替。
	 *  </p>
	 * 
	 *  <p>stage对象是被<code>Starling</code>类自动创建的，请不要手动创建一个stage对象。</p>
	 * 
	 *  <strong>键盘事件</strong>
	 * 
	 *  <p>在Starling中，键盘事件只能够在stage派发，所以，如果想捕获到派发的键盘事件，只能给stage添加键盘事件监听。</p>
	 * 
	 *  <strong>尺寸变化事件</strong>
	 * 
	 *  <p>当Flash player 尺寸变化时，stage会派发一个<code>ResizeEvent</code>事件。
	 *  这个事件的属性包含更新后的Flash player的宽度和高度。</p>
	 *
	 *  @see starling.events.KeyboardEvent
	 *  @see starling.events.ResizeEvent  
	 * 
	 * */
    public class Stage extends DisplayObjectContainer
    {
        private var mWidth:int;
        private var mHeight:int;
        private var mColor:uint;
        private var mEnterFrameEvent:EnterFrameEvent = new EnterFrameEvent(Event.ENTER_FRAME, 0.0);
        
        /** @private */
        public function Stage(width:int, height:int, color:uint=0)
        {
            mWidth = width;
            mHeight = height;
            mColor = color;
        }
        
        /** @inheritDoc */
        public function advanceTime(passedTime:Number):void
        {
            mEnterFrameEvent.reset(Event.ENTER_FRAME, false, passedTime);
            broadcastEvent(mEnterFrameEvent);
        }

		/**
		 * 返回舞台坐标系某个点下方的最顶层的显示对象，如果没有找到任何对象，则返回Stage本身。
		 * @param localPoint	舞台坐标系的某点
		 * @param forTouch		是否只检测能够触碰到的对象。如果为ture，检测会忽略掉不可见和不可触碰的对象。
		 * @return DisplayObject
		 */
        public override function hitTest(localPoint:Point, forTouch:Boolean=false):DisplayObject
        {
            if (forTouch && (!visible || !touchable))
                return null;
            
            // locations outside of the stage area shouldn't be accepted
            if (localPoint.x < 0 || localPoint.x > mWidth ||
                localPoint.y < 0 || localPoint.y > mHeight)
                return null;
            
            // if nothing else is hit, the stage returns itself as target
            var target:DisplayObject = super.hitTest(localPoint, forTouch);
            if (target == null) target = this;
            return target;
        }
        
        /** @private */
        public override function set width(value:Number):void 
        { 
            throw new IllegalOperationError("Cannot set width of stage");
        }
        
        /** @private */
        public override function set height(value:Number):void
        {
            throw new IllegalOperationError("Cannot set height of stage");
        }
        
        /** @private */
        public override function set x(value:Number):void
        {
            throw new IllegalOperationError("Cannot set x-coordinate of stage");
        }
        
        /** @private */
        public override function set y(value:Number):void
        {
            throw new IllegalOperationError("Cannot set y-coordinate of stage");
        }
        
        /** @private */
        public override function set scaleX(value:Number):void
        {
            throw new IllegalOperationError("Cannot scale stage");
        }

        /** @private */
        public override function set scaleY(value:Number):void
        {
            throw new IllegalOperationError("Cannot scale stage");
        }
        
        /** @private */
        public override function set rotation(value:Number):void
        {
            throw new IllegalOperationError("Cannot rotate stage");
        }
        
		/** 舞台的背景颜色 */
        public function get color():uint { return mColor; }
        public function set color(value:uint):void { mColor = value; }
        
		/** 舞台坐标系的宽度。改变此值，将会缩放舞台的显示内容（相对于starling对象的<code>viewPort</code>属性）。*/
        public function get stageWidth():int { return mWidth; }
        public function set stageWidth(value:int):void { mWidth = value; }
        
		/** 舞台坐标系的高度。改变此值，将会缩放舞台的显示内容（相对于starling对象的<code>viewPort</code>属性）。*/
        public function get stageHeight():int { return mHeight; }
        public function set stageHeight(value:int):void { mHeight = value; }
    }
}