// Ambient aurora + twinkling stars for Ghostty.
// Only paints where the terminal shows its background colour, so text is untouched.
// Tweak AURORA_STRENGTH / STAR_STRENGTH / SPEED below.

const vec3  BG              = vec3(11.0, 13.0, 20.0) / 255.0; // matches `background = #0b0d14`
const float AURORA_STRENGTH = 0.10;
const float STAR_STRENGTH   = 0.35;
const float SPEED           = 0.04;

float hash(vec2 p) {
    p = fract(p * vec2(123.34, 456.21));
    p += dot(p, p + 45.32);
    return fract(p.x * p.y);
}

float noise(vec2 p) {
    vec2 i = floor(p);
    vec2 f = fract(p);
    float a = hash(i);
    float b = hash(i + vec2(1.0, 0.0));
    float c = hash(i + vec2(0.0, 1.0));
    float d = hash(i + vec2(1.0, 1.0));
    vec2 u = f * f * (3.0 - 2.0 * f);
    return mix(mix(a, b, u.x), mix(c, d, u.x), u.y);
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

void mainImage(out vec4 fragColor, in vec2 fragCoord) {
    vec2 uv = fragCoord / iResolution.xy;
    vec4 term = texture(iChannel0, uv);

    // Slow drifting aurora clouds
    float t = iTime * SPEED;
    vec2 p = vec2(uv.x * iResolution.x / iResolution.y, uv.y);
    float n  = fbm(p * 1.6 + vec2(t, -t * 0.7));
    float n2 = fbm(p * 2.3 - vec2(t * 0.6, t * 0.3) + n);

    vec3 blue   = vec3(0.10, 0.20, 0.55);
    vec3 violet = vec3(0.35, 0.18, 0.60);
    vec3 teal   = vec3(0.05, 0.35, 0.45);
    vec3 glow = mix(blue, violet, smoothstep(0.3, 0.7, n2));
    glow = mix(glow, teal, smoothstep(0.55, 0.8, n) * 0.5);
    float aurora = smoothstep(0.35, 0.85, n2) * AURORA_STRENGTH;

    // Sparse twinkling stars
    float cellSize = 48.0;
    vec2 cell  = floor(fragCoord / cellSize);
    vec2 local = fract(fragCoord / cellSize);
    float h = hash(cell);
    float star = 0.0;
    if (h > 0.92) {
        vec2 pos = vec2(hash(cell + 7.1), hash(cell + 3.7));
        float d = length(local - pos) * cellSize;
        float twinkle = 0.5 + 0.5 * sin(iTime * (0.6 + h) + h * 40.0);
        star = (1.0 - smoothstep(0.0, 1.6, d)) * twinkle * STAR_STRENGTH;
    }

    // Only affect background pixels
    float isBg = 1.0 - smoothstep(0.03, 0.10, distance(term.rgb, BG));
    vec3 col = term.rgb + (glow * aurora + vec3(0.8, 0.85, 1.0) * star) * isBg;

    fragColor = vec4(col, term.a);
}
