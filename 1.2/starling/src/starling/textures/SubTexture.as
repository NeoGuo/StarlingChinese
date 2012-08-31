// =================================================================================================
//
//	Starling Framework
//	Copyright 2011 Gamua OG. All Rights Reserved.
//
//	This program is free software. You can redistribute and/or modify it
//	in accordance with the terms of the accompanying license agreement.
//
// =================================================================================================

package starling.textures
{
    import flash.display3D.textures.TextureBase;
    import flash.geom.Point;
    import flash.geom.Rectangle;
    
    import starling.utils.VertexData;

    /** 一个SubTexture用于表现另一个纹理的一部分。由于这是完全通过操作纹理坐标实现的，使得这个类非常高效。
     *
     *  <p><em>注意：从子纹理继续创建子纹理也是允许的。</em></p>
     */ 
    public class SubTexture extends Texture
    {
        private var mParent:Texture;
        private var mClipping:Rectangle;
        private var mRootClipping:Rectangle;
        private var mOwnsParent:Boolean;
        
        /** 助手对象。 */
        private static var sTexCoords:Point = new Point();
        
        /** 从一个父级纹理对象指定的区域（点）来创建一个新的SubTexture对象。 
         * 如果ownsParent设置为true，当subtexture被释放的时，父级纹理对象也会被释放。*/
        public function SubTexture(parentTexture:Texture, region:Rectangle,
                                   ownsParent:Boolean=false)
        {
            mParent = parentTexture;
            mOwnsParent = ownsParent;
            
            if (region == null) setClipping(new Rectangle(0, 0, 1, 1));
            else setClipping(new Rectangle(region.x / parentTexture.width,
                                           region.y / parentTexture.height,
                                           region.width / parentTexture.width,
                                           region.height / parentTexture.height));
        }
        
        /**如果ownsParent为true释放父级纹理对象。 */
        public override function dispose():void
        {
            if (mOwnsParent) mParent.dispose();
            super.dispose();
        }
        
        private function setClipping(value:Rectangle):void
        {
            mClipping = value;
            mRootClipping = value.clone();
            
            var parentTexture:SubTexture = mParent as SubTexture;
            while (parentTexture)
            {
                var parentClipping:Rectangle = parentTexture.mClipping;
                mRootClipping.x = parentClipping.x + mRootClipping.x * parentClipping.width;
                mRootClipping.y = parentClipping.y + mRootClipping.y * parentClipping.height;
                mRootClipping.width  *= parentClipping.width;
                mRootClipping.height *= parentClipping.height;
                parentTexture = parentTexture.mParent as SubTexture;
            }
        }
        
        /** @inheritDoc */
        public override function adjustVertexData(vertexData:VertexData, vertexID:int, count:int):void
        {
            super.adjustVertexData(vertexData, vertexID, count);
            
            var clipX:Number = mRootClipping.x;
            var clipY:Number = mRootClipping.y;
            var clipWidth:Number  = mRootClipping.width;
            var clipHeight:Number = mRootClipping.height;
            var endIndex:int = vertexID + count;
            
            for (var i:int=vertexID; i<endIndex; ++i)
            {
                vertexData.getTexCoords(i, sTexCoords);
                vertexData.setTexCoords(i, clipX + sTexCoords.x * clipWidth,
                                           clipY + sTexCoords.y * clipHeight);
            }
        }
        
        /** 该子纹理所基于的纹理对象。 */ 
        public function get parent():Texture { return mParent; }
        
        /** 指示父级纹理对象是否因当前子纹理对象的释放而释放。 */
        public function get ownsParent():Boolean { return mOwnsParent; }
        
        /** 一个在初始化时规定缩放到[0.0, 1.0]的裁剪矩形区域。 */
        public function get clipping():Rectangle { return mClipping.clone(); }
        
        /** @inheritDoc */
        public override function get base():TextureBase { return mParent.base; }
        
        /** @inheritDoc */
        public override function get format():String { return mParent.format; }
        
        /** @inheritDoc */
        public override function get width():Number { return mParent.width * mClipping.width; }
        
        /** @inheritDoc */
        public override function get height():Number { return mParent.height * mClipping.height; }
        
        /** @inheritDoc */
        public override function get mipMapping():Boolean { return mParent.mipMapping; }
        
        /** @inheritDoc */
        public override function get premultipliedAlpha():Boolean { return mParent.premultipliedAlpha; }
        
        /** @inheritDoc */
        public override function get scale():Number { return mParent.scale; } 
        
    }
}