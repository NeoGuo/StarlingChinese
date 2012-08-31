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
    import flash.geom.Rectangle;
    import flash.utils.Dictionary;

    /** 纹理集是一个将许多小的纹理整合到一张大图中。这个类是用来从一个纹理集中读取纹理。
     *  
     *  <p>使用纹理集能为你的纹理解决两个问题:</p>
     *  
     *  <ul>
     *    <li>在一定的时间内，始终有一个纹理处于活动的。每当你改变了处于活动的纹理，一个
     *        “纹理切换”就会执行，这个切换是需要时间的。</li>
     *    <li>任何Stage3D纹理的边长都必须是2的幂数。Starling向你隐藏了这个限制，但这将带来
     *        额外的图形存储成本。</li>
     *  </ul>
     *  
     *  <p>通过使用纹理集，您可以避免使用纹理切换和取消2的幂数的限制。所有的纹理被集合在一
     *     个“超级纹理”，并且Starling会确保纹理正确的部分被显示出来。</p>
     *  
     *  <p>有几种方法来创建纹理集。一种是使用捆绑在Starling的姊妹框架<a href="http://www.sparrow-framework.org">
     *     Sparrow framework</a>。里的纹理集生成脚本。 尽管目前这个脚本只能运行在Mac OS X上。
     *     另一个可供选择的出色工具 <a href="http://www.texturepacker.com">Texture Packer</a>，
     *     他是一个跨平台的商业软件。</p>
     *  
     *  <p>无论您使用的工具是什么，Starling可以支持以下文档格式:</p>
     * 
     *  <listing>
     * 	&lt;TextureAtlas imagePath='atlas.png'&gt;
     * 	  &lt;SubTexture name='texture_1' x='0'  y='0' width='50' height='50'/&gt;
     * 	  &lt;SubTexture name='texture_2' x='50' y='0' width='20' height='30'/&gt; 
     * 	&lt;/TextureAtlas&gt;
     *  </listing>
     *  
     *  <p>如果你的图像在边缘具有透明区域，您可以使用Texture类的<code>frame</code>属性。 通过
     *     去除纹理的透明边缘并且指定原始尺寸就像这样：</p>
     * 
     *  <listing>
     * 	&lt;SubTexture name='trimmed' x='0' y='0' height='10' width='10'
     * 	    frameX='-10' frameY='-10' frameWidth='30' frameHeight='30'/&gt;
     *  </listing>
     */
    public class TextureAtlas
    {
        private var mAtlasTexture:Texture;
        private var mTextureRegions:Dictionary;
        private var mTextureFrames:Dictionary;
        
        /** 通过指定纹理和用于描述范围的XML来创建一个纹理集。 */
        public function TextureAtlas(texture:Texture, atlasXml:XML=null)
        {
            mTextureRegions = new Dictionary();
            mTextureFrames  = new Dictionary();
            mAtlasTexture   = texture;
            
            if (atlasXml)
                parseAtlasXml(atlasXml);
        }
        
        /** 释放纹理集。 */
        public function dispose():void
        {
            mAtlasTexture.dispose();
        }
        
        /** 这个函数被构造函数调用,并用Starling默认的纹理集格式解析XML,重写
            这个方法去创建自定义逻辑(举例来说 去支持一个不同的文档格式)。 */
        protected function parseAtlasXml(atlasXml:XML):void
        {
            var scale:Number = mAtlasTexture.scale;
            
            for each (var subTexture:XML in atlasXml.SubTexture)
            {
                var name:String        = subTexture.attribute("name");
                var x:Number           = parseFloat(subTexture.attribute("x")) / scale;
                var y:Number           = parseFloat(subTexture.attribute("y")) / scale;
                var width:Number       = parseFloat(subTexture.attribute("width")) / scale;
                var height:Number      = parseFloat(subTexture.attribute("height")) / scale;
                var frameX:Number      = parseFloat(subTexture.attribute("frameX")) / scale;
                var frameY:Number      = parseFloat(subTexture.attribute("frameY")) / scale;
                var frameWidth:Number  = parseFloat(subTexture.attribute("frameWidth")) / scale;
                var frameHeight:Number = parseFloat(subTexture.attribute("frameHeight")) / scale;
                
                var region:Rectangle = new Rectangle(x, y, width, height);
                var frame:Rectangle  = frameWidth > 0 && frameHeight > 0 ?
                        new Rectangle(frameX, frameY, frameWidth, frameHeight) : null;
                
                addRegion(name, region, frame);
            }
        }
        
        /** 根据名称返回一个子纹理。如果没有找到，就返回null。 */
        public function getTexture(name:String):Texture
        {
            var region:Rectangle = mTextureRegions[name];
            
            if (region == null) return null;
            else return Texture.fromTexture(mAtlasTexture, region, mTextureFrames[name]);
        }
        
        /** 返回由一个指定的字符串开始按字母排序的所有纹理(这对"MovieClip"来说非常有用)。 */
        public function getTextures(prefix:String=""):Vector.<Texture>
        {
            var textures:Vector.<Texture> = new <Texture>[];
            var names:Vector.<String> = new <String>[];
            var name:String;
            
            for (name in mTextureRegions)
                if (name.indexOf(prefix) == 0)                
                    names.push(name);                
            
            names.sort(Array.CASEINSENSITIVE);
            
            for each (name in names) 
                textures.push(getTexture(name)); 
            
            return textures;
        }
        
        /** 根据特定名称返回一个矩形区域。 */
        public function getRegion(name:String):Rectangle
        {
            return mTextureRegions[name];
        }
        
        /** 根据一个特定区域返回一个矩形框架,如果那个区域内没有框架就返回null。 */
        public function getFrame(name:String):Rectangle
        {
            return mTextureFrames[name];
        }
        
        /** 为一个subtexture(通过像素坐标系里的矩阵来描述)添加一个含名字的区域以及一个可选的frame参数。 */
        public function addRegion(name:String, region:Rectangle, frame:Rectangle=null):void
        {
            mTextureRegions[name] = region;
            mTextureFrames[name]  = frame;
        }
        
        /** 通过名字来删除一个区域。 */
        public function removeRegion(name:String):void
        {
            delete mTextureRegions[name];
            delete mTextureFrames[name];
        }
    }
}