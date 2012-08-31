// =================================================================================================
//
//	Starling Framework
//	Copyright 2011 Gamua OG. All Rights Reserved.
//
//	This program is free software. You can redistribute and/or modify it
//	in accordance with the terms of the accompanying license agreement.
//
// =================================================================================================

package starling.textures
{
    import flash.display.Bitmap;
    import flash.display.BitmapData;
    import flash.display3D.Context3D;
    import flash.display3D.Context3DTextureFormat;
    import flash.display3D.textures.Texture;
    import flash.display3D.textures.TextureBase;
    import flash.geom.Matrix;
    import flash.geom.Point;
    import flash.geom.Rectangle;
    import flash.system.Capabilities;
    import flash.utils.ByteArray;
    import flash.utils.getQualifiedClassName;
    
    import starling.core.Starling;
    import starling.errors.AbstractClassError;
    import starling.errors.MissingContextError;
    import starling.utils.VertexData;
    import starling.utils.getNextPowerOfTwo;

    /**  <p>纹理是用来储存展示图像的信息。它不能直接被添加到显示列表；相应的它必须映射到一个显示对象上。
     *  在Staring中那个显示对象就是“Image”类。</p>
     *
     *  <strong>纹理格式</strong>
     *  
     *  <p>纹理能够由一个“BitmapData”对象创建，Starling能够支持任何Flash所支持的bitmap格式。
     *  并且由于你能够将任何Flash显示对象转换为BitmapData对象，你就能够利用这点在Starling中
     *  去显示非Starling内容,比如说Shape对象。</p>
     *
     *  <p>Starling同时支持ATF纹理（Adobe Texture Format），一个能够通过GPU高效渲染的被压缩纹理的容器。</p>
     *  
     *  <strong>Mip映射</strong>
     *  
     *  <p>MipMaps是按比例缩小的纹理类型。当一个图像被显示时小于它本来的尺寸时，
     *  GPU可能就会用mip maps去替代原生纹理。这就可以减少走样和加速渲染。当然这也需要额外的内存开销；
     *  你可以权衡利弊之后选择是否使用它。</p>  
     *  
     *  <strong>纹理框架</strong>
     *  
     *  <p>纹理的frame属性允许你设置纹理在image对象中的界限，在纹理周围留有透明空白区域。
     *  frame矩形被指定在纹理的坐标系统中，而不是image:</p>
     *  
     *  <listing>
     *  var frame:Rectangle = new Rectangle(-10, -10, 30, 30); 
     *  var texture:Texture = Texture.fromTexture(anotherTexture, null, frame);
     *  var image:Image = new Image(texture);
     *  </listing>
     *  
     *  <p>这段代码会创建一个30x30大小的图像，纹理会被放置在图像<code>x=10, y=10</code> 
     *  的位置上（假设'anotherTexture'是一个宽高都为10像素的纹理，它将出现在图像的正中位置）。</p>
     *  
     *  <p>纹理集就采用了这个特性，它允许裁剪一个纹理的透明边缘用来弥补由指定的原始纹理框架改变的尺寸。
     *  可以使用<a href="http://www.texturepacker.com/">TexturePacker</a>这样的工具来优化纹理集。</p>
     * 
     *  <strong>纹理坐标系</strong>
     *  
     *  <p>假如，从另一方面讲，你只想在图像中显示纹理的一部分（就是说修剪这个纹理），
     *  你可以创建一个子纹理（通过方法'Texture.fromTexture()'然后指定一个限定范围的矩形），
     *  或者你也可以操作image对象的纹理坐标系。方法'image.setTexCoords'允许你那样做。</p>
     *
     *  @see starling.display.Image
     *  @see TextureAtlas
     */ 
    public class Texture
    {
        private var mFrame:Rectangle;
        private var mRepeat:Boolean;
        
        /** @private */
        public function Texture()
        {
            if (Capabilities.isDebugger && 
                getQualifiedClassName(this) == "starling.textures::Texture")
            {
                throw new AbstractClassError();
            }
            
            mRepeat = false;
        }
        
        /** 释放基础纹理数据。 */
        public function dispose():void
        { 
            // override in subclasses
        }
        
        /** 通过一个bitmap来创建纹理对象。
         *  注意：如果Starling需要处理一个丢失的设备上下文，那么不允许你释放纹理数据。 */
        public static function fromBitmap(data:Bitmap, generateMipMaps:Boolean=true,
                                          optimizeForRenderTexture:Boolean=false,
                                          scale:Number=1):Texture
        {
            return fromBitmapData(data.bitmapData, generateMipMaps, optimizeForRenderTexture, scale);
        }
        
        /** 通过一个BitmapData来创建纹理对象。
         *  注意：如果Starling需要处理一个丢失的设备上下文，那么不允许你释放纹理数据。 */
        public static function fromBitmapData(data:BitmapData, generateMipMaps:Boolean=true,
                                              optimizeForRenderTexture:Boolean=false,
                                              scale:Number=1):Texture
        {
            var origWidth:int   = data.width;
            var origHeight:int  = data.height;
            var legalWidth:int  = getNextPowerOfTwo(origWidth);
            var legalHeight:int = getNextPowerOfTwo(origHeight);
            var context:Context3D = Starling.context;
            var potData:BitmapData;
            
            if (context == null) throw new MissingContextError();
            
            var nativeTexture:flash.display3D.textures.Texture = context.createTexture(
                legalWidth, legalHeight, Context3DTextureFormat.BGRA, optimizeForRenderTexture);
            
            if (legalWidth > origWidth || legalHeight > origHeight)
            {
                potData = new BitmapData(legalWidth, legalHeight, true, 0);
                potData.copyPixels(data, data.rect, new Point(0, 0));
                data = potData;
            }
            
            uploadBitmapData(nativeTexture, data, generateMipMaps);
            
            var concreteTexture:ConcreteTexture = new ConcreteTexture(
                nativeTexture, Context3DTextureFormat.BGRA, legalWidth, legalHeight,
                generateMipMaps, true, optimizeForRenderTexture, scale);
            
            if (Starling.handleLostContext)
                concreteTexture.restoreOnLostContext(data);
            else if (potData)
                potData.dispose();
            
            if (origWidth == legalWidth && origHeight == legalHeight)
                return concreteTexture;
            else
                return new SubTexture(concreteTexture, 
                                      new Rectangle(0, 0, origWidth/scale, origHeight/scale), 
                                      true);
        }
        
        /** 通过压缩的ATF格式来创建纹理对象。
         *  注意：如果Starling需要处理一个丢失的设备上下文，那么不允许你释放纹理数据。 */ 
        public static function fromAtfData(data:ByteArray, scale:Number=1):Texture
        {
            var context:Context3D = Starling.context;
            if (context == null) throw new MissingContextError();
            
            var atfData:AtfData = new AtfData(data);
            var nativeTexture:flash.display3D.textures.Texture = context.createTexture(
                    atfData.width, atfData.height, atfData.format, false);
            
            uploadAtfData(nativeTexture, data);
            
            var concreteTexture:ConcreteTexture = new ConcreteTexture(nativeTexture, atfData.format, 
                atfData.width, atfData.height, atfData.numTextures > 1, false, false, scale);
            
            if (Starling.handleLostContext) 
                concreteTexture.restoreOnLostContext(atfData);
            
            return concreteTexture;
        }
        
        /** 创建某一尺寸、颜色的空纹理。颜色参数需要制定为ARGB格式。*/
        public static function fromColor(width:int, height:int, color:uint=0xffffffff,
                                         optimizeForRenderTexture:Boolean=false, 
                                         scale:Number=-1):Texture
        {
            if (scale <= 0) scale = Starling.contentScaleFactor;
            
            var bitmapData:BitmapData = new BitmapData(width*scale, height*scale, true, color);
            var texture:Texture = fromBitmapData(bitmapData, false, optimizeForRenderTexture, scale);
            
            if (!Starling.handleLostContext)
                bitmapData.dispose();
            
            return texture;
        }
        
        /** 创建某一尺寸的空纹理。主要用于纹理渲染。
         *  注意纹理只有当你上载了一些颜色数据或者当它是一个有效渲染目标时清除纹理之后才能被使用。 */
        public static function empty(width:int=64, height:int=64, premultipliedAlpha:Boolean=false,
                                     optimizeForRenderTexture:Boolean=true,
                                     scale:Number=-1):Texture
        {
            if (scale <= 0) scale = Starling.contentScaleFactor;
            
            var origWidth:int  = width * scale;
            var origHeight:int = height * scale;
            var legalWidth:int  = getNextPowerOfTwo(origWidth);
            var legalHeight:int = getNextPowerOfTwo(origHeight);
            var format:String = Context3DTextureFormat.BGRA;
            var context:Context3D = Starling.context;
            
            if (context == null) throw new MissingContextError();
            
            var nativeTexture:flash.display3D.textures.Texture = context.createTexture(
                legalWidth, legalHeight, Context3DTextureFormat.BGRA, optimizeForRenderTexture);
            
            var concreteTexture:ConcreteTexture = new ConcreteTexture(nativeTexture, format,
                legalWidth, legalHeight, false, premultipliedAlpha, optimizeForRenderTexture, scale);
            
            if (origWidth == legalWidth && origHeight == legalHeight)
                return concreteTexture;
            else
                return new SubTexture(concreteTexture, new Rectangle(0, 0, width, height), true);
        }
        
        /** 从另一个纹理创建一个限定范围的纹理（以像素为单位）。
         *  这个新的纹理将会引用基础纹理；没有复制数据。 */
        public static function fromTexture(texture:Texture, region:Rectangle=null, frame:Rectangle=null):Texture
        {
            var subTexture:Texture = new SubTexture(texture, region);   
            subTexture.mFrame = frame;
            return subTexture;
        }
        
        /** 转换纹理的坐标系和原始顶点位置数据为渲染所需要的格式。 */
        public function adjustVertexData(vertexData:VertexData, vertexID:int, count:int):void
        {
            if (mFrame)
            {
                if (count != 4) 
                    throw new ArgumentError("Textures with a frame can only be used on quads");
                
                var deltaRight:Number  = mFrame.width  + mFrame.x - width;
                var deltaBottom:Number = mFrame.height + mFrame.y - height;
                
                vertexData.translateVertex(vertexID,     -mFrame.x, -mFrame.y);
                vertexData.translateVertex(vertexID + 1, -deltaRight, -mFrame.y);
                vertexData.translateVertex(vertexID + 2, -mFrame.x, -deltaBottom);
                vertexData.translateVertex(vertexID + 3, -deltaRight, -deltaBottom);
            }
        }
        
        /** 向原生纹理上载BitmapData数据，可选择创建MIP映射。 */
        internal static function uploadBitmapData(nativeTexture:flash.display3D.textures.Texture,
                                                  data:BitmapData, generateMipmaps:Boolean):void
        {
            nativeTexture.uploadFromBitmapData(data);
            
            if (generateMipmaps && data.width > 1 && data.height > 1)
            {
                var currentWidth:int  = data.width  >> 1;
                var currentHeight:int = data.height >> 1;
                var level:int = 1;
                var canvas:BitmapData = new BitmapData(currentWidth, currentHeight, true, 0);
                var transform:Matrix = new Matrix(.5, 0, 0, .5);
                var bounds:Rectangle = new Rectangle();
                
                while (currentWidth >= 1 || currentHeight >= 1)
                {
                    bounds.width = currentWidth; bounds.height = currentHeight;
                    canvas.fillRect(bounds, 0);
                    canvas.draw(data, transform, null, null, null, true);
                    nativeTexture.uploadFromBitmapData(canvas, level++);
                    transform.scale(0.5, 0.5);
                    currentWidth  = currentWidth  >> 1;
                    currentHeight = currentHeight >> 1;
                }
                
                canvas.dispose();
            }
        }
        
        /** 通过ByteArray上传ATF数据给原生纹理。 */
        internal static function uploadAtfData(nativeTexture:flash.display3D.textures.Texture, 
                                               data:ByteArray, offset:int=0):void
        {
            nativeTexture.uploadCompressedTextureFromByteArray(data, offset);
        }
        
        // properties
        
        /** 纹理框架（参阅类描述）*/
        public function get frame():Rectangle 
        { 
            return mFrame ? mFrame.clone() : new Rectangle(0, 0, width, height);
            
            // the frame property is readonly - set the frame in the 'fromTexture' method.
            // why is it readonly? To be able to efficiently cache the texture coordinates on
            // rendering, textures need to be immutable (except 'repeat', which is not cached,
            // anyway).
        }
        
        /** 确定纹理是否应该像墙纸一样平铺或者拉伸最外面的像素点。
	     *  注意：只有当纹理边长是2的幂数并且不是从一个纹理集（即无子纹理）中加载的才有效。*/
        public function get repeat():Boolean { return mRepeat; }
        public function set repeat(value:Boolean):void { mRepeat = value; }
        
        /** 以像素为单位的纹理宽度。 */
        public function get width():Number { return 0; }
        
        /** 以像素为单位的纹理高度。 */
        public function get height():Number { return 0; }

        /** 影响宽度和高度属性的缩放因子。 */
        public function get scale():Number { return 1.0; }
        
        /** 纹理所基于的Stage3D纹理对象。 */
        public function get base():TextureBase { return null; }
        
        /** 基本纹理数据的<code>Context3DTextureFormat</code>。 */
        public function get format():String { return Context3DTextureFormat.BGRA; }
        
        /** 表明纹理是否包含mip映射集。 */ 
        public function get mipMapping():Boolean { return false; }
        
        /** 表明透明值是否被预乘到了RGB值中。 */
        public function get premultipliedAlpha():Boolean { return false; }
    }
}