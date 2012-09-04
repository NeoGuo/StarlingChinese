// =================================================================================================
//
//    Starling Framework
//	Copyright 2011 Gamua OG. All Rights Reserved.
//
//	This program is free software. You can redistribute and/or modify it
//	in accordance with the terms of the accompanying license agreement.
//
// =================================================================================================

package starling.utils
{
    import flash.geom.Matrix;
    import flash.geom.Matrix3D;
    import flash.geom.Point;
    
    import starling.errors.AbstractClassError;

    /** 一个包含矩阵相关方法的类 */
    public class MatrixUtil
    {
        /** 有用的对象 */
        private static var sRawData:Vector.<Number> = 
            new <Number>[1, 0, 0, 0,  0, 1, 0, 0,  0, 0, 1, 0,  0, 0, 0, 1];
        
        /** @private */
        public function MatrixUtil() { throw new AbstractClassError(); }
        
        /** 2D矩阵转换为3D矩阵.如果传入'resultMatrix',则结果会存储在这个矩阵中，而不是创建一个新对象. */
        public static function convertTo3D(matrix:Matrix, resultMatrix:Matrix3D=null):Matrix3D
        {
            if (resultMatrix == null) resultMatrix = new Matrix3D();
            
            sRawData[0] = matrix.a;
            sRawData[1] = matrix.b;
            sRawData[4] = matrix.c;
            sRawData[5] = matrix.d;
            sRawData[12] = matrix.tx;
            sRawData[13] = matrix.ty;
            
            resultMatrix.copyRawDataFrom(sRawData);
            return resultMatrix;
        }
        
        /** 用一个矩阵转换2D坐标到另一个不同的空间.如果传入'resultPoint',则结果会存储在这个点里，而不是创建一个新对象. */
        public static function transformCoords(matrix:Matrix, x:Number, y:Number,
                                               resultPoint:Point=null):Point
        {
            if (resultPoint == null) resultPoint = new Point();   
            
            resultPoint.x = matrix.a * x + matrix.c * y + matrix.tx;
            resultPoint.y = matrix.d * y + matrix.b * x + matrix.ty;
            
            return resultPoint;
        }
        
        /** 以一定的弧度附加一个扭曲转换到矩阵中. */
        public static function skew(matrix:Matrix, skewX:Number, skewY:Number):void
        {
            var a:Number    = matrix.a;
            var b:Number    = matrix.b;
            var c:Number    = matrix.c;
            var d:Number    = matrix.d;
            var tx:Number   = matrix.tx;
            var ty:Number   = matrix.ty;
            
            var sinX:Number = Math.sin(skewX);
            var cosX:Number = Math.cos(skewX);
            var sinY:Number = Math.sin(skewY);
            var cosY:Number = Math.cos(skewY);
            
            matrix.a = a * cosY + c * sinY;
            matrix.b = b * cosY + d * sinY;
            matrix.c = c * cosX - a * sinX;
            matrix.d = d * cosX - b * sinX;
        }
        
        /** 通过与另一矩阵相乘，追加矩阵到'base'. */
        public static function prependMatrix(base:Matrix, prep:Matrix):void
        {
            base.setTo(base.a * prep.a + base.c * prep.b,
                       base.b * prep.a + base.d * prep.b,
                       base.a * prep.c + base.c * prep.d,
                       base.b * prep.c + base.d * prep.d,
                       base.tx + base.a * prep.tx + base.c * prep.ty,
                       base.ty + base.b * prep.tx + base.d * prep.ty);
        }
        
        /** 追加一个增量位移到矩阵中. */
        public static function prependTranslation(matrix:Matrix, tx:Number, ty:Number):void
        {
            matrix.tx += matrix.a * tx + matrix.c * ty;
            matrix.ty += matrix.b * tx + matrix.d * ty;
        }
        
        /** 追加一个增量缩放变换到矩阵中. */
        public static function prependScale(matrix:Matrix, sx:Number, sy:Number):void
        {
            matrix.setTo(matrix.a * sx, matrix.b * sx, 
                         matrix.c * sy, matrix.d * sy,
                         matrix.tx, matrix.ty);
        }
        
        /** 追加一个增量旋转到Matrix3D中. */
        public static function prependRotation(matrix:Matrix, angle:Number):void
        {
            var sin:Number = Math.sin(angle);
            var cos:Number = Math.cos(angle);
            
            matrix.setTo(matrix.a * cos + matrix.c * sin,  matrix.b * cos + matrix.d * sin,
                         matrix.c * cos - matrix.a * sin,  matrix.d * cos - matrix.b * sin,
                         matrix.tx, matrix.ty);
        }
    }
}