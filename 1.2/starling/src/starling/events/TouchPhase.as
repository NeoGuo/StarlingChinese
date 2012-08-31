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
    import starling.errors.AbstractClassError;

    /** 这个类提供了描述触碰的各个阶段的常量值。
     *  
     *  <p>一个触碰，在它的生命周期内会遵循下面的过程：</p>
     *  
     *  <code>BEGAN(开始) -> MOVED(移动) -> ENDED(结束)</code>
     *  
     *  <p>此外，一个触碰可能进入一个称之为STATIONARY(静止)的阶段。这一阶段本身不会触发触碰事件，并且它只能发生在多点触控环境。
     *  在某些场合下需要一个解决方案，比如一个手指移动，另一个静止。这个时候，一个触碰事件必须由正在移动的手指下方的对象来派发。
     *  在这个事件的触碰对象列表中，您将会找到第二个处于静止状态的触碰对象。</p>
     *  
     *  <p>最后，还有一个称之为HOVER(悬停)的状态，这种情况只会发生在使用鼠标的情况下。
     *  它是由Flash的MouseOver事件触发的，并且这个时候鼠标按键<em>没有</em>被按下。</p> 
     */
    public final class TouchPhase
    {
        /** @private */
        public function TouchPhase() { throw new AbstractClassError(); }
        
        /** Only available for mouse input: the cursor hovers over an object <em>without</em> a 
         *  pressed button. */
        public static const HOVER:String = "hover";
        
        /** The finger touched the screen just now, or the mouse button was pressed. */
        public static const BEGAN:String = "began";
        
        /** The finger moves around on the screen, or the mouse is moved while the button is 
         *  pressed. */
        public static const MOVED:String = "moved";
        
        /** The finger or mouse (with pressed button) has not moved since the last frame. */
        public static const STATIONARY:String = "stationary";
        
        /** The finger was lifted from the screen or from the mouse button. */
        public static const ENDED:String = "ended";
    }
}