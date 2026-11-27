shader_type canvas_item;
render_mode unshaded;
varying vec2 ground;
varying float depth;
float hash21(vec2 p) {
    vec3 p3 = fract(vec3(p.xyx) * 0.1031);
    p3 += dot(p3,p3.yzx+33.33);
    return fract((p3.x+p3.y)*p3.z);
}
float noise(vec2 p) {
    vec2 i=floor(p),f=fract(p); f=f*f*(3.0-2.0*f);
    return mix(mix(hash21(i),hash21(i+vec2(1,0)),f.x),mix(hash21(i+vec2(0,1)),hash21(i+vec2(1)),f.x),f.y);
}
void vertex() { ground=VERTEX; depth=COLOR.r; }
void fragment() {
    vec2 p=floor(ground/3.0);
    float grain=hash21(p);
    float ripple=noise(p/22.0);
    float band=depth+(ripple-0.5)*0.19;
    vec3 color=mix(vec3(0.66,0.78,0.82),vec3(0.34,0.52,0.67),smoothstep(0.0,0.9,band));
    color+=step(0.64,noise(p/9.0))*0.035;
    float foam=(1.0-smoothstep(0.018,0.035,abs(band-0.065)))*step(0.28,grain);
    color=mix(color,vec3(0.90,0.92,0.84),foam);
    float alpha=(1.0-smoothstep(0.12,1.0,band));
    // Ordered-looking pixel grain softens the outer shoal without a hard blue rim.
    alpha=clamp(alpha+(grain-0.5)*0.20,0.0,1.0);
    alpha*=1.0-smoothstep(0.88,1.0,depth);
    COLOR=vec4(color,alpha);
}
