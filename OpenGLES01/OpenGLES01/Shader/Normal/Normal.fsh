varying lowp vec4 TextureCoordsVarying;

void main(void) {
    // must set gl_FragColor for fragment shader
    gl_FragColor = TextureCoordsVarying;
}
