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
    import flash.geom.Matrix;
    import flash.geom.Point;
    
    import starling.core.starling_internal;
    import starling.display.DisplayObject;
    import starling.utils.MatrixUtil;
    import starling.utils.formatString;

    /** 一个Touch对象包含了在屏幕上的一个手指或鼠标的相关信息（出现或移动）。
     *  
     *  <p>您将从TouchEvent中获取这个对象。当这样的事件被触发，您可以查询目前呈现在屏幕上的所有触碰。
     *  一个Touch对象，包含了一个单指触碰的信息。一个Touch对象总是会通过TouchPhases的集合移动。请参阅TouchPhase类来获取更多信息。</p>
     *  
     *  <strong>触碰的位置</strong>
     *  
     *  <p>您可以用相应的属性，获取坐标系上的当前的和上一个位置。当然，在大部分情况下您希望能获取在一个不同的坐标系上的位置。 
     *  基于这个原因，这里有一些方法可以转换当前的和上一个位置到任何对象的局部坐标系。</p>
     * 
     *  @see TouchEvent
     *  @see TouchPhase
     */  
    public class Touch
    {
        private var mID:int;
        private var mGlobalX:Number;
        private var mGlobalY:Number;
        private var mPreviousGlobalX:Number;
        private var mPreviousGlobalY:Number;
        private var mTapCount:int;
        private var mPhase:String;
        private var mTarget:DisplayObject;
        private var mTimestamp:Number;
        
        /** Helper object. */
        private static var sHelperMatrix:Matrix = new Matrix();
        
        /** 创建一个新的Touch对象。 */
        public function Touch(id:int, globalX:Number, globalY:Number, phase:String, target:DisplayObject)
        {
            mID = id;
            mGlobalX = mPreviousGlobalX = globalX;
            mGlobalY = mPreviousGlobalY = globalY;
            mTapCount = 0;
            mPhase = phase;
            mTarget = target;
        }
        
        /** 转换当前touch的位置到一个显示对象的局部坐标系。
         *  如果你传递一个 resultPoint ，此方法的返回值会存储于这个Point对象中，而不是创建一个新的对象。
         *  version 1.2 添加了resultPoint参数 
         */
        public function getLocation(space:DisplayObject, resultPoint:Point=null):Point
        {
            if (resultPoint == null) resultPoint = new Point();
            mTarget.base.getTransformationMatrix(space, sHelperMatrix);
            return MatrixUtil.transformCoords(sHelperMatrix, mGlobalX, mGlobalY, resultPoint); 
        }
        
        /** 转换touch的上一个位置到一个显示对象的局部坐标系。 
         *  如果你传递一个 resultPoint ，此方法的返回值会存储于这个Point对象中，而不是创建一个新的对象。
         *  version 1.2 添加了resultPoint参数 */
        public function getPreviousLocation(space:DisplayObject, resultPoint:Point=null):Point
        {
            if (resultPoint == null) resultPoint = new Point();
            mTarget.base.getTransformationMatrix(space, sHelperMatrix);
            return MatrixUtil.transformCoords(sHelperMatrix, mPreviousGlobalX, mPreviousGlobalY, resultPoint);
        }
        
        /** 返回从上一个位置到当前位置移动的距离。 
         *  如果你传递一个 resultPoint ，此方法的返回值会存储于这个Point对象中，而不是创建一个新的对象。
         *  version 1.2 添加了resultPoint参数 */ 
        public function getMovement(space:DisplayObject, resultPoint:Point=null):Point
        {
            if (resultPoint == null) resultPoint = new Point();
            getLocation(space, resultPoint);
            var x:Number = resultPoint.x;
            var y:Number = resultPoint.y;
            getPreviousLocation(space, resultPoint);
            resultPoint.setTo(x - resultPoint.x, y - resultPoint.y);
            return resultPoint;
        }
        
        /** 返回这个对象的描述。 */
        public function toString():String
        {
            return formatString("Touch {0}: globalX={1}, globalY={2}, phase={3}",
                                mID, mGlobalX, mGlobalY, mPhase);
        }
        
        /** 创建这个一个Touch对象的副本 */
        public function clone():Touch
        {
            var clone:Touch = new Touch(mID, mGlobalX, mGlobalY, mPhase, mTarget);
            clone.mPreviousGlobalX = mPreviousGlobalX;
            clone.mPreviousGlobalY = mPreviousGlobalY;
            clone.mTapCount = mTapCount;
            clone.mTimestamp = mTimestamp;
            return clone;
        }
        
        /**一个Touch对象的唯一标示. '0' 代表鼠标事件, 正数用于touch事件。 */
        public function get id():int { return mID; }
        
        /**  touch对象在stage坐标系的X坐标值。 */
        public function get globalX():Number { return mGlobalX; }

        /**  touch对象在stage坐标系的Y坐标值。 */
        public function get globalY():Number { return mGlobalY; }
        
        /**touch对象的上一个位置在stage坐标系的X坐标值。 */
        public function get previousGlobalX():Number { return mPreviousGlobalX; }
        
        /** touch对象的上一个位置在stage坐标系的Y坐标值。 */
        public function get previousGlobalY():Number { return mPreviousGlobalY; }
        
        /**手指在很短的时间内触碰屏幕的次数。可以用来判断双击等情况。 */ 
        public function get tapCount():int { return mTapCount; }
        
        /** 当前触碰所处的阶段。 @see TouchPhase */
        public function get phase():String { return mPhase; }
        
        /** 发生触碰的显示对象。 */
        public function get target():DisplayObject { return mTarget; }
        
        /** 触碰发生时的时间（以秒为单位，自应用程序启动时算起）。 */
        public function get timestamp():Number { return mTimestamp; }
        
        // internal methods
        
        /** @private */
        starling_internal function setPosition(globalX:Number, globalY:Number):void
        {
            mPreviousGlobalX = mGlobalX;
            mPreviousGlobalY = mGlobalY;
            mGlobalX = globalX;
            mGlobalY = globalY;
        }
        
        /** @private */
        starling_internal function setPhase(value:String):void { mPhase = value; }
        
        /** @private */
        starling_internal function setTapCount(value:int):void { mTapCount = value; }
        
        /** @private */
        starling_internal function setTarget(value:DisplayObject):void { mTarget = value; }
        
        /** @private */
        starling_internal function setTimestamp(value:Number):void { mTimestamp = value; }
    }
}