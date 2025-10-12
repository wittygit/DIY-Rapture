shader_type canvas_item;
render_mode unshaded;

uniform sampler2D SCREEN_TEXTURE : source_color, repeat_disable, filter_nearest;

uniform float radius = 1.0;
uniform float speed : hint_range(0.0, 10.0) = 1.0;
uniform vec4 effect_color : source_color = vec4(0.251, 0.0, 0.0, 1.0);


uniform float zNear = 0.05;
uniform float zFar = 100;

uniform bool enable_outline = false;
uniform vec3 outline_color : source_color = vec3(0.0,0.0,0.0);
uniform float outline_thickness = 10.0;

uniform bool enable_color_limit = true;
uniform int color_levels : hint_range(2, 32) = 8;

uniform bool enable_color_palette = true;
uniform vec4 color1  : source_color  = vec4(1.0,0.925,0.839,1.0);			//#bfbfbf - avg = 0.749
uniform vec4 color2  : source_color  = vec4(1.0,0.831,0.639,1.0);			//#71a668 - avg = 0.501
uniform vec4 color3  : source_color  = vec4(1.0,0.667,0.369,1.0);			//#6a86b0 - avg = 0.543
uniform vec4 color4  : source_color  = vec4(0.816,0.506,0.349,1.0);			//#76568f - avg = 0.453
uniform vec4 color5  : source_color  = vec4(0.553,0.412,0.478,1.0);			//#ab5c74 - avg = 0.496
uniform vec4 color6  : source_color  = vec4(0.329,0.306,0.408,1.0);			//#b89d6e - avg = 0.589
uniform vec4 color7  : source_color  = vec4(0.125,0.236,0.337,1.0);			//#4c5b6b - avg = 0.358
uniform vec4 color8  : source_color  = vec4(0.05,0.169,0.271,1.0);			//#2e253d - avg = 0.188

// In order, dark -> light
// 8,7,4,5,2,3,6,1
uniform bool enable_dithering = true;
uniform float dither_strength : hint_range(0.0, 1.0) = 0.3;

//This shader uses the sobel-feldman operation to create outlines for any object on the screen.
//It utilizes the depth and normal buffers to create the most accurate or complete outlines.

// We do this using two kernels Gx and Gy (1) , which are convolved (adding each element to its local neighbors)
// with the input data (2). First with the depth buffer (3), and then with the normal buffer (4).
// These results are then handled in the fragment shader (5), to be output to the player's screen.


// (1)
// Gx and Gy are two "kernels" that contain horizontal (x) and vertical(y) derivative approximations.
const mat3 Gx = mat3(
				vec3(-1,-2,-1),
				vec3(0, 0, 0),
				vec3(1, 2, 1)
);
const mat3 Gy = mat3(
				vec3(-1,0,1),
				vec3(-2,0,2),
				vec3(-1,0,1)
);

// (1) 
// Calculating the scaled depth buffer, converting the depth from clip space, into view space.
float depth(sampler2D depth_texture, vec2 screen_uv, mat4 inv_proj_mat, in vec3 vertex)
{
	float depth_raw = texture(depth_texture, screen_uv)[0];
	vec3 ndc = vec3(screen_uv * 2.0 - 1.0, depth_raw);
	vec4 view_space = inv_proj_mat * vec4(ndc,1.0);
	view_space.z /= view_space.w;
	float linear_depth = view_space.z;
	float scaled_depth = (zFar-zNear)/(zNear + linear_depth * (zNear-zFar));

	return scaled_depth;
}



float snoise(vec3 uv, float res)
{
    const vec3 s = vec3(1e0, 1e2, 1e3);
    uv *= res;

    vec3 uv0 = floor(mod(uv, res)) * s;
    vec3 uv1 = floor(mod(uv + vec3(1.0), res)) * s;

    vec3 f = fract(uv);
    f = f * f * (3.0 - 2.0 * f);

    vec4 v = vec4(uv0.x + uv0.y + uv0.z, uv1.x + uv0.y + uv0.z,
                  uv0.x + uv1.y + uv0.z, uv1.x + uv1.y + uv0.z);

    vec4 r = fract(sin(v * 1e-1) * 1e3);
    float r0 = mix(mix(r.x, r.y, f.x), mix(r.z, r.w, f.x), f.y);

    r = fract(sin((v + uv1.z - uv0.z) * 1e-1) * 1e3);
    float r1 = mix(mix(r.x, r.y, f.x), mix(r.z, r.w, f.x), f.y);

    return mix(r0, r1, f.z) * 2.0 - 1.0;
}

// (2)
// Next, we perform the sobel operation on the scaled_depth value.
// This is half of the process for the outlines, giving us most of the outline effect,
// but we'll also be performing the sobel operation on the normal values, for a more "complete"
// looking outline.

// (4)
// Calculates relative luminance for a pixel's color using the "weighted vector"
// which is a shade of green that approximates the way light is percieved by humans.
float luminance(vec3 color)
{
	const vec3 weight = vec3(0.2125, 0.7154, 0.0721);
	return dot(weight,color);
}

