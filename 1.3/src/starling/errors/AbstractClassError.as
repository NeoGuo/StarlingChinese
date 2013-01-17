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
	 * 当您尝试创建一个抽象类的一个实例，就会抛出一个AbstractClassError。
	 */
    public class AbstractClassError extends Error
    {
		/** 
		 * 创建一个新的AbstractClassError对象。 
		 */
        public function AbstractClassError(message:*="", id:*=0)
        {
            super(message, id);
        }
    }
}