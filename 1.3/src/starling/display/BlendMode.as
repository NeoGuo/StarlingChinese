// =================================================================================================
//
//	Starling Framework
//	Copyright 2012 Gamua OG. All Rights Reserved.
//
//	This program is free software. You can redistribute and/or modify it
//	in accordance with the terms of the accompanying license agreement.
//
// =================================================================================================

package starling.display
{
    import flash.display3D.Context3DBlendFactor;
    
    import starling.errors.AbstractClassError;
    
	/** BlendMode类提供了混合模式视觉效果的常量。
	 *   
	 *  <p>一个混合模式，总是由两个'Context3DBlendFactor'值来定义。一个混合因素代表一个特定的四个数值的数组。
	 * 这个数组是根据源颜色和目标颜色用混合公式计算的，公式如下：</p>
	 * 
	 *  <pre>result = source × sourceFactor + destination × destinationFactor</pre>
	 * 
	 *  <p>在这个公式里，源颜色是像素着色器的输出颜色，目标颜色是在上一次清除和绘制操作以后，颜色缓冲区中当前存在的颜色。</p>
	 *  
	 *  <p>要注意的是，由于纹理类型的不同，混合因素产生产生的输出也不同。
	 * 纹理可能包含'预乘透明度'(pma)，意思就是它们的RGB色值是根据它们的颜色值分别相乘得到的（目的是节省计算时间）。
	 * 基于'BitmapData'的纹理，会含有预乘透明度值，ATF纹理没有这个值。
	 * 因此，一个混合模式可能会根据pma的值而拥有不同的混合因素。</p>
	 *  
	 *  @see flash.display3D.Context3DBlendFactor
	 */
    public class BlendMode
    {
        private static var sBlendFactors:Array = [ 
            // no premultiplied alpha
            { 
                "none"     : [ Context3DBlendFactor.ONE, Context3DBlendFactor.ZERO ],
                "normal"   : [ Context3DBlendFactor.SOURCE_ALPHA, Context3DBlendFactor.ONE_MINUS_SOURCE_ALPHA ],
                "add"      : [ Context3DBlendFactor.SOURCE_ALPHA, Context3DBlendFactor.DESTINATION_ALPHA ],
                "multiply" : [ Context3DBlendFactor.DESTINATION_COLOR, Context3DBlendFactor.ONE_MINUS_SOURCE_ALPHA ],
                "screen"   : [ Context3DBlendFactor.SOURCE_ALPHA, Context3DBlendFactor.ONE ],
                "erase"    : [ Context3DBlendFactor.ZERO, Context3DBlendFactor.ONE_MINUS_SOURCE_ALPHA ]
            },
            // premultiplied alpha
            { 
                "none"     : [ Context3DBlendFactor.ONE, Context3DBlendFactor.ZERO ],
                "normal"   : [ Context3DBlendFactor.ONE, Context3DBlendFactor.ONE_MINUS_SOURCE_ALPHA ],
                "add"      : [ Context3DBlendFactor.ONE, Context3DBlendFactor.ONE ],
                "multiply" : [ Context3DBlendFactor.DESTINATION_COLOR, Context3DBlendFactor.ONE_MINUS_SOURCE_ALPHA ],
                "screen"   : [ Context3DBlendFactor.ONE, Context3DBlendFactor.ONE_MINUS_SOURCE_COLOR ],
                "erase"    : [ Context3DBlendFactor.ZERO, Context3DBlendFactor.ONE_MINUS_SOURCE_ALPHA ]
            }
        ];
        
        // predifined modes
        
        /** @private */
        public function BlendMode() { throw new AbstractClassError(); }
        
		/** 继承这个显示对象的父级的混合模式。 */
        public static const AUTO:String = "auto";

		/** 停用混合，即禁止任何透明度。 */
        public static const NONE:String = "none";
        
		/** 显示对象显示在背景的前面。  */
        public static const NORMAL:String = "normal";
        
		/** 将显示对象的颜色值添加到背景的颜色里。  */
        public static const ADD:String = "add";
        
		/** 将显示对象的颜色值与背景的颜色相乘。  */
        public static const MULTIPLY:String = "multiply";
        
		/** 将显示对象颜色的补码（反码）与背景颜色的补码相乘，产生漂白效果。 */
        public static const SCREEN:String = "screen";
        
		/** 当绘制渲染纹理的时候擦除背景。 */
        public static const ERASE:String = "erase";
        
        // accessing modes
        
		/**
		 * 根据指定的模式名称和预乘透明度返回混合因素。
		 * 如果模式不存在，会抛出一个参数错误。
		 * @param mode		模式
		 * @param premultipliedAlpha	预乘透明度
		 * @return Array
		 * @throws ArgumentError
		 */
        public static function getBlendFactors(mode:String, premultipliedAlpha:Boolean=true):Array
        {
            var modes:Object = sBlendFactors[int(premultipliedAlpha)];
            if (mode in modes) return modes[mode];
            else throw new ArgumentError("Invalid blend mode");
        }
        
		/**
		 * 根据指定的名称和预乘透明度（pma）值注册一个混合模式。
		 * 如果一个用其他pma值的模式尚未注册，则两个pma的设置都会应用这些因素。
		 * @param name	名称
		 * @param sourceFactor	源因素
		 * @param destFactor	目标因素
		 * @param premultipliedAlpha	是否预乘透明度
		 */
        public static function register(name:String, sourceFactor:String, destFactor:String,
                                        premultipliedAlpha:Boolean=true):void
        {
            var modes:Object = sBlendFactors[int(premultipliedAlpha)];
            modes[name] = [sourceFactor, destFactor];
            
            var otherModes:Object = sBlendFactors[int(!premultipliedAlpha)];
            if (!(name in otherModes)) otherModes[name] = [sourceFactor, destFactor];
        }
    }
}