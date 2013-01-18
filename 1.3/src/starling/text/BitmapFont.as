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
    import flash.geom.Rectangle;
    import flash.utils.Dictionary;
    
    import starling.display.Image;
    import starling.display.QuadBatch;
    import starling.display.Sprite;
    import starling.textures.Texture;
    import starling.textures.TextureSmoothing;
    import starling.utils.HAlign;
    import starling.utils.VAlign;

	/** 
	 *  BitmapFont类解析bitmap字体文件，并保存在一个字符表中。
	 *
	 *  这个类解析的XML格式的文件使用了
	 *  <a href="http://www.angelcode.com/products/bmfont/">AngelCode Bitmap Font Generator</a> or
	 *  the <a href="http://glyphdesigner.71squared.com/">Glyph Designer</a>. 
	 *  T这种格式看起来就像下面写的:
	 *
	 *  <pre> 
	 *  &lt;font&gt;
	 *    &lt;info face="BranchingMouse" size="40" /&gt;
	 *    &lt;common lineHeight="40" /&gt;
	 *    &lt;pages&gt;  &lt;!-- currently, only one page is supported --&gt;
	 *      &lt;page id="0" file="texture.png" /&gt;
	 *    &lt;/pages&gt;
	 *    &lt;chars&gt;
	 *      &lt;char id="32" x="60" y="29" width="1" height="1" xoffset="0" yoffset="27" xadvance="8" /&gt;
	 *      &lt;char id="33" x="155" y="144" width="9" height="21" xoffset="0" yoffset="6" xadvance="9" /&gt;
	 *    &lt;/chars&gt;
	 *    &lt;kernings&gt; &lt;!-- Kerning is optional --&gt;
	 *      &lt;kerning first="83" second="83" amount="-4"/&gt;
	 *    &lt;/kernings&gt;
	 *  &lt;/font&gt;
	 *  </pre>
	 *  通过TextField类的<code>registerBitmapFont</code>方法传递一个这个类的实例。 
	 *  然后，设置文本字段的<code>fontName</code>属性为位图字体的名称值。这将使文本字段使用位图字体。
	 */ 
    public class BitmapFont
    {
        /** 为TextField类的fontSize属性设置这个常量，让位图字体按照它的默认大小渲染  */ 
        public static const NATIVE_SIZE:int = -1;
        
        /** 内嵌的一个小巧的位图字体. */
        public static const MINI:String = "mini";
        
        private static const CHAR_SPACE:int           = 32;
        private static const CHAR_TAB:int             =  9;
        private static const CHAR_NEWLINE:int         = 10;
        private static const CHAR_CARRIAGE_RETURN:int = 13;
        
        private var mTexture:Texture;
        private var mChars:Dictionary;
        private var mName:String;
        private var mSize:Number;
        private var mLineHeight:Number;
        private var mBaseline:Number;
        private var mHelperImage:Image;
        private var mCharLocationPool:Vector.<CharLocation>;
        
		/**
		 * 通过解析XML文件创建一个位图字体，并使用指定的纹理。如果不传递任何数据，就使用内嵌的MINI字型。 
		 * @param texture 纹理
		 * @param fontXml 字体XML
		 */
        public function BitmapFont(texture:Texture=null, fontXml:XML=null)
        {
            // if no texture is passed in, we create the minimal, embedded font
            if (texture == null && fontXml == null)
            {
                texture = MiniBitmapFont.texture;
                fontXml = MiniBitmapFont.xml;
            }
            
            mName = "unknown";
            mLineHeight = mSize = mBaseline = 14;
            mTexture = texture;
            mChars = new Dictionary();
            mHelperImage = new Image(texture);
            mCharLocationPool = new <CharLocation>[];
            
            if (fontXml) parseFontXml(fontXml);
        }
        
        /** 销毁位图字体的纹理  */
        public function dispose():void
        {
            if (mTexture)
                mTexture.dispose();
        }
        
        private function parseFontXml(fontXml:XML):void
        {
            var scale:Number = mTexture.scale;
            var frame:Rectangle = mTexture.frame;
            
            mName = fontXml.info.attribute("face");
            mSize = parseFloat(fontXml.info.attribute("size")) / scale;
            mLineHeight = parseFloat(fontXml.common.attribute("lineHeight")) / scale;
            mBaseline = parseFloat(fontXml.common.attribute("base")) / scale;
            
            if (fontXml.info.attribute("smooth").toString() == "0")
                smoothing = TextureSmoothing.NONE;
            
            if (mSize <= 0)
            {
                trace("[Starling] Warning: invalid font size in '" + mName + "' font.");
                mSize = (mSize == 0.0 ? 16.0 : mSize * -1.0);
            }
            
            for each (var charElement:XML in fontXml.chars.char)
            {
                var id:int = parseInt(charElement.attribute("id"));
                var xOffset:Number = parseFloat(charElement.attribute("xoffset")) / scale;
                var yOffset:Number = parseFloat(charElement.attribute("yoffset")) / scale;
                var xAdvance:Number = parseFloat(charElement.attribute("xadvance")) / scale;
                
                var region:Rectangle = new Rectangle();
                region.x = parseFloat(charElement.attribute("x")) / scale + frame.x;
                region.y = parseFloat(charElement.attribute("y")) / scale + frame.y;
                region.width  = parseFloat(charElement.attribute("width")) / scale;
                region.height = parseFloat(charElement.attribute("height")) / scale;
                
                var texture:Texture = Texture.fromTexture(mTexture, region);
                var bitmapChar:BitmapChar = new BitmapChar(id, texture, xOffset, yOffset, xAdvance); 
                addChar(id, bitmapChar);
            }
            
            for each (var kerningElement:XML in fontXml.kernings.kerning)
            {
                var first:int = parseInt(kerningElement.attribute("first"));
                var second:int = parseInt(kerningElement.attribute("second"));
                var amount:Number = parseFloat(kerningElement.attribute("amount")) / scale;
                if (second in mChars) getChar(second).addKerning(first, amount);
            }
        }
        
		/**
		 * 根据指定的字符ID返回一个位图字符 
		 * @param charID 字符ID
		 * @return BitmapChar
		 */ 
        public function getChar(charID:int):BitmapChar
        {
            return mChars[charID];   
        }
        
		/**
		 * 根据指定的字符ID增加一个位图字符 
		 * @param charID 字符ID
		 * @param bitmapChar
		 */ 
        public function addChar(charID:int, bitmapChar:BitmapChar):void
        {
            mChars[charID] = bitmapChar;
        }
        
		/**
		 * 创建一个包含字符图片的Sprite对象 
		 * @param width 宽度
		 * @param height 高度
		 * @param text 文本内容
		 * @param fontSize 文字大小
		 * @param color 颜色
		 * @param hAlign 水平对齐方式
		 * @param vAlign 垂直对齐方式
		 * @param autoScale 自动缩放
		 * @param kerning 字距
		 * @return 绘制生成的Sprite对象
		 */ 
        public function createSprite(width:Number, height:Number, text:String,
                                     fontSize:Number=-1, color:uint=0xffffff, 
                                     hAlign:String="center", vAlign:String="center",      
                                     autoScale:Boolean=true, 
                                     kerning:Boolean=true):Sprite
        {
            var charLocations:Vector.<CharLocation> = arrangeChars(width, height, text, fontSize, 
                                                                   hAlign, vAlign, autoScale, kerning);
            var numChars:int = charLocations.length;
            var sprite:Sprite = new Sprite();
            
            for (var i:int=0; i<numChars; ++i)
            {
                var charLocation:CharLocation = charLocations[i];
                var char:Image = charLocation.char.createImage();
                char.x = charLocation.x;
                char.y = charLocation.y;
                char.scaleX = char.scaleY = charLocation.scale;
                char.color = color;
                sprite.addChild(char);
            }
            
            return sprite;
        }
        
		/**
		 * 将文本绘制成QuadBatch. 
		 * @param quadBatch QuadBatch实例
		 * @param width 宽度
		 * @param height 高度
		 * @param text 文本
		 * @param fontSize 字号
		 * @param color 颜色
		 * @param hAlign 水平对齐方式
		 * @param vAlign 垂直对齐方式
		 * @param autoScale 自动缩放
		 * @param kerning 字距
		 */
        public function fillQuadBatch(quadBatch:QuadBatch, width:Number, height:Number, text:String,
                                      fontSize:Number=-1, color:uint=0xffffff, 
                                      hAlign:String="center", vAlign:String="center",      
                                      autoScale:Boolean=true, 
                                      kerning:Boolean=true):void
        {
            var charLocations:Vector.<CharLocation> = arrangeChars(width, height, text, fontSize, 
                                                                   hAlign, vAlign, autoScale, kerning);
            var numChars:int = charLocations.length;
            mHelperImage.color = color;
            
            if (numChars > 8192)
                throw new ArgumentError("Bitmap Font text is limited to 8192 characters.");

            for (var i:int=0; i<numChars; ++i)
            {
                var charLocation:CharLocation = charLocations[i];
                mHelperImage.texture = charLocation.char.texture;
                mHelperImage.readjustSize();
                mHelperImage.x = charLocation.x;
                mHelperImage.y = charLocation.y;
                mHelperImage.scaleX = mHelperImage.scaleY = charLocation.scale;
                quadBatch.addImage(mHelperImage);
            }
        }
        
        /** Arranges the characters of a text inside a rectangle, adhering to the given settings. 
         *  Returns a Vector of CharLocations. */
        private function arrangeChars(width:Number, height:Number, text:String, fontSize:Number=-1,
                                      hAlign:String="center", vAlign:String="center",
                                      autoScale:Boolean=true, kerning:Boolean=true):Vector.<CharLocation>
        {
            if (text == null || text.length == 0) return new <CharLocation>[];
            if (fontSize < 0) fontSize *= -mSize;
            
            var lines:Vector.<Vector.<CharLocation>>;
            var finished:Boolean = false;
            var charLocation:CharLocation;
            var numChars:int;
            var containerWidth:Number;
            var containerHeight:Number;
            var scale:Number;
            
            while (!finished)
            {
                scale = fontSize / mSize;
                containerWidth  = width / scale;
                containerHeight = height / scale;
                
                lines = new Vector.<Vector.<CharLocation>>();
                
                if (mLineHeight <= containerHeight)
                {
                    var lastWhiteSpace:int = -1;
                    var lastCharID:int = -1;
                    var currentX:Number = 0;
                    var currentY:Number = 0;
                    var currentLine:Vector.<CharLocation> = new <CharLocation>[];
                    
                    numChars = text.length;
                    for (var i:int=0; i<numChars; ++i)
                    {
                        var lineFull:Boolean = false;
                        var charID:int = text.charCodeAt(i);
                        var char:BitmapChar = getChar(charID);
                        
                        if (charID == CHAR_NEWLINE || charID == CHAR_CARRIAGE_RETURN)
                        {
                            lineFull = true;
                        }
                        else if (char == null)
                        {
                            trace("[Starling] Missing character: " + charID);
                        }
                        else
                        {
                            if (charID == CHAR_SPACE || charID == CHAR_TAB)
                                lastWhiteSpace = i;
                            
                            if (kerning)
                                currentX += char.getKerning(lastCharID);
                            
                            charLocation = mCharLocationPool.length ?
                                mCharLocationPool.pop() : new CharLocation(char);
                            
                            charLocation.char = char;
                            charLocation.x = currentX + char.xOffset;
                            charLocation.y = currentY + char.yOffset;
                            currentLine.push(charLocation);
                            
                            currentX += char.xAdvance;
                            lastCharID = charID;
                            
                            if (currentLine.length == 1)
                            {
                                // the first character is not meant to have an xOffset
                                currentX -= char.xOffset;
                                charLocation.x -= char.xOffset;
                            }
                            
                            if (charLocation.x + char.width > containerWidth)
                            {
                                // remove characters and add them again to next line
                                var numCharsToRemove:int = lastWhiteSpace == -1 ? 1 : i - lastWhiteSpace;
                                var removeIndex:int = currentLine.length - numCharsToRemove;
                                
                                currentLine.splice(removeIndex, numCharsToRemove);
                                
                                if (currentLine.length == 0)
                                    break;
                                
                                i -= numCharsToRemove;
                                lineFull = true;
                            }
                        }
                        
                        if (i == numChars - 1)
                        {
                            lines.push(currentLine);
                            finished = true;
                        }
                        else if (lineFull)
                        {
                            lines.push(currentLine);
                            
                            if (lastWhiteSpace == i)
                                currentLine.pop();
                            
                            if (currentY + 2*mLineHeight <= containerHeight)
                            {
                                currentLine = new <CharLocation>[];
                                currentX = 0;
                                currentY += mLineHeight;
                                lastWhiteSpace = -1;
                                lastCharID = -1;
                            }
                            else
                            {
                                break;
                            }
                        }
                    } // for each char
                } // if (mLineHeight <= containerHeight)
                
                if (autoScale && !finished)
                {
                    fontSize -= 1;
                    lines.length = 0;
                }
                else
                {
                    finished = true; 
                }
            } // while (!finished)
            
            var finalLocations:Vector.<CharLocation> = new <CharLocation>[];
            var numLines:int = lines.length;
            var bottom:Number = currentY + mLineHeight;
            var yOffset:int = 0;
            
            if (vAlign == VAlign.BOTTOM)      yOffset =  containerHeight - bottom;
            else if (vAlign == VAlign.CENTER) yOffset = (containerHeight - bottom) / 2;
            
            for (var lineID:int=0; lineID<numLines; ++lineID)
            {
                var line:Vector.<CharLocation> = lines[lineID];
                numChars = line.length;
                
                if (numChars == 0) continue;
                
                var lastLocation:CharLocation = line[line.length-1];
                var right:Number = lastLocation.x + lastLocation.char.width;
                var xOffset:int = 0;
                
                if (hAlign == HAlign.RIGHT)       xOffset =  containerWidth - right;
                else if (hAlign == HAlign.CENTER) xOffset = (containerWidth - right) / 2;
                
                for (var c:int=0; c<numChars; ++c)
                {
                    charLocation = line[c];
                    charLocation.x = scale * (charLocation.x + xOffset);
                    charLocation.y = scale * (charLocation.y + yOffset);
                    charLocation.scale = scale;
                    
                    if (charLocation.char.width > 0 && charLocation.char.height > 0)
                        finalLocations.push(charLocation);
                    
                    // return to pool for next call to "arrangeChars"
                    mCharLocationPool.push(charLocation);
                }
            }
            
            return finalLocations;
        }
        
        /** 字体名称 */
        public function get name():String { return mName; }
        
        /** 字号 */
        public function get size():Number { return mSize; }
        
        /** 行高. */
        public function get lineHeight():Number { return mLineHeight; }
        public function set lineHeight(value:Number):void { mLineHeight = value; }
        
        /** 是否开启平滑 */ 
        public function get smoothing():String { return mHelperImage.smoothing; }
        public function set smoothing(value:String):void { mHelperImage.smoothing = value; } 
        
        /** 字体的基线.  */
        public function get baseline():Number { return mBaseline; }
    }
}

import starling.text.BitmapChar;

class CharLocation
{
    public var char:BitmapChar;
    public var scale:Number;
    public var x:Number;
    public var y:Number;
    
    public function CharLocation(char:BitmapChar)
    {
        this.char = char;
    }
}