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
    import flash.geom.Point;
    
	/** 当Flash容器的尺寸改变后，stage会派发一个ResizeEvent。用这个值可以更新Starling的视口和stage的尺寸。
	 *  
	 *  <p>事件的属性包含了更新后的Flash Player的宽度和高度。如果您希望缩放stage上的内容来充满屏幕， 请更新 
	 *  <code>Starling.current.viewPort</code> 矩形区域。如果您希望使用额外的屏幕区域，
	 *  请更新 <code>stage.stageWidth</code> 和 <code>stage.stageHeight</code></p>
	 *
	 *  @see starling.display.Stage
	 *  @see starling.core.Starling
	 */
    public class ResizeEvent extends Event
    {
		/** 事件类型：Flash Player尺寸改变。 */
		public static const RESIZE:String = "resize";
        
		/** 创建一个新的ResizeEvent实例。 */
        public function ResizeEvent(type:String, width:int, height:int, bubbles:Boolean=false)
        {
        	super(type, bubbles, new Point(width, height));
        }
        
		/** 播放器更新后的宽度。 */
        public function get width():int { return (data as Point).x; }
        
		/** 播放器更新后的高度。 */
        public function get height():int { return (data as Point).y; }
	}
}