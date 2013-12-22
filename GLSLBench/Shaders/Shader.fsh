//
//  Shader.fsh
//  GLSLBench
//
//  Created by Yukishita Yohsuke on 2013/12/23.
//  Copyright (c) 2013年 monadworks. All rights reserved.
//

varying lowp vec4 colorVarying;

void main()
{
    gl_FragColor = colorVarying;
}
