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
    import flash.ui.Mouse;
    import flash.ui.MouseCursor;
    import flash.utils.getQualifiedClassName;
    
    import starling.core.RenderSupport;
    import starling.errors.AbstractClassError;
    import starling.errors.AbstractMethodError;
    import starling.events.EventDispatcher;
    import starling.events.TouchEvent;
    import starling.filters.FragmentFilter;
    import starling.utils.MatrixUtil;
    
	/** 当一个显示对象被添加到父级的时候派发。 */
	[Event(name="added", type="starling.events.Event")]
	/** 当一个显示对象被添加到stage(直接的或者间接的)的时候派发。 */
	[Event(name="addedToStage", type="starling.events.Event")]
	/** 当一个显示对象从父级删除的时候派发。 */
	[Event(name="removed", type="starling.events.Event")]
	/** 当一个显示对象从stage删除(直接的或者间接的)的时候派发，此对象不再会被渲染。 */ 
	[Event(name="removedFromStage", type="starling.events.Event")]
	/** 在每一帧派发给stage上的所有显示对象。 */ 
	[Event(name="enterFrame", type="starling.events.EnterFrameEvent")]
	/** 当显示对象被触碰时派发，冒泡事件。 */
	[Event(name="touch", type="starling.events.TouchEvent")]
    
	/**
	 *  DisplayObject 类是所有可放在显示列表中，在屏幕上可以被渲染的对象的基类。
	 *  
	 *  <p><strong>显示列表树</strong></p> 
	 *  
	 *  <p>在Starling中，所有可显示对象都处于显示列表树中，只有属于显示列表树的成员才可以在屏幕上显示和渲染。</p> 
	 *   
	 *  <p>显示列表树由可以直接渲染到屏幕的叶子节点（Image, Quad）和容器节点（<code>DisplayObjectContainer</code>的子类，比如 <code>Sprite</code>）组成。
	 * 	   容器是一个包含子节点（子节点可以是叶子节点或者其他容器）的显示对象。</p> 
	 *  
	 *  <p>Stage处于显示列表树的顶级节点，同样也是一个容器。
	 *  要创建一个Starling应用，你需要创建一个自定义的Sprite的子类，Starling会添加一个该子类的实例对象到stage上。</p>
	 *  
	 *  <p>一个显示对象有定义它自身相对于它的父级的位置的属性（x，y），有旋转和缩放参数（scaleX，scaleY），
	 * 可以使用<code>alpha</code> 和 <code>visible</code>属性分别控制显示对象的透明度和可见性。</p>
	 *  
	 *  <p>每个显示对象都有可能是触碰事件的目标，你可以设置"touchable"属性来禁止对象被触碰。
	 * 当它被设置为禁止触碰，对象本身和它的子对象都不会再响应触碰事件。</p>
	 *    
	 *  <strong>坐标转换</strong>
	 *  
	 *  <p>在显示坐标树里，每个对象都有自己的局部坐标系统，如果你旋转一个容器，意味着你旋转了整个容器的坐标
	 * 系统，并且影响到了容器的所有子对象。</p>
	 *  
	 *  <p>有时候你需要知道某个点相对于其他坐标系的坐标，<code>getTransformationMatrix</code>函数实现了这个功能。
	 * 它将创建一个矩阵，该矩阵表示从一个局部坐标系到另一个坐标系的转换。</p> 
	 *  
	 *  <strong>子类</strong>
	 *  
	 *  <p>由于DisplayObject是抽象类,所以你不能直接实例化它，只能用某个它的子类。目前已经有很多这样的子类了，
	 * 大部分情况下它们应该能够满足你的需要了。</p> 
	 *  
	 *  <p>然而，你也可以自定义你自己的子类，要实现自定义的子类，你需要实现自定义的渲染方法，在你自定义的子类中
	 * 需要实现下面的方法：</p>
	 *  
	 *  <ul>
	 *    <li><code>function render(support:RenderSupport, parentAlpha:Number):void</code></li>
	 *    <li><code>function getBounds(targetSpace:DisplayObject, 
	 *                                 resultRect:Rectangle=null):Rectangle</code></li>
	 *  </ul>
	 *  
	 *  <p>请参阅Quad类，它对于"getBounds"方法有一个简单的实现。
	 * 一个简单的例子阐述如何创建自定义的渲染方法，你可以参考这个在Starling Wiki上的<a href="http://wiki.starling-framework.org/manual/custom_display_objects">自定义显示对象</a></p> 
	 * 
	 *  <p>当你重载render方法时，请注意调用辅助对象(一个RenderSupport对象)的'finishQuadBatch'方法。
	 * 这将促使Starling使用不同的渲染方法来渲染之前累计的所有四边形（鉴于性能考虑），否则，z-ordering将会出错。</p> 
	 * 
	 *  @see DisplayObjectContainer
	 *  @see Sprite
	 *  @see Stage 
	 */
    public class DisplayObject extends EventDispatcher
    {
        // members
        
        private var mX:Number;
        private var mY:Number;
        private var mPivotX:Number;
        private var mPivotY:Number;
        private var mScaleX:Number;
        private var mScaleY:Number;
        private var mSkewX:Number;
        private var mSkewY:Number;
        private var mRotation:Number;
        private var mAlpha:Number;
        private var mVisible:Boolean;
        private var mTouchable:Boolean;
        private var mBlendMode:String;
        private var mName:String;
        private var mUseHandCursor:Boolean;
        private var mParent:DisplayObjectContainer;  
        private var mTransformationMatrix:Matrix;
        private var mOrientationChanged:Boolean;
        private var mFilter:FragmentFilter;
        
        /** Helper objects. */
        private static var sAncestors:Vector.<DisplayObject> = new <DisplayObject>[];
        private static var sHelperRect:Rectangle = new Rectangle();
        private static var sHelperMatrix:Matrix  = new Matrix();
        
        /** @private */ 
        public function DisplayObject()
        {
            if (Capabilities.isDebugger && 
                getQualifiedClassName(this) == "starling.display::DisplayObject")
            {
                throw new AbstractClassError();
            }
            
            mX = mY = mPivotX = mPivotY = mRotation = mSkewX = mSkewY = 0.0;
            mScaleX = mScaleY = mAlpha = 1.0;            
            mVisible = mTouchable = true;
            mBlendMode = BlendMode.AUTO;
            mTransformationMatrix = new Matrix();
            mOrientationChanged = mUseHandCursor = false;
        }
        
		/**
		 * 销毁掉该对象的所有资源。 
		 * 释放GPU缓存，移除监听的事件，清除添加的滤镜。
		 */
        public function dispose():void
        {
            if (mFilter) mFilter.dispose();
            removeEventListeners();
        }
        
		/**
		 * 如果对象已经添加进显示列表，则从父容器中删除此对象。
		 * @param dispose 值为true时清除掉此对象的所有资源，值为false时不清除。
		 */
        public function removeFromParent(dispose:Boolean=false):void
        {
            if (mParent) mParent.removeChild(this, dispose);
        }
        
        /**
         * 返回一个矩阵，该矩阵表示从一个局部坐标系到另一个坐标系的转换。
         * @param targetSpace	定义要使用的坐标系的显示对象。
         * @param resultMatrix	如果传入一个resultMatrix, 计算的结果将保存在这个矩阵里，而不是重新创建一个<code>Matrix</code>对象。
         * @return Matrix
         * @throws ArgumentError
         */
        public function getTransformationMatrix(targetSpace:DisplayObject, 
                                                resultMatrix:Matrix=null):Matrix
        {
            var commonParent:DisplayObject;
            var currentObject:DisplayObject;
            
            if (resultMatrix) resultMatrix.identity();
            else resultMatrix = new Matrix();
            
            if (targetSpace == this)
            {
                return resultMatrix;
            }
            else if (targetSpace == mParent || (targetSpace == null && mParent == null))
            {
                resultMatrix.copyFrom(transformationMatrix);
                return resultMatrix;
            }
            else if (targetSpace == null || targetSpace == base)
            {
                // targetCoordinateSpace 'null' represents the target space of the base object.
                // -> move up from this to base
                
                currentObject = this;
                while (currentObject != targetSpace)
                {
                    resultMatrix.concat(currentObject.transformationMatrix);
                    currentObject = currentObject.mParent;
                }
                
                return resultMatrix;
            }
            else if (targetSpace.mParent == this) // optimization
            {
                targetSpace.getTransformationMatrix(this, resultMatrix);
                resultMatrix.invert();
                
                return resultMatrix;
            }
            
            // 1. find a common parent of this and the target space
            
            commonParent = null;
            currentObject = this;
            
            while (currentObject)
            {
                sAncestors.push(currentObject);
                currentObject = currentObject.mParent;
            }
            
            currentObject = targetSpace;
            while (currentObject && sAncestors.indexOf(currentObject) == -1)
                currentObject = currentObject.mParent;
            
            sAncestors.length = 0;
            
            if (currentObject) commonParent = currentObject;
            else throw new ArgumentError("Object not connected to target");
            
            // 2. move up from this to common parent
            
            currentObject = this;
            while (currentObject != commonParent)
            {
                resultMatrix.concat(currentObject.transformationMatrix);
                currentObject = currentObject.mParent;
            }
            
            if (commonParent == targetSpace)
                return resultMatrix;
            
            // 3. now move up from target until we reach the common parent
            
            sHelperMatrix.identity();
            currentObject = targetSpace;
            while (currentObject != commonParent)
            {
                sHelperMatrix.concat(currentObject.transformationMatrix);
                currentObject = currentObject.mParent;
            }
            
            // 4. now combine the two matrices
            
            sHelperMatrix.invert();
            resultMatrix.concat(sHelperMatrix);
            
            return resultMatrix;
        }        
        
		/**
		 * 返回一个矩形，该矩形定义相对于 targetSpace 对象坐标系的显示对象区域。
		 * @param targetSpace	定义要使用的坐标系的显示对象。
		 * @param resultRect	如果传入一个resultRect参数, 计算的结果将保存在这个矩形里，而不是重新创建一个<code>Rectangle</code>对象。
		 * @return Rectangle
		 * @throws AbstractMethodError
		 */
        public function getBounds(targetSpace:DisplayObject, resultRect:Rectangle=null):Rectangle
        {
            throw new AbstractMethodError("Method needs to be implemented in subclass");
            return null;
        }
        
		/**
		 * 返回舞台坐标系某个点下方的最顶层的显示对象，如果没有找到任何对象，则返回null。
		 * @param localPoint	局部坐标系的某点
		 * @param forTouch		是否只检测能够触碰到的对象。如果为ture，检测会忽略掉不可见和不可触碰的对象。
		 * @return DisplayObject
		 */
        public function hitTest(localPoint:Point, forTouch:Boolean=false):DisplayObject
        {
            // on a touch test, invisible or untouchable objects cause the test to fail
            if (forTouch && (!mVisible || !mTouchable)) return null;
            
            // otherwise, check bounding box
            if (getBounds(this, sHelperRect).containsPoint(localPoint)) return this;
            else return null;
        }
        
		/**
		 * 将一个点坐标从局部坐标系转换成全局(stage)坐标系坐标 。
		 * @param localPoint    需要转换成全局坐标的局部坐标点。
		 * @param resultPoint	如果传入一个resultPoint, 计算的结果将保存在这个点里，而不是重新创建一个<code>Point</code>对象。
		 * @return Point
		 */
        public function localToGlobal(localPoint:Point, resultPoint:Point=null):Point
        {
            getTransformationMatrix(base, sHelperMatrix);
            return MatrixUtil.transformCoords(sHelperMatrix, localPoint.x, localPoint.y, resultPoint);
        }
        
		/**
		 * 将一个点坐标从全局(stage)坐标系转换成为局部坐标系坐标 。
		 * @param globalPoint	需要转换成局部坐标的全局坐标点。
		 * @param resultPoint	如果传入一个resultPoint, 计算的结果将保存在这个点里，而不是重新创建一个<code>Point</code>对象。
		 * @return Point
		 */
        public function globalToLocal(globalPoint:Point, resultPoint:Point=null):Point
        {
            getTransformationMatrix(base, sHelperMatrix);
            sHelperMatrix.invert();
            return MatrixUtil.transformCoords(sHelperMatrix, globalPoint.x, globalPoint.y, resultPoint);
        }
        
		/** 使用辅助对象来渲染显示对象，永远不要直接调用这个方法，除非在另外一个渲染方法里调用。 
		 *  @param support 为渲染显示对象提供一些实用方法。
		 *  @param parentAlpha 从显示对象的父级到stage的alpha值的累加值。*/
        public function render(support:RenderSupport, parentAlpha:Number):void
        {
            throw new AbstractMethodError("Method needs to be implemented in subclass");
        }
        
        /** Indicates if an object occupies any visible area. (Which is the case when its 'alpha', 
         *  'scaleX' and 'scaleY' values are not zero, and its 'visible' property is enabled.) */
		
        public function get hasVisibleArea():Boolean
        {
            return mAlpha != 0.0 && mVisible && mScaleX != 0.0 && mScaleY != 0.0;
        }
        
        // internal methods
        
        /** @private */
        internal function setParent(value:DisplayObjectContainer):void 
        {
            // check for a recursion
            var ancestor:DisplayObject = value;
            while (ancestor != this && ancestor != null)
                ancestor = ancestor.mParent;
            
            if (ancestor == this)
                throw new ArgumentError("An object cannot be added as a child to itself or one " +
                                        "of its children (or children's children, etc.)");
            else
                mParent = value; 
        }
        
        // helpers
        
        private final function isEquivalent(a:Number, b:Number, epsilon:Number=0.0001):Boolean
        {
            return (a - epsilon < b) && (a + epsilon > b);
        }
        
        private final function normalizeAngle(angle:Number):Number
        {
            // move into range [-180 deg, +180 deg]
            while (angle < -Math.PI) angle += Math.PI * 2.0;
            while (angle >  Math.PI) angle -= Math.PI * 2.0;
            return angle;
        }
        
        // properties
 
        /** The transformation matrix of the object relative to its parent.
         * 
         *  <p>If you assign a custom transformation matrix, Starling will try to figure out  
         *  suitable values for <code>x, y, scaleX, scaleY,</code> and <code>rotation</code>.
         *  However, if the matrix was created in a different way, this might not be possible. 
         *  In that case, Starling will apply the matrix, but not update the corresponding 
         *  properties.</p>
         * 
         *  @returns CAUTION: not a copy, but the actual object! */
        public function get transformationMatrix():Matrix
        {
            if (mOrientationChanged)
            {
                mOrientationChanged = false;
                mTransformationMatrix.identity();
                
                if (mScaleX != 1.0 || mScaleY != 1.0) mTransformationMatrix.scale(mScaleX, mScaleY);
                if (mSkewX  != 0.0 || mSkewY  != 0.0) MatrixUtil.skew(mTransformationMatrix, mSkewX, mSkewY);
                if (mRotation != 0.0)                 mTransformationMatrix.rotate(mRotation);
                if (mX != 0.0 || mY != 0.0)           mTransformationMatrix.translate(mX, mY);
                
                if (mPivotX != 0.0 || mPivotY != 0.0)
                {
                    // prepend pivot transformation
                    mTransformationMatrix.tx = mX - mTransformationMatrix.a * mPivotX
                                                  - mTransformationMatrix.c * mPivotY;
                    mTransformationMatrix.ty = mY - mTransformationMatrix.b * mPivotX 
                                                  - mTransformationMatrix.d * mPivotY;
                }
            }
            
            return mTransformationMatrix; 
        }
        
        public function set transformationMatrix(matrix:Matrix):void
        {
            mOrientationChanged = false;
            mTransformationMatrix.copyFrom(matrix);

            mX = matrix.tx;
            mY = matrix.ty;
            
            mScaleX = Math.sqrt(matrix.a * matrix.a + matrix.b * matrix.b);
            mSkewY  = Math.acos(matrix.a / mScaleX);
            
            if (!isEquivalent(matrix.b, mScaleX * Math.sin(mSkewY)))
            {
                mScaleX *= -1;
                mSkewY = Math.acos(matrix.a / mScaleX);
            }
            
            mScaleY = Math.sqrt(matrix.c * matrix.c + matrix.d * matrix.d);
            mSkewX  = Math.acos(matrix.d / mScaleY);
            
            if (!isEquivalent(matrix.c, -mScaleY * Math.sin(mSkewX)))
            {
                mScaleY *= -1;
                mSkewX = Math.acos(matrix.d / mScaleY);
            }
            
            if (isEquivalent(mSkewX, mSkewY))
            {
                mRotation = mSkewX;
                mSkewX = mSkewY = 0;
            }
            else
            {
                mRotation = 0;
            }
        }
        
        /** Indicates if the mouse cursor should transform into a hand while it's over the sprite. 
         *  @default false */
        public function get useHandCursor():Boolean { return mUseHandCursor; }
        public function set useHandCursor(value:Boolean):void
        {
            if (value == mUseHandCursor) return;
            mUseHandCursor = value;
            
            if (mUseHandCursor)
                addEventListener(TouchEvent.TOUCH, onTouch);
            else
                removeEventListener(TouchEvent.TOUCH, onTouch);
        }
        
        private function onTouch(event:TouchEvent):void
        {
            Mouse.cursor = event.interactsWith(this) ? MouseCursor.BUTTON : MouseCursor.AUTO;
        }
        
        /** The bounds of the object relative to the local coordinates of the parent. */
        public function get bounds():Rectangle
        {
            return getBounds(mParent);
        }
        
        /** The width of the object in pixels. */
        public function get width():Number { return getBounds(mParent, sHelperRect).width; }
        public function set width(value:Number):void
        {
            // this method calls 'this.scaleX' instead of changing mScaleX directly.
            // that way, subclasses reacting on size changes need to override only the scaleX method.
            
            scaleX = 1.0;
            var actualWidth:Number = width;
            if (actualWidth != 0.0) scaleX = value / actualWidth;
        }
        
        /** The height of the object in pixels. */
        public function get height():Number { return getBounds(mParent, sHelperRect).height; }
        public function set height(value:Number):void
        {
            scaleY = 1.0;
            var actualHeight:Number = height;
            if (actualHeight != 0.0) scaleY = value / actualHeight;
        }
        
        /** The x coordinate of the object relative to the local coordinates of the parent. */
        public function get x():Number { return mX; }
        public function set x(value:Number):void 
        { 
            if (mX != value)
            {
                mX = value;
                mOrientationChanged = true;
            }
        }
        
        /** The y coordinate of the object relative to the local coordinates of the parent. */
        public function get y():Number { return mY; }
        public function set y(value:Number):void 
        {
            if (mY != value)
            {
                mY = value;
                mOrientationChanged = true;
            }
        }
        
        /** The x coordinate of the object's origin in its own coordinate space (default: 0). */
        public function get pivotX():Number { return mPivotX; }
        public function set pivotX(value:Number):void 
        {
            if (mPivotX != value)
            {
                mPivotX = value;
                mOrientationChanged = true;
            }
        }
        
        /** The y coordinate of the object's origin in its own coordinate space (default: 0). */
        public function get pivotY():Number { return mPivotY; }
        public function set pivotY(value:Number):void 
        { 
            if (mPivotY != value)
            {
                mPivotY = value;
                mOrientationChanged = true;
            }
        }
        
        /** The horizontal scale factor. '1' means no scale, negative values flip the object. */
        public function get scaleX():Number { return mScaleX; }
        public function set scaleX(value:Number):void 
        { 
            if (mScaleX != value)
            {
                mScaleX = value;
                mOrientationChanged = true;
            }
        }
        
        /** The vertical scale factor. '1' means no scale, negative values flip the object. */
        public function get scaleY():Number { return mScaleY; }
        public function set scaleY(value:Number):void 
        { 
            if (mScaleY != value)
            {
                mScaleY = value;
                mOrientationChanged = true;
            }
        }
        
        /** The horizontal skew angle in radians. */
        public function get skewX():Number { return mSkewX; }
        public function set skewX(value:Number):void 
        {
            value = normalizeAngle(value);
            
            if (mSkewX != value)
            {
                mSkewX = value;
                mOrientationChanged = true;
            }
        }
        
        /** The vertical skew angle in radians. */
        public function get skewY():Number { return mSkewY; }
        public function set skewY(value:Number):void 
        {
            value = normalizeAngle(value);
            
            if (mSkewY != value)
            {
                mSkewY = value;
                mOrientationChanged = true;
            }
        }
        
        /** The rotation of the object in radians. (In Starling, all angles are measured 
         *  in radians.) */
        public function get rotation():Number { return mRotation; }
        public function set rotation(value:Number):void 
        {
            value = normalizeAngle(value);

            if (mRotation != value)
            {            
                mRotation = value;
                mOrientationChanged = true;
            }
        }
        
        /** The opacity of the object. 0 = transparent, 1 = opaque. */
        public function get alpha():Number { return mAlpha; }
        public function set alpha(value:Number):void 
        { 
            mAlpha = value < 0.0 ? 0.0 : (value > 1.0 ? 1.0 : value); 
        }
        
        /** The visibility of the object. An invisible object will be untouchable. */
        public function get visible():Boolean { return mVisible; }
        public function set visible(value:Boolean):void { mVisible = value; }
        
        /** Indicates if this object (and its children) will receive touch events. */
        public function get touchable():Boolean { return mTouchable; }
        public function set touchable(value:Boolean):void { mTouchable = value; }
        
        /** The blend mode determines how the object is blended with the objects underneath. 
         *   @default auto
         *   @see starling.display.BlendMode */ 
        public function get blendMode():String { return mBlendMode; }
        public function set blendMode(value:String):void { mBlendMode = value; }
        
        /** The name of the display object (default: null). Used by 'getChildByName()' of 
         *  display object containers. */
        public function get name():String { return mName; }
        public function set name(value:String):void { mName = value; }
        
        /** The filter or filter group that is attached to the display object. The starling.filters 
         *  package contains several classes that define specific filters you can use. 
         *  Beware that you should NOT use the same filter on more than one object (for 
         *  performance reasons). */ 
        public function get filter():FragmentFilter { return mFilter; }
        public function set filter(value:FragmentFilter):void { mFilter = value; }
        
        /** The display object container that contains this display object. */
        public function get parent():DisplayObjectContainer { return mParent; }
        
        /** The topmost object in the display tree the object is part of. */
        public function get base():DisplayObject
        {
            var currentObject:DisplayObject = this;
            while (currentObject.mParent) currentObject = currentObject.mParent;
            return currentObject;
        }
        
        /** The root object the display object is connected to (i.e. an instance of the class 
         *  that was passed to the Starling constructor), or null if the object is not connected
         *  to the stage. */
        public function get root():DisplayObject
        {
            var currentObject:DisplayObject = this;
            while (currentObject.mParent)
            {
                if (currentObject.mParent is Stage) return currentObject;
                else currentObject = currentObject.parent;
            }
            
            return null;
        }
        
        /** The stage the display object is connected to, or null if it is not connected 
         *  to the stage. */
        public function get stage():Stage { return this.base as Stage; }
    }
}