//
//  ColorKernel.metal
//  videoEffects
//
//  Created by Tony Monckton on 20/09/2019.
//  Copyright © 2019 Tony Monckton. All rights reserved.
//

#include <metal_stdlib>
using namespace metal;
 
kernel void colorKernel(texture2d<float, access::read> inTexture [[ texture(0) ]],
                        texture2d<float, access::write> outTexture [[ texture(1) ]],
                        device const float *time [[ buffer(0) ]],
                        device const float *effect [[ buffer(1) ]],
                        uint2 gid [[ thread_position_in_grid ]])
{
    float4 colorAtPixel = inTexture.read(gid);
//    outTexture.write(colorAtPixel, gid);

//    float iGlobalTime = *time;
    float iEffect = *effect;
    
    float r = colorAtPixel.x;
    float g = colorAtPixel.y;
    float b = colorAtPixel.z;
/*
       float2 ngid = float2(gid);
       ngid.x /= inTexture.get_width();
       ngid.y /= inTexture.get_height();
    
       float4 orig = inTexture.read(gid);
    
       float2 p = -1.0 + 2.0 * orig.xy;
    
       
    
       float x = p.x;
       float y = p.y;
    
       float mov0 = x + y + 1.0 * cos( 2.0*sin(iGlobalTime)) + 11.0 * sin(x/1.);
       float mov1 = y / 0.9 + iGlobalTime;
       float mov2 = x / 0.2;
    
       float c1 = abs( 0.5 * sin(mov1 + iGlobalTime) + 0.5 * mov2 - mov1 - mov2 + iGlobalTime );
       float c2 = abs( sin(c1 + cos(mov0/2. + iGlobalTime) + sin(y/1.0 + iGlobalTime) + 3.0 * sin((x+y)/1.)) );
       float c3 = abs( sin(c2 + sin(mov1 + mov2 + c2) + cos(mov2) + sin(x/1.)) );
*/
    // sepia
    
        float c1 = r*(1.0-iEffect) + ((r * 0.393 + g * 0.769 + b * 0.189) * iEffect);
        float c2 = g*(1.0-iEffect) + ((r * 0.349 + g * 0.686 + b * 0.168) * iEffect);
        float c3 = b*(1.0-iEffect) + ((r * 0.272 + g * 0.534 + b * 0.131) * iEffect);
    
       colorAtPixel = float4(c1, c2, c3, 1.0);
       outTexture.write(colorAtPixel, gid);
}
 
