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
    import flash.geom.Matrix;
    import flash.geom.Point;
    import flash.geom.Rectangle;
    import flash.system.Capabilities;
    import flash.utils.getQualifiedClassName;
    
    import starling.core.RenderSupport;
    import starling.core.starling_internal;
    import starling.errors.AbstractClassError;
    import starling.events.Event;
    import starling.filters.FragmentFilter;
    import starling.utils.MatrixUtil;
    
    use namespace starling_internal;
    
	/**
	 * 一个显示对象容器是一个包含了各种显示对象的集合。
	 * 这是所有容器类（包含其他显示对象的容器）的基类。它拥有一个有序列表来管理子级对象，并在显示对象树立定义了
	 * 所有子级的显示顺序。
	 *  
	 *  <p>一个容器本身是没有尺寸的，它的宽度和高度代表了子级的范围，改变这些属性会缩放它的所有子级。</p>
	 *  
	 *  <p>由于DisplayObjectContainer是一个抽象类，你不能直接实例化它，而是应该使用它的子类。
	 * 其中最轻量级的容器子类是"Sprite"。</p>
	 *  
	 *  <strong>添加和删除子级</strong>
	 *  
	 *  <p>这个类包含了一些允许你添加和删除子级的方法。
	 * 当你添加一个子级，它会被添加到列表的最顶层，有可能会遮挡住前一个添加的子级。
	 * 你可以通过索引访问子级，第一个子级索引为0，第二个子级索引为1，以此类推。</p> 
	 *  
	 * 向容器添加或者删对象会派发一些不冒泡的事件。
	 *  
	 *  <ul>
	 *   <li><code>Event.ADDED</code>: 对象被添加到了它的父级。</li>
	 *   <li><code>Event.ADDED_TO_STAGE</code>: 对象被添加到了它的父级，并且父级已经被添加
	 * 到stage上，因此对象立即显示。</li>
	 *   <li><code>Event.REMOVED</code>: 从对象的父级删除该对象。</li>
	 *   <li><code>Event.REMOVED_FROM_STAGE</code>: 从对象的父级删除该对象，并且父级已经被添加
	 * 到stage上，因此对象立即不显示。</li>
	 *  </ul>
	 * 
	 *  
	 * 尤其是<code>ADDED_TO_STAGE</code>事件是非常有用的，因为它可以让你在一个对象第一次被渲染时自动执行一些逻辑（比如开始播放一段动画）。
	 *  
	 *  @see Sprite
	 *  @see DisplayObject
	 */
    public class DisplayObjectContainer extends DisplayObject
    {
        // members
        
        private var mChildren:Vector.<DisplayObject>;
        
        /** Helper objects. */
        private static var sHelperMatrix:Matrix = new Matrix();
        private static var sHelperPoint:Point = new Point();
        private static var sBroadcastListeners:Vector.<DisplayObject> = new <DisplayObject>[];
        
        // construction
        
        /** @private */
        public function DisplayObjectContainer()
        {
            if (Capabilities.isDebugger && 
                getQualifiedClassName(this) == "starling.display::DisplayObjectContainer")
            {
                throw new AbstractClassError();
            }
            
            mChildren = new <DisplayObject>[];
        }
        
		/** 释放所有子级的资源。 */
        public override function dispose():void
        {
            for (var i:int=mChildren.length-1; i>=0; --i)
                mChildren[i].dispose();
            
            super.dispose();
        }
        
        // child management
        
		/**
		 * 添加一个显示对象到容器，它将被添加到顶层。
		 * @param child	子级显示对象
		 * @return DisplayObject
		 */
        public function addChild(child:DisplayObject):DisplayObject
        {
            addChildAt(child, numChildren);
            return child;
        }
        
		/**
		 * 根据一个索引值添加一个显示对象到容器。
		 * @param child	子级显示对象
		 * @param index	索引
		 * @return DisplayObject
		 * @throws RangeError
		 */
        public function addChildAt(child:DisplayObject, index:int):DisplayObject
        {
            var numChildren:int = mChildren.length; 
            
            if (index >= 0 && index <= numChildren)
            {
                child.removeFromParent();
                
                // 'splice' creates a temporary object, so we avoid it if it's not necessary
                if (index == numChildren) mChildren.push(child);
                else                      mChildren.splice(index, 0, child);
                
                child.setParent(this);
                child.dispatchEventWith(Event.ADDED, true);
                
                if (stage)
                {
                    var container:DisplayObjectContainer = child as DisplayObjectContainer;
                    if (container) container.broadcastEventWith(Event.ADDED_TO_STAGE);
                    else           child.dispatchEventWith(Event.ADDED_TO_STAGE);
                }
                
                return child;
            }
            else
            {
                throw new RangeError("Invalid child index");
            }
        }
        
		/**
		 * 从容器内删除一个显示对象，如果这个对象不是容器的子级，则什么都不会发生。
		 * 如果需要，可以销毁这个对象。
		 * @param child		子级显示对象
		 * @param dispose	是否释放子级对象的资源
		 * @return DisplayObject
		 */
        public function removeChild(child:DisplayObject, dispose:Boolean=false):DisplayObject
        {
            var childIndex:int = getChildIndex(child);
            if (childIndex != -1) removeChildAt(childIndex, dispose);
            return child;
        }
        
		/**
		 * 根据指定的索引值删除一个子级显示对象。
		 * 列表中这个对象上层的对象将往下移，如果需要，可以销毁这个对象。
		 * @param index	索引
		 * @param dispose	是否释放子级对象的资源
		 * @return DisplayObject
		 * @throws RangeError	抛出无效索引的错误。
		 */
        public function removeChildAt(index:int, dispose:Boolean=false):DisplayObject
        {
            if (index >= 0 && index < numChildren)
            {
                var child:DisplayObject = mChildren[index];
                child.dispatchEventWith(Event.REMOVED, true);
                
                if (stage)
                {
                    var container:DisplayObjectContainer = child as DisplayObjectContainer;
                    if (container) container.broadcastEventWith(Event.REMOVED_FROM_STAGE);
                    else           child.dispatchEventWith(Event.REMOVED_FROM_STAGE);
                }
                
                child.setParent(null);
                index = mChildren.indexOf(child); // index might have changed by event handler
                if (index >= 0) mChildren.splice(index, 1); 
                if (dispose) child.dispose();
                
                return child;
            }
            else
            {
                throw new RangeError("Invalid child index");
            }
        }
        
		/**
		 * 根据指定的范围删除容器内的一组对象（包括结束索引）。
		 * 如果没有传入参数，所有的子对象将被删除。
		 * @param beginIndex	起始索引
		 * @param endIndex		结束索引
		 * @param dispose		是否释放子级对象的资源
		 */
        public function removeChildren(beginIndex:int=0, endIndex:int=-1, dispose:Boolean=false):void
        {
            if (endIndex < 0 || endIndex >= numChildren) 
                endIndex = numChildren - 1;
            
            for (var i:int=beginIndex; i<=endIndex; ++i)
                removeChildAt(beginIndex, dispose);
        }
        
		/**
		 * 根据指定的索引返回对应的子级对象。
		 * @param index	索引
		 * @return DisplayObject
		 * @throws RangeError	抛出无效索引的错误。
		 */
        public function getChildAt(index:int):DisplayObject
        {
            if (index >= 0 && index < numChildren)
                return mChildren[index];
            else
                throw new RangeError("Invalid child index");
        }
        
		/**
		 * 根据指定的名称返回对应的子级对象（非递归，只遍历容器本身的子对象）。
		 * @param name	名称
		 * @return DisplayObject
		 */
        public function getChildByName(name:String):DisplayObject
        {
            var numChildren:int = mChildren.length;
            for (var i:int=0; i<numChildren; ++i)
                if (mChildren[i].name == name) return mChildren[i];

            return null;
        }
        
		/**
		 * 获取指定子级对象在容器中的索引。如果没有找到，返回"-1"。 
		 * @param child	子级显示对象
		 * @return 索引
		 */
        public function getChildIndex(child:DisplayObject):int
        {
            return mChildren.indexOf(child);
        }
        
		/**
		 * 移动一个子级到指定的索引，在它后面的子级将向后移动。
		 * @param child	子级显示对象
		 * @param index	索引
		 * @throws ArgumentError	
		 */
        public function setChildIndex(child:DisplayObject, index:int):void
        {
            var oldIndex:int = getChildIndex(child);
            if (oldIndex == -1) throw new ArgumentError("Not a child of this container");
            mChildren.splice(oldIndex, 1);
            mChildren.splice(index, 0, child);
        }
        
		/**
		 * 互换两个子级的索引。
		 * @param child1	子级显示对象1
		 * @param child2	子级显示对象2
		 * @throws ArgumentError
		 */
        public function swapChildren(child1:DisplayObject, child2:DisplayObject):void
        {
            var index1:int = getChildIndex(child1);
            var index2:int = getChildIndex(child2);
            if (index1 == -1 || index2 == -1) throw new ArgumentError("Not a child of this container");
            swapChildrenAt(index1, index2);
        }
        
		/**
		 * 互换两个子级的索引。
		 * @param index1	索引1
		 * @param index2	索引2
		 */
        public function swapChildrenAt(index1:int, index2:int):void
        {
            var child1:DisplayObject = getChildAt(index1);
            var child2:DisplayObject = getChildAt(index2);
            mChildren[index1] = child2;
            mChildren[index2] = child1;
        }
        
		/**
		 * 根据指定的排序方法对所有子级进行排序（就像Vector类的排序功能一样）。
		 * @param compareFunction	排序方法
		 */
        public function sortChildren(compareFunction:Function):void
        {
            mChildren = mChildren.sort(compareFunction);
        }
        
		/**
		 * 通过递归的方法，判断一个指定的显示对象是否为容器的子级（直接或者间接的）。
		 * @param child	子级显示对象
		 * @return Boolean
		 */
        public function contains(child:DisplayObject):Boolean
        {
            while (child)
            {
                if (child == this) return true;
                else child = child.parent;
            }
            return false;
        }
        
        /** @inheritDoc */ 
        public override function getBounds(targetSpace:DisplayObject, resultRect:Rectangle=null):Rectangle
        {
            if (resultRect == null) resultRect = new Rectangle();
            
            var numChildren:int = mChildren.length;
            
            if (numChildren == 0)
            {
                getTransformationMatrix(targetSpace, sHelperMatrix);
                MatrixUtil.transformCoords(sHelperMatrix, 0.0, 0.0, sHelperPoint);
                resultRect.setTo(sHelperPoint.x, sHelperPoint.y, 0, 0);
                return resultRect;
            }
            else if (numChildren == 1)
            {
                return mChildren[0].getBounds(targetSpace, resultRect);
            }
            else
            {
                var minX:Number = Number.MAX_VALUE, maxX:Number = -Number.MAX_VALUE;
                var minY:Number = Number.MAX_VALUE, maxY:Number = -Number.MAX_VALUE;
                
                for (var i:int=0; i<numChildren; ++i)
                {
                    mChildren[i].getBounds(targetSpace, resultRect);
                    minX = minX < resultRect.x ? minX : resultRect.x;
                    maxX = maxX > resultRect.right ? maxX : resultRect.right;
                    minY = minY < resultRect.y ? minY : resultRect.y;
                    maxY = maxY > resultRect.bottom ? maxY : resultRect.bottom;
                }
                
                resultRect.setTo(minX, minY, maxX - minX, maxY - minY);
                return resultRect;
            }                
        }
        
        /** @inheritDoc */
        public override function hitTest(localPoint:Point, forTouch:Boolean=false):DisplayObject
        {
            if (forTouch && (!visible || !touchable))
                return null;
            
            var localX:Number = localPoint.x;
            var localY:Number = localPoint.y;
            
            var numChildren:int = mChildren.length;
            for (var i:int=numChildren-1; i>=0; --i) // front to back!
            {
                var child:DisplayObject = mChildren[i];
                getTransformationMatrix(child, sHelperMatrix);
                
                MatrixUtil.transformCoords(sHelperMatrix, localX, localY, sHelperPoint);
                var target:DisplayObject = child.hitTest(sHelperPoint, forTouch);
                
                if (target) return target;
            }
            
            return null;
        }
        
        /** @inheritDoc */
        public override function render(support:RenderSupport, parentAlpha:Number):void
        {
            var alpha:Number = parentAlpha * this.alpha;
            var numChildren:int = mChildren.length;
            var blendMode:String = support.blendMode;
            
            for (var i:int=0; i<numChildren; ++i)
            {
                var child:DisplayObject = mChildren[i];
                
                if (child.hasVisibleArea)
                {
                    var filter:FragmentFilter = child.filter;

                    support.pushMatrix();
                    support.transformMatrix(child);
                    support.blendMode = child.blendMode;
                    
                    if (filter) filter.render(child, support, alpha);
                    else        child.render(support, alpha);
                    
                    support.blendMode = blendMode;
                    support.popMatrix();
                }
            }
        }
        
		/**
		 * 通过递归的方法，对所有的子级派发一个指定事件，此事件必须是非冒泡事件。
		 * @param event	事件
		 * @throws ArgumentError
		 */
        public function broadcastEvent(event:Event):void
        {
            if (event.bubbles)
                throw new ArgumentError("Broadcast of bubbling events is prohibited");
            
            // The event listeners might modify the display tree, which could make the loop crash. 
            // Thus, we collect them in a list and iterate over that list instead.
            // And since another listener could call this method internally, we have to take 
            // care that the static helper vector does not get currupted.
            
            var fromIndex:int = sBroadcastListeners.length;
            getChildEventListeners(this, event.type, sBroadcastListeners);
            var toIndex:int = sBroadcastListeners.length;
            
            for (var i:int=fromIndex; i<toIndex; ++i)
                sBroadcastListeners[i].dispatchEvent(event);
            
            sBroadcastListeners.length = fromIndex;
        }
        
		/**
		 * 通过递归的方法，对所有的子级派发一个包含数据的事件。
		 * 为了避免新的内存分配开销，此方法使用了内部的事件对象池。
		 * @param type	事件类型
		 * @param data	事件传递的数据
		 */
        public function broadcastEventWith(type:String, data:Object=null):void
        {
            var event:Event = Event.fromPool(type, false, data);
            broadcastEvent(event);
            Event.toPool(event);
        }
        
        private function getChildEventListeners(object:DisplayObject, eventType:String, 
                                                listeners:Vector.<DisplayObject>):void
        {
            var container:DisplayObjectContainer = object as DisplayObjectContainer;
            
            if (object.hasEventListener(eventType))
                listeners.push(object);
            
            if (container)
            {
                var children:Vector.<DisplayObject> = container.mChildren;
                var numChildren:int = children.length;
                
                for (var i:int=0; i<numChildren; ++i)
                    getChildEventListeners(children[i], eventType, listeners);
            }
        }
        
		/** 容器包含的子级数量。 */
        public function get numChildren():int { return mChildren.length; }        
    }
}
