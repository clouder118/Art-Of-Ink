import ddf.minim.*;//导入minim库，用于音乐播放

//导入pixelflow库，用于流体效果渲染
import com.thomasdiewald.pixelflow.java.DwPixelFlow;
import com.thomasdiewald.pixelflow.java.dwgl.DwGLSLProgram;
import com.thomasdiewald.pixelflow.java.fluid.DwFluid2D;
import com.thomasdiewald.pixelflow.java.fluid.DwFluidParticleSystem2D;

/*
 * 交互方式:
 * - 左键: 添加速度
 * - 右键: 添加温度
 * - 键盘控制:
 *   - p: 暂停/继续模拟
 *   - +: 增加流体网格分辨率
 *   - -: 减小流体网格分辨率
 *   - r: 重置模拟
*/
private class MyFluidData implements DwFluid2D.FluidData{
    // 这个方法在流体模拟更新步骤中被调用
    public void update(DwFluid2D fluid) {
        float px, py, vx, vy, radius, vscale;
        
        if(mousePressed ){
            vscale = 15;  // 速度缩放因子，控制流体运动强度
            px     = mouseX;
            py     = height-mouseY;  // 转换Y轴方向(Processing的Y轴向下，流体模拟中Y轴向上)
            vx     = (mouseX - pmouseX) * +vscale;  // 计算X方向速度分量
            vy     = (mouseY - pmouseY) * -vscale;  // 计算Y方向速度分量
            // 根据鼠标按键类型添加不同的物理量
            if(mouseButton == LEFT){
                radius = 25;  // 速度影响半径
                fluid.addVelocity(px, py, radius, vx, vy);  // 添加速度场
            }

            if(mouseButton == RIGHT){
                radius = 15;  // 温度影响半径
                fluid.addTemperature(px, py, radius, 15f);  // 添加温度场
            }
        }
        // 使用图像作为密度源输入
        // 在模拟的第一步完全使用图像，之后以0.009的比例混合，创造持续的流体效果
        float mix = fluid.simulation_step == 0 ? 1.0f : 0.009f;
        addDensityTexture(fluid, pg_image, mix);
    }
    
    public void addDensityTexture(DwFluid2D fluid, PGraphics2D pg, float mix){
        int[] pg_tex_handle = new int[1];
        // 获取PGraphics2D对象的OpenGL纹理句柄
        context.begin();
        context.getGLTextureHandle(pg, pg_tex_handle);
        
        // 开始绘制到流体密度目标纹理
        context.beginDraw(fluid.tex_density.dst);
        // 创建并使用自定义着色器程序(在data/addDensity.frag文件中定义)
        DwGLSLProgram shader = context.createShader(this, "data/addDensity.frag");
        shader.begin();
        
        // 设置着色器所需的各种参数
        shader.uniform2f    ("wh", fluid.fluid_w, fluid.fluid_h);          // 流体网格尺寸
        shader.uniform1i    ("blend_mode", 6);                              // 混合模式
        shader.uniform1f    ("mix_value", mix);                             // 混合比例
        shader.uniform1f    ("multiplier", 1);                              // 密度乘数
        shader.uniformTexture("tex_ext", pg_tex_handle[0]);                // 外部纹理(图像)
        shader.uniformTexture("tex_src", fluid.tex_density.src);           // 源密度纹理
        
        // 执行着色器程序，将图像数据添加到密度纹理
        shader.drawFullScreenQuad();
        shader.end();
        context.endDraw();
        context.end("app.addDensityTexture");
        
        // 交换密度纹理的源和目标，为下一帧做准备
        fluid.tex_density.swap();
    }
}
  
int viewport_w = 1583;  // 视口宽度
int viewport_h = 800;  // 视口高度
int viewport_x = 500;  // 视口X坐标
int viewport_y = 200;    // 视口Y坐标
int fluidgrid_scale = 1;  // 流体网格缩放因子，影响模拟精度和性能

// 主要对象声明
DwPixelFlow context;        // PixelFlow上下文
DwFluid2D fluid;            // 2D流体模拟对象

MyFluidData cb_fluid_data;  // 流体数据回调
DwFluidParticleSystem2D particle_system;  // 流体粒子系统

PGraphics2D pg_fluid;       // 流体渲染目标
PGraphics2D pg_image;       // 用于添加流体数据的纹理缓冲区

PImage image;               // 用户加载的图像

// 显示和控制相关的状态变量
int     BACKGROUND_COLOR           = 255;        // 背景颜色
boolean UPDATE_FLUID               = true;       // 是否更新流体模拟
boolean DISPLAY_FLUID_TEXTURES     = true;       // 是否显示流体纹理
int     DISPLAY_fluid_texture_mode = 0;          // 流体纹理显示模式

/**
 * 设置程序参数和窗口属性
 */
public void settings() {
    size(viewport_w, viewport_h, P2D);  // 设置窗口大小和渲染器
    smooth(4);  // 设置抗锯齿级别
}

