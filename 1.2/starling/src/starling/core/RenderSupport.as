// =================================================================================================
//
//	Starling 框架
//	版权信息  2012 Gamua OG. 所有权利保留.
//
//	这个程序是免费软件. 你可以在协议范围内自由修改和再发布.
//
// =================================================================================================


package starling.core
{
    import flash.geom.*;
    
    import starling.display.*;
    import starling.textures.Texture;
    import starling.utils.*;

	/** 这个类 包含了简化Stage3D渲染的辅助方法.
	 *
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
        private var mBlendModeStack:Vector.<String>;
        
        private var mQuadBatches:Vector.<QuadBatch>;
        private var mCurrentQuadBatchID:int;
        
		// 构造
        
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
            
            mBlendMode = BlendMode.NORMAL;
            mBlendModeStack = new <String>[];
            
            mCurrentQuadBatchID = 0;
            mQuadBatches = new <QuadBatch>[new QuadBatch()];
            
            loadIdentity();
            setOrthographicProjection(400, 300);
        }
        
		/** 删除所四角面. */
        public function dispose():void
        {
            for each (var quadBatch:QuadBatch in mQuadBatches)
                quadBatch.dispose();
        }
        
		// 矩阵处理
		
		/** 设置正面二维渲染的矩阵映射. */
        public function setOrthographicProjection(width:Number, height:Number):void
        {
            mProjectionMatrix.setTo(2.0/width, 0, 0, -2.0/height, -1.0, 1.0);
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
            
            mMatrixStack[mMatrixStackSize++].copyFrom(mModelViewMatrix);
        }
        
		/** 访问保存在堆中的模型视图矩阵. */
        public function popMatrix():void
        {
            mModelViewMatrix.copyFrom(mMatrixStack[--mMatrixStackSize]);
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
        
		// 混合
        
		/** 把当前混合模式存入堆中以便随后访问. */
        public function pushBlendMode():void
        {
            mBlendModeStack.push(mBlendMode);
        }
        
        /** 访问之前推入堆中的混合模式. */
        public function popBlendMode():void
        {
            mBlendMode = mBlendModeStack.pop();
        }
        
		/** 清除混合模式堆中数据恢复到默认普通混合模式. */
        public function resetBlendMode():void
        {
            mBlendModeStack.length = 0;
            mBlendMode = BlendMode.NORMAL;
        }
        
		/** 在当前的渲染内容中使用合适的混合因数. */
        public function applyBlendMode(premultipliedAlpha:Boolean):void
        {
            setBlendFactors(premultipliedAlpha, mBlendMode);
        }
        
		/** 在渲染中将要使用的混合模式. */
        public function get blendMode():String { return mBlendMode; }
        public function set blendMode(value:String):void
        {
            if (value != BlendMode.AUTO) mBlendMode = value;
        }
        
        // 优化四角面渲染
        
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
            resetBlendMode();
            mCurrentQuadBatchID = 0;
            mDrawCount = 0;
        }
        
		// 其它帮助方法
        
		/** 不再使用。调用'setBlendFactors'方法. */
        public static function setDefaultBlendFactors(premultipliedAlpha:Boolean):void
        {
            setBlendFactors(premultipliedAlpha);
        }
        
		/** 设置相应混合模式的混合参数. */
        public static function setBlendFactors(premultipliedAlpha:Boolean, blendMode:String="normal"):void
        {
            var blendFactors:Array = BlendMode.getBlendFactors(blendMode, premultipliedAlpha); 
            Starling.context.setBlendFactors(blendFactors[0], blendFactors[1]);
        }
        
		/** 以特定颜色和透明度清除渲染内容. */
        public static function clear(rgb:uint=0, alpha:Number=0.0):void
        {
            Starling.context.clear(
                Color.getRed(rgb)   / 255.0, 
                Color.getGreen(rgb) / 255.0, 
                Color.getBlue(rgb)  / 255.0,
                alpha);
        }
        
		// 数据统计
        
		/** 提升绘制计数特定的数值.在调用自定义渲染方法时调用这个方法来保持渲染数据的同步 */
        public function raiseDrawCount(value:uint=1):void { mDrawCount += value; }
        
		/** 指出stage3D绘制调用次数. */
        public function get drawCount():int { return mDrawCount; }
        
    }
}