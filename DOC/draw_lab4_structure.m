function fig = draw_lab4_structure(saveFiles)
% DRAW_LAB4_STRUCTURE  Lab4 VGA system architecture, based on the supplied RTL.
% 用法：
%   draw_lab4_structure          % 只显示结构图
%   draw_lab4_structure(true)    % 显示并导出 PDF、SVG 和 600 dpi PNG
%
% 不需要额外工具箱。此文件仅编写，尚未运行。
% 图内使用英文短标签；时钟和复位的扇出按时钟域汇总表示。
%
% RTL 对应关系：
%   pll：代码实际为二分频器，50 MHz -> 25 MHz。
%   debounce -> screen_fsm -> screen_meta/screen_sync -> screen_frame。
%   screen_frame 在 vsync_i 下降沿更新，连接 vga_pic.screen_sel。
%   vga_control 输出坐标、请求、有效区及行场同步信号。
%   RGB gate 对应顶层 assign rgb = rgb_valid ? pix_data : 16'h0000。
%   2-FF sync、Frame latch、RGB gate 均为顶层逻辑，不是独立 RTL 模块。
%   pix_x/y[9:0] 表示 pix_x[9:0] 和 pix_y[9:0] 两组坐标信号。

if nargin < 1
    saveFiles = false;
end

%% Style: white canvas, restrained colors, thin lines, short labels
C.ink    = [0.16 0.20 0.25];
C.muted  = [0.39 0.44 0.49];
C.clock  = [0.55 0.37 0.16];
C.reset  = [0.48 0.50 0.54];
C.ctrl   = [0.90 0.95 0.93];
C.video  = [0.89 0.94 0.98];
C.reg    = [0.94 0.92 0.97];
C.pll    = [0.98 0.94 0.86];
C.io     = [0.96 0.97 0.98];
C.dom50  = [0.980 0.989 0.984];
C.dom25  = [0.977 0.984 0.994];
C.font   = 'Arial';

fig = figure('Color','w', 'Name','Lab4 VGA system architecture', ...
    'NumberTitle','off', 'Units','pixels', 'Position',[60 60 1520 800], ...
    'MenuBar','none', 'ToolBar','none', 'Renderer','painters', ...
    'InvertHardcopy','off');
ax = axes('Parent',fig, 'Units','normalized', 'Position',[0 0 1 1], ...
    'XLim',[0 1900], 'YLim',[0 1000], 'DataAspectRatio',[1 1 1], ...
    'Visible','off', 'NextPlot','add');

%% Enclosures and headings
rectangle(ax, 'Position',[215 150 1455 730], ...
    'FaceColor','w', 'EdgeColor',C.ink, 'LineWidth',1.15);
domain(ax, [245 300 480 505], C.dom50);
domain(ax, [775 300 710 505], C.dom25);

label(ax, 950, 944, 'Lab4 VGA system architecture', 21, C.ink, C, 'center','bold');
label(ax, 245, 846, 'FPGA / vga_top', 14, C.ink, C, 'left','bold');
label(ax, 267, 781, '50 MHz  |  sys_clk', 11, C.muted, C, 'left','normal');
label(ax, 797, 781, '25 MHz  |  vga_clk', 11, C.muted, C, 'left','normal');

%% External ports and RTL blocks: [left bottom width height]
block(ax, [35 675 145 90],  'sys_clk',   '50 MHz',     C.io, C);
block(ax, [35 410 145 90],  'key_in',    'Active low', C.io, C);
block(ax, [35 175 145 72],  'sys_rst_n', 'Active low', C.io, C);

