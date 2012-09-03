// =================================================================================================
//
//	Starling Framework
//	Copyright 2011 Gamua OG. All Rights Reserved.
//
//	This program is free software. You can redistribute and/or modify it
//	in accordance with the terms of the accompanying license agreement.
//
// =================================================================================================

package starling.display
{
    import flash.geom.Rectangle;
    import flash.ui.Mouse;
    import flash.ui.MouseCursor;
    
    import starling.events.Event;
    import starling.events.Touch;
    import starling.events.TouchEvent;
    import starling.events.TouchPhase;
    import starling.text.TextField;
    import starling.textures.Texture;
    import starling.utils.HAlign;
    import starling.utils.VAlign;

    /** 当用户点击或者触碰了按钮时进行分派，冒泡事件。 */
    [Event(name="triggered", type="starling.events.Event")]
    
    /** 一个简单的按钮由一张图片和一个可选的文本组成。
     *  
     *  <p>你可以分别为按钮构造函数传递up和down两种状态的纹理。
	 * 如果你没有指定一个down状态的纹理，按钮会采用默认的办法：被触碰的时候缩小一点。
	 * 此外，你可以在按钮上覆盖一个文本，要自定义这个文本，只需要提供和原来的基本相同的文本框即可。
	 * 你可以使用<code>textBounds</code>属性，将文本移动到一个指定的位置。</p>
     *  
     *  <p>判断按钮是否被触碰，请使用<code>triggered</code>事件类型，
	 * 用这个事件来代替普通的触碰事件。也就是说，用户只要在松开手指或者鼠标之前，移动手指/鼠标离开按钮区域，就可以取消对该按钮的点击操作。</p> 
     */ 
    public class Button extends DisplayObjectContainer
    {
        private static const MAX_DRAG_DIST:Number = 50;
        
        private var mUpState:Texture;
        private var mDownState:Texture;
        
        private var mContents:Sprite;
        private var mBackground:Image;
        private var mTextField:TextField;
        private var mTextBounds:Rectangle;
        
        private var mScaleWhenDown:Number;
        private var mAlphaWhenDisabled:Number;
        private var mEnabled:Boolean;
        private var mIsDown:Boolean;
        private var mUseHandCursor:Boolean;
        
        /**
         * 创建一个按钮实例，设置它的up和down状态的纹理，以及文本。
         * @param upState	up状态纹理
         * @param text		文本
         * @param downState	down状态纹理，默认为:null
         * @throws ArgumentError
         */
        public function Button(upState:Texture, text:String="", downState:Texture=null)
        {
            if (upState == null) throw new ArgumentError("Texture cannot be null");
            
            mUpState = upState;
            mDownState = downState ? downState : upState;
            mBackground = new Image(upState);
            mScaleWhenDown = downState ? 1.0 : 0.9;
            mAlphaWhenDisabled = 0.5;
            mEnabled = true;
            mIsDown = false;
            mUseHandCursor = true;
            mTextBounds = new Rectangle(0, 0, upState.width, upState.height);            
            
            mContents = new Sprite();
            mContents.addChild(mBackground);
            addChild(mContents);
            addEventListener(TouchEvent.TOUCH, onTouch);
            
            if (text.length != 0) this.text = text;
        }
        
        private function resetContents():void
        {
            mIsDown = false;
            mBackground.texture = mUpState;
            mContents.x = mContents.y = 0;
            mContents.scaleX = mContents.scaleY = 1.0;
        }
        
        private function createTextField():void
        {
            if (mTextField == null)
            {
                mTextField = new TextField(mTextBounds.width, mTextBounds.height, "");
                mTextField.vAlign = VAlign.CENTER;
                mTextField.hAlign = HAlign.CENTER;
                mTextField.touchable = false;
                mTextField.autoScale = true;
                mContents.addChild(mTextField);
            }
            
            mTextField.width  = mTextBounds.width;
            mTextField.height = mTextBounds.height;
            mTextField.x = mTextBounds.x;
            mTextField.y = mTextBounds.y;
        }
        
        private function onTouch(event:TouchEvent):void
        {
            Mouse.cursor = (mUseHandCursor && mEnabled && event.interactsWith(this)) ? 
                MouseCursor.BUTTON : MouseCursor.AUTO;
            
            var touch:Touch = event.getTouch(this);
            if (!mEnabled || touch == null) return;
            
            if (touch.phase == TouchPhase.BEGAN && !mIsDown)
            {
                mBackground.texture = mDownState;
                mContents.scaleX = mContents.scaleY = mScaleWhenDown;
                mContents.x = (1.0 - mScaleWhenDown) / 2.0 * mBackground.width;
                mContents.y = (1.0 - mScaleWhenDown) / 2.0 * mBackground.height;
                mIsDown = true;
            }
            else if (touch.phase == TouchPhase.MOVED && mIsDown)
            {
                // reset button when user dragged too far away after pushing
                var buttonRect:Rectangle = getBounds(stage);
                if (touch.globalX < buttonRect.x - MAX_DRAG_DIST ||
                    touch.globalY < buttonRect.y - MAX_DRAG_DIST ||
                    touch.globalX > buttonRect.x + buttonRect.width + MAX_DRAG_DIST ||
                    touch.globalY > buttonRect.y + buttonRect.height + MAX_DRAG_DIST)
                {
                    resetContents();
                }
            }
            else if (touch.phase == TouchPhase.ENDED && mIsDown)
            {
                resetContents();
                dispatchEventWith(Event.TRIGGERED, true);
            }
        }
        
        /** 当按钮被触碰的时候的缩放参数。
		 *  默认情况下，如果按钮含有down状态的纹理，则不会被缩放。 */
        public function get scaleWhenDown():Number { return mScaleWhenDown; }
        public function set scaleWhenDown(value:Number):void { mScaleWhenDown = value; }
        
        /** 当按钮被禁用时的透明度，默认为：0.5。  */
        public function get alphaWhenDisabled():Number { return mAlphaWhenDisabled; }
        public function set alphaWhenDisabled(value:Number):void { mAlphaWhenDisabled = value; }
        
        /** 按钮是否能够被触碰。 */
        public function get enabled():Boolean { return mEnabled; }
        public function set enabled(value:Boolean):void
        {
            if (mEnabled != value)
            {
                mEnabled = value;
                mContents.alpha = value ? 1.0 : mAlphaWhenDisabled;
                resetContents();
            }
        }
        
        /** 按钮上的显示文本。  */
        public function get text():String { return mTextField ? mTextField.text : ""; }
        public function set text(value:String):void
        {
            createTextField();
            mTextField.text = value;
        }
       
        /** 按钮上显示文本的字体名称。
		 *  可能是系统字体，或者已注册的位图字体。 */
        public function get fontName():String { return mTextField ? mTextField.fontName : "Verdana"; }
        public function set fontName(value:String):void
        {
            createTextField();
            mTextField.fontName = value;
        }
        
        /** 文本字体大小。 */
        public function get fontSize():Number { return mTextField ? mTextField.fontSize : 12; }
        public function set fontSize(value:Number):void
        {
            createTextField();
            mTextField.fontSize = value;
        }
        
        /** 文本字体颜色。 */
        public function get fontColor():uint { return mTextField ? mTextField.color : 0x0; }
        public function set fontColor(value:uint):void
        {
            createTextField();
            mTextField.color = value;
        }
        
        /** 文本字体是否加粗。 */
        public function get fontBold():Boolean { return mTextField ? mTextField.bold : false; }
        public function set fontBold(value:Boolean):void
        {
            createTextField();
            mTextField.bold = value;
        }
        
        /** 按钮默认情况下显示的纹理（即没有被触碰的时候）。 */
        public function get upState():Texture { return mUpState; }
        public function set upState(value:Texture):void
        {
            if (mUpState != value)
            {
                mUpState = value;
                if (!mIsDown) mBackground.texture = value;
            }
        }
        
        /** 按钮被触碰时显示的纹理。 */
        public function get downState():Texture { return mDownState; }
        public function set downState(value:Texture):void
        {
            if (mDownState != value)
            {
                mDownState = value;
                if (mIsDown) mBackground.texture = value;
            }
        }
        
        /** 按钮上文本框的边界矩形。
		 * 允许移动文本到一个自定义的位置。 */
        public function get textBounds():Rectangle { return mTextBounds.clone(); }
        public function set textBounds(value:Rectangle):void
        {
            mTextBounds = value.clone();
            createTextField();
        }
        
        /** 当光标移动到按钮上时，是否显示手型光标，默认为：true。
         *  @default true */
        public override function get useHandCursor():Boolean { return mUseHandCursor; }
        public override function set useHandCursor(value:Boolean):void { mUseHandCursor = value; }
    }
}