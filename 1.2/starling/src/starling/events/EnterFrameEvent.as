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
    /** 
     *  处于显示列表树中的所有显示对象，在每一帧都会派发一个EnterFrameEvent事件。 
     *  
     *  它包含了从上一帧到现在所经过的时间的信息。这样，您就可以轻松的通过帧频创建动画，传递经过的时间给它。
     */ 
    public class EnterFrameEvent extends Event
    {
        /** 一个显示对象进入了新的一帧。 */
        public static const ENTER_FRAME:String = "enterFrame";
        
        /** 创建一个EnterFrameEvent实例 */
        public function EnterFrameEvent(type:String, passedTime:Number, bubbles:Boolean=false)
        {
            super(type, bubbles, passedTime);
        }
        
        /** 从上一帧到现在所经过的时间。（以秒为单位） */
        public function get passedTime():Number { return data as Number; }
    }
}