block(ax, [300 675 200 90], 'pll',         'Divide by 2',    C.pll, C);
block(ax, [285 410 165 90], 'debounce',    '10 ms',          C.ctrl, C);
block(ax, [535 410 165 90], 'screen_fsm',  '3 states',       C.ctrl, C);
block(ax, [800 410 145 90], '2-FF sync',   '',               C.reg, C);
block(ax, [1045 410 160 90],'Frame latch', '',               C.reg, C);
block(ax, [1045 655 200 110],'vga_control','Timing',         C.video, C);
block(ax, [1310 410 150 90],'vga_pic',     'Pixel generator',C.video, C);
block(ax, [1530 410 110 90],'RGB gate',    '',               C.video, C);

rectangle(ax, 'Position',[1740 375 135 395], ...
    'FaceColor',C.io, 'EdgeColor',C.ink, 'LineWidth',1.1);
label(ax, 1807.5, 604, 'VGA', 14, C.ink, C, 'center','bold');
label(ax, 1807.5, 565, ['640 ' char(215) ' 480'], 11, C.ink, C, 'center','normal');
label(ax, 1807.5, 534, 'RGB565', 11, C.muted, C, 'center','normal');

%% Clock: domain shading represents fan-out to sequential blocks
arrow(ax, [180 720; 300 720], C.clock, 1.25, '-');
arrow(ax, [500 720; 775 720], C.clock, 1.25, '-');
label(ax, 637.5, 747, 'vga_clk / 25 MHz', 10.5, C.clock, C, 'center','normal');
label(ax, 797, 720, 'Clock distribution', 10, C.muted, C, 'left','normal');

%% Screen-selection path
arrow(ax, [180 455; 285 455], C.ink, 1.25, '-');
arrow(ax, [450 455; 535 455], C.ink, 1.25, '-');
arrow(ax, [700 455; 800 455], C.ink, 1.25, '-');
arrow(ax, [945 455; 1045 455], C.ink, 1.25, '-');
arrow(ax, [1205 455; 1310 455], C.ink, 1.25, '-');

label(ax, 492.5, 529, 'press_pulse',       10.5, C.ink, C, 'center','normal');
label(ax, 750,   529, 'screen_sel[1:0]',   10.5, C.ink, C, 'center','normal');
label(ax, 995,   529, 'screen_sync[1:0]',  10.5, C.ink, C, 'center','normal');
label(ax, 1257.5,529, 'screen_frame[1:0]', 10.5, C.ink, C, 'center','normal');

stateCycle = ['BARS ' char(8594) ' MUST ' char(8594) ' END ' char(8594) ' BARS'];
label(ax, 485, 351, stateCycle, 10.5, C.muted, C, 'center','normal');

%% Timing and frame-boundary update
% vsync_i has two destinations: the latch below and the external vsync port.
arrow(ax, [1125 655; 1125 500], C.ink, 1.15, '-');
label(ax, 1108, 610, 'vsync_i',     10.5, C.ink, C, 'right','normal');
label(ax, 1108, 585, 'Falling edge', 9.5, C.muted, C, 'right','normal');

% Ordered orthogonal routes keep coordinate and request lines separate.
arrow(ax, [1175 655; 1175 555; 1345 555; 1345 500], C.ink, 1.15, '-');
arrow(ax, [1220 655; 1220 595; 1415 595; 1415 500], C.ink, 1.15, '-');
label(ax, 1260, 574, 'pix_x/y[9:0]', 10.5, C.ink, C, 'center','normal');
label(ax, 1335, 616, 'pix_data_req', 10.5, C.ink, C, 'center','normal');

%% Video output: sync bypasses the RGB gate
arrow(ax, [1245 735; 1740 735], C.ink, 1.15, '-');
arrow(ax, [1245 700; 1740 700], C.ink, 1.15, '-');
label(ax, 1682, 753, 'hsync', 10.5, C.ink, C, 'center','normal');
label(ax, 1682, 718, 'vsync', 10.5, C.ink, C, 'center','normal');

