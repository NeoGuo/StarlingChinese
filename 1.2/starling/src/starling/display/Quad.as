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
    
    import starling.core.RenderSupport;
    import starling.utils.VertexData;
    
    /** 一个四边形代表了由单一颜色或者渐变颜色填充的矩形。
     *  
     *  <p>你可以设置每一个顶点的颜色。不同顶点的颜色会在颜色交汇的地方平滑的过度。
	 * 要让四边形显示一个线性的渐变颜色，需要给顶点0,1设置一个颜色，然后给顶点2,3设置另一个颜色。 </p> 
     *
     *  <p>四边形的四个顶点的位置是这样排列的:</p>
     *  
     *  <pre>
     *  0 - 1
     *  | / |
     *  2 - 3
     *  </pre>
     * 
     *  @see Image
     */
    public class Quad extends DisplayObject
    {
        private var mTinted:Boolean;
        
        /** 四边形的原始顶点数据。 */
        protected var mVertexData:VertexData;
        
        /** Helper objects. */
        private static var sHelperPoint:Point = new Point();
        private static var sHelperMatrix:Matrix = new Matrix();
        
        /**
         * 根据指定的尺寸和颜色创建一个四边形。
		 * 最后一个参数决定是否在渲染的时候预乘透明度值，从而影响混合输出的颜色值，大多数情况下可以使用默认值。
         * @param width		宽度
         * @param height	高度
         * @param color		填充颜色
         * @param premultipliedAlpha	否在渲染的时候预乘透明度值，从而影响混合输出的颜色值，大多数情况下可以使用默认值。
         */
        public function Quad(width:Number, height:Number, color:uint=0xffffff,
                             premultipliedAlpha:Boolean=true)
        {
            mTinted = color != 0xffffff;
            
            mVertexData = new VertexData(4, premultipliedAlpha);
            mVertexData.setPosition(0, 0.0, 0.0);
            mVertexData.setPosition(1, width, 0.0);
            mVertexData.setPosition(2, 0.0, height);
            mVertexData.setPosition(3, width, height);            
            mVertexData.setUniformColor(color);
            
            onVertexDataChanged();
        }
        
        /** 在手动改变'mVertexData'的内容后调用此方法。 */
        protected function onVertexDataChanged():void
        {
            // override in subclasses, if necessary
        }
        
        /** @inheritDoc */
        public override function getBounds(targetSpace:DisplayObject, resultRect:Rectangle=null):Rectangle
        {
            if (resultRect == null) resultRect = new Rectangle();
            
            if (targetSpace == this) // optimization
            {
                mVertexData.getPosition(3, sHelperPoint);
                resultRect.setTo(0.0, 0.0, sHelperPoint.x, sHelperPoint.y);
            }
            else if (targetSpace == parent && rotation == 0.0) // optimization
            {
                var scaleX:Number = this.scaleX;
                var scaleY:Number = this.scaleY;
                mVertexData.getPosition(3, sHelperPoint);
                resultRect.setTo(x - pivotX * scaleX,      y - pivotY * scaleY,
                                 sHelperPoint.x * scaleX, sHelperPoint.y * scaleY);
                if (scaleX < 0) { resultRect.width  *= -1; resultRect.x -= resultRect.width;  }
                if (scaleY < 0) { resultRect.height *= -1; resultRect.y -= resultRect.height; }
            }
            else
            {
                getTransformationMatrix(targetSpace, sHelperMatrix);
                mVertexData.getBounds(sHelperMatrix, 0, 4, resultRect);
            }
            
            return resultRect;
        }
        
        /**
         * 返回指定索引的顶点的颜色。
         * @param vertexID	顶点索引
         * @return 顶点的颜色
         */
        public function getVertexColor(vertexID:int):uint
        {
            return mVertexData.getColor(vertexID);
        }
        
        /**
         * 设置指定索引的顶点的颜色。
         * @param vertexID	顶点索引
         * @param color		颜色
         */
        public function setVertexColor(vertexID:int, color:uint):void
        {
            mVertexData.setColor(vertexID, color);
            onVertexDataChanged();
            
            if (color != 0xffffff) mTinted = true;
            else mTinted = mVertexData.tinted;
        }
        
        /**
         * 返回指定索引的顶点的透明度。
         * @param vertexID	顶点索引
         * @return 			顶点的透明度
         */
        public function getVertexAlpha(vertexID:int):Number
        {
            return mVertexData.getAlpha(vertexID);
        }
        
        /**
         * 设置指定索引的顶点的透明度。
         * @param vertexID	顶点索引
         * @param alpha		透明度
         */
        public function setVertexAlpha(vertexID:int, alpha:Number):void
        {
            mVertexData.setAlpha(vertexID, alpha);
            onVertexDataChanged();
            
            if (alpha != 1.0) mTinted = true;
            else mTinted = mVertexData.tinted;
        }
        
        /** 返回四边形的颜色，如果四边形存在多个颜色，返回第一个顶点的颜色。 */
        public function get color():uint 
        { 
            return mVertexData.getColor(0); 
        }
        
        /** 设置所有顶点的颜色为指定的一种颜色。*/
        public function set color(value:uint):void 
        {
            for (var i:int=0; i<4; ++i)
                setVertexColor(i, value);
            
            if (value != 0xffffff || alpha != 1.0) mTinted = true;
            else mTinted = mVertexData.tinted;
        }
        
        /** @inheritDoc **/
        public override function set alpha(value:Number):void
        {
            super.alpha = value;
            
            if (value < 1.0) mTinted = true;
            else mTinted = mVertexData.tinted;
        }
        
        /** 拷贝四边形的顶点数据到一个新的顶点数据实例。*/
        public function copyVertexDataTo(targetData:VertexData, targetVertexID:int=0):void
        {
            mVertexData.copyTo(targetData, targetVertexID);
        }
        
        /** @inheritDoc */
        public override function render(support:RenderSupport, parentAlpha:Number):void
        {
            support.batchQuad(this, parentAlpha);
        }
        
        /** 一个布尔值，如果四边形（或者它的任意顶点）是非白色或者是透明的，返回true，否则返回 false。 */
        public function get tinted():Boolean { return mTinted; }
    }
}