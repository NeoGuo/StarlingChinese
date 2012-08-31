// =================================================================================================
//
//	Starling Framework
//	Copyright 2011 Gamua OG. All Rights Reserved.
//
//	This program is free software. You can redistribute and/or modify it
//	in accordance with the terms of the accompanying license agreement.
//
// =================================================================================================

package starling.events
{
    /** 一个键盘事件的派发，是对用户使用键盘输入的回应。
     * 
     *  <p>这个类是Flash的键盘事件的Starling版本。它包含了和Flash的键盘事件相同的属性。</p> 
     * 
     *  <p>要捕获键盘事件，需要在Starling的stage上添加事件侦听。stage的子节点是不能获取到键盘事件的。 
     *  Starling并没有像传统Flash那样的“焦点”的概念。</p>
     *  
     *  @see starling.display.Stage
     */  
    public class KeyboardEvent extends Event
    {
        /** Event type for a key that was released. */
        public static const KEY_UP:String = "keyUp";
        
        /** Event type for a key that was pressed. */
        public static const KEY_DOWN:String = "keyDown";
        
        private var mCharCode:uint;
        private var mKeyCode:uint;
        private var mKeyLocation:uint;
        private var mAltKey:Boolean;
        private var mCtrlKey:Boolean;
        private var mShiftKey:Boolean;
        
        /** Creates a new KeyboardEvent. */
        public function KeyboardEvent(type:String, charCode:uint=0, keyCode:uint=0, 
                                      keyLocation:uint=0, ctrlKey:Boolean=false, 
                                      altKey:Boolean=false, shiftKey:Boolean=false)
        {
            super(type, false, keyCode);
            mCharCode = charCode;
            mKeyCode = keyCode;
            mKeyLocation = keyLocation;
            mCtrlKey = ctrlKey;
            mAltKey = altKey;
            mShiftKey = shiftKey;
        }
        
        /** Contains the character code of the key. */
        public function get charCode():uint { return mCharCode; }
        
        /** The key code of the key. */
        public function get keyCode():uint { return mKeyCode; }
        
        /** Indicates the location of the key on the keyboard. This is useful for differentiating 
         *  keys that appear more than once on a keyboard. @see Keylocation */ 
        public function get keyLocation():uint { return mKeyLocation; }
        
        /** Indicates whether the Alt key is active on Windows or Linux; 
         *  indicates whether the Option key is active on Mac OS. */
        public function get altKey():Boolean { return mAltKey; }
        
        /** Indicates whether the Ctrl key is active on Windows or Linux; 
         *  indicates whether either the Ctrl or the Command key is active on Mac OS. */
        public function get ctrlKey():Boolean { return mCtrlKey; }
        
        /** Indicates whether the Shift key modifier is active (true) or inactive (false). */
        public function get shiftKey():Boolean { return mShiftKey; }
    }
}