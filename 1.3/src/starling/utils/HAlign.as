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
    import starling.errors.AbstractClassError;

	/** 提供物件水平方向上的对齐常量值. */
    public final class HAlign
    {
        /** @private */
        public function HAlign() { throw new AbstractClassError(); }
        
		/** 左对齐. */
        public static const LEFT:String   = "left";
        
		/** 居中对齐. */
        public static const CENTER:String = "center";
        
		/** 右对齐. */
        public static const RIGHT:String  = "right";
        
		/** 指定给出的对齐字符串是否合法. */
        public static function isValid(hAlign:String):Boolean
        {
            return hAlign == LEFT || hAlign == CENTER || hAlign == RIGHT;
        }
    }
}