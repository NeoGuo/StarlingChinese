// =================================================================================================
//
//	Starling Framework
//	Copyright 2012 Gamua OG. All Rights Reserved.
//
//	This program is free software. You can redistribute and/or modify it
//	in accordance with the terms of the accompanying license agreement.
//
// =================================================================================================

package starling.display
{
    import com.adobe.utils.AGALMiniAssembler;
    
    import flash.display3D.Context3D;
    import flash.display3D.Context3DProgramType;
    import flash.display3D.Context3DTextureFormat;
    import flash.display3D.Context3DVertexBufferFormat;
    import flash.display3D.IndexBuffer3D;
    import flash.display3D.VertexBuffer3D;
    import flash.geom.Matrix;
    import flash.geom.Matrix3D;
    import flash.geom.Rectangle;
    import flash.utils.Dictionary;
    import flash.utils.getQualifiedClassName;
    
    import starling.core.RenderSupport;
    import starling.core.Starling;
    import starling.core.starling_internal;
    import starling.errors.MissingContextError;
    import starling.events.Event;
    import starling.textures.Texture;
    import starling.textures.TextureSmoothing;
    import starling.utils.MatrixUtil;
    import starling.utils.VertexData;
    
    use namespace starling_internal;
    
    /** 
	 * QuadBatch类用于优化渲染大量具备相同状态的四边形(Quad类).
     * 
     *  <p>Starling的大部分渲染对象都是四边形。实际上，Starling的所有默认叶子节点都是四边形（Image和Quad类）。
	 * 如果所有的具有相同状态的四边形可以只用一次请求就上传给GPU，那么渲染这些四边形的执行效率将会得到极大的提升。这就是QuadBatch类的作用。</p>
     *  
     *  <p>Sprite类的'flatten'方法在内部使用了这个类来提升渲染效率。
	 * 大多数情况下，建议你使用"平面化"的对象，因为他们用起来很简单。不过有时，直接使用QuadBatch类效果会更好：
	 * 例如，你可以将一个四边形多次添加进一个四边形批次，但是，你只能添加它到一个sprite容器一次。
	 * 此外，当一个四边形被添加时，并不会派发<code>ADDED</code> 或者 <code>ADDED_TO_STAGE</code> 事件，这使得QuadBatch更加轻便。</p>
     *  
     *  <p>一个QuadBatch对象只能有一个特定的渲染状态。
	 * 你添加到批次的第一个对象将决定QuadBatch的状态，包括：它的纹理，它的平滑度和混合设置，
	 * 它是否被染色（有色的顶点 和/或  透明的）。当你重置批次，它将会在添加下一个四边形时接受一个新的状态。</p> 
     *  
     *  <p>这个类继承了DisplayObject，但是你可以使用它，即使它没有被添加到显示列表树。
	 * 只需从另一个渲染方法调用'renderCustom'方法，并且传递适当的值（包括变换矩阵，透明度，混合模式）。</p>
     *
     *  @see Sprite  
     */ 
    public class QuadBatch extends DisplayObject
    {
        private static const QUAD_PROGRAM_NAME:String = "QB_q";
        
        private var mNumQuads:int;
        private var mSyncRequired:Boolean;

        private var mTinted:Boolean;
        private var mTexture:Texture;
        private var mSmoothing:String;
        
        private var mVertexData:VertexData;
        private var mVertexBuffer:VertexBuffer3D;
        private var mIndexData:Vector.<uint>;
        private var mIndexBuffer:IndexBuffer3D;

        /** Helper objects. */
        private static var sHelperMatrix:Matrix = new Matrix();
        private static var sRenderAlpha:Vector.<Number> = new <Number>[1.0, 1.0, 1.0, 1.0];
        private static var sRenderMatrix:Matrix3D = new Matrix3D();
        private static var sProgramNameCache:Dictionary = new Dictionary();
        
        /** 用空的四边形数据创建一个新的 QuadBatch实例。 */
        public function QuadBatch()
        {
            mVertexData = new VertexData(0, true);
            mIndexData = new <uint>[];
            mNumQuads = 0;
            mTinted = false;
            mSyncRequired = false;
            
            // Handle lost context. We use the conventional event here (not the one from Starling)
            // so we're able to create a weak event listener; this avoids memory leaks when people 
            // forget to call "dispose" on the QuadBatch.
            Starling.current.stage3D.addEventListener(Event.CONTEXT3D_CREATE, 
                                                      onContextCreated, false, 0, true);
        }
        
        /**  
		 * 销毁顶点和索引缓冲区。 */
        public override function dispose():void
        {
            Starling.current.stage3D.removeEventListener(Event.CONTEXT3D_CREATE, onContextCreated);
            
            if (mVertexBuffer) mVertexBuffer.dispose();
            if (mIndexBuffer)  mIndexBuffer.dispose();
            
            super.dispose();
        }
        
        private function onContextCreated(event:Object):void
        {
            createBuffers();
            registerPrograms();
        }
        
        /** 复制当前对象。 */
        public function clone():QuadBatch
        {
            var clone:QuadBatch = new QuadBatch();
            clone.mVertexData = mVertexData.clone(0, mNumQuads * 4);
            clone.mIndexData = mIndexData.slice(0, mNumQuads * 6);
            clone.mNumQuads = mNumQuads;
            clone.mTinted = mTinted;
            clone.mTexture = mTexture;
            clone.mSmoothing = mSmoothing;
            clone.mSyncRequired = true;
            clone.blendMode = blendMode;
            clone.alpha = alpha;
            return clone;
        }
        
        private function expand(newCapacity:int=-1):void
        {
            var oldCapacity:int = capacity;
            
            if (newCapacity <  0) newCapacity = oldCapacity * 2;
            if (newCapacity == 0) newCapacity = 16;
            if (newCapacity <= oldCapacity) return;
            
            mVertexData.numVertices = newCapacity * 4;
            
            for (var i:int=oldCapacity; i<newCapacity; ++i)
            {
                mIndexData[int(i*6  )] = i*4;
                mIndexData[int(i*6+1)] = i*4 + 1;
                mIndexData[int(i*6+2)] = i*4 + 2;
                mIndexData[int(i*6+3)] = i*4 + 1;
                mIndexData[int(i*6+4)] = i*4 + 3;
                mIndexData[int(i*6+5)] = i*4 + 2;
            }
            
            createBuffers();
            registerPrograms();
        }
        
        private function createBuffers():void
        {
            var numVertices:int = mVertexData.numVertices;
            var numIndices:int = mIndexData.length;
            var context:Context3D = Starling.context;

            if (mVertexBuffer)    mVertexBuffer.dispose();
            if (mIndexBuffer)     mIndexBuffer.dispose();
            if (numVertices == 0) return;
            if (context == null)  throw new MissingContextError();
            
            mVertexBuffer = context.createVertexBuffer(numVertices, VertexData.ELEMENTS_PER_VERTEX);
            mVertexBuffer.uploadFromVector(mVertexData.rawData, 0, numVertices);
            
            mIndexBuffer = context.createIndexBuffer(numIndices);
            mIndexBuffer.uploadFromVector(mIndexData, 0, numIndices);
            
            mSyncRequired = false;
        }
        
        /** 上传所有的四边形源数据到顶点缓冲区。*/
        private function syncBuffers():void
        {
            if (mVertexBuffer == null)
                createBuffers();
            else
            {
                // as 3rd parameter, we could also use 'mNumQuads * 4', but on some GPU hardware (iOS!),
                // this is slower than updating the complete buffer.
                
                mVertexBuffer.uploadFromVector(mVertexData.rawData, 0, mVertexData.numVertices);
                mSyncRequired = false;
            }
        }
        
        /**
         * 结合对 模型-视图-投影矩阵，透明度和混合模式的自定义设置来渲染当前批次。
		 * 这样就使渲染那些不在显示列表的批次成为可能。
         * @param mvpMatrix	 模型-视图-投影矩阵
         * @param parentAlpha	父级的透明度
         * @param blendMode		混合模式
         */
        public function renderCustom(mvpMatrix:Matrix, parentAlpha:Number=1.0,
                                     blendMode:String=null):void
        {
            if (mNumQuads == 0) return;
            if (mSyncRequired) syncBuffers();
            
            var pma:Boolean = mVertexData.premultipliedAlpha;
            var context:Context3D = Starling.context;
            var tinted:Boolean = mTinted || (parentAlpha != 1.0);
            var programName:String = mTexture ? 
                getImageProgramName(tinted, mTexture.mipMapping, mTexture.repeat, mTexture.format, mSmoothing) : 
                QUAD_PROGRAM_NAME;
            
            sRenderAlpha[0] = sRenderAlpha[1] = sRenderAlpha[2] = pma ? parentAlpha : 1.0;
            sRenderAlpha[3] = parentAlpha;
            
            MatrixUtil.convertTo3D(mvpMatrix, sRenderMatrix);
            RenderSupport.setBlendFactors(pma, blendMode ? blendMode : this.blendMode);
            
            context.setProgram(Starling.current.getProgram(programName));
            context.setProgramConstantsFromVector(Context3DProgramType.VERTEX, 0, sRenderAlpha, 1);
            context.setProgramConstantsFromMatrix(Context3DProgramType.VERTEX, 1, sRenderMatrix, true);
            context.setVertexBufferAt(0, mVertexBuffer, VertexData.POSITION_OFFSET, 
                                      Context3DVertexBufferFormat.FLOAT_2); 
            
            if (mTexture == null || tinted)
                context.setVertexBufferAt(1, mVertexBuffer, VertexData.COLOR_OFFSET, 
                                          Context3DVertexBufferFormat.FLOAT_4);
            
            if (mTexture)
            {
                context.setTextureAt(0, mTexture.base);
                context.setVertexBufferAt(2, mVertexBuffer, VertexData.TEXCOORD_OFFSET, 
                                          Context3DVertexBufferFormat.FLOAT_2);
            }
            
            context.drawTriangles(mIndexBuffer, 0, mNumQuads * 2);
            
            if (mTexture)
            {
                context.setTextureAt(0, null);
                context.setVertexBufferAt(2, null);
            }
            
            context.setVertexBufferAt(1, null);
            context.setVertexBufferAt(0, null);
        }
        
        /** 重置当前批次。顶点和索引缓冲区仍保持原来的大小，以便能够很快被重用。 */  
        public function reset():void
        {
            mNumQuads = 0;
            mTexture = null;
            mSmoothing = null;
            mSyncRequired = true;
        }
        
        /**
         * 向当前批次添加一个图像。
		 * 这个方法在内部调用'addQuad'方法，并传递关于纹理和平滑度的正确参数。
         * @param image	图像
         * @param parentAlpha	父级的透明度
         * @param modelViewMatrix	模型视图矩阵
         * @param blendMode	混合模式
         */
        public function addImage(image:Image, parentAlpha:Number=1.0, modelViewMatrix:Matrix=null,
                                 blendMode:String=null):void
        {
            addQuad(image, parentAlpha, image.texture, image.smoothing, modelViewMatrix, blendMode);
        }
        
        /**
         * 添加一个四边形到当前批次。
		 * 第一个四边形决定批次的状态。比如纹理的值，平滑度和混合模式。
		 * 当你添加自定义的四边形，请确保他们共享了这些状态（比如'isStageChange'方法），或者重置这个批次。
         * @param quad	四边形
         * @param parentAlpha	父级的透明度
         * @param texture	纹理
         * @param smoothing	平滑度
         * @param modelViewMatrix	模型视图矩阵
         * @param blendMode	混合模式
         */
        public function addQuad(quad:Quad, parentAlpha:Number=1.0, texture:Texture=null, 
                                smoothing:String=null, modelViewMatrix:Matrix=null, 
                                blendMode:String=null):void
        {
            if (modelViewMatrix == null)
                modelViewMatrix = quad.transformationMatrix;
            
            var tinted:Boolean = texture ? (quad.tinted || parentAlpha != 1.0) : false;
            var alpha:Number = parentAlpha * quad.alpha;
            var vertexID:int = mNumQuads * 4;
            
            if (mNumQuads + 1 > mVertexData.numVertices / 4) expand();
            if (mNumQuads == 0) 
            {
                this.blendMode = blendMode ? blendMode : quad.blendMode;
                mTexture = texture;
                mTinted = tinted;
                mSmoothing = smoothing;
                mVertexData.setPremultipliedAlpha(
                    texture ? texture.premultipliedAlpha : true, false); 
            }
            
            quad.copyVertexDataTo(mVertexData, vertexID);
            mVertexData.transformVertex(vertexID, modelViewMatrix, 4);
            
            if (alpha != 1.0)
                mVertexData.scaleAlpha(vertexID, alpha, 4);

            mSyncRequired = true;
            mNumQuads++;
        }
        
        public function addQuadBatch(quadBatch:QuadBatch, parentAlpha:Number=1.0, 
                                     modelViewMatrix:Matrix=null, blendMode:String=null):void
        {
            if (modelViewMatrix == null)
                modelViewMatrix = quadBatch.transformationMatrix;
            
            var tinted:Boolean = quadBatch.mTinted || parentAlpha != 1.0;
            var alpha:Number = parentAlpha * quadBatch.alpha;
            var vertexID:int = mNumQuads * 4;
            var numQuads:int = quadBatch.numQuads;
            
            if (mNumQuads + numQuads > capacity) expand(mNumQuads + numQuads);
            if (mNumQuads == 0) 
            {
                this.blendMode = blendMode ? blendMode : quadBatch.blendMode;
                mTexture = quadBatch.mTexture;
                mTinted = tinted;
                mSmoothing = quadBatch.mSmoothing;
                mVertexData.setPremultipliedAlpha(quadBatch.mVertexData.premultipliedAlpha, false);
            }
            
            quadBatch.mVertexData.copyTo(mVertexData, vertexID, 0, numQuads*4);
            mVertexData.transformVertex(vertexID, modelViewMatrix, numQuads*4);
            
            if (alpha != 1.0)
                mVertexData.scaleAlpha(vertexID, alpha, numQuads*4);
            
            mSyncRequired = true;
            mNumQuads += numQuads;
        }
        
        /**
         * 判断如果一个四边形可以被添加到批次，会否引起状态的变化。
		 * 状态变化可能是由于四边形使用了不同的基础纹理，可能是有不同的"是否染色"，"平滑度"，"纹理是否平铺显示"，或者"混合模式"设置，
		 * 可能是因为批次满了（一个批次最多包含8192个四边形）。
         * @param tinted	是否染色
         * @param parentAlpha	父级的透明度
         * @param texture	纹理
         * @param smoothing	平滑度
         * @param blendMode	混合模式
         * @param numQuads	四边形的数量
         * @return 返回true 如果会引起状态变化，否则返回false
         */
        public function isStateChange(tinted:Boolean, parentAlpha:Number, texture:Texture, 
                                      smoothing:String, blendMode:String, numQuads:int=1):Boolean
        {
            if (mNumQuads == 0) return false;
            else if (mNumQuads + numQuads > 8192) return true; // maximum buffer size
            else if (mTexture == null && texture == null) return false;
            else if (mTexture != null && texture != null)
                return mTexture.base != texture.base ||
                       mTexture.repeat != texture.repeat ||
                       mSmoothing != smoothing ||
                       mTinted != (tinted || parentAlpha != 1.0) ||
                       this.blendMode != blendMode;
            else return true;
        }
        
        // display object methods
        
        /** @inheritDoc */
        public override function getBounds(targetSpace:DisplayObject, resultRect:Rectangle=null):Rectangle
        {
            if (resultRect == null) resultRect = new Rectangle();
            
            var transformationMatrix:Matrix = targetSpace == this ?
                null : getTransformationMatrix(targetSpace, sHelperMatrix);
            
            return mVertexData.getBounds(transformationMatrix, 0, mNumQuads*4, resultRect);
        }
        
        /** @inheritDoc */
        public override function render(support:RenderSupport, parentAlpha:Number):void
        {
            support.finishQuadBatch();
            support.raiseDrawCount();
            renderCustom(support.mvpMatrix, alpha * parentAlpha, support.blendMode);
        }
        
        // compilation (for flattened sprites)
        
        /**
         * 分析一个专门由四边形（或者其他容器）组成的容器对象，
		 * 并且创建一个矢量数组(元素类型是QuadBatch)来代替容器。 这可以用来非常高效的渲染容器。
		 * Sprite类的'flatten'方法在内部使用了这个方法。
         * @param container	容器
         * @param quadBatches	包含QuadBatch类型的矢量数组
         */
        public static function compile(container:DisplayObjectContainer, 
                                       quadBatches:Vector.<QuadBatch>):void
        {
            compileObject(container, quadBatches, -1, new Matrix());
        }
        
        private static function compileObject(object:DisplayObject, 
                                              quadBatches:Vector.<QuadBatch>,
                                              quadBatchID:int,
                                              transformationMatrix:Matrix,
                                              alpha:Number=1.0,
                                              blendMode:String=null):int
        {
            var i:int;
            var quadBatch:QuadBatch;
            var isRootObject:Boolean = false;
            var objectAlpha:Number = object.alpha;
            
            var container:DisplayObjectContainer = object as DisplayObjectContainer;
            var quad:Quad = object as Quad;
            var batch:QuadBatch = object as QuadBatch;
            
            if (quadBatchID == -1)
            {
                isRootObject = true;
                quadBatchID = 0;
                objectAlpha = 1.0;
                blendMode = object.blendMode;
                if (quadBatches.length == 0) quadBatches.push(new QuadBatch());
                else quadBatches[0].reset();
            }
            
            if (container)
            {
                var numChildren:int = container.numChildren;
                var childMatrix:Matrix = new Matrix();
                
                for (i=0; i<numChildren; ++i)
                {
                    var child:DisplayObject = container.getChildAt(i);
                    var childVisible:Boolean = child.alpha  != 0.0 && child.visible && 
                                               child.scaleX != 0.0 && child.scaleY != 0.0;
                    if (childVisible)
                    {
                        var childBlendMode:String = child.blendMode == BlendMode.AUTO ?
                                                    blendMode : child.blendMode;
                        childMatrix.copyFrom(transformationMatrix);
                        RenderSupport.transformMatrixForObject(childMatrix, child);
                        quadBatchID = compileObject(child, quadBatches, quadBatchID, childMatrix, 
                                                    alpha*objectAlpha, childBlendMode);
                    }
                }
            }
            else if (quad || batch)
            {
                var texture:Texture;
                var smoothing:String;
                var tinted:Boolean;
                var numQuads:int;
                
                if (quad)
                {
                    var image:Image = quad as Image;
                    texture = image ? image.texture : null;
                    smoothing = image ? image.smoothing : null;
                    tinted = quad.tinted;
                    numQuads = 1;
                }
                else
                {
                    texture = batch.mTexture;
                    smoothing = batch.mSmoothing;
                    tinted = batch.mTinted;
                    numQuads = batch.mNumQuads;
                }
                
                quadBatch = quadBatches[quadBatchID];
                
                if (quadBatch.isStateChange(tinted, alpha*objectAlpha, texture, 
                                            smoothing, blendMode, numQuads))
                {
                    quadBatchID++;
                    if (quadBatches.length <= quadBatchID) quadBatches.push(new QuadBatch());
                    quadBatch = quadBatches[quadBatchID];
                    quadBatch.reset();
                }
                
                if (quad)
                    quadBatch.addQuad(quad, alpha, texture, smoothing, transformationMatrix, blendMode);
                else
                    quadBatch.addQuadBatch(batch, alpha, transformationMatrix, blendMode);
            }
            else
            {
                throw new Error("Unsupported display object: " + getQualifiedClassName(object));
            }
            
            if (isRootObject)
            {
                // remove unused batches
                for (i=quadBatches.length-1; i>quadBatchID; --i)
                    quadBatches.pop().dispose();
            }
            
            return quadBatchID;
        }
        
        // properties
        
		/** 四边形的数量。 */
        public function get numQuads():int { return mNumQuads; }
		/** 是否染色。 */
        public function get tinted():Boolean { return mTinted; }
		/** 纹理。 */
        public function get texture():Texture { return mTexture; }
		/** 平滑度。 */
        public function get smoothing():String { return mSmoothing; }
        
        private function get capacity():int { return mVertexData.numVertices / 4; }
        
        // program management
        
        private static function registerPrograms():void
        {
            var target:Starling = Starling.current;
            if (target.hasProgram(QUAD_PROGRAM_NAME)) return; // already registered
            
            // create vertex and fragment programs from assembly
            var vertexProgramAssembler:AGALMiniAssembler = new AGALMiniAssembler();
            var fragmentProgramAssembler:AGALMiniAssembler = new AGALMiniAssembler();
            
            var vertexProgramCode:String;
            var fragmentProgramCode:String;
            
            // this is the input data we'll pass to the shaders:
            // 
            // va0 -> position
            // va1 -> color
            // va2 -> texCoords
            // vc0 -> alpha
            // vc1 -> mvpMatrix
            // fs0 -> texture
            
            // Quad:
            
            vertexProgramCode =
                "m44 op, va0, vc1 \n" + // 4x4 matrix transform to output clipspace
                "mul v0, va1, vc0 \n";  // multiply alpha (vc0) with color (va1)
            
            fragmentProgramCode =
                "mov oc, v0       \n";  // output color
            
            vertexProgramAssembler.assemble(Context3DProgramType.VERTEX, vertexProgramCode);
            fragmentProgramAssembler.assemble(Context3DProgramType.FRAGMENT, fragmentProgramCode);
            
            target.registerProgram(QUAD_PROGRAM_NAME,
                vertexProgramAssembler.agalcode, fragmentProgramAssembler.agalcode);
            
            // Image:
            // Each combination of tinted/repeat/mipmap/smoothing has its own fragment shader.
            
            for each (var tinted:Boolean in [true, false])
            {
                vertexProgramCode = tinted ?
                    "m44 op, va0, vc1 \n" + // 4x4 matrix transform to output clipspace
                    "mul v0, va1, vc0 \n" + // multiply alpha (vc0) with color (va1)
                    "mov v1, va2      \n"   // pass texture coordinates to fragment program
                  :
                    "m44 op, va0, vc1 \n" + // 4x4 matrix transform to output clipspace
                    "mov v1, va2      \n";  // pass texture coordinates to fragment program
                    
                vertexProgramAssembler.assemble(Context3DProgramType.VERTEX, vertexProgramCode);
                
                fragmentProgramCode = tinted ?
                    "tex ft1,  v1, fs0 <???> \n" + // sample texture 0
                    "mul  oc, ft1,  v0       \n"   // multiply color with texel color
                  :
                    "tex  oc,  v1, fs0 <???> \n";  // sample texture 0
                
                var smoothingTypes:Array = [
                    TextureSmoothing.NONE,
                    TextureSmoothing.BILINEAR,
                    TextureSmoothing.TRILINEAR
                ];
                
                var formats:Array = [
                    Context3DTextureFormat.BGRA,
                    Context3DTextureFormat.COMPRESSED,
                    "compressedAlpha" // use explicit string for compatibility
                ];
                
                for each (var repeat:Boolean in [true, false])
                {
                    for each (var mipmap:Boolean in [true, false])
                    {
                        for each (var smoothing:String in smoothingTypes)
                        {
                            for each (var format:String in formats)
                            {
                                var options:Array = ["2d", repeat ? "repeat" : "clamp"];
                                
                                if (format == Context3DTextureFormat.COMPRESSED)
                                    options.push("dxt1");
                                else if (format == "compressedAlpha")
                                    options.push("dxt5");
                                
                                if (smoothing == TextureSmoothing.NONE)
                                    options.push("nearest", mipmap ? "mipnearest" : "mipnone");
                                else if (smoothing == TextureSmoothing.BILINEAR)
                                    options.push("linear", mipmap ? "mipnearest" : "mipnone");
                                else
                                    options.push("linear", mipmap ? "miplinear" : "mipnone");
                                
                                fragmentProgramAssembler.assemble(Context3DProgramType.FRAGMENT,
                                    fragmentProgramCode.replace("???", options.join()));
                                
                                target.registerProgram(
                                    getImageProgramName(tinted, mipmap, repeat, format, smoothing),
                                    vertexProgramAssembler.agalcode, fragmentProgramAssembler.agalcode);
                            }
                        }
                    }
                }
            }
        }
        
        private static function getImageProgramName(tinted:Boolean, mipMap:Boolean=true, 
                                                    repeat:Boolean=false, format:String="bgra",
                                                    smoothing:String="bilinear"):String
        {
            var bitField:uint = 0;
            
            if (tinted) bitField |= 1;
            if (mipMap) bitField |= 1 << 1;
            if (repeat) bitField |= 1 << 2;
            
            if (smoothing == TextureSmoothing.NONE)
                bitField |= 1 << 3;
            else if (smoothing == TextureSmoothing.TRILINEAR)
                bitField |= 1 << 4;
            
            if (format == Context3DTextureFormat.COMPRESSED)
                bitField |= 1 << 5;
            else if (format == "compressedAlpha")
                bitField |= 1 << 6;
            
            var name:String = sProgramNameCache[bitField];
            
            if (name == null)
            {
                name = "QB_i." + bitField.toString(16);
                sProgramNameCache[bitField] = name;
            }
            
            return name;
        }
    }
}