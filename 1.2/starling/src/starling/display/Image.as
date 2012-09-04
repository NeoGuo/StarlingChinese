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
    import flash.display.Bitmap;
    import flash.geom.Point;
    import flash.geom.Rectangle;
    
    import starling.core.RenderSupport;
    import starling.textures.Texture;
    import starling.textures.TextureSmoothing;
    import starling.utils.VertexData;
    
    /**
	 * 一个图片是一个映射了纹理的四边形。
     *  
     *  <p>Image类相当于Flash的Bitmap类的Starling版本，不过Starling是用纹理来代替BitmapData来提供图像的像素资源。
	 * 要显示一个纹理，你需要把它映射到一个四边形上--这就是Image类的功能。</p>
     *  
     *  <p>因为"Image"是继承自"Quad",所以你可以给它设置颜色。
	 * 每个像素的颜色是根据纹理的颜色和四边形的颜色相乘得来的，这样，你就可以很容易的根据一个颜色改变纹理的色调。
	 * 此外，Image允许你对纹理坐标进行操作，你可以在不改变四边形任何顶点坐标的情况下，在图片的内部移动纹理。
	 * 你还可以使用这种功能以一个非常高效的方式创建一个矩形遮罩。</p> 
     *  
     *  @see starling.textures.Texture
     *  @see Quad
     */ 
    public class Image extends Quad
    {
        private var mTexture:Texture;
        private var mSmoothing:String;
        
        private var mVertexDataCache:VertexData;
        private var mVertexDataCacheInvalid:Boolean;
        
        /** 创建一个具有纹理映射的四边形。 */
        public function Image(texture:Texture)
        {
            if (texture)
            {
                var frame:Rectangle = texture.frame;
                var width:Number  = frame ? frame.width  : texture.width;
                var height:Number = frame ? frame.height : texture.height;
                var pma:Boolean = texture.premultipliedAlpha;
                
                super(width, height, 0xffffff, pma);
                
                mVertexData.setTexCoords(0, 0.0, 0.0);
                mVertexData.setTexCoords(1, 1.0, 0.0);
                mVertexData.setTexCoords(2, 0.0, 1.0);
                mVertexData.setTexCoords(3, 1.0, 1.0);
                
                mTexture = texture;
                mSmoothing = TextureSmoothing.BILINEAR;
                mVertexDataCache = new VertexData(4, pma);
                mVertexDataCacheInvalid = true;
            }
            else
            {
                throw new ArgumentError("Texture cannot be null");
            }
        }
        
        /**
         * 根据传入的位图对象创建一个包含纹理的Image。
         * @param bitmap	位图对象
         * @return 
         */
        public static function fromBitmap(bitmap:Bitmap):Image
        {
            return new Image(Texture.fromBitmap(bitmap));
        }
        
        /** @inheritDoc */
        protected override function onVertexDataChanged():void
        {
            mVertexDataCacheInvalid = true;
        }
        
        /** 根据图像当前的纹理调整图像的尺寸，在为图片设置了另外一个不同的纹理以后，需要调用这个方法来同步图像和纹理的尺寸。*/
        public function readjustSize():void
        {
            var frame:Rectangle = texture.frame;
            var width:Number  = frame ? frame.width  : texture.width;
            var height:Number = frame ? frame.height : texture.height;
            
            mVertexData.setPosition(0, 0.0, 0.0);
            mVertexData.setPosition(1, width, 0.0);
            mVertexData.setPosition(2, 0.0, height);
            mVertexData.setPosition(3, width, height); 
            
            onVertexDataChanged();
        }
        
        /**
         * 设置一个顶点的纹理坐标，坐标范围：[0,1]。
         * @param vertexID	顶点的ID
         * @param coords	坐标
         */
        public function setTexCoords(vertexID:int, coords:Point):void
        {
            mVertexData.setTexCoords(vertexID, coords.x, coords.y);
            onVertexDataChanged();
        }
        
        /**
         * 获取一个顶点的纹理坐标，坐标范围：[0,1]。
         * @param vertexID	顶点的ID
         * @param resultPoint	如果传入一个resultPoint, 计算的结果将保存在resultPoint里，而不是重新创建一个<code>Point</code>对象。
         * @return 
         */
        public function getTexCoords(vertexID:int, resultPoint:Point=null):Point
        {
            if (resultPoint == null) resultPoint = new Point();
            mVertexData.getTexCoords(vertexID, resultPoint);
            return resultPoint;
        }
        
        /**
         * 复制源顶点数据到一个<code>VertexData</code>实例。
		 * 纹理坐标已经存在于渲染所需的格式中。
         * @param targetData		目标<code>VertexData</code>实例
         * @param targetVertexID	目标顶点的ID
         */
        public override function copyVertexDataTo(targetData:VertexData, targetVertexID:int=0):void
        {
            if (mVertexDataCacheInvalid)
            {
                mVertexDataCacheInvalid = false;
                mVertexData.copyTo(mVertexDataCache);
                mTexture.adjustVertexData(mVertexDataCache, 0, 4);
            }
            
            mVertexDataCache.copyTo(targetData, targetVertexID);
        }
        
		/** 映射到四边形的纹理对象。 */
        public function get texture():Texture { return mTexture; }
        public function set texture(value:Texture):void 
        { 
            if (value == null)
            {
                throw new ArgumentError("Texture cannot be null");
            }
            else if (value != mTexture)
            {
                mTexture = value;
                mVertexData.setPremultipliedAlpha(mTexture.premultipliedAlpha);
                onVertexDataChanged();
            }
        }
        
        /** 用于纹理的平滑过滤方式，默认值为：bilinear。
        *   @default bilinear
        *   @see starling.textures.TextureSmoothing */ 
        public function get smoothing():String { return mSmoothing; }
        public function set smoothing(value:String):void 
        {
            if (TextureSmoothing.isValid(value))
                mSmoothing = value;
            else
                throw new ArgumentError("Invalid smoothing mode: " + value);
        }
        
        /** @inheritDoc */
        public override function render(support:RenderSupport, parentAlpha:Number):void
        {
            support.batchQuad(this, parentAlpha, mTexture, mSmoothing);
        }
    }
}