//初始化程序环境和对象
public void setup() {
    Minim minim;
    minim=new Minim(this);//创建minim对象
    AudioPlayer player;
    player = minim.loadFile("龚一 - 山居吟.mp3",1024);//读取音乐文件
    player.play();//播放音乐
    
    surface.setLocation(viewport_x, viewport_y);  // 设置窗口位置
    
    // 初始化PixelFlow上下文
    context = new DwPixelFlow(this);
    context.print();  // 打印PixelFlow信息
    context.printGL();  // 打印OpenGL信息
    
    // 初始化流体模拟
    fluid = new DwFluid2D(context, viewport_w, viewport_h, fluidgrid_scale);
    
    // 设置流体物理参数
    fluid.param.dissipation_density     = 0.99f;  // 密度耗散率(1.0表示无耗散)
    fluid.param.dissipation_velocity    = 0.88f;  // 速度耗散率
    fluid.param.dissipation_temperature = 0.70f;  // 温度耗散率
    fluid.param.vorticity               = 0.50f;  // 涡度参数，控制流体漩涡程度
    
    // 注册流体数据回调，用于向流体中添加数据
    cb_fluid_data = new MyFluidData();
    fluid.addCallback_FluiData(cb_fluid_data);
    // 加载用户自定义图片作为密度源
    image = loadImage("ink_painting3.png");  // 修改此处可加载自定义图片
    // 检查图片是否成功加载
    if (image == null || image.width <= 0) {
        println("无法加载图片 ink_painting.png，请确保图片文件在正确的位置！");
        // 使用默认的纯色背景替代
        pg_image = (PGraphics2D) createGraphics(viewport_w, viewport_h, P2D);
        pg_image.noSmooth();
        pg_image.beginDraw();
        pg_image.clear();
        pg_image.fill(100, 100, 200);  // 使用蓝色作为默认背景
        pg_image.rect(0, 0, viewport_w, viewport_h);
        pg_image.endDraw();
    } else {
        // 创建流体渲染目标
        pg_fluid = (PGraphics2D) createGraphics(viewport_w, viewport_h, P2D);
        pg_fluid.smooth(4);
        
        // 初始化粒子系统
        particle_system = new DwFluidParticleSystem2D();
        particle_system.resize(context, viewport_w/3, viewport_h/3);
        
        // 创建图像缓冲区，用于作为密度输入
        pg_image = (PGraphics2D) createGraphics(viewport_w, viewport_h, P2D);
        pg_image.noSmooth();
        pg_image.beginDraw();
        pg_image.clear();
        pg_image.translate(width/2, height/2);
        pg_image.imageMode(CENTER);
        pg_image.image(image, 0, 0);  // 将图像绘制到缓冲区
        pg_image.endDraw();
    }
    background(0);  // 设置初始背景为黑色
    frameRate(70);  // 设置目标帧率为70FPS
}
//主循环，每帧执行一次
public void draw() {
    // 更新流体模拟和粒子系统
    if(UPDATE_FLUID){
        fluid.update();  // 更新流体状态
        particle_system.update(fluid);  // 更新粒子系统
    }
    // 准备渲染流体
    pg_fluid.beginDraw();
    pg_fluid.background(BACKGROUND_COLOR);  // 设置背景颜色
    pg_fluid.endDraw();
    // 根据设置显示流体纹理
    if(DISPLAY_FLUID_TEXTURES){
        fluid.renderFluidTextures(pg_fluid, DISPLAY_fluid_texture_mode);
    }
    // 将渲染好的流体效果显示到屏幕上
    image(pg_fluid, 0, 0);
 
    // 更新窗口标题，显示当前帧率和模拟信息
    String txt_fps = String.format(getClass().getName()+ "   [size %d/%d]   [frame %d]   [fps %6.2f]", 
                                   fluid.fluid_w, fluid.fluid_h, fluid.simulation_step, frameRate);
    surface.setTitle(txt_fps);
}
//增大流体网格分辨率
public void fluid_resizeUp(){
    fluid.resize(width, height, fluidgrid_scale = max(1, --fluidgrid_scale));
}
//减小流体网格分辨率
public void fluid_resizeDown(){
    fluid.resize(width, height, ++fluidgrid_scale);
}
//重置流体模拟
public void fluid_reset(){
    fluid.reset();
}
//切换流体模拟暂停/继续状态
public void fluid_togglePause(){
    UPDATE_FLUID = !UPDATE_FLUID;
}
//  键盘释放事件处理
public void keyReleased(){
    if(key == 'p') fluid_togglePause();  // 暂停/继续模拟
    if(key == '+') fluid_resizeUp();     // 增加流体网格分辨率
    if(key == '-') fluid_resizeDown();   // 减小流体网格分辨率
    if(key == 'r') fluid_reset();        // 重置模拟
}
