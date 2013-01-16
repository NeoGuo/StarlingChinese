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
    import starling.core.starling_internal;
    import starling.events.Event;
    import starling.events.EventDispatcher;

	/** Juggler管理那些实现了IAnimatable接口的对象（比如Tweens）并执行它们。
	 * 
	 *  <p>一个juggler实例是一个非常简单的对象。它只是持有一个列表，列表里面是那些实现了IAnimatable接口的对象，并管理它们的执行时间（通过对象自己的advanceTime方法）。当动画播放完毕，就把这个对象抛出。</p>
	 *  
	 *  <p>在Starling类中有一个默认的juggler变量:</p>
	 *  
	 *  <pre>
	 *  var juggler:Juggler = Starling.juggler;
	 *  </pre>
	 *  
	 *  <p>您可以创建您自己的juggler对象，如果需要的话。这样，您就可以组合您的游戏到一些逻辑组件，并独立控制他们的动画。 您需要做的就是，在每一帧都调用您自定义的juggler的advanceTime方法。</p>
	 *  
	 *  <p>juggler另一个很强的特性就是"delayCall"方法。使用它可以延迟执行某个方法。但是和传统的延迟调用(比如setTimeout)不同, 这个方法只有在juggler被时间推送器驱动的时候才会起作用，这可以让您更加完美的控制呼叫的逻辑。</p>
	 *  <p>下面是delayCall的一些示例：</p>
	 *  <pre>
	 *  juggler.delayCall(object.removeFromParent, 1.0);
	 *  juggler.delayCall(object.addChild, 2.0, theChild);
	 *  juggler.delayCall(function():void { doSomethingFunny(); }, 3.0);
	 *  </pre>
	 * 
	 *  @see Tween
	 *  @see DelayedCall 
	 */
    public class Juggler implements IAnimatable
    {
        private var mObjects:Vector.<IAnimatable>;
        private var mElapsedTime:Number;
        
		/** 创建一个空的juggler实例. */
        public function Juggler()
        {
            mElapsedTime = 0;
            mObjects = new <IAnimatable>[];
        }

		/** 向juggler添加一个对象. @param object 实现IAnimatable的类的实例 */
        public function add(object:IAnimatable):void
        {
            if (object && mObjects.indexOf(object) == -1) 
            {
                mObjects.push(object);
            
                var dispatcher:EventDispatcher = object as EventDispatcher;
                if (dispatcher) dispatcher.addEventListener(Event.REMOVE_FROM_JUGGLER, onRemove);
            }
        }
        
        /** 判断juggler是否持有对这个对象的引用.@param object 实现IAnimatable的类的实例  */
        public function contains(object:IAnimatable):Boolean
        {
            return mObjects.indexOf(object) != -1;
        }
        
		/** 从juggler中删除一个对象. @param object 实现IAnimatable的类的实例 */
        public function remove(object:IAnimatable):void
        {
            if (object == null) return;
            
            var dispatcher:EventDispatcher = object as EventDispatcher;
            if (dispatcher) dispatcher.removeEventListener(Event.REMOVE_FROM_JUGGLER, onRemove);

            var index:int = mObjects.indexOf(object);
            if (index != -1) mObjects[index] = null;
        }
        
		/** 删除一个对象上应用的所有的tween对象 @param target 目标对象 */
        public function removeTweens(target:Object):void
        {
            if (target == null) return;
            
            for (var i:int=mObjects.length-1; i>=0; --i)
            {
                var tween:Tween = mObjects[i] as Tween;
                if (tween && tween.target == target)
                {
                    tween.removeEventListener(Event.REMOVE_FROM_JUGGLER, onRemove);
                    mObjects[i] = null;
                }
            }
        }
        
		/** 一次性删除所有的对象 */
        public function purge():void
        {
            // the object vector is not purged right away, because if this method is called 
            // from an 'advanceTime' call, this would make the loop crash. Instead, the
            // vector is filled with 'null' values. They will be cleaned up on the next call
            // to 'advanceTime'.
            
            for (var i:int=mObjects.length-1; i>=0; --i)
            {
                var dispatcher:EventDispatcher = mObjects[i] as EventDispatcher;
                if (dispatcher) dispatcher.removeEventListener(Event.REMOVE_FROM_JUGGLER, onRemove);
                mObjects[i] = null;
            }
        }
        
		/**
		 * 在一定的时间间隔之后执行指定的方法。方法会创建一个DelayedCall类的实例并返回。从juggler中删除这个实例即可取消调用。
		 * @param call 回调方法
		 * @param delay 延迟时间
		 * @param args 传递给回调方法的参数
		 * @return DelayedCall实例
		 */
        public function delayCall(call:Function, delay:Number, ...args):DelayedCall
        {
            if (call == null) return null;
            
            var delayedCall:DelayedCall = new DelayedCall(call, delay, args);
            add(delayedCall);
            return delayedCall;
        }
        
        /** Utilizes a tween to animate the target object over a certain time. Internally, this
         *  method uses a tween instance (taken from an object pool) that is added to the
         *  juggler right away. This method provides a convenient alternative for creating 
         *  and adding a tween manually.
         *  
         *  <p>Fill 'properties' with key-value pairs that describe both the 
         *  tween and the animation target. Here is an example:</p>
         *  
         *  <pre>
         *  juggler.tween(object, 2.0, {
         *      transition: Transitions.EASE_IN_OUT,
         *      delay: 20, // -> tween.delay = 20
         *      x: 50      // -> tween.animate("x", 50)
         *  });
         *  </pre> 
         */
		/**
		 * 
		 * @param target
		 * @param time
		 * @param properties
		 */		
        public function tween(target:Object, time:Number, properties:Object):void
        {
            var tween:Tween = Tween.starling_internal::fromPool(target, time);
            
            for (var property:String in properties)
            {
                var value:Object = properties[property];
                
                if (tween.hasOwnProperty(property))
                    tween[property] = value;
                else if (target.hasOwnProperty(property))
                    tween.animate(property, value as Number);
                else
                    throw new ArgumentError("Invalid property: " + property);
            }
            
            tween.addEventListener(Event.REMOVE_FROM_JUGGLER, onPooledTweenComplete);
            add(tween);
        }
        
        private function onPooledTweenComplete(event:Event):void
        {
            Tween.starling_internal::toPool(event.target as Tween);
        }
        
		/** 在一定的时间内集中处理所有的对象(单位是秒) @param time 时间(单位是秒) */
        public function advanceTime(time:Number):void
        {   
            var numObjects:int = mObjects.length;
            var currentIndex:int = 0;
            var i:int;
            
            mElapsedTime += time;
            if (numObjects == 0) return;
            
            // there is a high probability that the "advanceTime" function modifies the list 
            // of animatables. we must not process new objects right now (they will be processed
            // in the next frame), and we need to clean up any empty slots in the list.
            
            for (i=0; i<numObjects; ++i)
            {
                var object:IAnimatable = mObjects[i];
                if (object)
                {
                    // shift objects into empty slots along the way
                    if (currentIndex != i) 
                    {
                        mObjects[currentIndex] = object;
                        mObjects[i] = null;
                    }
                    
                    object.advanceTime(time);
                    ++currentIndex;
                }
            }
            
            if (currentIndex != i)
            {
                numObjects = mObjects.length; // count might have changed!
                
                while (i < numObjects)
                    mObjects[int(currentIndex++)] = mObjects[int(i++)];
                
                mObjects.length = currentIndex;
            }
        }
        
        private function onRemove(event:Event):void
        {
            remove(event.target as IAnimatable);
            
            var tween:Tween = event.target as Tween;
            if (tween && tween.isComplete)
                add(tween.nextTween);
        }
        
		/** 这个juggler对象截止到目前的存活时间累计. */
        public function get elapsedTime():Number { return mElapsedTime; }        
    }
}