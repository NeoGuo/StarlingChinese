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
    /** 
     * 当需要Context3D对象而它不存在或尚未准备好的时候，会抛出一个MissingContextError。
     */
    public class MissingContextError extends Error
    {
        /** 
         * 创建一个新的MissingContextError对象。
         */
        public function MissingContextError(message:*="", id:*=0)
        {
            super(message, id);
        }
    }
}