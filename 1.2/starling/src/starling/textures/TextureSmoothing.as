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
    import starling.errors.AbstractClassError;

    /** 这个类为可能的材质平滑算法提供常量值。 */ 
    public class TextureSmoothing
    {
        /** @private */
        public function TextureSmoothing() { throw new AbstractClassError(); }
        
        /** 不具备平滑, 通常称之为"Nearest Neighbor"。像素将放大成大个的矩形。 */
        public static const NONE:String      = "none";
        
        /** 双线性过滤。创建像素间的平滑过渡。 */
        public static const BILINEAR:String  = "bilinear";
        
        /** 三线性过滤。通过考虑使用更高级别的MIP映射.实现最高级别的渲染质量。 */
        public static const TRILINEAR:String = "trilinear";
        
        /** 确定一个平滑值是否是有效的。 */
        public static function isValid(smoothing:String):Boolean
        {
            return smoothing == NONE || smoothing == BILINEAR || smoothing == TRILINEAR;
        }
    }
}