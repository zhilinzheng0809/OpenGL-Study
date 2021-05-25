// variable pass into
attribute vec4 Position;    // position of vertex
attribute vec4 TextureCoords; // color of vertex

// variable pass out into fragment shader
// varying means that calculate the color of every pixel between two vertex linearly(smoothly) according to the 2 vertex's color
varying vec4 TextureCoordsVarying;

void main(void) {
    TextureCoordsVarying = TextureCoords;
    // gl_Position is built-in pass-out variable. Must config for in vertex shader
    gl_Position = Position;
}
