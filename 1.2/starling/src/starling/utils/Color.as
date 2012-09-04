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
    import starling.errors.AbstractClassError;

    /** 一个非常有用的类，包含在不用颜色表现间转换的预定义颜色和方法. */
	
    public class Color
    {
        public static const WHITE:uint   = 0xffffff;
        public static const SILVER:uint  = 0xc0c0c0;
        public static const GRAY:uint    = 0x808080;
        public static const BLACK:uint   = 0x000000;
        public static const RED:uint     = 0xff0000;
        public static const MAROON:uint  = 0x800000;
        public static const YELLOW:uint  = 0xffff00;
        public static const OLIVE:uint   = 0x808000;
        public static const LIME:uint    = 0x00ff00;
        public static const GREEN:uint   = 0x008000;
        public static const AQUA:uint    = 0x00ffff;
        public static const TEAL:uint    = 0x008080;
        public static const BLUE:uint    = 0x0000ff;
        public static const NAVY:uint    = 0x000080;
        public static const FUCHSIA:uint = 0xff00ff;
        public static const PURPLE:uint  = 0x800080;
        
        /** 返回ARGB的alpha部分(0 - 255).*/
        public static function getAlpha(color:uint):int { return (color >> 24) & 0xff; }
        
        /** 返回(A)RGB的red部分(0 - 255).*/
        public static function getRed(color:uint):int   { return (color >> 16) & 0xff; }
        
        /** 返回(A)RGB的green部分(0 - 255).*/
        public static function getGreen(color:uint):int { return (color >>  8) & 0xff; }
        
        /** 返回(A)RGB的blue部分(0 - 255).*/
        public static function getBlue(color:uint):int  { return  color        & 0xff; }
        
        /** 创建一个uint的RGB颜色。各通道范围为0 - 255.*/
        public static function rgb(red:int, green:int, blue:int):uint
        {
            return (red << 16) | (green << 8) | blue;
        }
        
        /** 创建一个uint的ARGB颜色。各通道范围为0 - 255.*/
        public static function argb(alpha:int, red:int, green:int, blue:int):uint
        {
            return (alpha << 24) | (red << 16) | (green << 8) | blue;
        }
        
        /** @private */
        public function Color() { throw new AbstractClassError(); }
    }
}