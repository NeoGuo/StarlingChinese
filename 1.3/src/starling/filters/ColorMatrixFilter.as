// =================================================================================================
//
//	Starling Framework
//	Copyright 2012 Gamua OG. All Rights Reserved.
//
//	This program is free software. You can redistribute and/or modify it
//	in accordance with the terms of the accompanying license agreement.
//
// =================================================================================================

// Most of the color transformation math was taken from the excellent ColorMatrix class by
// Mario Klingemann: http://www.quasimondo.com/archives/000565.php -- THANKS!!!

package starling.filters
{
    import flash.display3D.Context3D;
    import flash.display3D.Context3DProgramType;
    import flash.display3D.Program3D;
    
    import starling.textures.Texture;
    
    /** ColorMatrixFilter(颜色矩阵滤镜)允许你为输入图片的每个像素的RGBA颜色值和透明度，应用一个4*5的矩阵变换，来产生一个新的包含RGBA颜色和透明度的数据集。
	 *  它允许你调整色相变化，饱和度，亮度调整，以及其它各种效果。
     *  <p>这个类包含了一些用于颜色调整的简便方法。所有这些方法都会改变当前的矩阵，这就意味着你可以很容易的把它们组合在一个滤镜里面:</p>
     *  <listing>
     *  //用50%的饱和度和180度的色相旋转创建一个翻转滤镜
     *  var filter:ColorMatrixFilter = new ColorMatrixFilter();
     *  filter.invert();
     *  filter.adjustSaturation(-0.5);
     *  filter.adjustHue(1.0);
	 *  </listing>
     *  <p>如果你希望让颜色的变化产生动画效果，就在每一步重置滤镜，或者在每一步使用相同的调整值；这个改变就会逐渐累加。</p>
     */
    public class ColorMatrixFilter extends FragmentFilter
    {
        private var mShaderProgram:Program3D;
        
        private var mUserMatrix:Vector.<Number>;   // offset in range 0-255
        private var mShaderMatrix:Vector.<Number>; // offset in range 0-1, changed order
        
        private static const MIN_COLOR:Vector.<Number> = new <Number>[0, 0, 0, 0.0001];
        private static const IDENTITY:Array = [1,0,0,0,0,  0,1,0,0,0,  0,0,1,0,0,  0,0,0,1,0];
        private static const LUMA_R:Number = 0.299;
        private static const LUMA_G:Number = 0.587;
        private static const LUMA_B:Number = 0.114;
        
        /** helper objects */
        private static var sTmpMatrix1:Vector.<Number> = new Vector.<Number>(20, true);
        private static var sTmpMatrix2:Vector.<Number> = new <Number>[];
        
		/**
		 * 根据传入的矩阵创建一个新的ColorMatrixFilter实例。
		 * @param matrix 包含20个项的4*5的矩阵
		 */		
        public function ColorMatrixFilter(matrix:Vector.<Number>=null)
        {
            mUserMatrix   = new <Number>[];
            mShaderMatrix = new <Number>[];
            
            this.matrix = matrix;
        }
        
        /** @inheritDoc */
        public override function dispose():void
        {
            if (mShaderProgram) mShaderProgram.dispose();
            super.dispose();
        }
        
        /** @private */
        protected override function createPrograms():void
        {
            // fc0-3: matrix
            // fc4:   offset
            // fc5:   minimal allowed color value
            
            var fragmentProgramCode:String =
                "tex ft0, v0,  fs0 <2d, clamp, linear, mipnone>  \n" + // read texture color
                "max ft0, ft0, fc5              \n" + // avoid division through zero in next step
                "div ft0.xyz, ft0.xyz, ft0.www  \n" + // restore original (non-PMA) RGB values
                "m44 ft0, ft0, fc0              \n" + // multiply color with 4x4 matrix
                "add ft0, ft0, fc4              \n" + // add offset
                "mul ft0.xyz, ft0.xyz, ft0.www  \n" + // multiply with alpha again (PMA)
                "mov oc, ft0                    \n";  // copy to output
            
            mShaderProgram = assembleAgal(fragmentProgramCode);
        }
        
        /** @private */
        protected override function activate(pass:int, context:Context3D, texture:Texture):void
        {
            context.setProgramConstantsFromVector(Context3DProgramType.FRAGMENT, 0, mShaderMatrix);
            context.setProgramConstantsFromVector(Context3DProgramType.FRAGMENT, 5, MIN_COLOR);
            context.setProgram(mShaderProgram);
        }
        
        // color manipulation
        
        /** 翻转颜色 */
        public function invert():void
        {
            concatValues(-1,  0,  0,  0, 255,
                          0, -1,  0,  0, 255,
                          0,  0, -1,  0, 255,
                          0,  0,  0,  1,   0);
        }
        
		/**
		 * 改变饱和度。可选区间是(-1,1)。大于0的值会提高饱和度，小于0的值会降低饱和度。'-1'会产生一个灰度图像。
		 * @param sat 数值
		 */		
        public function adjustSaturation(sat:Number):void
        {
            sat += 1;
            
            var invSat:Number  = 1 - sat;
            var invLumR:Number = invSat * LUMA_R;
            var invLumG:Number = invSat * LUMA_G;
            var invLumB:Number = invSat * LUMA_B;
            
            concatValues((invLumR + sat), invLumG, invLumB, 0, 0,
                         invLumR, (invLumG + sat), invLumB, 0, 0,
                         invLumR, invLumG, (invLumB + sat), 0, 0,
                         0, 0, 0, 1, 0);
        }
        
		/**
		 * 改变对比度。可选区间是(-1,1)。大于0的值会提高对比度，小于0的值会降低对比度。
		 * @param value 数值
		 */		
        public function adjustContrast(value:Number):void
        {
            var s:Number = value + 1;
            var o:Number = 128 * (1 - s);
            
            concatValues(s, 0, 0, 0, o,
                         0, s, 0, 0, o,
                         0, 0, s, 0, o,
                         0, 0, 0, 1, 0);
        }
        
		/**
		 * 改变亮度。可选区间是(-1,1)。大于0的值会提高亮度，小于0的值会降低亮度。
		 * @param value 数值
		 */		
        public function adjustBrightness(value:Number):void
        {
            value *= 255;
            
            concatValues(1, 0, 0, 0, value,
                         0, 1, 0, 0, value,
                         0, 0, 1, 0, value,
                         0, 0, 0, 1, 0);
        }
        
        /** 改变图像的色调. 可选区间是(-1,1)。 */
        public function adjustHue(value:Number):void
        {
            value *= Math.PI;
            
            var cos:Number = Math.cos(value);
            var sin:Number = Math.sin(value);
            
            concatValues(
                ((LUMA_R + (cos * (1 - LUMA_R))) + (sin * -(LUMA_R))), ((LUMA_G + (cos * -(LUMA_G))) + (sin * -(LUMA_G))), ((LUMA_B + (cos * -(LUMA_B))) + (sin * (1 - LUMA_B))), 0, 0,
                ((LUMA_R + (cos * -(LUMA_R))) + (sin * 0.143)), ((LUMA_G + (cos * (1 - LUMA_G))) + (sin * 0.14)), ((LUMA_B + (cos * -(LUMA_B))) + (sin * -0.283)), 0, 0,
                ((LUMA_R + (cos * -(LUMA_R))) + (sin * -((1 - LUMA_R)))), ((LUMA_G + (cos * -(LUMA_G))) + (sin * LUMA_G)), ((LUMA_B + (cos * (1 - LUMA_B))) + (sin * LUMA_B)), 0, 0,
                0, 0, 0, 1, 0);
        }
        
        // matrix manipulation
        
        /** 重置矩阵 */
        public function reset():void
        {
            matrix = null;
        }
        
        /** 将当前矩阵和另一个矩阵合并。 */
        public function concat(matrix:Vector.<Number>):void
        {
            var i:int = 0;

            for (var y:int=0; y<4; ++y)
            {
                for (var x:int=0; x<5; ++x)
                {
                    sTmpMatrix1[int(i+x)] = 
                        matrix[i]        * mUserMatrix[x]           +
                        matrix[int(i+1)] * mUserMatrix[int(x +  5)] +
                        matrix[int(i+2)] * mUserMatrix[int(x + 10)] +
                        matrix[int(i+3)] * mUserMatrix[int(x + 15)] +
                        (x == 4 ? matrix[int(i+4)] : 0);
                }
                
                i+=5;
            }
            
            copyMatrix(sTmpMatrix1, mUserMatrix);
            updateShaderMatrix();
        }
        
        /** Concatenates the current matrix with another one, passing its contents directly. */
        private function concatValues(m0:Number, m1:Number, m2:Number, m3:Number, m4:Number, 
                                      m5:Number, m6:Number, m7:Number, m8:Number, m9:Number, 
                                      m10:Number, m11:Number, m12:Number, m13:Number, m14:Number, 
                                      m15:Number, m16:Number, m17:Number, m18:Number, m19:Number
                                      ):void
        {
            sTmpMatrix2.length = 0;
            sTmpMatrix2.push(m0, m1, m2, m3, m4, m5, m6, m7, m8, m9, 
                m10, m11, m12, m13, m14, m15, m16, m17, m18, m19);
            
            concat(sTmpMatrix2);
        }

        private function copyMatrix(from:Vector.<Number>, to:Vector.<Number>):void
        {
            for (var i:int=0; i<20; ++i)
                to[i] = from[i];
        }
        
        private function updateShaderMatrix():void
        {
            // the shader needs the matrix components in a different order, 
            // and it needs the offsets in the range 0-1.
            
            mShaderMatrix.length = 0;
            mShaderMatrix.push(
                mUserMatrix[0],  mUserMatrix[1],  mUserMatrix[2],  mUserMatrix[3],
                mUserMatrix[5],  mUserMatrix[6],  mUserMatrix[7],  mUserMatrix[8],
                mUserMatrix[10], mUserMatrix[11], mUserMatrix[12], mUserMatrix[13], 
                mUserMatrix[15], mUserMatrix[16], mUserMatrix[17], mUserMatrix[18],
                mUserMatrix[4] / 255.0,  mUserMatrix[9] / 255.0,  mUserMatrix[14] / 255.0,  
                mUserMatrix[19] / 255.0
            );
        }
        
        // properties
        
        /** 拥有20个项的 4x5 矩阵. */
        public function get matrix():Vector.<Number> { return mUserMatrix; }
        public function set matrix(value:Vector.<Number>):void
        {
            if (value && value.length != 20) 
                throw new ArgumentError("Invalid matrix length: must be 20");
            
            if (value == null)
            {
                mUserMatrix.length = 0;
                mUserMatrix.push.apply(mUserMatrix, IDENTITY);
            }
            else
            {
                copyMatrix(value, mUserMatrix);
            }
            
            updateShaderMatrix();
        }
    }
}