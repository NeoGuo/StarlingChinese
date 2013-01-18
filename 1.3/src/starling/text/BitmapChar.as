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

	/**
	 *  一个 BitmapChar包含了位图字体的一个字符的相关信息。 在大多数情况下您不需要直接使用这个类。TextField类已经为您做了封装。
	 */ 
    public class BitmapChar
    {
        private var mTexture:Texture;
        private var mCharID:int;
        private var mXOffset:Number;
        private var mYOffset:Number;
        private var mXAdvance:Number;
        private var mKernings:Dictionary;
        
		/**
		 * 根据纹理和它的属性创建一个字符
		 * @param id 唯一标示
		 * @param texture 纹理
		 * @param xOffset X偏移量
		 * @param yOffset Y偏移量
		 * @param xAdvance 移动偏移量
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
        
		/**
		 * 根据特定的字符ID设定边距
		 * @param charID 字符ID
		 * @param amount 边距
		 */
        public function addKerning(charID:int, amount:Number):void
        {
            if (mKernings == null)
                mKernings = new Dictionary();
            
            mKernings[charID] = amount;
        }
        
		/**
		 * 根据特定的字符ID返回边距
		 * @param charID 字符ID
		 * @return 边距
		 */
        public function getKerning(charID:int):Number
        {
            if (mKernings == null || mKernings[charID] == undefined) return 0.0;
            else return mKernings[charID];
        }
        
		/**
		 * 据字符创建一个图片.
		 * @return Image
		 */
        public function createImage():Image
        {
            return new Image(mTexture);
        }
        
        /** 字符的唯一标示. */
        public function get charID():int { return mCharID; }
        
        /** 排列字符的时候在X方向上的偏移量. */
        public function get xOffset():Number { return mXOffset; }
        
        /** 排列字符的时候在Y方向上的偏移量. */
        public function get yOffset():Number { return mYOffset; }
        
        /** 光标移动到下一个字符时的偏移量 */
        public function get xAdvance():Number { return mXAdvance; }
        
        /** 这个字符的纹理. */
        public function get texture():Texture { return mTexture; }
        
        /** 字符宽度. */
        public function get width():Number { return mTexture.width; }
        
        /** 字符高度. */
        public function get height():Number { return mTexture.height; }
    }
}