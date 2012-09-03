// =================================================================================================
//
//	Starling 框架
//	版权信息  2012 Gamua OG. 所有权利保留.
//
//	这个程序是免费软件. 你可以在协议范围内自由修改和再发布.
//
// =================================================================================================
package starling.core
{
    import flash.system.System;
    
    import starling.display.BlendMode;
    import starling.display.Quad;
    import starling.display.Sprite;
    import starling.events.EnterFrameEvent;
    import starling.events.Event;
    import starling.text.BitmapFont;
    import starling.text.TextField;
    import starling.utils.HAlign;
    import starling.utils.VAlign;
    
	/** 一个很小的，轻量级的盒子，它显示了当前的帧速率，内存消耗和每帧绘制调用次数 */
    internal class StatsDisplay extends Sprite
    {
        private var mBackground:Quad;
        private var mTextField:TextField;
        
        private var mFrameCount:int = 0;
        private var mDrawCount:int  = 0;
        private var mTotalTime:Number = 0;
        
		/** 创建一个数据统计盒子. */
        public function StatsDisplay()
        {
            mBackground = new Quad(50, 25, 0x0);
            mTextField = new TextField(48, 25, "", BitmapFont.MINI, BitmapFont.NATIVE_SIZE, 0xffffff);
            mTextField.x = 2;
            mTextField.hAlign = HAlign.LEFT;
            mTextField.vAlign = VAlign.TOP;
            
            addChild(mBackground);
            addChild(mTextField);
            
            addEventListener(Event.ENTER_FRAME, onEnterFrame);
            updateText(0, getMemory(), 0);
            blendMode = BlendMode.NONE;
        }
        
        private function updateText(fps:Number, memory:Number, drawCount:int):void
        {
            mTextField.text = "FPS: " + fps.toFixed(fps < 100 ? 1 : 0) + 
                            "\nMEM: " + memory.toFixed(memory < 100 ? 1 : 0) +
                            "\nDRW: " + drawCount; 
        }
        
        private function getMemory():Number
        {
            return System.totalMemory * 0.000000954; // 1 / (1024*1024) 转化成 MB	
        }
        
        private function onEnterFrame(event:EnterFrameEvent):void
        {
            mTotalTime += event.passedTime;
            mFrameCount++;
            
            if (mTotalTime > 1.0)
            {
                updateText(mFrameCount / mTotalTime, getMemory(), mDrawCount-2); // DRW: 忽略本身
                mFrameCount = mTotalTime = 0;
            }
        }
        
		/** Stage3D每秒绘制调用次数. */
        public function get drawCount():int { return mDrawCount; }
        public function set drawCount(value:int):void { mDrawCount = value; }
    }
}