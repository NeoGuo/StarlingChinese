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
    import flash.geom.Rectangle;
    
    import starling.errors.AbstractClassError;

    /** 一个增强Rectangle类功能的工具类. */
    public class RectangleUtil
    {
        /** @private */
        public function RectangleUtil() { throw new AbstractClassError(); }
        
		/**
		 * 计算在两个矩形的交集。如果矩形不相交，则此方法返回一个空的Rectangle对象，其属性设置为0。
		 * @param rect1 矩形1
		 * @param rect2 矩形2
		 * @param resultRect 返回的矩形
		 * @return Rectangle
		 */		
        public static function intersect(rect1:Rectangle, rect2:Rectangle, 
                                         resultRect:Rectangle=null):Rectangle
        {
            if (resultRect == null) resultRect = new Rectangle();
            
            var left:Number   = Math.max(rect1.x, rect2.x);
            var right:Number  = Math.min(rect1.x + rect1.width, rect2.x + rect2.width);
            var top:Number    = Math.max(rect1.y, rect2.y);
            var bottom:Number = Math.min(rect1.y + rect1.height, rect2.y + rect2.height);
            
            if (left > right || top > bottom)
                resultRect.setEmpty();
            else
                resultRect.setTo(left, top, right-left, bottom-top);
            
            return resultRect;
        }
        
		/**
		 * 根据等比缩放的原则计算传入的'rectangle'(矩形)，并相对于'into'(矩形)来居中。
		 * <p>这个方法可用于根据指定的显示尺寸，计算最佳的viewPort区域。你可以使用不同的缩放模式，从而得到不同的计算结果。
		 * 此外，你可以通过只允许全数字相乘/相除(比如3，2，1，1/2，1/3)来避免像素排列错误。</p>
		 * @param rectangle 原显示尺寸
		 * @param into 屏幕可用区域
		 * @param scaleMode 缩放模式
		 * @param pixelPerfect 避免像素排列错误
		 * @param resultRect 如果设置了这个选项，则结果存储在这个对象中
		 * @return Rectangle
		 * @see starling.utils.ScaleMode
		 */		
        public static function fit(rectangle:Rectangle, into:Rectangle, 
                                   scaleMode:String="showAll", pixelPerfect:Boolean=false,
                                   resultRect:Rectangle=null):Rectangle
        {
            if (!ScaleMode.isValid(scaleMode)) throw new ArgumentError("Invalid scaleMode: " + scaleMode);
            if (resultRect == null) resultRect = new Rectangle();
            
            var width:Number   = rectangle.width;
            var height:Number  = rectangle.height;
            var factorX:Number = into.width  / width;
            var factorY:Number = into.height / height;
            var factor:Number  = 1.0;
            
            if (scaleMode == ScaleMode.SHOW_ALL)
            {
                factor = factorX < factorY ? factorX : factorY;
                if (pixelPerfect) factor = nextSuitableScaleFactor(factor, false);
            }
            else if (scaleMode == ScaleMode.NO_BORDER)
            {
                factor = factorX > factorY ? factorX : factorY;
                if (pixelPerfect) factor = nextSuitableScaleFactor(factor, true);
            }
            
            width  *= factor;
            height *= factor;
            
            resultRect.setTo(
                into.x + (into.width  - width)  / 2,
                into.y + (into.height - height) / 2,
                width, height);
            
            return resultRect;
        }
        
        /** Calculates the next whole-number multiplier or divisor, moving either up or down. */
        private static function nextSuitableScaleFactor(factor:Number, up:Boolean):Number
        {
            var divisor:Number = 1.0;
            
            if (up)
            {
                if (factor >= 0.5) return Math.ceil(factor);
                else
                {
                    while (1.0 / (divisor + 1) > factor)
                        ++divisor;
                }
            }
            else
            {
                if (factor >= 1.0) return Math.floor(factor);
                else
                {
                    while (1.0 / divisor > factor)
                        ++divisor;
                }
            }
            
            return 1.0 / divisor;
        }
    }
}