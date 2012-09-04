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
    // TODO: add number formatting options
    
    /** 格式化字符串.样式为配对的大括号(如"{0}").还不支持任何数字格式化选项.*/
    public function formatString(format:String, ...args):String
    {
        for (var i:int=0; i<args.length; ++i)
            format = format.replace(new RegExp("\\{"+i+"\\}", "g"), args[i]);
        
        return format;
    }
}