//
//  ViewController.m
//  OpenGLES01
//
//  Created by zhilinzheng on 2021/5/25.
//

#import "ViewController.h"
#import <GLKit/GLKit.h>

@interface ViewController ()

@property (nonatomic, strong) EAGLContext *context;

@property (nonatomic, strong) CADisplayLink *displayLink; // 用于刷新屏幕
@property (nonatomic, assign) NSTimeInterval startTimeInterval; // 开始的时间戳

@property (nonatomic, assign) GLuint program; // 着色器程序

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    [self commonInit];
    [self startFilerAnimation];
}

- (void)commonInit {
    self.context = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES2];
    [EAGLContext setCurrentContext:self.context];
    
    CAEAGLLayer *layer = [[CAEAGLLayer alloc] init];
    layer.frame = CGRectMake(0, 100, self.view.frame.size.width, self.view.frame.size.width);
    layer.contentsScale = [[UIScreen mainScreen] scale];
    
    [self.view.layer addSublayer:layer];
    
    [self bindRenderLayer:layer];
    
    [self setupShaderProgramWithName:@"Normal"];
}

- (void)bindRenderLayer:(CALayer <EAGLDrawable> *)layer {
    GLuint renderBuffer;
    GLuint frameBuffer;
    
    // render buffer用来存储即将绘制到屏幕上的图像数据，理解为帧缓冲的一个附件，用来真正存储图像的数据。
    // 创建绘制缓冲区
    glGenRenderbuffers(1, &renderBuffer);
    // 绑定绘制缓冲区到渲染管线
    glBindRenderbuffer(GL_RENDERBUFFER, renderBuffer);
    // 为绘制缓冲区分配存储区：将CAEAGLLayer的绘制存储区作为绘制缓冲区的存储区
    [self.context renderbufferStorage:GL_RENDERBUFFER fromDrawable:layer];
    
    // 帧缓冲理解为多种缓冲的结合。
    // 创建帧缓冲区
    glGenFramebuffers(1, &frameBuffer);
    // 绑定帧缓冲区到渲染管线
    glBindFramebuffer(GL_FRAMEBUFFER, frameBuffer);
    // 将绘制缓冲区绑定到帧缓冲区
    glFramebufferRenderbuffer(GL_FRAMEBUFFER,
                              GL_COLOR_ATTACHMENT0,
                              GL_RENDERBUFFER,
                              renderBuffer);
}

// 开始一个滤镜动画
- (void)startFilerAnimation {
    if (self.displayLink) {
        [self.displayLink invalidate];
        self.displayLink = nil;
    }
    
    self.startTimeInterval = 0;
    self.displayLink = [CADisplayLink displayLinkWithTarget:self selector:@selector(timeAction)];
    [self.displayLink addToRunLoop:[NSRunLoop mainRunLoop]
                           forMode:NSRunLoopCommonModes];
}

- (void)timeAction {
    if (self.startTimeInterval == 0) {
        self.startTimeInterval = self.displayLink.timestamp;
    }
    
    // 清除画布
    // 用来指定要用清屏颜色来清除由mask指定的buffer，此处是color buffer
    glClear(GL_COLOR_BUFFER_BIT);
    glClearColor(0.0f, 0.0f, 1.0f, 1.0f);
    
    GLfloat attrArr[] =
    {
        1.0f, -0.5f, 0.0f,  // 右下
        0.0f, 0.5f, 0.0f,   // 上
        -1.0f, -0.5f, 0.0f  // 左下
    };
    
    GLuint attrBuffer;
    glGenBuffers(1, &attrBuffer);
    glBindBuffer(GL_ARRAY_BUFFER, attrBuffer);
    //将顶点坐标写入顶点VBO
    glBufferData(GL_ARRAY_BUFFER, sizeof(attrArr), attrArr, GL_STATIC_DRAW);
    
    // 获取参数索引
    GLuint position = glGetAttribLocation(self.program, "Position");
    
    //告诉OpenGL该如何解析顶点数据
    glVertexAttribPointer(position, 3, GL_FLOAT, GL_FALSE, sizeof(GLfloat) * 3, NULL);
    glEnableVertexAttribArray(position);
    
    //绘制三个顶点的三角形
    glDrawArrays(GL_TRIANGLES, 0, 3);
    
    // 重绘
//    glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);
    // 将指定renderBuffer渲染在屏幕上
    [self.context presentRenderbuffer:GL_RENDERBUFFER];
}

- (void)setupShaderProgramWithName:(NSString *)name {
    GLuint program = [self programWithShaderName:name];
    glUseProgram(program);
    
    self.program = program;
}

- (GLuint)programWithShaderName:(NSString *)shaderName {
    // 编译着色器
    GLuint vertexShader = [self compileShaderWithName:shaderName type:GL_VERTEX_SHADER];
    GLuint fragmentShader = [self compileShaderWithName:shaderName type:GL_FRAGMENT_SHADER];
    
    // 连接Vertex Shader和Fragment Shader成一个完整的OpenGL Shader Program
    GLuint program = glCreateProgram();
    glAttachShader(program, vertexShader);
    glAttachShader(program, fragmentShader);
    
    //释放不需要的shader
    glDeleteShader(vertexShader);
    glDeleteShader(fragmentShader);
    
    // link
    glLinkProgram(program);
    
    // 检查link状态
    GLint linkSuccess;
    glGetProgramiv(program, GL_LINK_STATUS, &linkSuccess);
    if (linkSuccess == GL_FALSE) {
        GLchar messages[256];
        glGetProgramInfoLog(program, sizeof(messages), 0, &messages[0]);
        NSString *messageString = [NSString stringWithUTF8String:messages];
        NSAssert(NO, @"program链接失败：%@", messageString);
        exit(1);
    }
    return program;
}

- (GLuint)compileShaderWithName:(NSString *)name type:(GLenum)shaderType {
    // 1 查找shader文件
    NSString *shaderPath = [[NSBundle mainBundle] pathForResource:name ofType:shaderType == GL_VERTEX_SHADER ? @"vsh" : @"fsh"];
    NSError *error;
    NSString *shaderString = [NSString stringWithContentsOfFile:shaderPath encoding:NSUTF8StringEncoding error:&error];
    if (!shaderString) {
        NSAssert(NO, @"读取shader失败");
        exit(1);
    }
    
    // 2 创建一个代表shader的OpenGL对象, 指定vertex或fragment shader
    GLuint shader = glCreateShader(shaderType);
    
    // 3 获取shader的source
    const char *shaderStringUTF8 = [shaderString UTF8String];
    int shaderStringLength = (int)[shaderString length];
    glShaderSource(shader, 1, &shaderStringUTF8, &shaderStringLength);
    
    // 4 编译shader
    glCompileShader(shader);
    
    // 5 查询shader对象的信息
    GLint compileSuccess;
    glGetShaderiv(shader, GL_COMPILE_STATUS, &compileSuccess);
    if (compileSuccess == GL_FALSE) {
        GLchar messages[256];
        glGetShaderInfoLog(shader, sizeof(messages), 0, &messages[0]);
        NSString *messageString = [NSString stringWithUTF8String:messages];
        NSAssert(NO, @"shader编译失败：%@", messageString);
        exit(1);
    }
    
    return shader;
}


@end
