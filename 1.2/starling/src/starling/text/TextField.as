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
    import flash.display.BitmapData;
    import flash.geom.Matrix;
    import flash.geom.Rectangle;
    import flash.text.AntiAliasType;
    import flash.text.TextField;
    import flash.text.TextFormat;
    import flash.utils.Dictionary;
    
    import starling.core.RenderSupport;
    import starling.core.Starling;
    import starling.display.DisplayObject;
    import starling.display.DisplayObjectContainer;
    import starling.display.Image;
    import starling.display.Quad;
    import starling.display.QuadBatch;
    import starling.display.Sprite;
    import starling.events.Event;
    import starling.textures.Texture;
    import starling.utils.HAlign;
    import starling.utils.VAlign;

    /** A TextField displays text, either using standard true type fonts or custom bitmap fonts.
     *  
     *  <p>You can set all properties you are used to, like the font name and size, a color, the 
     *  horizontal and vertical alignment, etc. The border property is helpful during development, 
     *  because it lets you see the bounds of the textfield.</p>
     *  
     *  <p>There are two types of fonts that can be displayed:</p>
     *  
     *  <ul>
     *    <li>Standard true type fonts. This renders the text just like a conventional Flash
     *        TextField. It is recommended to embed the font, since you cannot be sure which fonts
     *        are available on the client system, and since this enhances rendering quality. 
     *        Simply pass the font name to the corresponding property.</li>
     *    <li>Bitmap fonts. If you need speed or fancy font effects, use a bitmap font instead. 
     *        That is a font that has its glyphs rendered to a texture atlas. To use it, first 
     *        register the font with the method <code>registerBitmapFont</code>, and then pass 
     *        the font name to the corresponding property of the text field.</li>
     *  </ul> 
     *    
     *  For bitmap fonts, we recommend one of the following tools:
     * 
     *  <ul>
     *    <li>Windows: <a href="http://www.angelcode.com/products/bmfont">Bitmap Font Generator</a>
     *       from Angel Code (free). Export the font data as an XML file and the texture as a png 
     *       with white characters on a transparent background (32 bit).</li>
     *    <li>Mac OS: <a href="http://glyphdesigner.71squared.com">Glyph Designer</a> from 
     *        71squared or <a href="http://http://www.bmglyph.com">bmGlyph</a> (both commercial). 
     *        They support Starling natively.</li>
     *  </ul> 
     */
	//
	/** TextField类用来显示文本，使用标准的True Type字体或自定义位图字体。
	 *  
	 *  <p>您可以设置你用到的所有属性，比如字体名称和字号，颜色，横向和垂直对齐方式，等等。边框属性对于开发是非常有帮助的，因为这样可以让您看到文本的边界。</p>
	 *  
	 *  <p>有两种类型的字体可以被显示:</p>
	 *  
	 *  <ul>
	 *    <li>标准的true type字体. 渲染这种类型的字体就像传统的Flash的文本框一样。建议您使用嵌入字体，
	 * 因为您无法确保客户端有哪些字体可用， 而且嵌入字体具有更好的渲染质量。只需要给相应的属性传入字体名称即可。</li>
	 *    <li>位图字体. 如果您需要加速显示或希望使用很酷的样式，请使用位图字体。这是一种将字型渲染到纹理地图集的格式。 
	 * 要使用位图字体，需要首先通过registerBitmapFont注册这个字体，然后传递字体名称到文本框相应的属性上。</li>
	 *  </ul> 
	 *    
	 *  对于位图字体来说，我们推荐下面的工具:
	 * 
	 *  <ul>
	 *    <li>
	 *       Windows: <a href="http://www.angelcode.com/products/bmfont">位图字体生成器</a>来自 Angel Code (免费). 导出字体数据为一个XML文件，
	 * 纹理导出为一个PNG图片，将白色的文字放在透明背景上(32位)。</li>
	 *    <li>Mac OS: <a href="http://glyphdesigner.71squared.com">Glyph Designer</a> 
	 * 来自 71squared 或者 <a href="http://http://www.bmglyph.com">bmGlyph</a>
	 *  (都是商业软件). 他们本身都支持Starling。</li>
	 *  </ul> 
	 */
    public class TextField extends DisplayObjectContainer
    {
        private var mFontSize:Number;
        private var mColor:uint;
        private var mText:String;
        private var mFontName:String;
        private var mHAlign:String;
        private var mVAlign:String;
        private var mBold:Boolean;
        private var mItalic:Boolean;
        private var mUnderline:Boolean;
        private var mAutoScale:Boolean;
        private var mKerning:Boolean;
        private var mNativeFilters:Array;
        private var mRequiresRedraw:Boolean;
        private var mIsRenderedText:Boolean;
        private var mTextBounds:Rectangle;
        
        private var mHitArea:DisplayObject;
        private var mBorder:DisplayObjectContainer;
        
        private var mImage:Image;
        private var mQuadBatch:QuadBatch;
        
        // this object will be used for text rendering	
        private static var sNativeTextField:flash.text.TextField = new flash.text.TextField();
        
        // this is the container for bitmap fonts
        private static var sBitmapFonts:Dictionary = new Dictionary();
        
        /** Create a new text field with the given properties. */
		/**
		 * 根据给定的属性创建一个新的文本框 
		 * @param width 宽度
		 * @param height 高度
		 * @param text   文本
		 * @param fontName 字体名称
		 * @param fontSize 字号
		 * @param color 颜色
		 * @param bold 是否加粗
		 * 
		 */		
        public function TextField(width:int, height:int, text:String, fontName:String="Verdana",
                                  fontSize:Number=12, color:uint=0x0, bold:Boolean=false)
        {
            mText = text ? text : "";
            mFontSize = fontSize;
            mColor = color;
            mHAlign = HAlign.CENTER;
            mVAlign = VAlign.CENTER;
            mBorder = null;
            mKerning = true;
            mBold = bold;
            this.fontName = fontName;
            
            mHitArea = new Quad(width, height);
            mHitArea.alpha = 0.0;
            addChild(mHitArea);
            
            addEventListener(Event.FLATTEN, onFlatten);
        }
        
        /** Disposes the underlying texture data. */
		/**
		 * 销毁纹理数据 
		 * 
		 */		
        public override function dispose():void
        {
            removeEventListener(Event.FLATTEN, onFlatten);
            if (mImage) mImage.texture.dispose();
            if (mQuadBatch) mQuadBatch.dispose();
            super.dispose();
        }
        
        private function onFlatten(event:Event):void
        {
            if (mRequiresRedraw) redrawContents();
        }
        
        /** @inheritDoc */
		/**
		 * 使用辅助对象来渲染这个渲染对象。永远不要直接调用这个方法，除非是从另一个渲染方法调用的。 
		 * @param support   为渲染提供实用功能
		 * @param parentAlpha 从这个对象的父级到stage的透明度累加值
		 * 
		 */		
        public override function render(support:RenderSupport, parentAlpha:Number):void
        {
            if (mRequiresRedraw) redrawContents();
            super.render(support, parentAlpha);
        }
        
        private function redrawContents():void
        {
            if (mIsRenderedText) createRenderedContents();
            else                 createComposedContents();
            
            mRequiresRedraw = false;
        }
        
        private function createRenderedContents():void
        {
            if (mQuadBatch)
            { 
                mQuadBatch.removeFromParent(true); 
                mQuadBatch = null; 
            }
            
            var scale:Number  = Starling.contentScaleFactor;
            var width:Number  = mHitArea.width  * scale;
            var height:Number = mHitArea.height * scale;
            
            var textFormat:TextFormat = new TextFormat(mFontName, 
                mFontSize * scale, mColor, mBold, mItalic, mUnderline, null, null, mHAlign);
            textFormat.kerning = mKerning;
            
            sNativeTextField.defaultTextFormat = textFormat;
            sNativeTextField.width = width;
            sNativeTextField.height = height;
            sNativeTextField.antiAliasType = AntiAliasType.ADVANCED;
            sNativeTextField.selectable = false;            
            sNativeTextField.multiline = true;            
            sNativeTextField.wordWrap = true;            
            sNativeTextField.text = mText;
            sNativeTextField.embedFonts = true;
            sNativeTextField.filters = mNativeFilters;
            
            // we try embedded fonts first, non-embedded fonts are just a fallback
            if (sNativeTextField.textWidth == 0.0 || sNativeTextField.textHeight == 0.0)
                sNativeTextField.embedFonts = false;
            
            if (mAutoScale)
                autoScaleNativeTextField(sNativeTextField);
            
            var textWidth:Number  = sNativeTextField.textWidth;
            var textHeight:Number = sNativeTextField.textHeight;
            
            var xOffset:Number = 0.0;
            if (mHAlign == HAlign.LEFT)        xOffset = 2; // flash adds a 2 pixel offset
            else if (mHAlign == HAlign.CENTER) xOffset = (width - textWidth) / 2.0;
            else if (mHAlign == HAlign.RIGHT)  xOffset =  width - textWidth - 2;

            var yOffset:Number = 0.0;
            if (mVAlign == VAlign.TOP)         yOffset = 2; // flash adds a 2 pixel offset
            else if (mVAlign == VAlign.CENTER) yOffset = (height - textHeight) / 2.0;
            else if (mVAlign == VAlign.BOTTOM) yOffset =  height - textHeight - 2;
            
            var bitmapData:BitmapData = new BitmapData(width, height, true, 0x0);
            bitmapData.draw(sNativeTextField, new Matrix(1, 0, 0, 1, 0, int(yOffset)-2));
            sNativeTextField.text = "";
            
            // update textBounds rectangle
            if (mTextBounds == null) mTextBounds = new Rectangle();
            mTextBounds.setTo(xOffset   / scale, yOffset    / scale,
                              textWidth / scale, textHeight / scale);
            
            var texture:Texture = Texture.fromBitmapData(bitmapData, false, false, scale);
            
            if (mImage == null) 
            {
                mImage = new Image(texture);
                mImage.touchable = false;
                addChild(mImage);
            }
            else 
            { 
                mImage.texture.dispose();
                mImage.texture = texture; 
                mImage.readjustSize(); 
            }
        }
        
        private function autoScaleNativeTextField(textField:flash.text.TextField):void
        {
            var size:Number   = Number(textField.defaultTextFormat.size);
            var maxHeight:int = textField.height - 4;
            var maxWidth:int  = textField.width - 4;
            
            while (textField.textWidth > maxWidth || textField.textHeight > maxHeight)
            {
                if (size <= 4) break;
                
                var format:TextFormat = textField.defaultTextFormat;
                format.size = size--;
                textField.setTextFormat(format);
            }
        }
        
        private function createComposedContents():void
        {
            if (mImage) 
            { 
                mImage.removeFromParent(true); 
                mImage = null; 
            }
            
            if (mQuadBatch == null) 
            { 
                mQuadBatch = new QuadBatch(); 
                mQuadBatch.touchable = false;
                addChild(mQuadBatch); 
            }
            else
                mQuadBatch.reset();
            
            var bitmapFont:BitmapFont = sBitmapFonts[mFontName];
            if (bitmapFont == null) throw new Error("Bitmap font not registered: " + mFontName);
            
            bitmapFont.fillQuadBatch(mQuadBatch,
                mHitArea.width, mHitArea.height, mText, mFontSize, mColor, mHAlign, mVAlign,
                mAutoScale, mKerning);
            
            mTextBounds = null; // will be created on demand
        }
        
        private function updateBorder():void
        {
            if (mBorder == null) return;
            
            var width:Number  = mHitArea.width;
            var height:Number = mHitArea.height;
            
            var topLine:Quad    = mBorder.getChildAt(0) as Quad;
            var rightLine:Quad  = mBorder.getChildAt(1) as Quad;
            var bottomLine:Quad = mBorder.getChildAt(2) as Quad;
            var leftLine:Quad   = mBorder.getChildAt(3) as Quad;
            
            topLine.width    = width; topLine.height    = 1;
            bottomLine.width = width; bottomLine.height = 1;
            leftLine.width   = 1;     leftLine.height   = height;
            rightLine.width  = 1;     rightLine.height  = height;
            rightLine.x  = width  - 1;
            bottomLine.y = height - 1;
            topLine.color = rightLine.color = bottomLine.color = leftLine.color = mColor;
        }
        
        /** Returns the bounds of the text within the text field. */
		/**
		 * 返回文本框中的文本区域 
		 * @return 文本区域
		 * 
		 */		
        public function get textBounds():Rectangle
        {
            if (mRequiresRedraw) redrawContents();
            if (mTextBounds == null) mTextBounds = mQuadBatch.getBounds(mQuadBatch);
            return mTextBounds.clone();
        }
        
        /** @inheritDoc */
		/**
		 * 如果一个对象出现在其它坐标系，需要用这个方法返回围绕这个对象的一个四边形的区域。 
		 * 如果您传递一个'resultRect'参数，结果将存储在这个矩形里面，而不是创建一个新对象。 
		 * @param targetSpace 目标
		 * @param resultRect 预先准备的矩形
		 * @return Rectangle
		 * 
		 */		
        public override function getBounds(targetSpace:DisplayObject, resultRect:Rectangle=null):Rectangle
        {
            return mHitArea.getBounds(targetSpace, resultRect);
        }
        
        /** @inheritDoc */
		/**
		 * 对象的宽度
		 * @param value
		 * 
		 */		
        public override function set width(value:Number):void
        {
            // different to ordinary display objects, changing the size of the text field should 
            // not change the scaling, but make the texture bigger/smaller, while the size 
            // of the text/font stays the same (this applies to the height, as well).
            
            mHitArea.width = value;
            mRequiresRedraw = true;
            updateBorder();
        }
		/** @inheritDoc */
		/**
		 * 对象的高度 
		 * @param value
		 * 
		 */
        public override function set height(value:Number):void
        {
            mHitArea.height = value;
            mRequiresRedraw = true;
            updateBorder();
        }
        
        /** The displayed text. */
		/**
		 * 显示的文本 
		 * @return 
		 * 
		 */		
        public function get text():String { return mText; }
        public function set text(value:String):void
        {
            if (value == null) value = "";
            if (mText != value)
            {
                mText = value;
                mRequiresRedraw = true;
            }
        }
        
        /** The name of the font (true type or bitmap font). */
		/**
		 * 字体名称(true type字体或位图字体). 
		 * @return 
		 * 
		 */		
        public function get fontName():String { return mFontName; }
        public function set fontName(value:String):void
        {
            if (mFontName != value)
            {
                if (value == BitmapFont.MINI && sBitmapFonts[value] == undefined)
                    registerBitmapFont(new BitmapFont());
                
                mFontName = value;
                mRequiresRedraw = true;
                mIsRenderedText = sBitmapFonts[value] == undefined;
            }
        }
        
        /** The size of the font. For bitmap fonts, use <code>BitmapFont.NATIVE_SIZE</code> for 
         *  the original size. */
		/**
		 * 字号，在位图字体中，使用<code>BitmapFont.NATIVE_SIZE</code>来代替原来的大小
		 * @return 
		 * 
		 */		
        public function get fontSize():Number { return mFontSize; }
        public function set fontSize(value:Number):void
        {
            if (mFontSize != value)
            {
                mFontSize = value;
                mRequiresRedraw = true;
            }
        }
        
        /** The color of the text. For bitmap fonts, use <code>Color.WHITE</code> to use the
         *  original, untinted color. @default black */
		/**
		 * 字体颜色，在位图字体中，使用 <code>Color.WHITE</code>来代替默认的颜色
		 * @return 
		 * 
		 */		
        public function get color():uint { return mColor; }
        public function set color(value:uint):void
        {
            if (mColor != value)
            {
                mColor = value;
                updateBorder();
                mRequiresRedraw = true;
            }
        }
        
        /** The horizontal alignment of the text. @default center @see starling.utils.HAlign */
		/**
		 * 文本的横向对齐方式. @default 居中对齐 @see starling.utils.HAlign 
		 * @return 
		 * 
		 */		
        public function get hAlign():String { return mHAlign; }
        public function set hAlign(value:String):void
        {
            if (!HAlign.isValid(value))
                throw new ArgumentError("Invalid horizontal align: " + value);
            
            if (mHAlign != value)
            {
                mHAlign = value;
                mRequiresRedraw = true;
            }
        }
        
        /** The vertical alignment of the text. @default center @see starling.utils.VAlign */
		/**
		 * 文本的垂直对齐方式。@defaule 居中对齐  @see starling.utils.VAlign
		 * @return 
		 * 
		 */		
        public function get vAlign():String { return mVAlign; }
        public function set vAlign(value:String):void
        {
            if (!VAlign.isValid(value))
                throw new ArgumentError("Invalid vertical align: " + value);
            
            if (mVAlign != value)
            {
                mVAlign = value;
                mRequiresRedraw = true;
            }
        }
        
        /** Draws a border around the edges of the text field. Useful for visual debugging. 
         *  @default false */
		/**
		 *  围绕文本框绘制一个边框.
		 * @default false
		 * @return 
		 * 
		 */		
        public function get border():Boolean { return mBorder != null; }
        public function set border(value:Boolean):void
        {
            if (value && mBorder == null)
            {                
                mBorder = new Sprite();
                addChild(mBorder);
                
                for (var i:int=0; i<4; ++i)
                    mBorder.addChild(new Quad(1.0, 1.0));
                
                updateBorder();
            }
            else if (!value && mBorder != null)
            {
                mBorder.removeFromParent(true);
                mBorder = null;
            }
        }
        
        /** Indicates whether the text is bold. @default false */
		/**
		 * 字体加粗
		 *  @default false
		 * @return 
		 * 
		 */		
        public function get bold():Boolean { return mBold; }
        public function set bold(value:Boolean):void 
        {
            if (mBold != value)
            {
                mBold = value;
                mRequiresRedraw = true;
            }
        }
        
        /** Indicates whether the text is italicized. @default false */
		/**
		 * 是否是斜体.
		 *  @default false
		 * @return 
		 * 
		 */		
        public function get italic():Boolean { return mItalic; }
        public function set italic(value:Boolean):void
        {
            if (mItalic != value)
            {
                mItalic = value;
                mRequiresRedraw = true;
            }
        }
        
        /** Indicates whether the text is underlined. @default false */
		/**
		 * 是否具备下划线.
		 * @default false
		 * @return 
		 * 
		 */		
        public function get underline():Boolean { return mUnderline; }
        public function set underline(value:Boolean):void
        {
            if (mUnderline != value)
            {
                mUnderline = value;
                mRequiresRedraw = true;
            }
        }
        
        /** Indicates whether kerning is enabled. @default true */
		/**
		 * 指示是否启用字距.
		 *  @default true
		 * @return 
		 * 
		 */		
        public function get kerning():Boolean { return mKerning; }
        public function set kerning(value:Boolean):void
        {
            if (mKerning != value)
            {
                mKerning = value;
                mRequiresRedraw = true;
            }
        }
        
        /** Indicates whether the font size is scaled down so that the complete text fits
         *  into the text field. @default false */
		/**
		 * 指示是否开启自动缩放，使文本可以完整的填充整个文字区域。
		 * @default false
		 * @return 
		 * 
		 */		
        public function get autoScale():Boolean { return mAutoScale; }
        public function set autoScale(value:Boolean):void
        {
            if (mAutoScale != value)
            {
                mAutoScale = value;
                mRequiresRedraw = true;
            }
        }

        /** The native Flash BitmapFilters to apply to this TextField. 
         *  Only available when using standard (TrueType) fonts! */
		/**
		 * 当你使用默认字体（TrueType）类型的时候，你可以使用Flash原生的 BitmapFilters.
		 * @return 滤镜集合
		 * 
		 */		
        public function get nativeFilters():Array { return mNativeFilters; }
        public function set nativeFilters(value:Array) : void
        {
            if (!mIsRenderedText)
                throw(new Error("The TextField.nativeFilters property cannot be used on Bitmap fonts."));
			
            mNativeFilters = value.concat();
            mRequiresRedraw = true;
        }
        
        /** Makes a bitmap font available at any text field, identified by its <code>name</code>.
         *  Per default, the <code>name</code> property of the bitmap font will be used, but you 
         *  can pass a custom name, as well. @returns the name of the font. */
		/**
		 *  让位图字体可以应用在任何文本框。设置文本框的fontName属性为位图字体的name值，来使用位图字体进行渲染。
		 * @param bitmapFont 位图字体
		 * @param name 名称
		 * @return 
		 * 
		 */		
        public static function registerBitmapFont(bitmapFont:BitmapFont, name:String=null):String
        {
            if (name == null) name = bitmapFont.name;
            sBitmapFonts[name] = bitmapFont;
            return name;
        }
        
        /** Unregisters the bitmap font and, optionally, disposes it. */
		/**
		 * 取消注册一个位图字体，并销毁它（可选）. 
		 * @param name
		 * @param dispose
		 * 
		 */		
        public static function unregisterBitmapFont(name:String, dispose:Boolean=true):void
        {
            if (dispose && sBitmapFonts[name] != undefined)
                sBitmapFonts[name].dispose();
            
            delete sBitmapFonts[name];
        }
        
        /** Returns a registered bitmap font (or null, if the font has not been registered). */
		/**
		 * 获取一个位图纹理 
		 * @param name 字体名称
		 * @return 
		 * 
		 */		
        public static function getBitmapFont(name:String):BitmapFont
        {
            return sBitmapFonts[name];
        }
    }
}