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
    /**  IAnimatable接口定义了这样的一些对象：基于一个时间范围实现动画过程。任何实现了这个接口的类的实例，都可以被添加到juggler。
     *   <p>当一个对象不再需要运动的时候，您应当将它从juggler删除。要实现这一点，您可以手动执行这个方法：juggler.remove(object) 来删除它，
	 *   或者让这个对象派发一个事件来请求juggler删除自己，事件类型是Event.REMOVE_FROM_JUGGLER. 
	 *   Tween类就是这样一个基于事件调度的类的例子，您不需要手动从juggler删除tween的实例。</p>
     *   
     *   @see Juggler
     *   @see Tween
     */
    public interface IAnimatable 
    {
        /** 暂且把这个方法称之为"时间推送器"吧. 在Starling里面，这个方法一般会和EnterFrame事件绑定起来，
		 *  就是说，如果和EnterFrame绑定，每一帧都会调用这个方法，同时传递消逝的时间值。这个时间值非常重要，
		 *  比如当Starling停止渲染，然后恢复的时候，需要从正确的点开始执行动画。
		 *  当然您也可以手动控制什么时候调用这个方法，比如在EnterFrame回调方法里面加入一些条件判断，确定是否调用这个方法，来实现画面的暂停。
		 *  @param time 已经流逝的时间(秒) */
        function advanceTime(time:Number):void;
    }
}