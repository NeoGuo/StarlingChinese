// =================================================================================================
//
//	Starling Framework
//	Copyright 2012 Gamua OG. All Rights Reserved.
//
//	This program is free software. You can redistribute and/or modify it
//	in accordance with the terms of the accompanying license agreement.
//
// =================================================================================================

package starling.core
{
    import flash.display.Sprite;
    import flash.display.Stage3D;
    import flash.display.StageAlign;
    import flash.display.StageScaleMode;
    import flash.display3D.Context3D;
    import flash.display3D.Context3DCompareMode;
    import flash.display3D.Context3DTriangleFace;
    import flash.display3D.Program3D;
    import flash.errors.IllegalOperationError;
    import flash.events.ErrorEvent;
    import flash.events.Event;
    import flash.events.KeyboardEvent;
    import flash.events.MouseEvent;
    import flash.events.TouchEvent;
    import flash.geom.Rectangle;
    import flash.text.TextField;
    import flash.text.TextFieldAutoSize;
    import flash.text.TextFormat;
    import flash.text.TextFormatAlign;
    import flash.ui.Mouse;
    import flash.ui.Multitouch;
    import flash.ui.MultitouchInputMode;
    import flash.utils.ByteArray;
    import flash.utils.Dictionary;
    import flash.utils.getTimer;
    import flash.utils.setTimeout;
    
    import starling.animation.Juggler;
    import starling.display.DisplayObject;
    import starling.display.Stage;
    import starling.events.EventDispatcher;
    import starling.events.ResizeEvent;
    import starling.events.TouchPhase;
    import starling.utils.HAlign;
    import starling.utils.VAlign;
    
	/** 新的渲染环境创建后派发事件. */
    [Event(name="context3DCreate", type="starling.events.Event")]
    
	/** 根类创建后派发事件. */
    [Event(name="rootCreated", type="starling.events.Event")]
    
	/** Starling类展现了Starling框架的核心.
	 *
	 *  <p>Starling框架让使用Stage3D技术(在flash player 11中引入)创建二维程序和游戏成为可能。 它实现了和Flash
	 * 	一样的显示列表系统，同时使用先进的GPUs加速渲染. </p>
	 *  
	 *  <p>Starling类展示了Flash显示列表和Starling显示列表之间的结构关系。创建一个Starling应用程序，你必须首先
	 * 	创建一个Starling类的实例对象。</p>
	 *  
	 *  <pre>var starling:Starling = new Starling(Game, stage);</pre>
	 *  
	 *  <p>第一个参数必须是Starling的显示类。例如<code>starling.display.Sprite</code>的子类，在上面的例子
	 * 	中，类“Game”是程序的根。当Starling初始化后“Game”的对象也随之创建。
	 * 	第二个参数是FLash本身的stage对象，在默认情况下，Starling会在stage下层显示内容。</p>
	 *  
	 *  <p>建议保存Starling对象作为成员变量，这样可以保证垃圾回收系统不会销毁它。在创建Starling对象后，你必须这样启动它：</p>
	 * 
	 *  <pre>starling.start();</pre>
	 * 
	 *  <p>现在它会按照为程序设置好帧频率（和设置Flash stage的方法一样）来渲染“Game”类的内容了.</p> 
	 *  
	 *  <strong>访问Starling对象</strong>
	 * 
	 *  <p>在你的程序里，你可以在任意时间通过静态方法<code>Starling.current</code>访问当前的Starling对象。它会返回
	 * 	当前活跃的Starling实例（实际上大多数程序只会有一个Starling对象）。</p> 
	 * 
	 *  <strong>观察口，视口</strong>
	 * 
	 *  <p>即是Starling内容渲染显示的范围，默认情况下是舞台大小。但是，你可以使用“viewport”属性去改变它。当你只想在屏幕的一部分中
	 * 	渲染，或者播放器大小改变时，这个属性非常有用。随后你可以监听由Starling舞台发出的RESIZE事件。</p>
	 * 
	 *  <strong>原生Flash叠加层</strong>
	 *  
	 *  <p>有时你会想在Starling上面显示一些原生Flash内容，这就是<code>nativeOverlay</code>属性的作用。它返回的是在Starling之上
	 * 	的原生FLash Sprite。你可以在叠加层内添加原生Flash对象。</p>
	 *  
	 *  <p>但是需要注意，在3D加速内容之上的原生Flash内容在某些（移动）平台上会有性能上的问题。因为这个原因，请注意删除这一层中所有
	 * 	不需要和不再使用的对象。当这一层被置空后Starling会从显示列表中删除原生Flash叠加层。</p>
	 *  
	 *  <strong>多点触摸</strong>
	 *  
	 *  <p>对于提供支持多点触摸功能的设备，Starling也支持这项功能。在开发过程中，我们大多数基本上都是使用鼠标的键盘，Starling可以
	 * 	在“Shift”和“Ctrl”的帮助下（Mac苹果机是“Cmd”）模拟实现多点触摸事件。启动<code>simulateMultitouch</code>属性就可以激活
	 * 	这个功能。</p>
	 *  
	 *  <strong>处理丢失的渲染内容</strong>
	 *  
	 *  <p>在某些系统和某些条件下（例如，从系统睡眠中返回），Starling的stage3D渲染内容会丢失。如果类属性“handleLostContext”
	 * 	设置为 “true” Starling会自动修复丢失内容。但是需要注意，这是以提高内存消耗为代价的。Starling会在内存中创建纹理缓存，这样
	 * 	在内容丢失时才可以修复它。</p> 
	 *  
	 *  <p>如果你想和丢失的内容交互，Starling在这个内容修复时发送"Event.CONTEXT3D_CREATE"事件，你可以在相对应的事件监听器中重新
	 * 	创建这些不可用资源.</p>
	 * 
	 *  <strong>共享三维加速内容</strong>
	 * 
	 *  <p>正常情况下，Starling是独立处理stage3d加速内容。如果你想让Starling和其它的stage3d引擎同时使用，可能会达不到你需要的效果。
	 * 	在这种情况下，你可以使用<code>shareContext</code>属性:</p> 
	 *  
	 *  <ol>
	 *    <li>手动创建和定义一个让两个框架公用的context3D对象
	 *        (通过<code>stage3D.requestContext3D</code> 和
	 *        <code>context.configureBackBuffer</code>)创建.</li>
	 *    <li>使用已经定义了的context3d对象的stage3d实例来初始化Starling。
	 *        这样做会自动启用 <code>shareContext</code>.</li>
	 *    <li>调用Starling实例的  <code>start()</code>(与往常一样). 这样做是让  
	 *        Starling 对事件监听进行排队处理 (keyboard/mouse/touch).</li>
	 *    <li>创建一个游戏逻辑（例如，使用原生的<code>ENTER_FRAME</code>事件）然后让它调用Starling的 
	 *        <code>nextFrame</code>同时调用其它Stage3D引擎的同功能方法 . 
	 * 		相关类型的方法还有<code>context.clear()</code> 和
	 *        <code>context.present()</code>.</li>
	 *  </ol>
	 */
    public class Starling extends EventDispatcher
    {
		/** Starling framework的版本. */
        public static const VERSION:String = "1.3";
        
        /** 在'contextData'中存储的着色器程序的键值 */
        private static const PROGRAM_DATA_NAME:String = "Starling.programs"; 
        
        // members
        
        private var mStage3D:Stage3D;
        private var mStage:Stage; // starling.display.stage!
        private var mRootClass:Class;
        private var mRoot:DisplayObject;
        private var mJuggler:Juggler;
        private var mStarted:Boolean;        
        private var mSupport:RenderSupport;
        private var mTouchProcessor:TouchProcessor;
        private var mAntiAliasing:int;
        private var mSimulateMultitouch:Boolean;
        private var mEnableErrorChecking:Boolean;
        private var mLastFrameTimestamp:Number;
        private var mLeftMouseDown:Boolean;
        private var mStatsDisplay:StatsDisplay;
        private var mShareContext:Boolean;
        private var mProfile:String;
        private var mContext:Context3D;
        
        private var mViewPort:Rectangle;
        private var mPreviousViewPort:Rectangle;
        private var mClippedViewPort:Rectangle;
        
        private var mNativeStage:flash.display.Stage;
        private var mNativeOverlay:flash.display.Sprite;
        
        private static var sCurrent:Starling;
        private static var sHandleLostContext:Boolean;
        private static var sContextData:Dictionary = new Dictionary(true);
        
        // construction
        
		/** 创建一个新的Starling实例. 
		 *  @param rootClass  Starling显示对象的子类。它将会在Starling
		 *                    初始化完成后创建成为Starling舞台的第一个子对象
		 *  @param stage      Flash (2D) 舞台.
		 *  @param viewPort   一个显示内容的矩形区域. @default 舞台的大小
		 *  @param stage3D    渲染内容的stage3D对象. 如果已经包含了 context, <code>sharedContext</code>将会被设置为
		 * 					 <code>true</code>. @default 第一个 Stage3D.
		 *  @param renderMode 用这个参数设置软件加速. 
		 *  @param profile    要请求的 Context3DProfile 类型.
		 */
        public function Starling(rootClass:Class, stage:flash.display.Stage, 
                                 viewPort:Rectangle=null, stage3D:Stage3D=null,
                                 renderMode:String="auto", profile:String="baselineConstrained") 
        {
            if (stage == null) throw new ArgumentError("Stage must not be null");
            if (rootClass == null) throw new ArgumentError("Root class must not be null");
            if (viewPort == null) viewPort = new Rectangle(0, 0, stage.stageWidth, stage.stageHeight);
            if (stage3D == null) stage3D = stage.stage3Ds[0];
            
            makeCurrent();
            
            mRootClass = rootClass;
            mViewPort = viewPort;
            mPreviousViewPort = new Rectangle();
            mStage3D = stage3D;
            mStage = new Stage(viewPort.width, viewPort.height, stage.color);
            mNativeOverlay = new Sprite();
            mNativeStage = stage;
            mNativeStage.addChild(mNativeOverlay);
            mTouchProcessor = new TouchProcessor(mStage);
            mJuggler = new Juggler();
            mAntiAliasing = 0;
            mSimulateMultitouch = false;
            mEnableErrorChecking = false;
            mProfile = profile;
            mLastFrameTimestamp = getTimer() / 1000.0;
            mSupport  = new RenderSupport();
            
            // for context data, we actually reference by stage3D, since it survives a context loss
            sContextData[stage3D] = new Dictionary();
            sContextData[stage3D][PROGRAM_DATA_NAME] = new Dictionary();
            
            // all other modes are problematic in Starling, so we force those here
            stage.scaleMode = StageScaleMode.NO_SCALE;
            stage.align = StageAlign.TOP_LEFT;
            
            // register touch/mouse event handlers            
            for each (var touchEventType:String in touchEventTypes)
                stage.addEventListener(touchEventType, onTouch, false, 0, true);
            
            // register other event handlers
            stage.addEventListener(Event.ENTER_FRAME, onEnterFrame, false, 0, true);
            stage.addEventListener(KeyboardEvent.KEY_DOWN, onKey, false, 0, true);
            stage.addEventListener(KeyboardEvent.KEY_UP, onKey, false, 0, true);
            stage.addEventListener(Event.RESIZE, onResize, false, 0, true);
            stage.addEventListener(Event.MOUSE_LEAVE, onMouseLeave, false, 0, true);
            
            mStage3D.addEventListener(Event.CONTEXT3D_CREATE, onContextCreated, false, 10, true);
            mStage3D.addEventListener(ErrorEvent.ERROR, onStage3DError, false, 10, true);
            
            if (mStage3D.context3D && mStage3D.context3D.driverInfo != "Disposed")
            {
                mShareContext = true;
                setTimeout(initialize, 1); // we don't call it right away, because Starling should
                                           // behave the same way with or without a shared context
            }
            else
            {
                mShareContext = false;
                
                try
                {
                    // "Context3DProfile" is only available starting with Flash Player 11.4/AIR 3.4.
                    // to stay compatible with older versions, we check if the parameter is available.
                    
                    var requestContext3D:Function = mStage3D.requestContext3D;
                    if (requestContext3D.length == 1) requestContext3D(renderMode);
                    else requestContext3D(renderMode, profile);
                }
                catch (e:Error)
                {
                    showFatalError("Context3D error: " + e.message);
                }
            }
        }
        
		/**销毁stage的所有子级和渲染上下文，删除所有的事件侦听器*/
        public function dispose():void
        {
            stop();
            
            mNativeStage.removeEventListener(Event.ENTER_FRAME, onEnterFrame, false);
            mNativeStage.removeEventListener(KeyboardEvent.KEY_DOWN, onKey, false);
            mNativeStage.removeEventListener(KeyboardEvent.KEY_UP, onKey, false);
            mNativeStage.removeEventListener(Event.RESIZE, onResize, false);
            mNativeStage.removeEventListener(Event.MOUSE_LEAVE, onMouseLeave, false);
            mNativeStage.removeChild(mNativeOverlay);
            
            mStage3D.removeEventListener(Event.CONTEXT3D_CREATE, onContextCreated, false);
            mStage3D.removeEventListener(ErrorEvent.ERROR, onStage3DError, false);
            
            for each (var touchEventType:String in touchEventTypes)
                mNativeStage.removeEventListener(touchEventType, onTouch, false);
            
            if (mStage) mStage.dispose();
            if (mSupport) mSupport.dispose();
            if (mTouchProcessor) mTouchProcessor.dispose();
            if (mContext && !mShareContext) mContext.dispose();
            if (sCurrent == this) sCurrent = null;
        }
        
        // functions
        
        private function initialize():void
        {
            makeCurrent();
            
            initializeGraphicsAPI();
            initializeRoot();
            
            mTouchProcessor.simulateMultitouch = mSimulateMultitouch;
            mLastFrameTimestamp = getTimer() / 1000.0;
        }
        
        private function initializeGraphicsAPI():void
        {
            mContext = mStage3D.context3D;
            mContext.enableErrorChecking = mEnableErrorChecking;
            contextData[PROGRAM_DATA_NAME] = new Dictionary();
            
            updateViewPort(true);
            
            trace("[Starling] Initialization complete.");
            trace("[Starling] Display Driver:", mContext.driverInfo);
            
            dispatchEventWith(starling.events.Event.CONTEXT3D_CREATE, false, mContext);
        }
        
        private function initializeRoot():void
        {
            if (mRoot == null)
            {
                mRoot = new mRootClass() as DisplayObject;
                if (mRoot == null) throw new Error("Invalid root class: " + mRootClass);
                mStage.addChildAt(mRoot, 0);
            
                dispatchEventWith(starling.events.Event.ROOT_CREATED, false, mRoot);
            }
        }
        
		/** 调用 <code>advanceTime()</code> (上一帧到现在的渲染时间)
		 *  和 <code>render()</code>. */ 
        public function nextFrame():void
        {
            var now:Number = getTimer() / 1000.0;
            var passedTime:Number = now - mLastFrameTimestamp;
            mLastFrameTimestamp = now;
            
            advanceTime(passedTime);
            render();
        }
        
		/** 在显示列表上派发ENTER_FRAME事件, 优化 Juggler 
		 *  和 处理 触摸事件. */
        public function advanceTime(passedTime:Number):void
        {
            makeCurrent();
            
            mTouchProcessor.advanceTime(passedTime);
            mStage.advanceTime(passedTime);
            mJuggler.advanceTime(passedTime);
        }
        
		/** 渲染整个显示列表. 在渲染之前, context会被清除; 在这之后,
		 *  才进行显示. 启用<code>shareContext</code>可以禁用这项功能.*/ 
        public function render():void
        {
            if (!contextValid)
                return;
            
            makeCurrent();
            updateViewPort();
            updateNativeOverlay();
            mSupport.nextFrame();
            
            if (!mShareContext)
                RenderSupport.clear(mStage.color, 1.0);
            
            var scaleX:Number = mViewPort.width  / mStage.stageWidth;
            var scaleY:Number = mViewPort.height / mStage.stageHeight;
            
            mContext.setDepthTest(false, Context3DCompareMode.ALWAYS);
            mContext.setCulling(Context3DTriangleFace.NONE);
            
            mSupport.renderTarget = null; // back buffer
            mSupport.setOrthographicProjection(
                mViewPort.x < 0 ? -mViewPort.x / scaleX : 0.0, 
                mViewPort.y < 0 ? -mViewPort.y / scaleY : 0.0,
                mClippedViewPort.width  / scaleX, 
                mClippedViewPort.height / scaleY);
            
            mStage.render(mSupport, 1.0);
            mSupport.finishQuadBatch();
            
            if (mStatsDisplay)
                mStatsDisplay.drawCount = mSupport.drawCount;
            
            if (!mShareContext)
                mContext.present();
        }
        
        private function updateViewPort(updateAliasing:Boolean=false):void
        {
            // the last set viewport is stored in a variable; that way, people can modify the
            // viewPort directly (without a copy) and we still know if it has changed.
            
            if (updateAliasing || mPreviousViewPort.width != mViewPort.width || 
                mPreviousViewPort.height != mViewPort.height ||
                mPreviousViewPort.x != mViewPort.x || mPreviousViewPort.y != mViewPort.y)
            {
                mPreviousViewPort.setTo(mViewPort.x, mViewPort.y, mViewPort.width, mViewPort.height);
                
                // Constrained mode requires that the viewport is within the native stage bounds;
                // thus, we use a clipped viewport when configuring the back buffer. (In baseline
                // mode, that's not necessary, but it does not hurt either.)
                
                mClippedViewPort = mViewPort.intersection(
                    new Rectangle(0, 0, mNativeStage.stageWidth, mNativeStage.stageHeight));
                
                if (!mShareContext)
                {
                    // setting x and y might move the context to invalid bounds (since changing
                    // the size happens in a separate operation) -- so we have no choice but to
                    // set the backbuffer to a very small size first, to be on the safe side.
                    
                    if (mProfile == "baselineConstrained")
                        mSupport.configureBackBuffer(32, 32, mAntiAliasing, false);
                    
                    mStage3D.x = mClippedViewPort.x;
                    mStage3D.y = mClippedViewPort.y;
                    
                    mSupport.configureBackBuffer(
                        mClippedViewPort.width, mClippedViewPort.height, mAntiAliasing, false);
                }
                else
                {
                    mSupport.backBufferWidth  = mClippedViewPort.width;
                    mSupport.backBufferHeight = mClippedViewPort.height;
                }
            }
        }

        private function updateNativeOverlay():void
        {
            mNativeOverlay.x = mViewPort.x;
            mNativeOverlay.y = mViewPort.y;
            mNativeOverlay.scaleX = mViewPort.width / mStage.stageWidth;
            mNativeOverlay.scaleY = mViewPort.height / mStage.stageHeight;
        }
        
        private function showFatalError(message:String):void
        {
            var textField:TextField = new TextField();
            var textFormat:TextFormat = new TextFormat("Verdana", 12, 0xFFFFFF);
            textFormat.align = TextFormatAlign.CENTER;
            textField.defaultTextFormat = textFormat;
            textField.wordWrap = true;
            textField.width = mStage.stageWidth * 0.75;
            textField.autoSize = TextFieldAutoSize.CENTER;
            textField.text = message;
            textField.x = (mStage.stageWidth - textField.width) / 2;
            textField.y = (mStage.stageHeight - textField.height) / 2;
            textField.background = true;
            textField.backgroundColor = 0x440000;
            nativeOverlay.addChild(textField);
        }
        
		/** 让Starling实例成为 <code>current</code> 实例. */
        public function makeCurrent():void
        {
            sCurrent = this;
        }
        
		/** Starling启动后，它会对输入事件排队处理 (keyboard/mouse/touch);   
		 *  另外, <code>nextFrame</code>方法 会在Flash Player中每一帧调用。
		 *  (如果 <code>shareContext</code>启用: 在这种情况, 你必须手动
		 *  调用这个方法.) */
        public function start():void 
        { 
            mStarted = true; 
            mLastFrameTimestamp = getTimer() / 1000.0;
        }
        
		/**
		 * 停止所有的逻辑处理，并冻结游戏的当前状态。但实际上每一帧仍然在渲染内容（只是看起来不更新了），因为如果不这样做的话，传统显示列表就无法更新。
		 */		
        public function stop():void 
        { 
            mStarted = false; 
        }
        
        // event handlers
        
        private function onStage3DError(event:ErrorEvent):void
        {
            if (event.errorID == 3702)
                showFatalError("This application is not correctly embedded (wrong wmode value)");
            else
                showFatalError("Stage3D error: " + event.text);
        }
        
        private function onContextCreated(event:Event):void
        {
            if (!Starling.handleLostContext && mContext)
            {
                stop();
                event.stopImmediatePropagation();
                showFatalError("Fatal error: The application lost the device context!");
                trace("[Starling] The device context was lost. " + 
                      "Enable 'Starling.handleLostContext' to avoid this error.");
            }
            else
            {
                initialize();
            }
        }
        
        private function onEnterFrame(event:Event):void
        {
            // On mobile, the native display list is only updated on stage3D draw calls. 
            // Thus, we render even when Starling is paused.
            
            if (!mShareContext)
            {
                if (mStarted) nextFrame();
                else          render();
            }
        }
        
        private function onKey(event:KeyboardEvent):void
        {
            if (!mStarted) return;
            
            makeCurrent();
            mStage.dispatchEvent(new starling.events.KeyboardEvent(
                event.type, event.charCode, event.keyCode, event.keyLocation, 
                event.ctrlKey, event.altKey, event.shiftKey));
        }
        
        private function onResize(event:Event):void
        {
            var stage:flash.display.Stage = event.target as flash.display.Stage; 
            mStage.dispatchEvent(new ResizeEvent(Event.RESIZE, stage.stageWidth, stage.stageHeight));
        }

        private function onMouseLeave(event:Event):void
        {
            mTouchProcessor.enqueueMouseLeftStage();
        }
        
        private function onTouch(event:Event):void
        {
            if (!mStarted) return;
            
            var globalX:Number;
            var globalY:Number;
            var touchID:int;
            var phase:String;
            var pressure:Number = 1.0;
            var width:Number = 1.0;
            var height:Number = 1.0;
            
            // figure out general touch properties
            if (event is MouseEvent)
            {
                var mouseEvent:MouseEvent = event as MouseEvent;
                globalX = mouseEvent.stageX;
                globalY = mouseEvent.stageY;
                touchID = 0;
                
                // MouseEvent.buttonDown returns true for both left and right button (AIR supports
                // the right mouse button). We only want to react on the left button for now,
                // so we have to save the state for the left button manually.
                if (event.type == MouseEvent.MOUSE_DOWN)    mLeftMouseDown = true;
                else if (event.type == MouseEvent.MOUSE_UP) mLeftMouseDown = false;
            }
            else
            {
                var touchEvent:TouchEvent = event as TouchEvent;
                globalX = touchEvent.stageX;
                globalY = touchEvent.stageY;
                touchID = touchEvent.touchPointID;
                pressure = touchEvent.pressure;
                width = touchEvent.sizeX;
                height = touchEvent.sizeY;
            }
            
            // figure out touch phase
            switch (event.type)
            {
                case TouchEvent.TOUCH_BEGIN: phase = TouchPhase.BEGAN; break;
                case TouchEvent.TOUCH_MOVE:  phase = TouchPhase.MOVED; break;
                case TouchEvent.TOUCH_END:   phase = TouchPhase.ENDED; break;
                case MouseEvent.MOUSE_DOWN:  phase = TouchPhase.BEGAN; break;
                case MouseEvent.MOUSE_UP:    phase = TouchPhase.ENDED; break;
                case MouseEvent.MOUSE_MOVE: 
                    phase = (mLeftMouseDown ? TouchPhase.MOVED : TouchPhase.HOVER); break;
            }
            
            // move position into viewport bounds
            globalX = mStage.stageWidth  * (globalX - mViewPort.x) / mViewPort.width;
            globalY = mStage.stageHeight * (globalY - mViewPort.y) / mViewPort.height;
            
            // enqueue touch in touch processor
            mTouchProcessor.enqueue(touchID, phase, globalX, globalY, pressure, width, height);
        }
        
        private function get touchEventTypes():Array
        {
            return Mouse.supportsCursor || !multitouchEnabled ?
                [ MouseEvent.MOUSE_DOWN,  MouseEvent.MOUSE_MOVE, MouseEvent.MOUSE_UP ] :
                [ TouchEvent.TOUCH_BEGIN, TouchEvent.TOUCH_MOVE, TouchEvent.TOUCH_END ];  
        }
        
        // program management
        
		/**
		 * 根据一个指定的名称注册一个顶点和片段着色器程序。如果这个名称已经被使用了，那么上一个使用这个名称的程序将会被覆盖。
		 * @param name 名称
		 * @param vertexProgram 顶点着色程序
		 * @param fragmentProgram 片段着色程序
		 */		
        public function registerProgram(name:String, vertexProgram:ByteArray, fragmentProgram:ByteArray):void
        {
            deleteProgram(name);
            
            var program:Program3D = mContext.createProgram();
            program.upload(vertexProgram, fragmentProgram);            
            programs[name] = program;
        }
        
        /** 根据指定的名称，删除一个顶点着色程序和片段着色程序. */
        public function deleteProgram(name:String):void
        {
            var program:Program3D = getProgram(name);            
            if (program)
            {                
                program.dispose();
                delete programs[name];
            }
        }
        
        /** 根据指定的名称，返回一个已注册的顶点着色程序和片段着色程序. */
        public function getProgram(name:String):Program3D
        {
            return programs[name] as Program3D;
        }
        
        /** 根据指定的名称，判断这个顶点着色程序和片段着色程序是否被注册. */
        public function hasProgram(name:String):Boolean
        {
            return name in programs;
        }
        
        private function get programs():Dictionary { return contextData[PROGRAM_DATA_NAME]; }
        
        // properties
        
        /** 判断上下文是否是可用并且未销毁的. */
        private function get contextValid():Boolean
        {
            return (mContext && mContext.driverInfo != "Disposed");
        }
        
		/** Starling 实例是否启动. */
        public function get isStarted():Boolean { return mStarted; }
        
        /** 这个实例上的默认juggler对象. 这个对象将会在每一帧被调用. */
        public function get juggler():Juggler { return mJuggler; }
        
        /** 这个实例的渲染上下文. */
        public function get context():Context3D { return mContext; }
        
        /** A dictionary that can be used to save custom data related to the current context. 
         *  If you need to share data that is bound to a specific stage3D instance
         *  (e.g. textures), use this dictionary instead of creating a static class variable.
         *  The Dictionary is actually bound to the stage3D instance, thus it survives a 
         *  context loss. */
        public function get contextData():Dictionary
        {
            return sContextData[mStage3D] as Dictionary;
        }
        
		/** 多点触摸模拟 "Shift" 和 "Ctrl"/"Cmd"-是否启用. 
		 *  @default false */
        public function get simulateMultitouch():Boolean { return mSimulateMultitouch; }
        public function set simulateMultitouch(value:Boolean):void
        {
            mSimulateMultitouch = value;
            if (mContext) mTouchProcessor.simulateMultitouch = value;
        }
        
        /** Indicates if Stage3D render methods will report errors. Activate only when needed,
         *  as this has a negative impact on performance. @default false */
        public function get enableErrorChecking():Boolean { return mEnableErrorChecking; }
        public function set enableErrorChecking(value:Boolean):void 
        { 
            mEnableErrorChecking = value;
            if (mContext) mContext.enableErrorChecking = value; 
        }
        
        /** The antialiasing level. 0 - no antialasing, 16 - maximum antialiasing. @default 0 */
        public function get antiAliasing():int { return mAntiAliasing; }
        public function set antiAliasing(value:int):void
        {
            if (mAntiAliasing != value)
            {
                mAntiAliasing = value;
                if (contextValid) updateViewPort(true);
            }
        }
        
        /** The viewport into which Starling contents will be rendered. */
        public function get viewPort():Rectangle { return mViewPort; }
        public function set viewPort(value:Rectangle):void { mViewPort = value.clone(); }
        
        /** The ratio between viewPort width and stage width. Useful for choosing a different
         *  set of textures depending on the display resolution. */
        public function get contentScaleFactor():Number
        {
            return mViewPort.width / mStage.stageWidth;
        }
        
        /** A Flash Sprite placed directly on top of the Starling content. Use it to display native
         *  Flash components. */ 
        public function get nativeOverlay():Sprite { return mNativeOverlay; }
        
        /** Indicates if a small statistics box (with FPS, memory usage and draw count) is displayed. */
        public function get showStats():Boolean { return mStatsDisplay && mStatsDisplay.parent; }
        public function set showStats(value:Boolean):void
        {
            if (value == showStats) return;
            
            if (value)
            {
                if (mStatsDisplay) mStage.addChild(mStatsDisplay);
                else               showStatsAt();
            }
            else mStatsDisplay.removeFromParent();
        }
        
        /** Displays the statistics box at a certain position. */
        public function showStatsAt(hAlign:String="left", vAlign:String="top", scale:Number=1):void
        {
            if (mContext == null)
            {
                // Starling is not yet ready - we postpone this until it's initialized.
                addEventListener(starling.events.Event.ROOT_CREATED, onRootCreated);
            }
            else
            {
                if (mStatsDisplay == null)
                {
                    mStatsDisplay = new StatsDisplay();
                    mStatsDisplay.touchable = false;
                    mStage.addChild(mStatsDisplay);
                }
                
                var stageWidth:int  = mStage.stageWidth;
                var stageHeight:int = mStage.stageHeight;
                
                mStatsDisplay.scaleX = mStatsDisplay.scaleY = scale;
                
                if (hAlign == HAlign.LEFT) mStatsDisplay.x = 0;
                else if (hAlign == HAlign.RIGHT) mStatsDisplay.x = stageWidth - mStatsDisplay.width; 
                else mStatsDisplay.x = int((stageWidth - mStatsDisplay.width) / 2);
                
                if (vAlign == VAlign.TOP) mStatsDisplay.y = 0;
                else if (vAlign == VAlign.BOTTOM) mStatsDisplay.y = stageHeight - mStatsDisplay.height;
                else mStatsDisplay.y = int((stageHeight - mStatsDisplay.height) / 2);
            }
            
            function onRootCreated():void
            {
                showStatsAt(hAlign, vAlign, scale);
                removeEventListener(starling.events.Event.ROOT_CREATED, onRootCreated);
            }
        }
        
        /** The Starling stage object, which is the root of the display tree that is rendered. */
        public function get stage():Stage
        {
            return mStage;
        }

        /** The Flash Stage3D object Starling renders into. */
        public function get stage3D():Stage3D
        {
            return mStage3D;
        }
        
        /** The Flash (2D) stage object Starling renders beneath. */
        public function get nativeStage():flash.display.Stage
        {
            return mNativeStage;
        }
        
        /** The instance of the root class provided in the constructor. Available as soon as 
         *  the event 'ROOT_CREATED' has been dispatched. */
        public function get root():DisplayObject
        {
            return mRoot;
        }
        
        /** Indicates if the Context3D render calls are managed externally to Starling, 
         *  to allow other frameworks to share the Stage3D instance. @default false */
        public function get shareContext() : Boolean { return mShareContext; }
        public function set shareContext(value : Boolean) : void { mShareContext = value; }
        
        /** The Context3D profile as requested in the constructor. Beware that if you are 
         *  using a shared context, this might not be accurate. */
        public function get profile():String { return mProfile; }
        
        // static properties
        
        /** The currently active Starling instance. */
        public static function get current():Starling { return sCurrent; }
        
        /** The render context of the currently active Starling instance. */
        public static function get context():Context3D { return sCurrent ? sCurrent.context : null; }
        
        /** The default juggler of the currently active Starling instance. */
        public static function get juggler():Juggler { return sCurrent ? sCurrent.juggler : null; }
        
        /** The contentScaleFactor of the currently active Starling instance. */
        public static function get contentScaleFactor():Number 
        {
            return sCurrent ? sCurrent.contentScaleFactor : 1.0;
        }
        
        /** Indicates if multitouch input should be supported. */
        public static function get multitouchEnabled():Boolean 
        { 
            return Multitouch.inputMode == MultitouchInputMode.TOUCH_POINT;
        }
        
        public static function set multitouchEnabled(value:Boolean):void
        {
            if (sCurrent) throw new IllegalOperationError(
                "'multitouchEnabled' must be set before Starling instance is created");
            else 
                Multitouch.inputMode = value ? MultitouchInputMode.TOUCH_POINT :
                                               MultitouchInputMode.NONE;
        }
        
        /** Indicates if Starling should automatically recover from a lost device context.
         *  On some systems, an upcoming screensaver or entering sleep mode may 
         *  invalidate the render context. This setting indicates if Starling should recover from 
         *  such incidents. Beware that this has a huge impact on memory consumption!
         *  It is recommended to enable this setting on Android and Windows, but to deactivate it
         *  on iOS and Mac OS X. @default false */
        public static function get handleLostContext():Boolean { return sHandleLostContext; }
        public static function set handleLostContext(value:Boolean):void 
        {
            if (sCurrent) throw new IllegalOperationError(
                "'handleLostContext' must be set before Starling instance is created");
            else
                sHandleLostContext = value;
        }
    }
}