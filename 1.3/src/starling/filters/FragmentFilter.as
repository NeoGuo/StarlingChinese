// =================================================================================================
//
//	Starling Framework
//	Copyright 2012 Gamua OG. All Rights Reserved.
//
//	This program is free software. You can redistribute and/or modify it
//	in accordance with the terms of the accompanying license agreement.
//
// =================================================================================================

package starling.filters
{
    import flash.display3D.Context3D;
    import flash.display3D.Context3DProgramType;
    import flash.display3D.Context3DVertexBufferFormat;
    import flash.display3D.IndexBuffer3D;
    import flash.display3D.Program3D;
    import flash.display3D.VertexBuffer3D;
    import flash.errors.IllegalOperationError;
    import flash.geom.Matrix;
    import flash.geom.Rectangle;
    import flash.system.Capabilities;
    import flash.utils.getQualifiedClassName;
    
    import starling.core.RenderSupport;
    import starling.core.Starling;
    import starling.core.starling_internal;
    import starling.display.BlendMode;
    import starling.display.DisplayObject;
    import starling.display.Image;
    import starling.display.QuadBatch;
    import starling.display.Stage;
    import starling.errors.AbstractClassError;
    import starling.errors.MissingContextError;
    import starling.events.Event;
    import starling.textures.Texture;
    import starling.utils.MatrixUtil;
    import starling.utils.RectangleUtil;
    import starling.utils.VertexData;
    import starling.utils.getNextPowerOfTwo;

    /** FragmentFilter(片段滤镜)类是Starling中所有滤镜效果的基类。这个包中所有的其它滤镜都是扩展自这个类。
	 *  你可以通过使用属性'filter'，将这些滤镜附加到任何显示对象上。
     *  <p>一个片段滤镜是通过如下的方式工作的:</p>
     *  <ol>
     *    <li>应用滤镜的对象会被渲染到一个纹理上 (在全局坐标系下).</li>
     *    <li>然后这个纹理会被传递给第一个滤镜处理通道。</li>
     *    <li>每一个通道使用片段着色器(或者额外再加一个顶点着色器)来处理纹理，实现特定的效果。</li>
     *    <li>每一个通道的输出，将会作为下一个通道的输入。如果它是最终的通道，就会把它直接渲染到后台缓冲区。</li>
     *  </ol>
     *  <p>所有的这些过程，都被抽象类FragmentFilter定义了。所有的子类只需要覆盖这几个方法：
	 *  'createPrograms', 'activate' 和 (可选) 'deactivate'，来创建和执行它的自定义着色代码。
	 *  每一个滤镜可以设置为取代原来的显示对象，或在显示对象的上层或下层绘制。这取决于'mode'属性的设置，可选值定义在'FragmentFilterMode'这个类中。</p>
     * 	<p>需要注意的是，在同一时刻，每一个滤镜只能应用于一个显示对象。否则，它就会变的很慢，需要更多的资源和缓存，并导致无法预料的后果。</p>
     */ 
    public class FragmentFilter
    {
        /** 所有的滤镜处理预计都会使用预乘透明度*/
        protected const PMA:Boolean = true;
        
		/**标准的顶点着色代码。如果你没有创建自定义的顶点着色器，就会自动使用这个标准的着色代码。*/
        protected const STD_VERTEX_SHADER:String = 
            "m44 op, va0, vc0 \n" + // 4x4 matrix transform to output space
            "mov v0, va1      \n";  // pass texture coordinates to fragment program
        
        /** 标准的片段着色器代码. 它只是转发纹理颜色到输出端. */
        protected const STD_FRAGMENT_SHADER:String =
            "tex oc, v0, fs0 <2d, clamp, linear, mipnone>"; // just forward texture color
        
        private var mVertexPosAtID:int = 0;
        private var mTexCoordsAtID:int = 1;
        private var mBaseTextureID:int = 0;
        private var mMvpConstantID:int = 0;
        
        private var mNumPasses:int;
        private var mPassTextures:Vector.<Texture>;

        private var mMode:String;
        private var mResolution:Number;
        private var mMarginX:Number;
        private var mMarginY:Number;
        private var mOffsetX:Number;
        private var mOffsetY:Number;
        
        private var mVertexData:VertexData;
        private var mVertexBuffer:VertexBuffer3D;
        private var mIndexData:Vector.<uint>;
        private var mIndexBuffer:IndexBuffer3D;
        
        private var mCacheRequested:Boolean;
        private var mCache:QuadBatch;
        
        /** helper objects. */
        private var mProjMatrix:Matrix = new Matrix();
        private static var sBounds:Rectangle  = new Rectangle();
        private static var sStageBounds:Rectangle = new Rectangle();
        private static var sTransformationMatrix:Matrix = new Matrix();
        
		/**
		 * 根据指定的通道数量和分辨率，创建一个新的片段滤镜。只有在子类的构造方法中，才能调用这个构造方法。
		 * @param numPasses 通道数量
		 * @param resolution 分辨率
		 */		
        public function FragmentFilter(numPasses:int=1, resolution:Number=1.0)
        {
            if (Capabilities.isDebugger && 
                getQualifiedClassName(this) == "starling.filters::FragmentFilter")
            {
                throw new AbstractClassError();
            }
            
            if (numPasses < 1) throw new ArgumentError("At least one pass is required.");
            
            mNumPasses = numPasses;
            mMarginX = mMarginY = 0.0;
            mOffsetX = mOffsetY = 0;
            mResolution = resolution;
            mMode = FragmentFilterMode.REPLACE;
            
            mVertexData = new VertexData(4);
            mVertexData.setTexCoords(0, 0, 0);
            mVertexData.setTexCoords(1, 1, 0);
            mVertexData.setTexCoords(2, 0, 1);
            mVertexData.setTexCoords(3, 1, 1);
            
            mIndexData = new <uint>[0, 1, 2, 1, 3, 2];
            mIndexData.fixed = true;
            
            createPrograms();
            
            // Handle lost context. By using the conventional event, we can make it weak; this  
            // avoids memory leaks when people forget to call "dispose" on the filter.
            Starling.current.stage3D.addEventListener(Event.CONTEXT3D_CREATE, 
                onContextCreated, false, 0, true);
        }
        
        /** 销毁滤镜 (着色程序, 缓冲区, 纹理). */
        public function dispose():void
        {
            Starling.current.stage3D.removeEventListener(Event.CONTEXT3D_CREATE, onContextCreated);
            if (mVertexBuffer) mVertexBuffer.dispose();
            if (mIndexBuffer)  mIndexBuffer.dispose();
            disposePassTextures();
            disposeCache();
        }
        
        private function onContextCreated(event:Object):void
        {
            mVertexBuffer = null;
            mIndexBuffer  = null;
            mPassTextures = null;
            
            createPrograms();
        }
        
		/**
		 * 在指定的显示对象上应用滤镜，渲染输出结果到当前的渲染目标上。当Starling渲染一个附加了滤镜的对象时，会自动调用这个方法。
		 * @param object 显示对象
		 * @param support 渲染辅助对象
		 * @param parentAlpha 父级透明度
		 */		
        public function render(object:DisplayObject, support:RenderSupport, parentAlpha:Number):void
        {
            // bottom layer
            
            if (mode == FragmentFilterMode.ABOVE)
                object.render(support, parentAlpha);
            
            // center layer
            
            if (mCacheRequested)
            {
                mCacheRequested = false;
                mCache = renderPasses(object, support, 1.0, true);
                disposePassTextures();
            }
            
            if (mCache)
                mCache.render(support, parentAlpha);
            else
                renderPasses(object, support, parentAlpha, false);
            
            // top layer
            
            if (mode == FragmentFilterMode.BELOW)
                object.render(support, parentAlpha);
        }
        
        private function renderPasses(object:DisplayObject, support:RenderSupport, 
                                      parentAlpha:Number, intoCache:Boolean=false):QuadBatch
        {
            var cacheTexture:Texture = null;
            var stage:Stage = object.stage;
            var context:Context3D = Starling.context;
            var scale:Number = Starling.current.contentScaleFactor;
            
            if (stage   == null) throw new Error("Filtered object must be on the stage.");
            if (context == null) throw new MissingContextError();
            
            // the bounds of the object in stage coordinates 
            calculateBounds(object, stage, !intoCache, sBounds);
            
            if (sBounds.isEmpty())
            {
                disposePassTextures();
                return intoCache ? new QuadBatch() : null; 
            }
            
            updateBuffers(context, sBounds);
            updatePassTextures(sBounds.width, sBounds.height, mResolution * scale);

            support.finishQuadBatch();
            support.raiseDrawCount(mNumPasses);
            support.pushMatrix();
            
            // save original projection matrix and render target
            mProjMatrix.copyFrom(support.projectionMatrix); 
            var previousRenderTarget:Texture = support.renderTarget;
            
            if (previousRenderTarget)
                throw new IllegalOperationError(
                    "It's currently not possible to stack filters! " +
                    "This limitation will be removed in a future Stage3D version.");
            
            if (intoCache) 
                cacheTexture = Texture.empty(sBounds.width, sBounds.height, PMA, true, 
                                             mResolution * scale);
            
            // draw the original object into a texture
            support.renderTarget = mPassTextures[0];
            support.clear();
            support.blendMode = BlendMode.NORMAL;
            support.setOrthographicProjection(sBounds.x, sBounds.y, sBounds.width, sBounds.height);
            object.render(support, parentAlpha);
            support.finishQuadBatch();
            
            // prepare drawing of actual filter passes
            RenderSupport.setBlendFactors(PMA);
            support.loadIdentity();  // now we'll draw in stage coordinates!
            
            context.setVertexBufferAt(mVertexPosAtID, mVertexBuffer, VertexData.POSITION_OFFSET, 
                                      Context3DVertexBufferFormat.FLOAT_2);
            context.setVertexBufferAt(mTexCoordsAtID, mVertexBuffer, VertexData.TEXCOORD_OFFSET,
                                      Context3DVertexBufferFormat.FLOAT_2);
            
            // draw all passes
            for (var i:int=0; i<mNumPasses; ++i)
            {
                if (i < mNumPasses - 1) // intermediate pass  
                {
                    // draw into pass texture
                    support.renderTarget = getPassTexture(i+1);
                    support.clear();
                }
                else // final pass
                {
                    if (intoCache)
                    {
                        // draw into cache texture
                        support.renderTarget = cacheTexture;
                        support.clear();
                    }
                    else
                    {
                        // draw into back buffer, at original (stage) coordinates
                        support.renderTarget = previousRenderTarget;
                        support.projectionMatrix.copyFrom(mProjMatrix); // restore projection matrix
                        support.translateMatrix(mOffsetX, mOffsetY);
                        support.blendMode = object.blendMode;
                        support.applyBlendMode(PMA);
                    }
                }
                
                var passTexture:Texture = getPassTexture(i);
                
                context.setProgramConstantsFromMatrix(Context3DProgramType.VERTEX, mMvpConstantID, 
                                                      support.mvpMatrix3D, true);
                context.setTextureAt(mBaseTextureID, passTexture.base);
                
                activate(i, context, passTexture);
                context.drawTriangles(mIndexBuffer, 0, 2);
                deactivate(i, context, passTexture);
            }
            
            // reset shader attributes
            context.setVertexBufferAt(mVertexPosAtID, null);
            context.setVertexBufferAt(mTexCoordsAtID, null);
            context.setTextureAt(mBaseTextureID, null);
            
            support.popMatrix();
            
            if (intoCache)
            {
                // restore support settings
                support.renderTarget = previousRenderTarget;
                support.projectionMatrix.copyFrom(mProjMatrix);
                
                // Create an image containing the cache. To have a display object that contains
                // the filter output in object coordinates, we wrap it in a QuadBatch: that way,
                // we can modify it with a transformation matrix.
                
                var quadBatch:QuadBatch = new QuadBatch();
                var image:Image = new Image(cacheTexture);
                
                stage.getTransformationMatrix(object, sTransformationMatrix);
                MatrixUtil.prependTranslation(sTransformationMatrix, 
                                              sBounds.x + mOffsetX, sBounds.y + mOffsetY);
                quadBatch.addImage(image, 1.0, sTransformationMatrix);

                return quadBatch;
            }
            else return null;
        }
        
        // helper methods
        
        private function updateBuffers(context:Context3D, bounds:Rectangle):void
        {
            mVertexData.setPosition(0, bounds.x, bounds.y);
            mVertexData.setPosition(1, bounds.right, bounds.y);
            mVertexData.setPosition(2, bounds.x, bounds.bottom);
            mVertexData.setPosition(3, bounds.right, bounds.bottom);
            
            if (mVertexBuffer == null)
            {
                mVertexBuffer = context.createVertexBuffer(4, VertexData.ELEMENTS_PER_VERTEX);
                mIndexBuffer  = context.createIndexBuffer(6);
                mIndexBuffer.uploadFromVector(mIndexData, 0, 6);
            }
            
            mVertexBuffer.uploadFromVector(mVertexData.rawData, 0, 4);
        }
        
        private function updatePassTextures(width:int, height:int, scale:Number):void
        {
            var numPassTextures:int = mNumPasses > 1 ? 2 : 1;
            
            var needsUpdate:Boolean = mPassTextures == null || 
                mPassTextures.length != numPassTextures ||
                mPassTextures[0].width != width || mPassTextures[0].height != height;  
            
            if (needsUpdate)
            {
                if (mPassTextures)
                {
                    for each (var texture:Texture in mPassTextures) 
                        texture.dispose();
                    
                    mPassTextures.length = numPassTextures;
                }
                else
                {
                    mPassTextures = new Vector.<Texture>(numPassTextures);
                }
                
                for (var i:int=0; i<numPassTextures; ++i)
                    mPassTextures[i] = Texture.empty(width, height, PMA, true, scale);
            }
        }
        
        private function getPassTexture(pass:int):Texture
        {
            return mPassTextures[pass % 2];
        }
        
		/**计算滤镜在全局坐标系下的范围，同时确保相应的纹理符合2的幂数的要求。*/
        private function calculateBounds(object:DisplayObject, stage:Stage, 
                                         intersectWithStage:Boolean, resultRect:Rectangle):void
        {
            // optimize for full-screen effects
            if (object == stage || object == Starling.current.root)
                resultRect.setTo(0, 0, stage.stageWidth, stage.stageHeight);
            else
                object.getBounds(stage, resultRect);
            
            if (intersectWithStage)
            {
                sStageBounds.setTo(0, 0, stage.stageWidth, stage.stageHeight);
                RectangleUtil.intersect(resultRect, sStageBounds, resultRect);
            }
            
            if (!resultRect.isEmpty())
            {    
                // the bounds are a rectangle around the object, in stage coordinates,
                // and with an optional margin. To fit into a POT-texture, it will grow towards
                // the right and bottom.
                var deltaMargin:Number = mResolution == 1.0 ? 0.0 : 1.0 / mResolution; // avoid hard edges
                resultRect.x -= mMarginX + deltaMargin;
                resultRect.y -= mMarginY + deltaMargin;
                resultRect.width  += 2 * (mMarginX + deltaMargin);
                resultRect.height += 2 * (mMarginY + deltaMargin);
                resultRect.width  = getNextPowerOfTwo(resultRect.width  * mResolution) / mResolution;
                resultRect.height = getNextPowerOfTwo(resultRect.height * mResolution) / mResolution;
            }
        }
        
        private function disposePassTextures():void
        {
            for each (var texture:Texture in mPassTextures)
                texture.dispose();
            
            mPassTextures = null;
        }
        
        private function disposeCache():void
        {
            if (mCache)
            {
                if (mCache.texture) mCache.texture.dispose();
                mCache.dispose();
                mCache = null;
            }
        }
        
        // protected methods

		/**子类必须覆盖这个方法，并且使用它来创建他们自己的片段和顶点着色程序*/
        protected function createPrograms():void
        {
            throw new Error("Method has to be implemented in subclass!");
        }

		/**
		 * 子类必须覆盖这个方法，并且使用它来实现他们自己的片段和顶点着色程序。
		 * 'activate'方法的调用先于'context.drawTriangles'方法的调用。根据你的滤镜的需要设置上下文。下面的常量和属性会被自动设置：
		 * 
		 * <ul><li>vertex constants 0-3: mvpMatrix (3D)</li>
         *      <li>vertex attribute 0: vertex position (FLOAT_2)</li>
         *      <li>vertex attribute 1: texture coordinates (FLOAT_2)</li>
         *      <li>texture 0: input texture</li>
         * </ul>
		 * 
		 * @param pass 当前的渲染通道，从'0'开始。多通道的滤镜可以为每一个通道提供不同的逻辑。
		 * @param context 上下文 当前的context3D对象(实际上就是Starling.context，这里传递只是为了调用方便)
		 * @param texture 纹理 输入纹理，已经被绑定到采样器0
		 */		
        protected function activate(pass:int, context:Context3D, texture:Texture):void
        {
            throw new Error("Method has to be implemented in subclass!");
        }
        
		/**
		 * 这个方法会在'context.drawTriangles'方法调用之后，被调用。如果你需要做一些诸如清理资源的工作，可以在这个方法里面来做。
		 * @param pass 当前的渲染通道
		 * @param context 上下文
		 * @param texture 纹理
		 */		
        protected function deactivate(pass:int, context:Context3D, texture:Texture):void
        {
            // clean up resources
        }
        
		/**
		 * 将字符串格式的片段和顶点着色代码汇编到一个Program3D对象。如果有任何参数是null，就会采用默认值（STD_FRAGMENT_SHADER或STD_VERTEX_SHADER）来替代。
		 * @param fragmentShader 片段着色代码
		 * @param vertexShader 顶点着色代码
		 * @return Program3D
		 */		
        protected function assembleAgal(fragmentShader:String=null, vertexShader:String=null):Program3D
        {
            if (fragmentShader == null) fragmentShader = STD_FRAGMENT_SHADER;
            if (vertexShader   == null) vertexShader   = STD_VERTEX_SHADER;
            
            return RenderSupport.assembleAgal(vertexShader, fragmentShader);
        }
        
        // cache
        
		/**缓存滤镜输出到一个纹理。一个没有缓存的滤镜，会在每一帧进行渲染；而一个缓存的滤镜则只需要渲染一次。
		 * 当然，如果应用滤镜的对象或滤镜设置改变了，缓存也应该被更新；要做到这一点，可以再次调用'cache'方法。*/
        public function cache():void
        {
            mCacheRequested = true;
            disposeCache();
        }
        
		/**清理滤镜的缓存输出。在这个方法调用后，滤镜将会在每帧执行一次。*/
        public function clearCache():void
        {
            mCacheRequested = false;
            disposeCache();
        }
        
        // flattening
        
        /** @private */
        starling_internal function compile(object:DisplayObject):QuadBatch
        {
            if (mCache) return mCache;
            else
            {
                var renderSupport:RenderSupport;
                var stage:Stage = object.stage;
                
                if (stage == null) 
                    throw new Error("Filtered object must be on the stage.");
                
                renderSupport = new RenderSupport();
                object.getTransformationMatrix(stage, renderSupport.modelViewMatrix);
                return renderPasses(object, renderSupport, 1.0, true);
            }
        }
        
        // properties
        
        /** 判断滤镜是否被缓存了 (通过"cache" 方法). */
        public function get isCached():Boolean { return (mCache != null) || mCacheRequested; }
        
		/**
		 * 滤镜纹理的分辨率。"1"代表stage分辨率，"0.5"代表stage分辨率的一半。一个较小的分辨率，可以节省存储空间和执行时间(取决于GPU)，
		 * 但是输出质量会降低。如果数值大于1也是允许的；当过滤器缩放时，这样的值可能是有意义的。
		 */		
        public function get resolution():Number { return mResolution; }
        public function set resolution(value:Number):void 
        {
            if (value <= 0) throw new ArgumentError("Resolution must be > 0");
            else mResolution = value; 
        }
        
        /** 滤镜模式, 由"FragmentFilterMode" 定义。
         *  @default "replace" */
        public function get mode():String { return mMode; }
        public function set mode(value:String):void { mMode = value; }
        
        /** 滤镜的左右偏移量. */
        public function get offsetX():Number { return mOffsetX; }
        public function set offsetX(value:Number):void { mOffsetX = value; }
        
        /**滤镜的上下偏移量 */
        public function get offsetY():Number { return mOffsetY; }
        public function set offsetY(value:Number):void { mOffsetY = value; }
        
        /** x余量将会沿着X的方法扩展滤镜纹理的尺寸，当使用外发光效果时非常有用。 */
        protected function get marginX():Number { return mMarginX; }
        protected function set marginX(value:Number):void { mMarginX = value; }
        
        /** y余量将会沿着Y的方法扩展滤镜纹理的尺寸，当使用外发光效果时非常有用。 */
        protected function get marginY():Number { return mMarginY; }
        protected function set marginY(value:Number):void { mMarginY = value; }
        
        /** 滤镜应用的通道数量. "activate" 和 "deactivate" 方法会来调用。 */
        protected function set numPasses(value:int):void { mNumPasses = value; }
        protected function get numPasses():int { return mNumPasses; }
        
		/**存储了顶点位置的顶点缓冲区属性的ID*/
        protected final function get vertexPosAtID():int { return mVertexPosAtID; }
        protected final function set vertexPosAtID(value:int):void { mVertexPosAtID = value; }
        
		/**存储了顶点坐标的顶点缓冲区属性的ID*/
        protected final function get texCoordsAtID():int { return mTexCoordsAtID; }
        protected final function set texCoordsAtID(value:int):void { mTexCoordsAtID = value; }

        /** 输入纹理的ID(取样器)，包含上一个通道的输出 */
        protected final function get baseTextureID():int { return mBaseTextureID; }
        protected final function set baseTextureID(value:int):void { mBaseTextureID = value; }
        
        /** 模型投影常数(4*4矩阵)的第一个寄存器ID*/
        protected final function get mvpConstantID():int { return mMvpConstantID; }
        protected final function set mvpConstantID(value:int):void { mMvpConstantID = value; }
    }
}