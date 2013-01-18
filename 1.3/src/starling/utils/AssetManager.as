package starling.utils
{
    import flash.display.Bitmap;
    import flash.display.Loader;
    import flash.events.Event;
    import flash.events.IOErrorEvent;
    import flash.events.ProgressEvent;
    import flash.media.Sound;
    import flash.media.SoundChannel;
    import flash.media.SoundTransform;
    import flash.net.FileReference;
    import flash.net.URLLoader;
    import flash.net.URLLoaderDataFormat;
    import flash.net.URLRequest;
    import flash.system.ImageDecodingPolicy;
    import flash.system.LoaderContext;
    import flash.utils.ByteArray;
    import flash.utils.Dictionary;
    import flash.utils.clearTimeout;
    import flash.utils.describeType;
    import flash.utils.getQualifiedClassName;
    import flash.utils.setTimeout;
    
    import starling.core.Starling;
    import starling.text.BitmapFont;
    import starling.text.TextField;
    import starling.textures.Texture;
    import starling.textures.TextureAtlas;
    
    /** AssetManager这个类用于处理加载和访问各种素菜类型。你可以直接添加一个素材（通过'add...'方法），或者通过一个异步队列。
	 * 这使得你可以用一种统一的方式来处理资源，不管它们是来自于一个外部加载的文件，一个目录，一个URL地址，还是一个嵌入对象。
	 * <p>如果你是从磁盘上加载文件，那么下面的类型是支持的：<code>png, jpg, atf, mp3, xml, fnt</code></p>
     */    
    public class AssetManager
    {
        private const SUPPORTED_EXTENSIONS:Vector.<String> = 
            new <String>["png", "jpg", "jpeg", "atf", "mp3", "xml", "fnt"]; 
        
        private var mScaleFactor:Number;
        private var mUseMipMaps:Boolean;
        private var mVerbose:Boolean;
        
        private var mRawAssets:Array;
        private var mTextures:Dictionary;
        private var mAtlases:Dictionary;
        private var mSounds:Dictionary;
        
        /** 内部使用辅助对象 */
        private var sNames:Vector.<String> = new <String>[];
        
		/**
		 * 创建一个新的AssetManager实例。'scaleFactor' 和 'useMipmaps'这两个参数定义了队列中的位图如何转换为纹理。
		 * @param scaleFactor 缩放比例，默认-1
		 * @param useMipmaps 是否使用mip映射，默认false
		 */		
        public function AssetManager(scaleFactor:Number=-1, useMipmaps:Boolean=false)
        {
            mVerbose = false;
            mScaleFactor = scaleFactor > 0 ? scaleFactor : Starling.contentScaleFactor;
            mUseMipMaps = useMipmaps;
            mRawAssets = [];
            mTextures = new Dictionary();
            mAtlases = new Dictionary();
            mSounds = new Dictionary();
        }
        
        /** 销毁所有的纹理 */
        public function dispose():void
        {
            for each (var texture:Texture in mTextures)
                texture.dispose();
            
            for each (var atlas:TextureAtlas in mAtlases)
                atlas.dispose();
        }
        
        // retrieving
        
		/**
		 * 根据指定的名称返回一个纹理。这个方法首先会查询所有直接添加进来的纹理；
		 * 如果找不到这个名称的纹理，则会继续从所有的纹理图集中继续查找。
		 * @param name 名称
		 * @return Texture
		 */		
        public function getTexture(name:String):Texture
        {
            if (name in mTextures) return mTextures[name];
            else
            {
                for each (var atlas:TextureAtlas in mAtlases)
                {
                    var texture:Texture = atlas.getTexture(name);
                    if (texture) return texture;
                }
                return null;
            }
        }
        
		/**
		 * 根据指定的字符串前缀，返回所有符合条件的纹理，按照字母排序（对于"MovieClip"非常有用）。
		 * @param prefix 前缀
		 * @param result 返回数组
		 * @return 纹理数组
		 */		
        public function getTextures(prefix:String="", result:Vector.<Texture>=null):Vector.<Texture>
        {
            if (result == null) result = new <Texture>[];
            
            for each (var name:String in getTextureNames(prefix, sNames))
                result.push(getTexture(name));
            
            sNames.length = 0;
            return result;
        }
        
		/**
		 * 根据一个指定的字符串前缀，返回所有符合条件的纹理名称，按照字母排序。
		 * @param prefix 前缀
		 * @param result 存储结果的数组
		 * @return 名称数组
		 */		
        public function getTextureNames(prefix:String="", result:Vector.<String>=null):Vector.<String>
        {
            if (result == null) result = new <String>[];
            
            for (var name:String in mTextures)
                if (name.indexOf(prefix) == 0)
                    result.push(name);                
            
            for each (var atlas:TextureAtlas in mAtlases)
                atlas.getNames(prefix, result);
            
            result.sort(Array.CASEINSENSITIVE);
            return result;
        }
        
		/**
		 * 根据指定的名称，返回一个纹理图集，找不到的话就返回null
		 * @param name 名称
		 * @return 纹理图集
		 */		
        public function getTextureAtlas(name:String):TextureAtlas
        {
            return mAtlases[name] as TextureAtlas;
        }
        
		/**
		 * 根据指定的名称返回一个声音
		 * @param name 名称
		 * @return Sound
		 */		
        public function getSound(name:String):Sound
        {
            return mSounds[name];
        }
        
		/**
		 * 根据指定的字符串前缀返回符合条件的声音名称，按照字母排序。
		 * @param prefix 前缀
		 * @return 名称数组
		 */		
        public function getSoundNames(prefix:String=""):Vector.<String>
        {
            var names:Vector.<String> = new <String>[];
            
            for (var name:String in mSounds)
                if (name.indexOf(prefix) == 0)
                    names.push(name);
            
            return names.sort(Array.CASEINSENSITIVE);
        }
        
		/**
		 * 创建一个新的SoundChannel对象来播放声音.这个方法返回一个SoundChannel对象，这样你就可以用来停止声音播放或调整音量。
		 * @param name 名称
		 * @param startTime 起始时间
		 * @param loops 循环次数
		 * @param transform 声音变换控制
		 * @return SoundChannel
		 */		
        public function playSound(name:String, startTime:Number=0, loops:int=0, 
                                  transform:SoundTransform=null):SoundChannel
        {
            if (name in mSounds)
                return getSound(name).play(startTime, loops, transform);
            else 
                return null;
        }
        
        // direct adding
        
		/**
		 * 根据指定的名称注册一个纹理。注册后立刻可用。
		 * @param name 名称
		 * @param texture 纹理
		 */		
        public function addTexture(name:String, texture:Texture):void
        {
            log("Adding texture '" + name + "'");
            
            if (name in mTextures)
                throw new Error("Duplicate texture name: " + name);
            else
                mTextures[name] = texture;
        }
        
		/**
		 * 根据指定的名称注册一个纹理图集。注册后立刻可用。
		 * @param name 名称
		 * @param atlas 图集
		 */		
        public function addTextureAtlas(name:String, atlas:TextureAtlas):void
        {
            log("Adding texture atlas '" + name + "'");
            
            if (name in mAtlases)
                throw new Error("Duplicate texture atlas name: " + name);
            else
                mAtlases[name] = atlas;
        }
        
		/**
		 * 根据指定的名称注册一个声音。注册后立刻可用。
		 * @param name 名称
		 * @param sound 声音
		 */		
        public function addSound(name:String, sound:Sound):void
        {
            log("Adding sound '" + name + "'");
            
            if (name in mSounds)
                throw new Error("Duplicate sound name: " + name);
            else
                mSounds[name] = sound;
        }
        
        // removing
        
		/**
		 * 删除一个纹理，销毁它(可选)
		 * @param name 名称
		 * @param dispose 是否销毁
		 */		
        public function removeTexture(name:String, dispose:Boolean=true):void
        {
            if (dispose && name in mTextures)
                mTextures[name].dispose();
            
            delete mTextures[name];
        }
        
		/**
		 * 删除一个纹理图集，销毁它(可选)
		 * @param name 名称
		 * @param dispose 是否销毁
		 */		
        public function removeTextureAtlas(name:String, dispose:Boolean=true):void
        {
            if (dispose && name in mAtlases)
                mAtlases[name].dispose();
            
            delete mAtlases[name];
        }
        
		/**
		 * 删除一个声音
		 * @param name 名称
		 */		
        public function removeSound(name:String):void
        {
            delete mSounds[name];
        }
        
        /** 删除所有的素材，并清空队列 */
        public function purge():void
        {
            for each (var texture:Texture in mTextures)
                texture.dispose();
            
            for each (var atlas:TextureAtlas in mAtlases)
                atlas.dispose();
            
            mRawAssets.length = 0;
            mTextures = new Dictionary();
            mAtlases = new Dictionary();
            mSounds = new Dictionary();
        }
        
        // queued adding
        
        /** 将一个或一组素材加入到队列中；只有在成功调用了"loadQueue"方法后这些资源才可用。这个方法可以接受下面这些类型：
         *  <ul>
         *    <li>使用字符串定义的URL，链接到一个本地或远程网络上的资源。支持类型:
         *        <code>png, jpg, atf, mp3, fnt, xml</code> (纹理图集).</li>
         *    <li>File类的实例 (只有AIR应用适用) 指定的一个目录或一个文件.如果是目录，则会自动扫描该目录下所有支持的文件类型。</li>
         *    <li>包含静态成员结合Embed方式内嵌素材的类.</li>
         *  </ul>
         *  对象的名称会自动提取：比如一个文件名称是"image.png"，那么会自动将素材命名为"image"。如果是通过类的嵌入素材方式，那么变量名称就会使用嵌入时那个名称。
		 *  一个例外是纹理图集：他们将具备相同的名称（实际引用的那个纹理名称）。
         */
        public function enqueue(...rawAssets):void
        {
            for each (var rawAsset:Object in rawAssets)
            {
                if (rawAsset is Array)
                {
                    enqueue.apply(this, rawAsset);
                }
                else if (rawAsset is Class)
                {
                    var typeXml:XML = describeType(rawAsset);
                    var childNode:XML;
                    
                    if (mVerbose)
                        log("Looking for static embedded assets in '" + 
                            (typeXml.@name).split("::").pop() + "'"); 
                    
                    for each (childNode in typeXml.constant.(@type == "Class"))
                        push(rawAsset[childNode.@name], childNode.@name);
                    
                    for each (childNode in typeXml.variable.(@type == "Class"))
                        push(rawAsset[childNode.@name], childNode.@name);
                }
                else if (getQualifiedClassName(rawAsset) == "flash.filesystem::File")
                {
                    if (!rawAsset["exists"])
                    {
                        log("File or directory not found: '" + rawAsset["url"] + "'");
                    }
                    else if (!rawAsset["isHidden"])
                    {
                        if (rawAsset["isDirectory"])
                            enqueue.apply(this, rawAsset["getDirectoryListing"]());
                        else
                        {
                            var extension:String = rawAsset["extension"].toLowerCase();
                            if (SUPPORTED_EXTENSIONS.indexOf(extension) != -1)
                                push(rawAsset["url"]);
                            else
                                log("Ignoring unsupported file '" + rawAsset["name"] + "'");
                        }
                    }
                }
                else if (rawAsset is String)
                {
                    push(rawAsset);
                }
                else
                {
                    log("Ignoring unsupported asset type: " + getQualifiedClassName(rawAsset));
                }
            }
            
            function push(asset:Object, name:String=null):void
            {
                if (name == null) name = getName(asset);
                log("Enqueuing '" + name + "'");
                
                mRawAssets.push({ 
                    name: name, 
                    asset: asset 
                });
            }
        }
        
        /** 异步加载所有处于队列中的素材。'onProgress'方法会在加载过程中不断调用，并传递一个'ratio'值，范围是'0.0' 到 '1.0'，'1.0'就代表加载完成了。
         *  @param onProgress: <code>function(ratio:Number):void;</code> 
         */
        public function loadQueue(onProgress:Function):void
        {
            if (Starling.context == null)
                throw new Error("The Starling instance needs to be ready before textures can be loaded.");
            
            var xmls:Vector.<XML> = new <XML>[];
            var numElements:int = mRawAssets.length;
            var currentRatio:Number = 0.0;
            var timeoutID:uint;
            
            resume();
            
            function resume():void
            {
                currentRatio = 1.0 - (mRawAssets.length / numElements);
                
                if (mRawAssets.length)
                    timeoutID = setTimeout(processNext, 1);
                else
                    processXmls();
                
                if (onProgress != null)
                    onProgress(currentRatio);
            }
            
            function processNext():void
            {
                var assetInfo:Object = mRawAssets.pop();
                clearTimeout(timeoutID);
                loadRawAsset(assetInfo.name, assetInfo.asset, xmls, progress, resume);
            }
            
            function processXmls():void
            {
                // xmls are processed seperately at the end, because the textures they reference
                // have to be available for other XMLs. Texture atlases are processed first:
                // that way, their textures can be referenced, too.
                
                xmls.sort(function(a:XML, b:XML):int { 
                    return a.localName() == "TextureAtlas" ? -1 : 1; 
                });
                
                for each (var xml:XML in xmls)
                {
                    var name:String;
                    var rootNode:String = xml.localName();
                    
                    if (rootNode == "TextureAtlas")
                    {
                        name = getName(xml.@imagePath.toString());
                        
                        var atlasTexture:Texture = getTexture(name);
                        addTextureAtlas(name, new TextureAtlas(atlasTexture, xml));
                        removeTexture(name, false);
                    }
                    else if (rootNode == "font")
                    {
                        name = getName(xml.pages.page.@file.toString());
                        
                        var fontTexture:Texture = getTexture(name);
                        TextField.registerBitmapFont(new BitmapFont(fontTexture, xml));
                        removeTexture(name, false);
                    }
                    else
                        throw new Error("XML contents not recognized: " + rootNode);
                }
            }
            
            function progress(ratio:Number):void
            {
                onProgress(currentRatio + (1.0 / numElements) * Math.min(1.0, ratio) * 0.99);
            }
        }
        
        private function loadRawAsset(name:String, rawAsset:Object, xmls:Vector.<XML>,
                                      onProgress:Function, onComplete:Function):void
        {
            var extension:String = null;
            
            if (rawAsset is Class)
            {
                var asset:Object = new rawAsset();
                
                if (asset is Sound)
                {
                    addSound(name, asset as Sound);
                    onComplete();
                }
                else if (asset is Bitmap)
                {
                    addTexture(name, Texture.fromBitmap(asset as Bitmap, mUseMipMaps, false, mScaleFactor));
                    onComplete();
                }
                else if (asset is ByteArray)
                {
                    var bytes:ByteArray = asset as ByteArray;
                    var signature:String = String.fromCharCode(bytes[0], bytes[1], bytes[2]);
                    
                    if (signature == "ATF")
                    {
                        addTexture(name, Texture.fromAtfData(asset as ByteArray, mScaleFactor, 
                            mUseMipMaps, onComplete));
                    }
                    else
                    {
                        xmls.push(new XML(bytes));
                        onComplete();
                    }
                }
                else
                {
                    log("Ignoring unsupported asset type: " + getQualifiedClassName(asset));
                    onComplete();
                }
            }
            else if (rawAsset is String)
            {
                var url:String = rawAsset as String;
                extension = url.split(".").pop().toLowerCase();
                
                var urlLoader:URLLoader = new URLLoader();
                urlLoader.dataFormat = URLLoaderDataFormat.BINARY;
                urlLoader.addEventListener(IOErrorEvent.IO_ERROR, onIoError);
                urlLoader.addEventListener(ProgressEvent.PROGRESS, onLoadProgress);
                urlLoader.addEventListener(Event.COMPLETE, onUrlLoaderComplete);
                urlLoader.load(new URLRequest(url));
            }
            
            function onIoError(event:IOErrorEvent):void
            {
                log("IO error: " + event.text);
                onComplete();
            }
            
            function onLoadProgress(event:ProgressEvent):void
            {
                onProgress(event.bytesLoaded / event.bytesTotal);
            }
            
            function onUrlLoaderComplete(event:Event):void
            {
                var urlLoader:URLLoader = event.target as URLLoader;
                var bytes:ByteArray = urlLoader.data as ByteArray;
                var sound:Sound;
                
                urlLoader.removeEventListener(IOErrorEvent.IO_ERROR, onIoError);
                urlLoader.removeEventListener(ProgressEvent.PROGRESS, onProgress);
                urlLoader.removeEventListener(Event.COMPLETE, onUrlLoaderComplete);
                
                switch (extension)
                {
                    case "atf":
                        addTexture(name, Texture.fromAtfData(bytes, mScaleFactor, mUseMipMaps, onComplete));
                        break;
                    case "fnt":
                    case "xml":
                        xmls.push(new XML(bytes));
                        onComplete();
                        break;
                    case "mp3":
                        sound = new Sound();
                        sound.loadCompressedDataFromByteArray(bytes, bytes.length);
                        addSound(name, sound);
                        onComplete();
                        break;
                    default:
                        var loaderContext:LoaderContext = new LoaderContext();
                        var loader:Loader = new Loader();
                        loaderContext.imageDecodingPolicy = ImageDecodingPolicy.ON_LOAD;
                        loader.contentLoaderInfo.addEventListener(Event.COMPLETE, onLoaderComplete);
                        loader.loadBytes(urlLoader.data as ByteArray, loaderContext);
                        break;
                }
            }
            
            function onLoaderComplete(event:Event):void
            {
                event.target.removeEventListener(Event.COMPLETE, onLoaderComplete);
                var content:Object = event.target.content;
                
                if (content is Bitmap)
                    addTexture(name,
                        Texture.fromBitmap(content as Bitmap, mUseMipMaps, false, mScaleFactor));
                else
                    throw new Error("Unsupported asset type: " + getQualifiedClassName(content));
                
                onComplete();
            }
        }
        
        // helpers
        
        private function getName(rawAsset:Object):String
        {
            var matches:Array;
            var name:String;
            
            if (rawAsset is String || rawAsset is FileReference)
            {
                name = rawAsset is String ? rawAsset as String : (rawAsset as FileReference).name;
                name = name.replace(/%20/g, " "); // URLs use '%20' for spaces
                matches = /(.*[\\\/])?([\w\s\-]+)(\.[\w]{1,4})?/.exec(name);
                
                if (matches && matches.length == 4) return matches[2];
                else throw new ArgumentError("Could not extract name from String '" + rawAsset + "'");
            }
            else
            {
                name = getQualifiedClassName(rawAsset);
                throw new ArgumentError("Cannot extract names for objects of type '" + name + "'");
            }
        }
        
        private function log(message:String):void
        {
            if (verbose) trace("[AssetManager]", message);
        }
        
        // properties
        
        /**是否输出加载过程中的信息 */
        public function get verbose():Boolean { return mVerbose; }
        public function set verbose(value:Boolean):void { mVerbose = value; }
        
		/**对于位图纹理，此标志表示，加载后创建的纹理是否使用MIP映射;
		 * 对于ATF格式的纹理，它表示使用的时候MIP映射是否有效。*/
        public function get useMipMaps():Boolean { return mUseMipMaps; }
        public function set useMipMaps(value:Boolean):void { mUseMipMaps = value; }
        
        /** 无论是从位图创建的纹理，还是ATF格式的纹理，都会被分配一个缩放比例 */
        public function get scaleFactor():Number { return mScaleFactor; }
        public function set scaleFactor(value:Number):void { mScaleFactor = value; }
    }
}