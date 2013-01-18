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
    import flash.display.BitmapData;
    import flash.display3D.Context3D;
    import flash.display3D.Context3DTextureFormat;
    import flash.display3D.textures.TextureBase;
    
    import starling.core.Starling;
    import starling.events.Event;

	/** 一个封装了Stage3D纹理对象的ConcreteTexture，用于存储纹理属性。 */
    public class ConcreteTexture extends Texture
    {
        private var mBase:TextureBase;
        private var mFormat:String;
        private var mWidth:int;
        private var mHeight:int;
        private var mMipMapping:Boolean;
        private var mPremultipliedAlpha:Boolean;
        private var mOptimizedForRenderTexture:Boolean;
        private var mData:Object;
        private var mScale:Number;
        
		/**
		 * 创建一个具有TextureBase和存储信息(关于尺寸,mip映射和该Texture对象的alpha通道是否被
         * 预乘到RGB)的ConcreteTexture对象。
		 * @param base TextureBase对象
		 * @param format 格式
		 * @param width 宽度
		 * @param height 高度
		 * @param mipMapping mip映射
		 * @param premultipliedAlpha 预乘透明度
		 * @param optimizedForRenderTexture 优化渲染
		 * @param scale 缩放比例
		 */        
        public function ConcreteTexture(base:TextureBase, format:String, width:int, height:int, 
                                        mipMapping:Boolean, premultipliedAlpha:Boolean,
                                        optimizedForRenderTexture:Boolean=false,
                                        scale:Number=1)
        {
            mScale = scale <= 0 ? 1.0 : scale;
            mBase = base;
            mFormat = format;
            mWidth = width;
            mHeight = height;
            mMipMapping = mipMapping;
            mPremultipliedAlpha = premultipliedAlpha;
            mOptimizedForRenderTexture = optimizedForRenderTexture;
        }
        
		/** 释放TextureBase对象的纹理数据。 */
        public override function dispose():void
        {
            if (mBase) mBase.dispose();
            restoreOnLostContext(null); // removes event listener & data reference 
            super.dispose();
        }
        
        // texture backup (context lost)
        
		/** 指示此实例在上下文丢失时恢复其基本纹理。数据可以是BitmapData或包含ATF数据的ByteArray。 */ 
        public function restoreOnLostContext(data:Object):void
        {
            if (mData == null && data != null)
                Starling.current.addEventListener(Event.CONTEXT3D_CREATE, onContextCreated);
            else if (data == null)
                Starling.current.removeEventListener(Event.CONTEXT3D_CREATE, onContextCreated);
            
            mData = data;
        }
        
        private function onContextCreated(event:Event):void
        {
            var context:Context3D = Starling.context;
            var bitmapData:BitmapData = mData as BitmapData;
            var atfData:AtfData = mData as AtfData;
            var nativeTexture:flash.display3D.textures.Texture;
            
            if (bitmapData)
            {
                nativeTexture = context.createTexture(mWidth, mHeight, 
                    Context3DTextureFormat.BGRA, mOptimizedForRenderTexture);
                Texture.uploadBitmapData(nativeTexture, bitmapData, mMipMapping);
            }
            else if (atfData)
            {
                nativeTexture = context.createTexture(atfData.width, atfData.height, atfData.format,
                                                      mOptimizedForRenderTexture);
                Texture.uploadAtfData(nativeTexture, atfData.data);
            }
            
            mBase = nativeTexture;
        }
        
        // properties
        
		/** 表示当基础纹理进行纹理渲染时是否优化。 */
        public function get optimizedForRenderTexture():Boolean { return mOptimizedForRenderTexture; }
        
        /** @inheritDoc */
        public override function get base():TextureBase { return mBase; }
        
        /** @inheritDoc */
        public override function get root():ConcreteTexture { return this; }
        
        /** @inheritDoc */
        public override function get format():String { return mFormat; }
        
        /** @inheritDoc */
        public override function get width():Number  { return mWidth / mScale;  }
        
        /** @inheritDoc */
        public override function get height():Number { return mHeight / mScale; }
        
        /** @inheritDoc */
        public override function get nativeWidth():Number { return mWidth; }
        
        /** @inheritDoc */
        public override function get nativeHeight():Number { return mHeight; }
        
        /** The scale factor, which influences width and height properties. */
        public override function get scale():Number { return mScale; }
        
        /** @inheritDoc */
        public override function get mipMapping():Boolean { return mMipMapping; }
        
        /** @inheritDoc */
        public override function get premultipliedAlpha():Boolean { return mPremultipliedAlpha; }
    }
}