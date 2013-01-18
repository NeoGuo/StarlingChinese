// =================================================================================================
//
//	Starling Framework
//	Copyright 2012 Gamua OG. All Rights Reserved.
//
//	This program is free software. You can redistribute and/or modify it
//	in accordance with the terms of the accompanying license agreement.
//
// =================================================================================================

package starling.filters
{
    import starling.errors.AbstractClassError;

	/** 这个类提供了一些静态变量来表示滤镜模式。
	 *  这些值用于FragmentFilter.mode属性，并且定义一个滤镜和一个原有对象结合后的呈现结果。*/	
    public class FragmentFilterMode
    {
        /** @private */
        public function FragmentFilterMode() { throw new AbstractClassError(); }
        
        /** 滤镜在对象的下方显示 */
        public static const BELOW:String = "below";
        
        /** 滤镜替换原有的对象 */
        public static const REPLACE:String = "replace";
        
        /** 滤镜在对象的上方显示 */ 
        public static const ABOVE:String = "above";
    }
}