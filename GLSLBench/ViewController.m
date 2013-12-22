//
//  ViewController.m
//  GLSLBench
//
//  Created by Yukishita Yohsuke on 2013/12/23.
//  Copyright (c) 2013年 monadworks. All rights reserved.
//

#import "ViewController.h"
#import <BlocksKit+UIKit.h>

#define BUFFER_OFFSET(i) ((char *)NULL + (i))
#define NSPRINTF(fmt, ...) [NSString stringWithFormat:(fmt), ##__VA_ARGS__]
#define RGBA(r, g, b, a) [UIColor colorWithRed:(r)/255.0 green:(g)/255.0 blue:(b)/255.0 alpha:a]

@interface ViewController () {
    GLint _program;
}
@property (nonatomic, assign) id currentResponder;
@property (strong, nonatomic) EAGLContext *context;
@property NSString *compile_log;

@end

@implementation ViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.context = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES2];

    if (!self.context) {
        NSLog(@"Failed to create ES context");
    }

    self.log.text = @"";
    self.last_modified.text = @"";

    [@[self.fs_path, self.vs_path, self.dir_path] bk_each:^(UITextField *v) {
        v.bk_didEndEditingBlock = ^(UITextField *v) {
            self.currentResponder = nil;
            [self setupGL];
        };

        v.bk_didBeginEditingBlock = ^(UITextField *v) {
            self.currentResponder = v;
        };

        v.bk_shouldReturnBlock = ^(UITextField *v) {
            [v resignFirstResponder];
            return YES;
        };
    }];

    [self.view bk_whenTapped:^{
        [self.currentResponder resignFirstResponder];
        [self setupGL];
    }];
}

- (void)dealloc
{
    if ([EAGLContext currentContext] == self.context) {
        [EAGLContext setCurrentContext:nil];
    }
}

- (void)_appendLog:(NSString *)s
{
    if (self.compile_log.length > 0) {
        self.compile_log = NSPRINTF(@"%@\n%@", self.compile_log, s);
    } else {
        self.compile_log = s;
    }
    NSLog(@"%@", s);
}

- (void)setupGL
{
    [EAGLContext setCurrentContext:self.context];

    self.compile_log = @"";

    NSDateFormatter *ndf = [NSDateFormatter new];
    ndf.locale = [NSLocale currentLocale];
    ndf.timeStyle = NSDateFormatterMediumStyle;
    ndf.dateStyle = NSDateFormatterMediumStyle;

    self.last_modified.text = NSPRINTF(@"Last compiled: %@", [ndf stringFromDate:[NSDate date]]);

    if ([self loadShaders]) {
        self.log.backgroundColor = RGBA(0,0,255,0.2);
        [self _appendLog:@"OK"];
    } else {
        self.log.backgroundColor = RGBA(255,0,0,0.2);
    }

    glDeleteProgram(_program);
    _program = 0;

    self.log.text = self.compile_log;
}

#pragma mark -  OpenGL ES 2 shader compilation

- (BOOL)loadShaders
{
    GLuint vertShader, fragShader;
    NSString *vertShaderPathname, *fragShaderPathname;
    
    // Create shader program.
    _program = glCreateProgram();
    
    // Create and compile vertex shader.
    vertShaderPathname = NSPRINTF(@"%@/%@", self.dir_path.text, self.vs_path.text);
    if (![self compileShader:&vertShader type:GL_VERTEX_SHADER file:vertShaderPathname hint:@"vertex"]) {
        [self _appendLog:@"Failed to compile vertex shader"];

        return NO;
    }
    
    // Create and compile fragment shader.
    fragShaderPathname = NSPRINTF(@"%@/%@", self.dir_path.text, self.fs_path.text);
    if (![self compileShader:&fragShader type:GL_FRAGMENT_SHADER file:fragShaderPathname hint:@"fragment"]) {
        [self _appendLog:@"Failed to compile fragment shader"];
        return NO;
    }
    
    // Attach vertex shader to program.
    glAttachShader(_program, vertShader);
    
    // Attach fragment shader to program.
    glAttachShader(_program, fragShader);

    // Link program.
    if (![self linkProgram:_program]) {
        [self _appendLog:NSPRINTF(@"Failed to link program: %d", _program)];
        
        if (vertShader) {
            glDeleteShader(vertShader);
            vertShader = 0;
        }
        if (fragShader) {
            glDeleteShader(fragShader);
            fragShader = 0;
        }
        if (_program) {
            glDeleteProgram(_program);
            _program = 0;
        }
        
        return NO;
    }
    
    // Release vertex and fragment shaders.
    if (vertShader) {
        glDetachShader(_program, vertShader);
        glDeleteShader(vertShader);
    }
    if (fragShader) {
        glDetachShader(_program, fragShader);
        glDeleteShader(fragShader);
    }

    return YES;
}

- (BOOL)compileShader:(GLuint *)shader type:(GLenum)type file:(NSString *)file hint:(NSString *)hint
{
    GLint status;
    const GLchar *source;
    
    source = (GLchar *)[[NSString stringWithContentsOfFile:file encoding:NSUTF8StringEncoding error:nil] UTF8String];
    if (!source) {
        [self _appendLog:NSPRINTF(@"Failed to load %@ shader", hint)];
        return NO;
    }
    
    *shader = glCreateShader(type);
    glShaderSource(*shader, 1, &source, NULL);
    glCompileShader(*shader);

    GLint logLength;
    glGetShaderiv(*shader, GL_INFO_LOG_LENGTH, &logLength);
    if (logLength > 0) {
        GLchar *log = (GLchar *)malloc(logLength);
        glGetShaderInfoLog(*shader, logLength, &logLength, log);
        [self _appendLog:NSPRINTF(@"[[%@ SHADER]]\n%s\n", [hint uppercaseString]
 , log)];
        free(log);
    }
    
    glGetShaderiv(*shader, GL_COMPILE_STATUS, &status);
    if (status == 0) {
        glDeleteShader(*shader);
        return NO;
    }
    
    return YES;
}

- (BOOL)linkProgram:(GLuint)prog
{
    GLint status;
    glLinkProgram(prog);

    GLint logLength;
    glGetProgramiv(prog, GL_INFO_LOG_LENGTH, &logLength);
    if (logLength > 0) {
        GLchar *log = (GLchar *)malloc(logLength);
        glGetProgramInfoLog(prog, logLength, &logLength, log);
        [self _appendLog:NSPRINTF(@"[[LINK]]]\n%s\n", log)];
        free(log);
    }
    
    glGetProgramiv(prog, GL_LINK_STATUS, &status);
    if (status == 0) {
        return NO;
    }
    
    return YES;
}

- (BOOL)validateProgram:(GLuint)prog
{
    GLint logLength, status;
    
    glValidateProgram(prog);
    glGetProgramiv(prog, GL_INFO_LOG_LENGTH, &logLength);
    if (logLength > 0) {
        GLchar *log = (GLchar *)malloc(logLength);
        glGetProgramInfoLog(prog, logLength, &logLength, log);
        [self _appendLog:NSPRINTF(@"[[VALIDATION]]]\n%s\n", log)];
        free(log);
    }
    
    glGetProgramiv(prog, GL_VALIDATE_STATUS, &status);
    if (status == 0) {
        return NO;
    }
    
    return YES;
}

@end
