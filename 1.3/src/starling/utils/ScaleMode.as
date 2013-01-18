package starling.utils
{
    import starling.errors.AbstractClassError;

    /** 用于'RectangleUtil.fit' 方法的缩放模式常量值. */
    public class ScaleMode
    {
        /** @private */
        public function ScaleMode() { throw new AbstractClassError(); }
        
        /** 不缩放矩形，但是在整个区域中居中 */
        public static const NONE:String = "none";
        
        /** 等比缩放，填充整体区域，不留空白区域，有可能会对显示内容进行裁剪 */
        public static const NO_BORDER:String = "noBorder";
        
        /** 等比缩放，保持显示区域完整可见，可能会在上下或左右两侧留下空白区域 */
        public static const SHOW_ALL:String = "showAll";
        
        /** 判断缩放模式是否合法 */
        public static function isValid(scaleMode:String):Boolean
        {
            return scaleMode == NONE || scaleMode == NO_BORDER || scaleMode == SHOW_ALL;
        }
    }
}