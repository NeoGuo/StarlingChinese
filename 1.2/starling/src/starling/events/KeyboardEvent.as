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
        /** 事件类型：当一个键被释放。 */
        public static const KEY_UP:String = "keyUp";
        
        /** 事件类型：当一个键被按下。 */
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
        
        /** 按键的标示符号。 */
        public function get charCode():uint { return mCharCode; }
        
        /** 按键的标示符号。 */
        public function get keyCode():uint { return mKeyCode; }
        
        /** 按键在键盘上的区域。如果一个按键会在键盘上出现多次，这个属性将非常有用 。 @see Keylocation */ 
        public function get keyLocation():uint { return mKeyLocation; }
        
        /** 判断Alt键（Windows或Linux）或Option键（Mac OS）是否被激活。按下为true，松开为false。*/
        public function get altKey():Boolean { return mAltKey; }
        
        /** 判断Ctrl键（Windows或Linux）或Ctrl/Command键（Mac OS）是否被激活，按下为true，松开为false。 */
        public function get ctrlKey():Boolean { return mCtrlKey; }
        
        /**判断Shift键是否被激活，按下为true，松开为false。 */
        public function get shiftKey():Boolean { return mShiftKey; }
    }
}