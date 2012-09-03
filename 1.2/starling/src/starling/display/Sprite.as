// =================================================================================================
//
//	Starling Framework
//	Copyright 2011 Gamua OG. All Rights Reserved.
//
//	This program is free software. You can redistribute and/or modify it
//	in accordance with the terms of the accompanying license agreement.
//
// =================================================================================================

package starling.display
{
    import flash.geom.Matrix;
    
    import starling.core.RenderSupport;
    import starling.events.Event;

    /** 当"平面化"这个对象时，向对象的所有子级分派此事件。 */
    [Event(name="flatten", type="starling.events.Event")]
    
    /** Sprite是一个极其轻量，非抽象的容器类。
	 * 
     *  <p>通常把Sprite作为一种把一组显示对象集中到一个坐标系内的简单手段，也可以把它用做自定义显示对象的基类。</p>
     *
     *  <strong>"平面化" Sprite对象</strong>
     * 
     *  <p><code>flatten</code>方法允许你在渲染时优化显示列表中的静态部分。</p>
     *
     *  <p><code>flatten</code> 分析了添加到这个Sprite的显示列表的子对象，优化了渲染调用，极大的提高了渲染速度。
	 * 但是速度的大幅提升是要付出代价的：你将再也看不见子对象属性的任何变化（位置，旋转，透明等等）。
	 * 要更新这个sprite对象的显示，只需再一次调用<code>flatten</code>，或者<code>unflatten</code>这个对象。</p>
     * 
     *  @see DisplayObject
     *  @see DisplayObjectContainer
     */  
    public class Sprite extends DisplayObjectContainer
    {
        private var mFlattenedContents:Vector.<QuadBatch>;
        
        /** 创建一个空的Sprite实例。 */
        public function Sprite()
        {
            super();
        }
        
        /** @inheritDoc */
        public override function dispose():void
        {
            unflatten();
            super.dispose();
        }
		
		/** 优化Sprite对象得到最佳渲染性能。
		 *  对于被"平面化"的Sprite，子对象的改变是不会有任何显示更新的。
		 *  要更新这个Sprite对象的显示，只需再一次调用<code>flatten</code>，或者对它进行<code>unflatten</code>。
		 *  */
        public function flatten():void
        {
            broadcastEventWith(Event.FLATTEN);
            
            if (mFlattenedContents == null)
                mFlattenedContents = new <QuadBatch>[];
            
            QuadBatch.compile(this, mFlattenedContents);
        }
        
        /** 取消对这个Sprite的"平面化"渲染优化操作。
		 *  此时子对象的改变会使Sprite对象立即更新显示。 */ 
        public function unflatten():void
        {
            if (mFlattenedContents)
            {
                var numBatches:int = mFlattenedContents.length;
                
                for (var i:int=0; i<numBatches; ++i)
                    mFlattenedContents[i].dispose();
                
                mFlattenedContents = null;
            }
        }
        
        /** 返回这个对象是否经过"平面化"处理。 */
        public function get isFlattened():Boolean { return mFlattenedContents != null; }
        
        /** @inheritDoc */
        public override function render(support:RenderSupport, parentAlpha:Number):void
        {
            if (mFlattenedContents)
            {
                var alpha:Number = parentAlpha * this.alpha;
                var numBatches:int = mFlattenedContents.length;
                var mvpMatrix:Matrix = support.mvpMatrix;
                
                support.finishQuadBatch();
                support.raiseDrawCount(numBatches);
                
                for (var i:int=0; i<numBatches; ++i)
                {
                    var quadBatch:QuadBatch = mFlattenedContents[i];
                    var blendMode:String = quadBatch.blendMode == BlendMode.AUTO ?
                        support.blendMode : quadBatch.blendMode;
                    quadBatch.renderCustom(mvpMatrix, alpha, blendMode);
                }
            }
            else super.render(support, parentAlpha);
        }
    }
}