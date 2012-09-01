// =================================================================================================
//
//	Starling Framework
//	Copyright 2011 Gamua OG. All Rights Reserved.
//
//	This program is free software. You can redistribute and/or modify it
//	in accordance with the terms of the accompanying license agreement.
//
// =================================================================================================

package starling.errors
{
    /** 当您尝试调用一个抽象方法，就会抛出一个AbstractMethodError。 */
    public class AbstractMethodError extends Error
    {
        /** 创建一个新的AbstractMethodError对象。 */
        public function AbstractMethodError(message:*="", id:*=0)
        {
            super(message, id);
        }
    }
}