arrow(ax, [1245 665; 1585 665; 1585 500], C.ink, 1.15, '-');
label(ax, 1500, 682, 'rgb_valid', 10.5, C.ink, C, 'center','normal');
arrow(ax, [1460 455; 1530 455], C.ink, 1.25, '-');
arrow(ax, [1640 455; 1740 455], C.ink, 1.25, '-');
label(ax, 1495, 548, 'pix_data', 10, C.ink, C, 'center','normal');
label(ax, 1495, 526, '[15:0]',   10, C.ink, C, 'center','normal');
label(ax, 1690, 480, 'rgb[15:0]',10.5, C.ink, C, 'center','normal');
label(ax, 1585, 351, 'Blanking = 0', 9.5, C.muted, C, 'center','normal');

%% Shared active-low reset, grouped by domain
plot(ax, [180 1130], [211 211], '--', 'Color',C.reset, 'LineWidth',1.0);
arrow(ax, [485 211; 485 300], C.reset, 1.0, '--');
arrow(ax, [1130 211; 1130 300], C.reset, 1.0, '--');
plot(ax, [485 1130], [211 211], '.', 'Color',C.reset, 'MarkerSize',9);
label(ax, 790, 236, 'Reset to all sequential logic', 10.5, C.reset, C, 'center','normal');

label(ax, 950, 89, ...
    'Shaded regions indicate clock domains; clock/reset fan-out is grouped by domain.', ...
    10, C.muted, C, 'center','normal');

%% Optional export; disabled unless saveFiles is true
if saveFiles
    outDir = fullfile(fileparts(mfilename('fullpath')), 'lab4_figures');
    if ~exist(outDir, 'dir')
        mkdir(outDir);
    end
    set(fig, 'PaperUnits','centimeters', 'PaperSize',[30.4 16], ...
        'PaperPosition',[0 0 30.4 16], 'PaperPositionMode','manual');
    print(fig, fullfile(outDir,'lab4_structure.pdf'), '-dpdf', '-painters');
    print(fig, fullfile(outDir,'lab4_structure.svg'), '-dsvg', '-painters');
    print(fig, fullfile(outDir,'lab4_structure.png'), '-dpng', '-r600');
    fprintf('Exported figures to: %s\n', outDir);
end
end

%% Local drawing helpers
function domain(ax, p, face)
% Borderless shading keeps domain boundaries from crossing signal labels.
rectangle(ax, 'Position',p, 'FaceColor',face, 'EdgeColor','none');
end

function block(ax, p, name, subtitle, face, C)
rectangle(ax, 'Position',p, 'FaceColor',face, 'EdgeColor',C.ink, ...
    'LineWidth',1.05, 'Curvature',[0 0]);
cx = p(1) + p(3)/2;
cy = p(2) + p(4)/2;
if isempty(subtitle)
    label(ax, cx, cy, name, 12, C.ink, C, 'center','bold');
else
    label(ax, cx, cy + 14, name, 12, C.ink, C, 'center','bold');
    label(ax, cx, cy - 18, subtitle, 10, C.muted, C, 'center','normal');
end
end

function label(ax, x, y, str, sizePt, color, C, align, weight)
text(ax, x, y, str, 'FontName',C.font, 'FontSize',sizePt, ...
    'FontWeight',weight, 'Color',color, 'Interpreter','none', ...
    'HorizontalAlignment',align, 'VerticalAlignment','middle', ...
    'Clipping','off');
end

function arrow(ax, points, color, width, style)
% Draw a polyline with a filled arrowhead only on its final segment.
plot(ax, points(:,1), points(:,2), 'Color',color, ...
    'LineWidth',width, 'LineStyle',style);
tip = points(end,:);
direction = tip - points(end-1,:);
direction = direction / norm(direction);
normal = [-direction(2), direction(1)];
base = tip - 11*direction;
triangle = [tip; base + 4.3*normal; base - 4.3*normal];
patch(ax, triangle(:,1), triangle(:,2), color, ...
    'EdgeColor',color, 'LineWidth',0.4);
end
