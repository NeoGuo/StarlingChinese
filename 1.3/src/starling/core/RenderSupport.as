// =================================================================================================
//
//	Starling Framework
//	Copyright 2011 Gamua OG. All Rights Reserved.
//
//	This program is free software. You can redistribute and/or modify it
//	in accordance with the terms of the accompanying license agreement.
//
// =================================================================================================

package starling.core
{
    import com.adobe.utils.AGALMiniAssembler;
    
    import flash.display3D.Context3D;
    import flash.display3D.Context3DProgramType;
    import flash.display3D.Program3D;
    import flash.geom.Matrix;
    import flash.geom.Matrix3D;
    import flash.geom.Point;
    import flash.geom.Rectangle;
    
    import starling.display.BlendMode;
    import starling.display.DisplayObject;
    import starling.display.Quad;
    import starling.display.QuadBatch;
    import starling.errors.MissingContextError;
    import starling.textures.Texture;
    import starling.utils.Color;
    import starling.utils.MatrixUtil;

	/** 这个类 包含了简化Stage3D渲染的辅助方法.
	 *  RenderSupport实例可以被任意显示对象的“渲染”方法使用. 
	 *  它可以对当前变换矩阵和其它帮助方法进行处理 (与OpenGL 1.x的变换矩阵方法类似).
	 */
    public class RenderSupport
    {
        // members
        
        private var mProjectionMatrix:Matrix;
        private var mModelViewMatrix:Matrix;
        private var mMvpMatrix:Matrix;
        private var mMvpMatrix3D:Matrix3D;
        private var mMatrixStack:Vector.<Matrix>;
        private var mMatrixStackSize:int;
        private var mDrawCount:int;
        private var mBlendMode:String;

        private var mRenderTarget:Texture;
        private var mBackBufferWidth:int;
        private var mBackBufferHeight:int;
        private var mScissorRectangle:Rectangle;
        
        private var mQuadBatches:Vector.<QuadBatch>;
        private var mCurrentQuadBatchID:int;
        
        /** helper objects */
        private static var sPoint:Point = new Point();
        private static var sRectangle:Rectangle = new Rectangle();
        private static var sAssembler:AGALMiniAssembler = new AGALMiniAssembler();
        
        // construction
        
		/** 创建一个携带空矩阵堆的RenderSupport对象. */
        public function RenderSupport()
        {
            mProjectionMatrix = new Matrix();
            mModelViewMatrix = new Matrix();
            mMvpMatrix = new Matrix();
            mMvpMatrix3D = new Matrix3D();
            mMatrixStack = new <Matrix>[];
            mMatrixStackSize = 0;
            mDrawCount = 0;
            mRenderTarget = null;
            mBlendMode = BlendMode.NORMAL;
            mScissorRectangle = new Rectangle();
            
            mCurrentQuadBatchID = 0;
            mQuadBatches = new <QuadBatch>[new QuadBatch()];
            
            loadIdentity();
            setOrthographicProjection(0, 0, 400, 300);
        }
        
		/** 删除所四角面. */
        public function dispose():void
        {
            for each (var quadBatch:QuadBatch in mQuadBatches)
                quadBatch.dispose();
        }
        
        // matrix manipulation
        
		/** 设置正面二维渲染的矩阵映射. */
        public function setOrthographicProjection(x:Number, y:Number, width:Number, height:Number):void
        {
            mProjectionMatrix.setTo(2.0/width, 0, 0, -2.0/height, 
                -(2*x + width) / width, (2*y + height) / height);
        }
        
		/** 把模型视图矩阵变换为单位矩阵. */
        public function loadIdentity():void
        {
            mModelViewMatrix.identity();
        }
        
		/** 根据相应位移变化得到模型视图矩阵. */
        public function translateMatrix(dx:Number, dy:Number):void
        {
            MatrixUtil.prependTranslation(mModelViewMatrix, dx, dy);
        }
        
		/** 根据相应旋转变化得到模型视图矩阵. */
        public function rotateMatrix(angle:Number):void
        {
            MatrixUtil.prependRotation(mModelViewMatrix, angle);
        }
        
		/** 根据相应缩放变化得到模型视图矩阵. */
        public function scaleMatrix(sx:Number, sy:Number):void
        {
            MatrixUtil.prependScale(mModelViewMatrix, sx, sy);
        }
        
		/** 与另一矩阵相乘得到模型视图矩阵. */
        public function prependMatrix(matrix:Matrix):void
        {
            MatrixUtil.prependMatrix(mModelViewMatrix, matrix);
        }
        
		/** 根据对象的坐标变换，缩放和旋转生成模型视图矩阵. */
        public function transformMatrix(object:DisplayObject):void
        {
            MatrixUtil.prependMatrix(mModelViewMatrix, object.transformationMatrix);
        }
        
		/** 把当前模型视图矩阵推入堆中以便随后访问. */
        public function pushMatrix():void
        {
            if (mMatrixStack.length < mMatrixStackSize + 1)
                mMatrixStack.push(new Matrix());
            
            mMatrixStack[int(mMatrixStackSize++)].copyFrom(mModelViewMatrix);
        }
        
		/** 访问保存在堆中的模型视图矩阵. */
        public function popMatrix():void
        {
            mModelViewMatrix.copyFrom(mMatrixStack[int(--mMatrixStackSize)]);
        }
        
		/** 置空矩阵堆, 把模型视图矩阵重设为单位矩阵. */
        public function resetMatrix():void
        {
            mMatrixStackSize = 0;
            loadIdentity();
        }
        
		/** 把一个对象的位移，缩放和旋转转化为自定义矩阵. */
        public static function transformMatrixForObject(matrix:Matrix, object:DisplayObject):void
        {
            MatrixUtil.prependMatrix(matrix, object.transformationMatrix);
        }
        
		/** 计算模型视图矩阵和映射矩阵的商. 
		 *  注意：不要保存这个对象的引用！每次调用实际返回的是同一实例。 */
        public function get mvpMatrix():Matrix
        {
			mMvpMatrix.copyFrom(mModelViewMatrix);
            mMvpMatrix.concat(mProjectionMatrix);
            return mMvpMatrix;
        }
        
		/** 计算模型视图矩阵和映射矩阵的商保存到一个三维矩阵中. 
		 *  注意：不要保存这个对象的引用！每次调用实际返回的是同一实例。 */
        public function get mvpMatrix3D():Matrix3D
        {
            return MatrixUtil.convertTo3D(mvpMatrix, mMvpMatrix3D);
        }
        
		/** 返回当前模型视图矩阵. 注意：不是拷贝 - 小心使用! */
        public function get modelViewMatrix():Matrix { return mModelViewMatrix; }
        
		/** 返回当前映射矩阵. 注意：不是拷贝 - 小心使用! */
        public function get projectionMatrix():Matrix { return mProjectionMatrix; }
        
        // blending
        
		/** 在当前的渲染内容中使用合适的混合因数. */
        public function applyBlendMode(premultipliedAlpha:Boolean):void
        {
            setBlendFactors(premultipliedAlpha, mBlendMode);
        }
        
		/**
		 * 在渲染中将要使用的混合模式.要应用这个设置，您必须手工调用"applyBlendMode"方法(因为实际的混合因素依赖于对PMA模式)。
		 */		
        public function get blendMode():String { return mBlendMode; }
        public function set blendMode(value:String):void
        {
            if (value != BlendMode.AUTO) mBlendMode = value;
        }
        
        // 渲染目标
        
		/**当前即将被渲染的纹理，如果是'null'将渲染到后台缓冲区。如果您设置一个新对象，则它马上就会被启动。*/
        public function get renderTarget():Texture { return mRenderTarget; }
        public function set renderTarget(target:Texture):void 
        {
            mRenderTarget = target;
            
            if (target) Starling.context.setRenderToTexture(target.base);
            else        Starling.context.setRenderToBackBuffer();
        }
        
		/**
		 * 配置当前Context3D对象的后台缓冲区。
		 * 通过使用这个方法，Starling可以存储后台缓冲区的大小，并且在其它方法(比如矩形区域的裁切)中使用这个信息。
		 * 后台缓冲区的宽度和高度，可以在以后通过相同的属性名称来访问。
		 * @param width 宽度
		 * @param height 高度
		 * @param antiAlias 抗锯齿级别
		 * @param enableDepthAndStencil 是否开启深度和印模缓冲区
		 */        
        public function configureBackBuffer(width:int, height:int, antiAlias:int, 
                                            enableDepthAndStencil:Boolean):void
        {
            mBackBufferWidth  = width;
            mBackBufferHeight = height;
            Starling.context.configureBackBuffer(width, height, antiAlias, enableDepthAndStencil);
        }
        
        /** 后台缓冲区的宽度，它是被最后一次调用'RenderSupport.configureBackBuffer()'时确定的。
		 * 请注意：更改此值实际上并不会修改后台缓冲区的尺寸；setter方法只是用来通知Starling后台缓冲区的尺寸（它无法控制的情况，比如共享上下文的情况下）。
         */
        public function get backBufferWidth():int { return mBackBufferWidth; }
        public function set backBufferWidth(value:int):void { mBackBufferWidth = value; }
        
		/** 后台缓冲区的高度，它是被最后一次调用'RenderSupport.configureBackBuffer()'时确定的。
		 * 请注意：更改此值实际上并不会修改后台缓冲区的尺寸；setter方法只是用来通知Starling后台缓冲区的尺寸（它无法控制的情况，比如共享上下文的情况下）。
		 */
        public function get backBufferHeight():int { return mBackBufferHeight; }
        public function set backBufferHeight(value:int):void { mBackBufferHeight = value; }
        
        // scissor rect
        
        /** 裁切矩形可以被用于限制当前渲染目标到一个指定的区域。
		 * 这个方法需要stage坐标系中的一个矩形(和Context3D的同名方法不同，它使用的是像素)。传递null将关闭裁剪。注意：这不是一个副本，小心使用！*/ 
        public function get scissorRectangle():Rectangle 
        { 
            return mScissorRectangle.isEmpty() ? null : mScissorRectangle; 
        }
        public function set scissorRectangle(value:Rectangle):void
        {
            if (value)
            {
                mScissorRectangle.setTo(value.x, value.y, value.width, value.height);

                var width:int  = mRenderTarget ? mRenderTarget.root.nativeWidth  : mBackBufferWidth;
                var height:int = mRenderTarget ? mRenderTarget.root.nativeHeight : mBackBufferHeight;
                
                MatrixUtil.transformCoords(mProjectionMatrix, value.x, value.y, sPoint);
                sRectangle.x = Math.max(0, ( sPoint.x + 1) / 2) * width;
                sRectangle.y = Math.max(0, (-sPoint.y + 1) / 2) * height;
                
                MatrixUtil.transformCoords(mProjectionMatrix, value.right, value.bottom, sPoint);
                sRectangle.right  = Math.min(1, ( sPoint.x + 1) / 2) * width;
                sRectangle.bottom = Math.min(1, (-sPoint.y + 1) / 2) * height;
                
                Starling.context.setScissorRectangle(sRectangle);
            }
            else 
            {
                mScissorRectangle.setEmpty();
                Starling.context.setScissorRectangle(null);
            }
        }
        
        // optimized quad rendering
        
		/** 在当前未渲染的四角面组中添加一个四角面. 如果当前状态改变则立即渲染之前组中四角面,然后重置当前组。 */
        public function batchQuad(quad:Quad, parentAlpha:Number, 
                                  texture:Texture=null, smoothing:String=null):void
        {
            if (mQuadBatches[mCurrentQuadBatchID].isStateChange(quad.tinted, parentAlpha, texture, 
                                                                smoothing, mBlendMode))
            {
                finishQuadBatch();
            }
            
            mQuadBatches[mCurrentQuadBatchID].addQuad(quad, parentAlpha, texture, smoothing, 
                                                      mModelViewMatrix, mBlendMode);
        }
        
		/** 渲染当前四角面组然后重置. */
        public function finishQuadBatch():void
        {
            var currentBatch:QuadBatch = mQuadBatches[mCurrentQuadBatchID];
            
            if (currentBatch.numQuads != 0)
            {
                currentBatch.renderCustom(mProjectionMatrix);
                currentBatch.reset();
                
                ++mCurrentQuadBatchID;
                ++mDrawCount;
                
                if (mQuadBatches.length <= mCurrentQuadBatchID)
                    mQuadBatches.push(new QuadBatch());
            }
        }
        
		/** 重置矩阵和混合模式堆，四角面组索引,和绘画计数。*/
        public function nextFrame():void
        {
            resetMatrix();
            mBlendMode = BlendMode.NORMAL;
            mCurrentQuadBatchID = 0;
            mDrawCount = 0;
        }
        
        // other helper methods
        
		/** 不再使用。调用'setBlendFactors'方法. */
        public static function setDefaultBlendFactors(premultipliedAlpha:Boolean):void
        {
            setBlendFactors(premultipliedAlpha);
        }
        
		/** 设置相应混合模式的混合参数. 
		 * @param premultipliedAlpha 是否预乘透明度
		 * @param blendMode 混合模式，默认是normal
		 **/
        public static function setBlendFactors(premultipliedAlpha:Boolean, blendMode:String="normal"):void
        {
            var blendFactors:Array = BlendMode.getBlendFactors(blendMode, premultipliedAlpha); 
            Starling.context.setBlendFactors(blendFactors[0], blendFactors[1]);
        }
        
		/** 以特定颜色和透明度清除渲染内容. 
		 * @param rgb RGB色值
		 * @param alpha 透明度
		 **/
        public static function clear(rgb:uint=0, alpha:Number=0.0):void
        {
            Starling.context.clear(
                Color.getRed(rgb)   / 255.0, 
                Color.getGreen(rgb) / 255.0, 
                Color.getBlue(rgb)  / 255.0,
                alpha);
        }
        
        /** 以特定颜色和透明度清除渲染内容. 
		 * @param rgb RGB色值
		 * @param alpha 透明度
		 **/
        public function clear(rgb:uint=0, alpha:Number=0.0):void
        {
            RenderSupport.clear(rgb, alpha);
        }
        
		/**
		 * 汇编通过字符串传递的片段和顶点着色器到Program3D中。如果您传递了一个'resultProgram'参数，那么结果就会上传到传入的这个Program3D对象中。
		 * 否则，将从当前的Stage3D上下文中，创建一个新的Program3D对象。
		 * @param vertexShader 顶点着色器源码
		 * @param fragmentShader 片段着色器源码
		 * @param resultProgram Program3D对象
		 * @return Program3D对象
		 */		
        public static function assembleAgal(vertexShader:String, fragmentShader:String,
                                            resultProgram:Program3D=null):Program3D
        {
            if (resultProgram == null) 
            {
                var context:Context3D = Starling.context;
                if (context == null) throw new MissingContextError();
                resultProgram = context.createProgram();
            }
            
            resultProgram.upload(
                sAssembler.assemble(Context3DProgramType.VERTEX, vertexShader),
                sAssembler.assemble(Context3DProgramType.FRAGMENT, fragmentShader));
            
            return resultProgram;
        }
        
        // statistics
        
		/** 提升绘制计数特定的数值.在调用自定义渲染方法时调用这个方法来保持渲染数据的同步 */
        public function raiseDrawCount(value:uint=1):void { mDrawCount += value; }
        
		/** 指出stage3D绘制调用次数. */
        public function get drawCount():int { return mDrawCount; }
        
    }
}