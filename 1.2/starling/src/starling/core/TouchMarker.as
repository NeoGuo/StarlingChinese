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
    import flash.geom.Point;
    
    import starling.display.Image;
    import starling.display.Sprite;
    import starling.textures.Texture;
    
	/** TouchMarker在内部使用，它标记 触摸是通过"simulateMultitouch"创建的. */
    internal class TouchMarker extends Sprite
    {
        [Embed(source="../../assets/touch_marker.png")]
        private static var TouchMarkerBmp:Class;
        
        private var mCenter:Point;
        private var mTexture:Texture;
        
        public function TouchMarker()
        {
            mCenter = new Point();
            mTexture = Texture.fromBitmap(new TouchMarkerBmp());
            
            for (var i:int=0; i<2; ++i)
            {
                var marker:Image = new Image(mTexture);
                marker.pivotX = mTexture.width / 2;
                marker.pivotY = mTexture.height / 2;
                marker.touchable = false;
                addChild(marker);
            }
        }
        
        public override function dispose():void
        {
            mTexture.dispose();
            super.dispose();
        }
        
        public function moveMarker(x:Number, y:Number, withCenter:Boolean=false):void
        {
            if (withCenter)
            {
                mCenter.x += x - realMarker.x;
                mCenter.y += y - realMarker.y;
            }
            
            realMarker.x = x;
            realMarker.y = y;
            mockMarker.x = 2*mCenter.x - x;
            mockMarker.y = 2*mCenter.y - y;
        }
        
        public function moveCenter(x:Number, y:Number):void
        {
            mCenter.x = x;
            mCenter.y = y;
            moveMarker(realX, realY); // 重置模拟地址
        }
        
        private function get realMarker():Image { return getChildAt(0) as Image; }
        private function get mockMarker():Image { return getChildAt(1) as Image; }
        
        public function get realX():Number { return realMarker.x; }
        public function get realY():Number { return realMarker.y; }
        
        public function get mockX():Number { return mockMarker.x; }
        public function get mockY():Number { return mockMarker.y; }
    }        
}