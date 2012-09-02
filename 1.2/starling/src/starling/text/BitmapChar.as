// =================================================================================================
//
//	Starling Framework
//	Copyright 2011 Gamua OG. All Rights Reserved.
//
//	This program is free software. You can redistribute and/or modify it
//	in accordance with the terms of the accompanying license agreement.
//
// =================================================================================================

package starling.text
{
    import flash.utils.Dictionary;
    
    import starling.display.Image;
    import starling.textures.Texture;

    /** A BitmapChar contains the information about one char of a bitmap font.  
     *  <em>You don't have to use this class directly in most cases. 
     *  The TextField class contains methods that handle bitmap fonts for you.</em>    
     */ 
	// 一个 BitmapChar包含了位图字体的一个字符的相关信息。 在大多数情况下您不需要直接使用这个类。TextField类已经为您做了封装。
	/**
	 *  一个 BitmapChar包含了位图字体的一个字符的相关信息。 在大多数情况下您不需要直接使用这个类。TextField类已经为您做了封装。
	 * @author mebius
	 * 
	 */    
	public class BitmapChar
    {
        private var mTexture:Texture;
        private var mCharID:int;
        private var mXOffset:Number;
        private var mYOffset:Number;
        private var mXAdvance:Number;
        private var mKernings:Dictionary;
        
        /** Creates a char with a texture and its properties. */
		//根据纹理和它的属性创建一个字符
		/**
		 *  根据纹理和它的属性创建一个字符
		 * @param id 唯一标示
		 * @param texture 纹理
		 * @param xOffset X偏移量
		 * @param yOffset Y偏移量
		 * @param xAdvance 移动偏移量
		 * 
		 */		
        public function BitmapChar(id:int, texture:Texture, 
                                   xOffset:Number, yOffset:Number, xAdvance:Number)
        {
            mCharID = id;
            mTexture = texture;
            mXOffset = xOffset;
            mYOffset = yOffset;
            mXAdvance = xAdvance;
            mKernings = null;
        }
        
        /** Adds kerning information relative to a specific other character ID. */
		//根据特定的字符ID设定边距
		/**
		 *  根据特定的字符ID设定边距
		 * @param charID 字符ID
		 * @param amount 边距
		 * 
		 */		
        public function addKerning(charID:int, amount:Number):void
        {
            if (mKernings == null)
                mKernings = new Dictionary();
            
            mKernings[charID] = amount;
        }
        
        /** Retrieve kerning information relative to the given character ID. */
		//根据特定的字符ID返回边距
		/**
		 *  根据特定的字符ID返回边距
		 * @param charID 字符ID
		 * @return 边距
		 * 
		 */		
        public function getKerning(charID:int):Number
        {
            if (mKernings == null || mKernings[charID] == undefined) return 0.0;
            else return mKernings[charID];
        }
        
        /** Creates an image of the char. */
		//根据字符创建一个图片.
		/**
		 *  据字符创建一个图片.
		 * @return 
		 * 
		 */		
        public function createImage():Image
        {
            return new Image(mTexture);
        }
        
        /** The unicode ID of the char. */
		//字符的唯一标示.
		/**
		 *  字符的唯一标示.
		 * @return 
		 * 
		 */		
        public function get charID():int { return mCharID; }
        
        /** The number of points to move the char in x direction on character arrangement. */
		//排列字符的时候在X方向上的偏移量.
		/**
		 *  排列字符的时候在X方向上的偏移量.
		 * @return 
		 * 
		 */		
        public function get xOffset():Number { return mXOffset; }
        
        /** The number of points to move the char in y direction on character arrangement. */
		//排列字符的时候在Y方向上的偏移量.
		/**
		 *  排列字符的时候在Y方向上的偏移量.
		 * @return 
		 * 
		 */		
        public function get yOffset():Number { return mYOffset; }
        
        /** The number of points the cursor has to be moved to the right for the next char. */
		//光标移动到下一个字符时的偏移量
		/**
		 *  光标移动到下一个字符时的偏移量
		 * @return 
		 * 
		 */		
        public function get xAdvance():Number { return mXAdvance; }
        
        /** The texture of the character. */
		//这个字符的纹理.
		/**
		 *  这个字符的纹理.
		 * @return 
		 * 
		 */		
        public function get texture():Texture { return mTexture; }
        
        /** The width of the character in points. */
		// 字符宽度.
		/**
		 *  字符宽度.
		 * @return 
		 * 
		 */		
        public function get width():Number { return mTexture.width; }
        
        /** The height of the character in points. */
		//字符高度.
		/**
		 *  字符高度.
		 * @return 
		 * 
		 */		
        public function get height():Number { return mTexture.height; }
    }
}