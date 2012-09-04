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
    /** 返回大于或等于这个指定的数，这个数为紧接着的2的倍数.
	 *  <br>比如，getNextPowerOfTwo(3)返回4；getNextPowerOfTwo(8)返回8；getNextPowerOfTwo(9)返回16 */
    public function getNextPowerOfTwo(number:int):int
    {
        if (number > 0 && (number & (number - 1)) == 0) // see: http://goo.gl/D9kPj
            return number;
        else
        {
            var result:int = 1;
            while (result < number) result <<= 1;
            return result;
        }
    }
}