// Using the luminance, we can find even more edges by finding the major luminance differences
// found within the normal buffer. Using the calculated luminance value, we'll perform the sobel operation again,
// providing us with what will become our "full" edge detected results.



// Color posterization, or quantization, is handled by passing in the red, green and blue values of a color one at a time
// into the function. the "value" in this instance, would be one of those rgb values, from the color vec3/vec4.
// Meanwhile, the "levels" integer is the number of colors we want to "allow" within the color posterization.
// This function will take the input rgb float value, multiply it by the number of levels, and then round it to the nearest int.
// Then, lastly, it'll be divided again by the number of color levels, to bring it back to an rgb float value that falls between 0.0 and 1.0
// while still being affected by the rounding. 

//There are likely better ways to handle this, but this was my first implementation and it worked well enough for this project.
float posterize(float val, int levels)
{
	return round(val * float(levels)) / float(levels);
}


// The dithering is fairly heavy handed, and is applied directly to the screen-space quad. This results
// in a full-screen "darkening" of sorts, instead of just being applied to the actual materials of objects 
// to "fix" the color banding from the posterization, like it probably should be.
// Because of that, there are definitely better ways to implement this, and I'd definitely re-do it in the future.
float dither(vec2 position, float brightness)
{
	int x = int(mod(position.x, 4.0));
	int y = int(mod(position.y, 4.0));
	int index = x + y * 4;

	float dithering[16] = float[](
		0.0,0.5,0.125,0.625,
		0.75,0.25,0.875,0.375,
		0.1875,0.6875,0.0625,0.5625,
		0.9375,0.4375,1.0,0.8125
	);
	float threshold = dithering[index];
	return brightness < threshold ? 0.0 : 1.0;
}

void fragment() {
	vec2 p = (UV - 0.5) * radius; 

    float color = 3.0 - (3.0 * length(2.0 * p));

    vec3 coord = vec3(atan(p.x, p.y) / 6.2832 + 0.5, length(p) * 0.4, 0.5);

    float time = -TIME / speed;
    for (int i = 1; i <= 7; i++)
    {
        float power = pow(2.0, float(i));
        color += (1.5 / power) * snoise(coord + vec3(0.0, -time * 0.05, time * 0.01), power * 16.0);
    }
	float edge_start = effect_color.a * 0.5;
	float edge_end   = 1.0;                  
	float alpha = (1.0 - smoothstep(edge_start, edge_end, color)) * 0.7;


	alpha = pow(alpha, 1.6); 

    vec4 vignette = vec4((color - (1.0 - effect_color.r))*alpha, (color - (1.0 - effect_color.g))*alpha,( color - (1.0 - effect_color.b))*alpha, alpha);
	// Called for every pixel the material is visible on.
	vec3 palette[8];
		palette[0] = color1.rgb;
		palette[1] = color2.rgb;
		palette[2] = color3.rgb;
		palette[3] = color4.rgb;
		palette[4] = color5.rgb;
		palette[5] = color6.rgb;
		palette[6] = color7.rgb;
		palette[7] = color8.rgb;

	vec3 screen_color = texture(SCREEN_TEXTURE, SCREEN_UV).rgb;

	vec3 final_color = screen_color;

	if(enable_color_limit)
	{
		// Posterizes the fragment's color using the limit value set in "color_levels"
		final_color = vec3(posterize(final_color.r,color_levels),posterize(final_color.g,color_levels),posterize(final_color.b,color_levels));
		
	}

	if (enable_color_palette)
	{
		vec3 difference = final_color - palette[0];
		float dist = dot(difference,difference);

		float closest_distance = dist;
		vec3 closest_color = palette[0];

		// Iterates through the color palette array, comparing the "distance" of the
		// source color, against the current palette color. It finds the palette
		// color with the shortest distance from the source color, and applies it to
		// the "final_color", of the current fragment. This "replaces" the original image's
		// colors with the best-fit from the palette.
		for( int i = 0; i < palette.length(); i++)
		{
			difference = final_color - palette[i];
			dist = dot(difference,difference);

			if(dist<closest_distance)
			{
				closest_distance = dist;
				closest_color = palette[i];
			}
		}
		final_color = closest_color;
	}

	// Applies the dithering to the screen, based on the dither strength.
	if(enable_dithering)
	{
		float brightness = dot(final_color, vec3(0.3,0.59,0.11));
		brightness += dither_strength * (dither(FRAGCOORD.xy, brightness) -0.5);
		final_color *= (1.0 + dither_strength * (dither(FRAGCOORD.xy, brightness) -0.5));
	}
	
	
	//The combined results of all of the effects are then output to the quad's albedo, displaying them on the screen.
	COLOR = vec4(final_color,1.0) + vignette;
}

void light() {
	// Called for every pixel for every light affecting the material.
	// Uncomment to replace the default light processing function with this one.
}
