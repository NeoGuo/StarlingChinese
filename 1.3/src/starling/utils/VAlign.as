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

	/** 提供物件垂直方向上的对齐常量值. */
    public final class VAlign
    {
        /** @private */
        public function VAlign() { throw new AbstractClassError(); }
        
		/** 顶部对齐. */
        public static const TOP:String    = "top";
        
		/** 居中对齐. */
        public static const CENTER:String = "center";
        
		/** 底对齐. */
        public static const BOTTOM:String = "bottom";
        
		/** 指定给出的对齐字符串是否合法. */
        public static function isValid(vAlign:String):Boolean
        {
            return vAlign == TOP || vAlign == CENTER || vAlign == BOTTOM;
        }
    }
}