package display;

import flixel.FlxG;
import flixel.system.FlxAssets.FlxShader;

// https://gist.github.com/Beeblerox/54324d9d5aa19b27651b7cda9130f5dd

class CrtShader extends FlxShader {
    @:glFragmentSource('
        #pragma header

        uniform vec2 uResolution;
        uniform float uTime;

        const float vignetteVal = 0.1;
        
        vec2 curve(vec2 uv) {
            uv = (uv - 0.5) * 2.0;
            uv *= 1.1;	
            uv.x *= 1.0 + pow((abs(uv.y) / 5.0), 2.0);
            uv.y *= 1.0 + pow((abs(uv.x) / 4.0), 2.0);
            uv  = (uv / 2.0) + 0.5;
            uv =  uv * 0.92 + 0.04;
            return uv;
        }
        
        void main() {
            vec2 q = gl_FragCoord.xy / uResolution.xy;
            vec2 uv = q;
            uv = curve(uv);
            // vec3 oricol = texture2D(bitmap, vec2(q.x, q.y)).xyz;
            vec3 col = texture2D(bitmap, vec2(uv.x, uv.y)).xyz;
            // switch following lines to remove "ripples"
            // float x = sin(0.3 * uTime + uv.y * 21.0) * sin(0.7 * uTime + uv.y * 29.0) * sin(0.3 + 0.33 * uTime + uv.y * 31.0) * 0.0017;
            float x = 0.0;

            // color creation and displacement
            col.r = texture2D(bitmap, vec2(x + uv.x + 0.001, uv.y + 0.001)).x + 0.05;
            col.g = texture2D(bitmap, vec2(x + uv.x + 0.000, uv.y - 0.002)).y + 0.05;
            col.b = texture2D(bitmap, vec2(x + uv.x - 0.002, uv.y + 0.000)).z + 0.05;
            // col.r += 0.08 * texture2D(bitmap, 0.75 * vec2(x + 0.025, -0.027) + vec2(uv.x + 0.001, uv.y + 0.001)).x;
            // col.g += 0.05 * texture2D(bitmap, 0.75 * vec2(x - 0.022, -0.02) + vec2(uv.x + 0.000, uv.y - 0.002)).y;
            // col.b += 0.08 * texture2D(bitmap, 0.75 * vec2(x - 0.02, -0.018) + vec2(uv.x - 0.002, uv.y + 0.000)).z;

            // saturation?
            // col = clamp(col * 0.6 + 0.4 * col * col * 1.0, 0.0, 1.0);

            // vignette effect
            float vig = (0.0 + 1.0 * 16.0 * uv.x * uv.y * (1.0 - uv.x) * (1.0 - uv.y));
            // change to lower value to lower vignette (~0.1)
            col *= vec3(pow(vig, vignetteVal));
            
            // slight green increase
            // col *= vec3(0.95, 1.05, 0.95);

            // scalines
            // col *= 2.8;
            // float scans = clamp( 0.35 + 0.35 * sin(3.5 * uTime + uv.y * uResolution.y * 1.5), 0.0, 1.0);
            // float s = pow(scans, 1.0);
            // col = col * vec3( 0.4 + 0.7 * s);
            // // prevents the burn
            // col *= 1.0 - 0.65 * vec3(clamp((mod(gl_FragCoord.x, 2.0) - 1.0) * 2.0, 0.0, 1.0));			

            // crt flash
            // col *= 1.0 + 0.01 * sin(110.0 * uTime);

            // nothing beyond the corners.
            if (uv.x < 0.0 || uv.x > 1.0 || uv.y < 0.0 || uv.y > 1.0) {
                col *= 0.0;
            }
            
            // uncomment the below to compare
            // float comp = smoothstep(0.1, 0.9, sin(uTime));
            // col = mix( col, oricol, comp );

            // alternative scanlines
            // if (mod(floor(openfl_TextureCoordv.y * openfl_TextureSize.y), 2.0) == 0.0) {
            //     gl_FragColor = vec4(col * 0.5, 1.0);
            // } else {
                gl_FragColor = vec4(col, 1.0);
            // }
        }'
    )

    public function new () {
        super();

        this.uResolution.value = [960.0, 540.0];
        this.uTime.value = [0.0];
    }

    override function __update () {
        this.uTime.value[0] += FlxG.elapsed;
        super.__update();
    }
}
