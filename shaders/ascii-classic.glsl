// Light-blue ASCII dither background for Ghostty (classic: fixed background colour, works on older Ghostty).
// A slow flowing field is ordered-dithered (Bayer 4x4) and drawn as tiny ASCII glyphs.
// Only paints where the terminal shows its background colour, so text is untouched.

const vec3  BG        = vec3(11.0, 13.0, 20.0) / 255.0; // matches `background = #0b0d14`
const vec3  INK       = vec3(0.55, 0.78, 1.00);         // light blue
const float STRENGTH  = 0.30;  // overall brightness of the glyphs (0.15 subtle .. 0.5 bold)
const float CELL      = 14.0;  // glyph cell size in pixels (bigger = chunkier ASCII)
const float DENSITY   = 0.45;  // field level below which cells stay empty (higher = sparser)
const float SPEED     = 0.05;  // flow speed

float hash(vec2 p) {
    p = fract(p * vec2(123.34, 456.21));
    p += dot(p, p + 45.32);
    return fract(p.x * p.y);
}

float noise(vec2 p) {
    vec2 i = floor(p);
    vec2 f = fract(p);
    vec2 u = f * f * (3.0 - 2.0 * f);
    return mix(mix(hash(i), hash(i + vec2(1.0, 0.0)), u.x),
               mix(hash(i + vec2(0.0, 1.0)), hash(i + vec2(1.0, 1.0)), u.x), u.y);
}

float fbm(vec2 p) {
    float v = 0.0;
    float a = 0.5;
    for (int i = 0; i < 4; i++) {
        v += a * noise(p);
        p *= 2.0;
        a *= 0.5;
    }
    return v;
}

float bayer4(vec2 c) {
    const float m[16] = float[16](
         0.0,  8.0,  2.0, 10.0,
        12.0,  4.0, 14.0,  6.0,
         3.0, 11.0,  1.0,  9.0,
        15.0,  7.0, 13.0,  5.0);
    int x = int(mod(c.x, 4.0));
    int y = int(mod(c.y, 4.0));
    return m[x + y * 4] / 16.0;
}

// 5x5 bitmap glyphs packed into ints; p is the position inside the cell in [-1, 1].
float glyph(int n, vec2 p) {
    p = floor(p * vec2(-4.0, 4.0) + 2.5);
    if (clamp(p.x, 0.0, 4.0) == p.x && clamp(p.y, 0.0, 4.0) == p.y) {
        int a = int(p.x + 5.0 * p.y);
        if (((n >> a) & 1) == 1) return 1.0;
    }
    return 0.0;
}

int glyphFor(float g) {
    if (g < 0.15) return 4096;      // .
    if (g < 0.30) return 65600;     // :
    if (g < 0.45) return 332772;    // *
    if (g < 0.60) return 15255086;  // o
    if (g < 0.75) return 23385164;  // &
    if (g < 0.90) return 15252014;  // 8
    return 13199452;                // @
}

void mainImage(out vec4 fragColor, in vec2 fragCoord) {
    vec2 uv = fragCoord / iResolution.xy;
    vec4 term = texture(iChannel0, uv);

    vec2 cell  = floor(fragCoord / CELL);
    vec2 local = fract(fragCoord / CELL) * 2.0 - 1.0;

    // Flowing field: drifting clouds + a slow diagonal wave
    float t = iTime * SPEED;
    float clouds = fbm(cell * 0.06 + vec2(t, -t * 0.6));
    float wave   = 0.5 + 0.5 * sin(cell.x * 0.12 + cell.y * 0.07 - iTime * 0.5);
    float v = mix(clouds, wave, 0.3);

    // Ordered dither, then quantise into glyph levels
    v += (bayer4(cell) - 0.5) * 0.18;
    float g = clamp((v - DENSITY) / (1.0 - DENSITY), 0.0, 1.0);

    float ink = 0.0;
    if (v > DENSITY) {
        ink = glyph(glyphFor(g), local) * (0.35 + 0.65 * g);
    }

    float isBg = 1.0 - smoothstep(0.03, 0.10, distance(term.rgb, BG));
    vec3 col = term.rgb + INK * ink * STRENGTH * isBg;

    fragColor = vec4(col, term.a);
}
