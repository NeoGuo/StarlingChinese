// =================================================================================================
//
//	Starling Framework
//	Copyright 2012 Gamua OG. All Rights Reserved.
//
//	This program is free software. You can redistribute and/or modify it
//	in accordance with the terms of the accompanying license agreement.
//
// =================================================================================================

package starling.utils
{
    import flash.geom.Matrix;
    import flash.geom.Point;

	/** 用一个矩阵转换2D坐标到另一个不同的空间.如果传入'resultPoint',则结果会存储在这个点里，而不是创建一个新对象. */
    public function transformCoords(matrix:Matrix, x:Number, y:Number,
                                    resultPoint:Point=null):Point
    {
        if (!deprecationNotified)
        {
            deprecationNotified = true;
            trace("[Starling] The method 'transformCoords' is deprecated. " + 
                  "Please use 'MatrixUtil.transformCoords' instead.");
        }
        
        if (resultPoint == null) resultPoint = new Point();   
        
        resultPoint.x = matrix.a * x + matrix.c * y + matrix.tx;
        resultPoint.y = matrix.d * y + matrix.b * x + matrix.ty;
        
        return resultPoint;
    }
}

var deprecationNotified:Boolean = false;