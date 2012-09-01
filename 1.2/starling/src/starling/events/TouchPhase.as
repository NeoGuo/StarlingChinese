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
        
        /**  只有鼠标模式下可用：当光标滑过一个对象，并且没有按下鼠标。 */
        public static const HOVER:String = "hover";
        
        /** 当手指刚刚接触屏幕，或者鼠标按下。 */
        public static const BEGAN:String = "began";
        
        /** 手指在屏幕上滑动，或者鼠标在按下的情况下在屏幕上滑动。 */
        public static const MOVED:String = "moved";
        
        /** 手指或鼠标(按下) 没有移动。 */
        public static const STATIONARY:String = "stationary";
        
        /** 手指离开屏幕或鼠标松开。 */
        public static const ENDED:String = "ended";
    }
}