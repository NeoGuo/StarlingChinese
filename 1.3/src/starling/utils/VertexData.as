// =================================================================================================
//
//	Starling Framework
//	Copyright 2011 Gamua OG. All Rights Reserved.
//
//	This program is free software. You can redistribute and/or modify it
//	in accordance with the terms of the accompanying license agreement.
//
// =================================================================================================

package starling.utils
{
    import flash.geom.Matrix;
    import flash.geom.Point;
    import flash.geom.Rectangle;
    
	/** 
	 * 顶点数据类，它管理一个顶点信息的原始数据列表，允许直接上传到Stage3D顶点缓冲池中.
	 * <em>
	 * 如果想用自定义渲染函数创建显示对象，则必须使用此类。如果不打算这种做，你可以安全的忽略它。
	 * </em>
	 * 
	 *  <p>
	 * 要用Stage3D渲染对象，你得组织顶点数据到所谓的顶点缓冲池中。
	 * 这些缓冲池位于图像内存中，并可以非常高效的被GPU访问。
	 * 在你把数据放入顶点缓冲池之前，你得把它设置到普通内存中 - 也就是在一个矢量对象中。
	 * 这个矢量包括所有顶点信息 (坐标，颜色，纹理坐标) - 一个顶点接下一个顶点。</p>
	 *  
	 *  <p>
	 * 为了简化和工作一个如此庞大的列表，需要创建这个顶点数据类。它包括指定和修改顶点数据的方法。
	 * 这个原始矢量由很容易上传到顶点缓冲池的类管理</p>
	 * 
	 *  <strong>自左乘Alpha</strong>
	 *  
	 *  <p>
	 * "BitmapData"对象的颜色值包括自左乘alpha值，这意味着<code>rgb</code>值在保存前，会与<code>alpha</code>相乘。
	 * 自从纹理从位图数据中被创建，他们包括同样格式的值。当渲染的时候，它会以alpha值被保存的方式产生差异；
	 * 出于这个原因，顶点数据类模拟了这个行为。你可以选择这个alpha应该通过<code>premultipliedAlpha</code>属性被如何处理。</p>
	 * 
	 */ 
    public class VertexData 
    {
		/** 存储每个顶点元素的总数量. */
        public static const ELEMENTS_PER_VERTEX:int = 8;
        
		/** 每个顶点内的位置数据 (x, y) 偏移量. */
        public static const POSITION_OFFSET:int = 0;
        
		/** 每个顶点内的颜色数据 (r, g, b, a) 偏移量. */ 
        public static const COLOR_OFFSET:int = 2;
        
		/** 每个顶点内的坐标数据 (u, v) 偏移量. */
        public static const TEXCOORD_OFFSET:int = 6;
        
        private var mRawData:Vector.<Number>;
        private var mPremultipliedAlpha:Boolean;
        private var mNumVertices:int;

        /** Helper object. */
        private static var sHelperPoint:Point = new Point();
        
		/** 用指定的顶点数创建一个新的顶点数据. */
        public function VertexData(numVertices:int, premultipliedAlpha:Boolean=false)
        {
            mRawData = new <Number>[];
            mPremultipliedAlpha = premultipliedAlpha;
            this.numVertices = numVertices;
        }

		/** 创建一个完成顶点数据对象或子集的一个副本. 
		 *  克隆所有顶点，'numVertices'值默认为 '-1'. */
        public function clone(vertexID:int=0, numVertices:int=-1):VertexData
        {
            if (numVertices < 0 || vertexID + numVertices > mNumVertices)
                numVertices = mNumVertices - vertexID;
            
            var clone:VertexData = new VertexData(0, mPremultipliedAlpha);
            clone.mNumVertices = numVertices; 
            clone.mRawData = mRawData.slice(vertexID * ELEMENTS_PER_VERTEX, 
                                            numVertices * ELEMENTS_PER_VERTEX); 
            clone.mRawData.fixed = true;
            return clone;
        }
        
		/** 拷贝改实例的顶点数据(或者它的一个范围，由'vertexID' 和 'numVertices'定义) 
		 *  到另一个顶点数据对象，从某个确定索引算起. */
        public function copyTo(targetData:VertexData, targetVertexID:int=0,
                               vertexID:int=0, numVertices:int=-1):void
        {
            if (numVertices < 0 || vertexID + numVertices > mNumVertices)
                numVertices = mNumVertices - vertexID;
            
            // todo: check/convert pma
            
            var targetRawData:Vector.<Number> = targetData.mRawData;
            var targetIndex:int = targetVertexID * ELEMENTS_PER_VERTEX;
            var sourceIndex:int = vertexID * ELEMENTS_PER_VERTEX;
            var dataLength:int = numVertices * ELEMENTS_PER_VERTEX;
            
            for (var i:int=sourceIndex; i<dataLength; ++i)
                targetRawData[int(targetIndex++)] = mRawData[i];
        }
        
		/** 从另一个顶点数据对象中追加顶点. */
        public function append(data:VertexData):void
        {
            mRawData.fixed = false;
            
            var targetIndex:int = mRawData.length;
            var rawData:Vector.<Number> = data.mRawData;
            var rawDataLength:int = rawData.length;
            
            for (var i:int=0; i<rawDataLength; ++i)
                mRawData[int(targetIndex++)] = rawData[i];
            
            mNumVertices += data.numVertices;
            mRawData.fixed = true;
        }
        
        // functions
        
		/** 更新顶点位置. */
        public function setPosition(vertexID:int, x:Number, y:Number):void
        {
            var offset:int = getOffset(vertexID) + POSITION_OFFSET;
            mRawData[offset] = x;
            mRawData[int(offset+1)] = y;
        }
        
		/** 返回顶点位置. */
        public function getPosition(vertexID:int, position:Point):void
        {
            var offset:int = getOffset(vertexID) + POSITION_OFFSET;
            position.x = mRawData[offset];
            position.y = mRawData[int(offset+1)];
        }
        
		/** 更新顶点RGB值. */ 
        public function setColor(vertexID:int, color:uint):void
        {   
            var offset:int = getOffset(vertexID) + COLOR_OFFSET;
            var multiplier:Number = mPremultipliedAlpha ? mRawData[int(offset+3)] : 1.0;
            mRawData[offset]        = ((color >> 16) & 0xff) / 255.0 * multiplier;
            mRawData[int(offset+1)] = ((color >>  8) & 0xff) / 255.0 * multiplier;
            mRawData[int(offset+2)] = ( color        & 0xff) / 255.0 * multiplier;
        }
        
		/** 返回顶点RGB值 (无alpha). */
        public function getColor(vertexID:int):uint
        {
            var offset:int = getOffset(vertexID) + COLOR_OFFSET;
            var divisor:Number = mPremultipliedAlpha ? mRawData[int(offset+3)] : 1.0;
            
            if (divisor == 0) return 0;
            else
            {
                var red:Number   = mRawData[offset]        / divisor;
                var green:Number = mRawData[int(offset+1)] / divisor;
                var blue:Number  = mRawData[int(offset+2)] / divisor;
                
                return (int(red*255) << 16) | (int(green*255) << 8) | int(blue*255);
            }
        }
        
		/** 更新顶点Aplha值 (范围 0-1). */
        public function setAlpha(vertexID:int, alpha:Number):void
        {
            var offset:int = getOffset(vertexID) + COLOR_OFFSET + 3;
            
            if (mPremultipliedAlpha)
            {
                if (alpha < 0.001) alpha = 0.001; // zero alpha would wipe out all color data
                var color:uint = getColor(vertexID);
                mRawData[offset] = alpha;
                setColor(vertexID, color);
            }
            else
            {
                mRawData[offset] = alpha;
            }
        }
        
		/** 返回顶点Aplha值 (范围 0-1). */
        public function getAlpha(vertexID:int):Number
        {
            var offset:int = getOffset(vertexID) + COLOR_OFFSET + 3;
            return mRawData[offset];
        }
        
		/** 更新顶点纹理坐标值 (范围 0-1). */
        public function setTexCoords(vertexID:int, u:Number, v:Number):void
        {
            var offset:int = getOffset(vertexID) + TEXCOORD_OFFSET;
            mRawData[offset]        = u;
            mRawData[int(offset+1)] = v;
        }
        
		/** 返回顶点纹理坐标值 (范围 0-1). */
        public function getTexCoords(vertexID:int, texCoords:Point):void
        {
            var offset:int = getOffset(vertexID) + TEXCOORD_OFFSET;
            texCoords.x = mRawData[offset];
            texCoords.y = mRawData[int(offset+1)];
        }
        
        // utility functions
        
		/** 以一定偏移量来移动顶点位置. */
        public function translateVertex(vertexID:int, deltaX:Number, deltaY:Number):void
        {
            var offset:int = getOffset(vertexID) + POSITION_OFFSET;
            mRawData[offset]        += deltaX;
            mRawData[int(offset+1)] += deltaY;
        }

		/** 通过与一个转换矩阵来转换后面的顶点位置. */
        public function transformVertex(vertexID:int, matrix:Matrix, numVertices:int=1):void
        {
            var offset:int = getOffset(vertexID) + POSITION_OFFSET;
            
            for (var i:int=0; i<numVertices; ++i)
            {
                var x:Number = mRawData[offset];
                var y:Number = mRawData[int(offset+1)];
                
                mRawData[offset]        = matrix.a * x + matrix.c * y + matrix.tx;
                mRawData[int(offset+1)] = matrix.d * y + matrix.b * x + matrix.ty;
                
                offset += ELEMENTS_PER_VERTEX;
            }
        }
        
		/** 对所有顶点设置相同的颜色值. */
        public function setUniformColor(color:uint):void
        {
            for (var i:int=0; i<mNumVertices; ++i)
                setColor(i, color);
        }
        
		/** 对所有顶点设置相同的alpha值. */
        public function setUniformAlpha(alpha:Number):void
        {
            for (var i:int=0; i<mNumVertices; ++i)
                setAlpha(i, alpha);
        }
        
		/** 对指定的顶点alpha值乘以某个delta. */
        public function scaleAlpha(vertexID:int, alpha:Number, numVertices:int=1):void
        {
            if (alpha == 1.0) return;
            if (numVertices < 0 || vertexID + numVertices > mNumVertices)
                numVertices = mNumVertices - vertexID;
             
            var i:int;
            
            if (mPremultipliedAlpha)
            {
                for (i=0; i<numVertices; ++i)
                    setAlpha(vertexID+i, getAlpha(vertexID+i) * alpha);
            }
            else
            {
                var offset:int = getOffset(vertexID) + COLOR_OFFSET + 3;
                for (i=0; i<numVertices; ++i)
                    mRawData[int(offset + i*ELEMENTS_PER_VERTEX)] *= alpha;
            }
        }
        
        private function getOffset(vertexID:int):int
        {
            return vertexID * ELEMENTS_PER_VERTEX;
        }
        
		/** 计算顶点范围，可以选择性的通过矩阵进行转换. 
		 *  如果传递resultRect，结果会保存在这个矩阵中，而不会创建一个新对象.
		 *  要给所有顶点计算，设置'numVertices' 为 '-1'. */
        public function getBounds(transformationMatrix:Matrix=null, 
                                  vertexID:int=0, numVertices:int=-1,
                                  resultRect:Rectangle=null):Rectangle
        {
            if (resultRect == null) resultRect = new Rectangle();
            if (numVertices < 0 || vertexID + numVertices > mNumVertices)
                numVertices = mNumVertices - vertexID;
            
            var minX:Number = Number.MAX_VALUE, maxX:Number = -Number.MAX_VALUE;
            var minY:Number = Number.MAX_VALUE, maxY:Number = -Number.MAX_VALUE;
            var offset:int = getOffset(vertexID) + POSITION_OFFSET;
            var x:Number, y:Number, i:int;
            
            if (transformationMatrix == null)
            {
                for (i=vertexID; i<numVertices; ++i)
                {
                    x = mRawData[offset];
                    y = mRawData[int(offset+1)];
                    offset += ELEMENTS_PER_VERTEX;
                    
                    minX = minX < x ? minX : x;
                    maxX = maxX > x ? maxX : x;
                    minY = minY < y ? minY : y;
                    maxY = maxY > y ? maxY : y;
                }
            }
            else
            {
                for (i=vertexID; i<numVertices; ++i)
                {
                    x = mRawData[offset];
                    y = mRawData[int(offset+1)];
                    offset += ELEMENTS_PER_VERTEX;
                    
                    MatrixUtil.transformCoords(transformationMatrix, x, y, sHelperPoint);
                    minX = minX < sHelperPoint.x ? minX : sHelperPoint.x;
                    maxX = maxX > sHelperPoint.x ? maxX : sHelperPoint.x;
                    minY = minY < sHelperPoint.y ? minY : sHelperPoint.y;
                    maxY = maxY > sHelperPoint.y ? maxY : sHelperPoint.y;
                }
            }
            
            resultRect.setTo(minX, minY, maxX - minX, maxY - minY);
            return resultRect;
        }
        
        // properties
        
		/** 返回所有顶点是否非白或完全透明. */
        public function get tinted():Boolean
        {
            var offset:int = COLOR_OFFSET;
            
            for (var i:int=0; i<mNumVertices; ++i)
            {
                for (var j:int=0; j<4; ++j)
                    if (mRawData[int(offset+j)] != 1.0) return true;

                offset += ELEMENTS_PER_VERTEX;
            }
            
            return false;
        }
        
		/** 改变alpha和颜色值的存储方式. 更新所有存在的顶点. */
        public function setPremultipliedAlpha(value:Boolean, updateData:Boolean=true):void
        {
            if (value == mPremultipliedAlpha) return;
            
            if (updateData)
            {
                var dataLength:int = mNumVertices * ELEMENTS_PER_VERTEX;
                
                for (var i:int=COLOR_OFFSET; i<dataLength; i += ELEMENTS_PER_VERTEX)
                {
                    var alpha:Number = mRawData[int(i+3)];
                    var divisor:Number = mPremultipliedAlpha ? alpha : 1.0;
                    var multiplier:Number = value ? alpha : 1.0;
                    
                    if (divisor != 0)
                    {
                        mRawData[i]        = mRawData[i]        / divisor * multiplier;
                        mRawData[int(i+1)] = mRawData[int(i+1)] / divisor * multiplier;
                        mRawData[int(i+2)] = mRawData[int(i+2)] / divisor * multiplier;
                    }
                }
            }
            
            mPremultipliedAlpha = value;
        }
        
		/** 返回存储的rgb值是否与此apha值左自乘. */
        public function get premultipliedAlpha():Boolean { return mPremultipliedAlpha; }
        
		/** 顶点总数. */
        public function get numVertices():int { return mNumVertices; }
        public function set numVertices(value:int):void
        {
            mRawData.fixed = false;
            
            var i:int;
            var delta:int = value - mNumVertices;
            
            for (i=0; i<delta; ++i)
                mRawData.push(0, 0,  0, 0, 0, 1,  0, 0); // alpha should be '1' per default
            
            for (i=0; i<-(delta*ELEMENTS_PER_VERTEX); ++i)
                mRawData.pop();
            
            mNumVertices = value;
            mRawData.fixed = true;
        }
        
		/** 原始顶点数据; 非克隆数据! */
        public function get rawData():Vector.<Number> { return mRawData; }
    }
}