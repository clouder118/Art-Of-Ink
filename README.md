# Art of Ink · 交互式水墨山水

一个基于 Processing（Java 模式）的交互式水墨山水数字艺术作品。项目以静态山水画为图像来源，通过 PixelFlow 的二维流体模拟，让画面随着鼠标操作产生流动、扩散与扰动，并配合《山居吟》营造山水意境。

> **运行版本提醒：请使用 Processing 3.5.4 打开和运行本项目。最新版 Processing 会因兼容性问题导致显示异常，请勿直接使用最新版运行。**
>
> [下载 Processing 3.5.4（官方发布页）](https://github.com/processing/processing/releases/tag/processing-0270-3.5.4)

## 山水底图

下图为程序加载的原始图像，运行后的动态效果需要通过交互体验。

![水墨山水原始图像](ink_painting3.png)

## 作品特点

- **图像驱动的水墨流动**：将山水图像持续注入流体密度场，使画面在扰动中仍保留原有山水形态。
- **鼠标实时交互**：通过速度场与温度场影响流体，改变画面的运动状态。
- **可调模拟精度**：支持暂停、重置，以及调整流体网格分辨率。
- **音乐伴随**：启动时播放项目附带的 `龚一 - 山居吟.mp3`。当前代码为单次播放，不会自动循环。

## 运行环境与依赖

| 组件 | 要求或用途 |
| --- | --- |
| Processing | **3.5.4**，使用 Java 模式 |
| PixelFlow | 提供 GPU 流体模拟、纹理处理与粒子系统 |
| Minim | 加载和播放 MP3 音频 |
| 图形环境 | 支持项目所用 P2D / OpenGL 渲染及 GLSL 150 着色器 |

在 Processing 中通过 `Sketch → Import Library… → Add Library…` 打开库管理器，搜索并安装 **PixelFlow** 和 **Minim**。如果库管理器无法获取 PixelFlow，可按照其官方仓库的说明手动安装，安装后重启 Processing。

依赖说明与安装参考：[PixelFlow 官方仓库](https://github.com/diwi/PixelFlow)、[Minim 官方页面](https://code.compartmental.net/tools/minim/)。项目未附带这两个库，也未锁定库版本，安装时请选择支持 Processing 3 的版本。

## 快速开始

1. 下载并启动 **Processing 3.5.4**，确认当前为 **Java 模式**。
2. 安装 PixelFlow 和 Minim。
3. 整理草图文件夹：Processing 要求主 `.pde` 文件与所在文件夹同名。目前主文件是 `project_5.pde`，项目目录名为 `art_of_ink`，可将完整项目复制到名为 `project_5` 的文件夹后打开。也可以将主文件重命名为 `art_of_ink.pde`，保留当前文件夹名称。只需选择其中一种方式。
4. 确认山水图片、MP3 和整个 `data/` 文件夹都保留在草图目录中。若 Processing 提示自动创建同名文件夹，请确认这些资源也一并放入新文件夹，避免只移动 `.pde` 文件。
5. 打开主 `.pde` 文件，点击运行按钮。程序默认创建 **1583 × 800** 的窗口，并开始模拟与播放音乐。
6. 在画面内按住鼠标左键拖动，观察水墨流动；使用下表中的操作继续体验。

草图目录命名规则可参考 [Processing 官方环境说明](https://processing.org/environment/)。

## 交互操作

操作前请先让作品窗口获得焦点。键盘命令在按键释放时触发，字母键使用小写。

| 操作 | 效果 |
| --- | --- |
| 按住鼠标左键并拖动 | 根据鼠标移动方向和速度向流体添加速度，推动画面流动 |
| 按住鼠标右键 | 在鼠标位置向流体添加温度，影响流体运动 |
| `p` | 暂停 / 继续流体模拟 |
| `+` | 提高流体网格分辨率，增加模拟精度 |
| `-` | 降低流体网格分辨率，减轻计算负担 |
| `r` | 重置流体模拟 |

初始网格缩放因子为 `1`，已是当前代码允许的最高网格分辨率，因此刚启动时按 `+` 不会继续提升；可以先用 `-` 降低分辨率，再用 `+` 恢复。暂停时不会更新流体，鼠标扰动也要在继续模拟后才会生效。

`p` 和 `r` 仅控制流体模拟，不会暂停或重新播放音乐。窗口标题会显示流体网格尺寸、模拟步数和当前帧率。

## 项目结构

```text
art_of_ink/
├── README.md                 # 项目说明
├── project_5.pde             # 主程序：初始化、流体更新、渲染和交互
├── ink_painting3.png         # 山水底图 / 流体密度来源
├── 龚一 - 山居吟.mp3          # 启动时播放的音乐
└── data/
    ├── addDensity.frag       # 将图像混合进流体密度场的片元着色器
    └── AgencyFB-Reg-48.vlw   # 字体资源，当前主程序未使用
```

上面展示的是仓库原始结构；运行前请按“快速开始”处理草图与文件夹的命名关系。

## 实现方式

1. `setup()` 初始化 Minim、PixelFlow 和 `DwFluid2D`，将山水图像居中绘制到离屏缓冲区。
2. `MyFluidData.update()` 读取鼠标输入，分别向流体注入速度或温度。
3. `addDensityTexture()` 调用 `data/addDensity.frag`，将图像纹理混入流体密度场。模拟第一步的混合比例为 `1.0`，之后为 `0.009`，持续补入原图内容。
4. `draw()` 更新流体及粒子系统，再将流体纹理绘制到窗口。当前显示的是流体纹理，代码没有单独绘制粒子系统。

着色器采用混合模式 `6`，以外部图像的透明度调节混合强度。

## 可调整的参数

以下参数均位于主 `.pde` 文件中，修改后需重新运行。

| 参数 / 位置 | 默认值 | 作用 |
| --- | --- | --- |
| `viewport_w` / `viewport_h` | `1583` / `800` | 窗口尺寸 |
| `viewport_x` / `viewport_y` | `500` / `200` | 窗口初始位置 |
| `fluidgrid_scale` | `1` | 网格缩放因子；越大，网格分辨率越低 |
| `dissipation_density` | `0.99` | 密度保留系数，越接近 `1`，消散越慢 |
| `dissipation_velocity` | `0.88` | 速度保留系数 |
| `dissipation_temperature` | `0.70` | 温度保留系数 |
| `vorticity` | `0.50` | 涡旋强度 |
| `MyFluidData.update()` 中的 `vscale` | `15` | 鼠标移动对速度场的影响强度 |
| `frameRate(70)` | `70` | 目标帧率，实际帧率取决于运行环境 |

替换画面时，可修改 `loadImage("ink_painting3.png")` 中的文件名；当前代码按图像原始尺寸居中绘制，不会自动缩放以适配窗口。替换音乐时，修改 `minim.loadFile("龚一 - 山居吟.mp3", 1024)` 中的文件名，并确保相应资源可被草图读取。

## 常见问题

- **画面显示异常**：首先确认使用的是 **Processing 3.5.4**。最新版 Processing 存在本项目的兼容性问题；如版本正确，再检查 PixelFlow 安装和控制台中的 OpenGL 信息。
- **提示找不到 PixelFlow 或 Minim**：检查两个库是否安装在当前 Processing 使用的 Sketchbook 库目录中，安装后重启编辑器。
- **图片或音乐加载失败**：检查文件名、中文字符、扩展名和草图目录是否完整。代码实际读取的是 `ink_painting3.png`，但图片失败提示中的文件名写成了 `ink_painting.png`，排查时以实际加载语句为准。图片缺失时的备用分支没有初始化后续所需的全部对象，因此仍可能报错，请确保原图存在。
- **着色器加载失败**：确认 `data/addDensity.frag` 存在，并且随主程序一起放在正确的草图目录中。
- **运行卡顿**：按 `-` 降低网格分辨率，或适当减小窗口尺寸。
- **窗口位置不合适**：修改 `viewport_x`、`viewport_y`；当前初始位置为屏幕坐标 `(500, 200)`。

## 致谢

本项目使用 [Processing](https://processing.org/)、Thomas Diewald 的 [PixelFlow](https://github.com/diwi/PixelFlow) 和 [Minim](https://code.compartmental.net/tools/minim/)。`addDensity.frag` 保留了 PixelFlow 的版权及 MIT 许可说明。
