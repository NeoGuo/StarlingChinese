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
    import flash.display3D.Context3D;
    import flash.display3D.textures.TextureBase;
    import flash.geom.Matrix;
    import flash.geom.Rectangle;
    
    import starling.core.RenderSupport;
    import starling.core.Starling;
    import starling.display.DisplayObject;
    import starling.display.Image;
    import starling.errors.MissingContextError;
    import starling.utils.VertexData;
    import starling.utils.getNextPowerOfTwo;

    /** RenderTexture是一个能在其上绘制任何显示对象的动态纹理。
     *
     *  <p>在创建一个RenderTexture对象后，仅需调用 <code>drawObject</code> 方法直接在纹理上渲染一个对象。 
     *  对象将会在当前位置，连带当前的旋转，缩放和透明值属性被绘制在纹理上。</p> 
     *  
     *  <p>绘制能够被高效的完成，因为它在显存中是直接发生的。绘制能够被高效的完成，因为它在显存中是直接发生的。
     *  当你在纹理上绘制完对象后，不管你绘制了多少个对象，它的性能将和通常的纹理没什么区别。</p>
     *  
     *  <p>如果你一次绘制许多的对象的话，推荐通过<code>drawBundled</code>方法把绘制调用捆绑在一个代码块中，像下面展示的一样。
     * 那将会产生极大地提速，允许你迅速绘制几百个对象。</p>
     *  
     * 	<pre>
     *  renderTexture.drawBundled(function():void
     *  {
     *     for (var i:int=0; i&lt;numDrawings; ++i)
     *     {
     *         image.rotation = (2 &#42; Math.PI / numDrawings) &#42; i;
     *         renderTexture.draw(image);
     *     }   
     *  });
     *  </pre>
     *  
     *  <p>为了擦除一个经渲染纹理的一部分，你可以使用像“rubber”一样的任意显示对象通过设置它的混合模式为"BlendMode.ERASE"。</p>
     * 
     *  <p>注意当Starling的渲染上下文丢失，渲染纹理就不能够被恢复。
     *  </p>
     *     
     */
    public class RenderTexture extends Texture
    {
        private const PMA:Boolean = true;
        
        private var mActiveTexture:Texture;
        private var mBufferTexture:Texture;
        private var mHelperImage:Image;
        private var mDrawing:Boolean;
        private var mBufferReady:Boolean;
        
        private var mNativeWidth:int;
        private var mNativeHeight:int;
        private var mSupport:RenderSupport;
        
        /** 创建一个某一尺寸的新RenderTexture对象。如果设置presistent为true，在每次调用绘制之后纹理的内容都会原封不动的
         *  保留下来，允许你像使用画布一样使用纹理。相反的设为false，将会在每次调用绘制时先进行清除操作。
         *  前一种会加倍所需要的显示内存！因此如果你只需一次绘制调用或一次块绘制调用，你应该停用它。
         */
        public function RenderTexture(width:int, height:int, persistent:Boolean=true, scale:Number=-1)
        {
            if (scale <= 0) scale = Starling.contentScaleFactor; 
            
            mNativeWidth  = getNextPowerOfTwo(width  * scale);
            mNativeHeight = getNextPowerOfTwo(height * scale);
            mActiveTexture = Texture.empty(width, height, PMA, true, scale);
            
            mSupport = new RenderSupport();
            mSupport.setOrthographicProjection(mNativeWidth/scale, mNativeHeight/scale);
            
            if (persistent)
            {
                mBufferTexture = Texture.empty(width, height, PMA, true, scale);
                mHelperImage = new Image(mBufferTexture);
                mHelperImage.smoothing = TextureSmoothing.NONE; // solves some antialias-issues
            }
        }
        
        /** @inheritDoc */
        public override function dispose():void
        {
            mActiveTexture.dispose();
            
            if (isPersistent) 
            {
                mBufferTexture.dispose();
                mHelperImage.dispose();
            }
            
            super.dispose();
        }
        
        /** 绘制一个对象到纹理上。
         * 
         *  @param object       要绘制的对象。
         *  @param matrix       如果matrix参数为空，对象绘制时将采用它的位置，缩放和旋转属性。如果不为空，
         *                      对象将会根据matrix的描述来绘制。
         *  @param alpha        对象的透明度将被乘以这个值。
         *  @param antiAliasing 这个参数目前被Stage3D忽略。
         */
        public function draw(object:DisplayObject, matrix:Matrix=null, alpha:Number=1.0, 
                             antiAliasing:int=0):void
        {
            if (object == null) return;
            
            if (mDrawing)
                render();
            else
                drawBundled(render, antiAliasing);
            
            function render():void
            {
                mSupport.pushMatrix();
                mSupport.pushBlendMode();
                mSupport.blendMode = object.blendMode;
                
                if (matrix) mSupport.prependMatrix(matrix);
                else        mSupport.transformMatrix(object);
                
                object.render(mSupport, alpha);
                
                mSupport.popMatrix();
                mSupport.popBlendMode();
            }
        }
           
        /** 把几个<code>draw</code>的调用一起捆绑在一个代码块中。这就避免了缓冲开关并且允许你绘制多
         *  个对象到一个非持久（non-persistent）的纹理上。 */
        public function drawBundled(drawingBlock:Function, antiAliasing:int=0):void
        {
            var scale:Number = mActiveTexture.scale;
            var context:Context3D = Starling.context;
            if (context == null) throw new MissingContextError();
            
            // limit drawing to relevant area
            context.setScissorRectangle(
                new Rectangle(0, 0, mActiveTexture.width * scale, mActiveTexture.height * scale));
            
            // persistent drawing uses double buffering, as Molehill forces us to call 'clear'
            // on every render target once per update.
            
            // switch buffers
            if (isPersistent)
            {
                var tmpTexture:Texture = mActiveTexture;
                mActiveTexture = mBufferTexture;
                mBufferTexture = tmpTexture;
                mHelperImage.texture = mBufferTexture;
            }
            
            context.setRenderToTexture(mActiveTexture.base, false, antiAliasing);
            RenderSupport.clear();
            
            // draw buffer
            if (isPersistent && mBufferReady)
                mHelperImage.render(mSupport, 1.0);
            else
                mBufferReady = true;
            
            try
            {
                mDrawing = true;
                
                // draw new objects
                if (drawingBlock != null)
                    drawingBlock();
            }
            finally
            {
                mDrawing = false;
                mSupport.finishQuadBatch();
                mSupport.nextFrame();
                context.setScissorRectangle(null);
                context.setRenderToBackBuffer();
            }
        }
        
        /** 清除纹理（恢复完整透明值）。 */
        public function clear():void
        {
            var context:Context3D = Starling.context;
            if (context == null) throw new MissingContextError();
            
            context.setRenderToTexture(mActiveTexture.base);
            RenderSupport.clear();
            context.setRenderToBackBuffer();
        }
        
        /** @inheritDoc */
        public override function adjustVertexData(vertexData:VertexData, vertexID:int, count:int):void
        {
            mActiveTexture.adjustVertexData(vertexData, vertexID, count);   
        }
        
        /** Indicates if the texture is persistent over multiple draw calls. */
        public function get isPersistent():Boolean { return mBufferTexture != null; }
        
        /** @inheritDoc */
        public override function get width():Number { return mActiveTexture.width; }        
        
        /** @inheritDoc */
        public override function get height():Number { return mActiveTexture.height; }        
        
        /** @inheritDoc */
        public override function get scale():Number { return mActiveTexture.scale; }
 
        /** @inheritDoc */
        public override function get premultipliedAlpha():Boolean { return PMA; }
        
        /** @inheritDoc */
        public override function get base():TextureBase 
        { 
            return mActiveTexture.base; 
        }
    }
}