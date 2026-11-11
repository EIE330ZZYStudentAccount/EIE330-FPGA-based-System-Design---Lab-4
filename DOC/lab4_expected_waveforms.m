function expected = lab4_expected_waveforms(exportDir)
%LAB4_EXPECTED_WAVEFORMS Ideal functional waveforms using recorded VCD inputs.
% 中文：expected 使用黑底白线；输入、复位、时钟和结束时间来自真实 VCD。
% 手动运行：expected = lab4_expected_waveforms;
% 可选导出：expected = lab4_expected_waveforms('expected_png');
% 本程序交付前未执行。本文件已内嵌 VCD 输入快照，可单独使用。
% 修订版：固定 8 张图（编号 01/08 至 08/08）；vga_pic 保留 8 条信号。
% This is an explicit reference model, not a recoloring of DUT output data.
% See EXPECTED使用说明.txt for assumptions and the fourth debounce press.

    if nargin < 1, exportDir = ''; end
    exportDir = char(exportDir);
    if ~isempty(exportDir) && ~isfolder(exportDir), mkdir(exportDir); end
    fprintf('lab4_expected_waveforms | revision 8figures-v2\n');
    stimulus = lab4_vcd_stimulus;

    % All times below are integer ticks at 1 ps per tick.
    cfg.sysPeriod = 20000;             % 20 ns, matching the recorded clocks.
    cfg.debounceStableTime = 10000000000; % Normal 10 ms qualification.
    cfg.debouncePipelineDelay = 30000; % 30 ns offset of the first 3 normal presses.
    cfg.requireReleaseAfterReset = true; % Matches the held-key reset trace.
    cfg.H_SYNC = 96; cfg.H_BACK = 48; cfg.H_ACTIVE = 640; cfg.H_FRONT = 16;
    cfg.V_SYNC = 2; cfg.V_BACK = 33; cfg.V_ACTIVE = 480; cfg.V_FRONT = 10;
    cfg.invalidCoordinate = 1023;

    expected = struct();
    expected.revision = '8figures-v2';
    expected.tickSeconds = stimulus.tickSeconds;
    expected.parameters = cfg;
    expected.source = 'Recorded input snapshot + explicit ideal functional model';

    s = stimulus.debounce_tb;
    d = model_debounce(s.key, constant_trace(1), s.endTick, cfg);
    expected.debounce_tb = panel(s, 'ms', { ...
        'key_in', 'VCD input', s.key, 'logic'; ...
        'key_deb', 'expected', d.keyDeb, 'logic'; ...
        'press_pulse', 'expected', d.pulse, 'logic'; ...
        'pulse_cnt', 'expected', d.count, 'state'});

    s = stimulus.lab4_top;
    d = model_debounce(s.key, s.reset, s.endTick, cfg);
    state = model_top_state(d.pulse, s.reset, s.endTick, cfg.sysPeriod);
    expected.lab4_top = panel(s, 'ms', { ...
        'sys_rst_n', 'VCD input', s.reset, 'logic'; ...
        'key_in', 'VCD input', s.key, 'logic'; ...
        'press_pulse', 'expected', d.pulse, 'logic'; ...
        'state', 'expected', state, 'state'});

    s = stimulus.pll_tb;
    divided = model_divider(s.clock, s.reset);
    expected.pll_tb = panel(s, 'ns', { ...
        'sys_rst_n', 'VCD input', s.reset, 'logic'; ...
        'sys_clk', 'VCD input', s.clock, 'logic'; ...
        'vga_clk', 'expected', divided, 'logic'});

    s = stimulus.screen_fsm_tb;
    [state, nextState] = model_fsm(s.clock, s.reset, s.press);
    expected.screen_fsm_tb = panel(s, 'ns', { ...
        'clk', 'VCD input', s.clock, 'logic'; ...
        'rst_n', 'VCD input', s.reset, 'logic'; ...
        'press', 'VCD input', s.press, 'logic'; ...
        'state', 'expected', state, 'state'; ...
        'next_state', 'expected', nextState, 'state'; ...
        'screen_sel', 'expected', state, 'state'});

    s = stimulus.vga_control_tb;
    v = model_vga_control(s.clock, s.reset, cfg);
    expected.vga_control_tb = panel(s, 'us', { ...
        'vga_clk', 'VCD input', s.clock, 'logic'; ...
        'sys_rst_n', 'VCD input', s.reset, 'logic'; ...
        'hsync', 'expected', v.hsync, 'logic'; ...
        'vsync', 'expected', v.vsync, 'logic'; ...
        'pix_data_req', 'expected', v.request, 'logic'; ...
        'rgb_valid', 'expected', v.valid, 'logic'; ...
        'pix_x', 'expected', v.x, 'number'; ...
        'pix_y', 'expected', v.y, 'number'; ...
        'cnt_h', 'expected', v.h, 'number'; ...
        'cnt_v', 'expected', v.v, 'number'});

    s = stimulus.vga_pic_tb;
    pixel = model_pixel_samples(s);
    expected.vga_pic_tb = panel(s, 'ns', { ...
        'vga_clk', 'VCD input', s.clock, 'logic'; ...
        'sys_rst_n', 'VCD input', s.reset, 'logic'; ...
        'screen_sel', 'VCD input', s.screen, 'state'; ...
        'pix_data_req', 'VCD input', s.request, 'logic'; ...
        'pix_x', 'VCD input', s.x, 'number'; ...
        'pix_y', 'VCD input', s.y, 'number'; ...
        'pix_data', 'expected from check_pixel.exp', pixel, 'hex'; ...
        'check_pixel.exp', 'VCD testbench reference', s.pixel_expected, 'hex'});

    % Explicitly enumerate all 8 figures; never silently skip a pulse view.
    views = { ...
        'debounce_tb', 'overview'; ...
        'debounce_tb', 'pulse_zoom'; ...
        'lab4_top', 'overview'; ...
        'lab4_top', 'pulse_zoom'; ...
        'pll_tb', 'overview'; ...
        'screen_fsm_tb', 'overview'; ...
        'vga_control_tb', 'overview'; ...
        'vga_pic_tb', 'overview'};
    total = size(views, 1);
    plan = struct('number', {}, 'module', {}, 'title', {}, 'unit', {}, ...
        'window', {}, 'origin', {}, 'filename', {});
    for k = 1:total
        name = views{k, 1};
        p = expected.(name);
        unit = p.unit; window = [0, p.endTick]; origin = 0;
        label = name; suffix = '';
        if strcmp(views{k, 2}, 'pulse_zoom')
            index = find(strcmp({p.signals.name}, 'press_pulse'), 1);
            if isempty(index)
                error('lab4:MissingPulseSignal', 'Cannot prepare %s zoom: press_pulse is absent.', name);
            end
            rising = rising_edges(p.signals(index).trace);
            if isempty(rising)
                error('lab4:MissingExpectedPulse', ...
                    'Cannot prepare all 8 figures: %s has no expected rising pulse.', name);
            end
            origin = rising(1);
            window = [max(0, origin - 100000), min(p.endTick, origin + 100000)];
            unit = 'ns';
            label = [name, ' | first pulse zoom'];
            suffix = '_pulse_zoom';
        end
        plan(k) = struct('number', k, 'module', name, ...
            'title', sprintf('%02d/%02d | %s', k, total, label), ...
            'unit', unit, 'window', window, 'origin', origin, ...
            'filename', sprintf('expected_%02d_%s%s.png', k, name, suffix));
    end
    expected.figureManifest = plan;
    expected.figureCount = total;
    expected.figureHandles = gobjects(total, 1);
    for k = 1:total
        view = plan(k);
        fig = plot_panel(expected.(view.module), view.title, view.unit, view.window, view.origin);
        expected.figureHandles(k) = fig;
        fprintf('Created %s\n', view.title);
    end
    fprintf('Created all %d expected-waveform figures.\n', total);
    % Finish creating all windows before any optional file export.
    for k = 1:total
        [~, baseName] = fileparts(plan(k).filename);
        save_if_requested(expected.figureHandles(k), exportDir, baseName);
    end
    fprintf('Expected waveforms use black backgrounds and white traces.\n');
    fprintf('Inputs and time ranges are taken from the supplied VCD files.\n');
    fprintf('Debounce: normal 10 ms behavior includes the fourth expected press.\n');
    fprintf('See EXPECTED使用说明.txt for model assumptions and observed differences.\n');
end


function d = model_debounce(key, reset, endTick, cfg)
% Event-based qualification, avoiding millions of simulated clock cycles.
% Reset cancels pending qualification. A key held across reset must first
% be released, matching the final reset scenario in lab4_top.vcd.
    boundaries = unique([0; key.t; reset.t; endTick]);
    keyValues = sample_trace(key, boundaries);
    resetValues = sample_trace(reset, boundaries);
    stable = 1;
    armed = keyValues(1) == 1;
    previousReset = resetValues(1);
    pending = Inf;
    pendingValue = stable;
    debEvents = [0, 1];
    pulseStarts = zeros(0, 1);
    for k = 1:numel(boundaries) - 1
        t = boundaries(k);
        stop = boundaries(k + 1);
        input = keyValues(k);
        rst = resetValues(k);
        if rst == 0
            stable = 1;
            debEvents(end + 1, :) = [t, stable]; %#ok<AGROW>
            pending = Inf;
            armed = false;
        else
            if previousReset == 0
                armed = ~cfg.requireReleaseAfterReset || input == 1;
            end
            if input == 1, armed = true; end
            if input == stable || (~armed && input == 0)
                pending = Inf;
            elseif ~isfinite(pending) || pendingValue ~= input
                pending = t + cfg.debounceStableTime + cfg.debouncePipelineDelay;
                pendingValue = input;
            end
            if pending < stop || (stop == endTick && pending == stop)
                stable = pendingValue;
                debEvents(end + 1, :) = [pending, stable]; %#ok<AGROW>
                if stable == 0
                    pulseStarts(end + 1, 1) = pending; %#ok<AGROW>
                end
                pending = Inf;
            end
        end
        previousReset = rst;
    end
    pulseEnds = pulseStarts + cfg.sysPeriod;
    d.keyDeb = normalized_trace(debEvents(:, 1), debEvents(:, 2));
    pulseT = [0; pulseStarts; pulseEnds];
    pulseV = [0; ones(size(pulseStarts)); zeros(size(pulseEnds))];
    keep = pulseT <= endTick;
    d.pulse = normalized_trace(pulseT(keep), pulseV(keep));
    countTimes = pulseEnds(pulseEnds <= endTick);
    d.count = normalized_trace([0; countTimes], [0; (1:numel(countTimes))']);
end


function stateTrace = model_top_state(pulse, reset, endTick, clockPeriod)
% The FSM consumes a newly registered press pulse on the following clock.
    consume = rising_edges(pulse) + clockPeriod;
    consume = consume(consume <= endTick);
    t = unique([0; consume; reset.t]);
    resets = sample_trace(reset, t);
    advance = ismember(t, consume);
    value = zeros(size(t));
    state = 0;
    for k = 1:numel(t)
        if resets(k) == 0
            state = 0;
        elseif advance(k)
            state = mod(state + 1, 3);
        end
        value(k) = state;
    end
    stateTrace = normalized_trace(t, value);
end


function output = model_divider(clock, reset)
    edges = rising_edges(clock);
    t = unique([0; edges; reset.t]);
    rst = sample_trace(reset, t);
    isEdge = ismember(t, edges);
    value = zeros(size(t));
    q = 0;
    for k = 1:numel(t)
        if rst(k) == 0
            q = 0;
        elseif isEdge(k)
            q = 1 - q;
        end
        value(k) = q;
    end
    output = normalized_trace(t, value);
end


function [stateTrace, nextTrace] = model_fsm(clock, reset, press)
    edges = rising_edges(clock);
    t = unique([0; edges; reset.t; press.t]);
    rst = sample_trace(reset, t);
    pressed = sample_trace(press, t);
    isEdge = ismember(t, edges);
    values = zeros(size(t));
    q = 0;
    for k = 1:numel(t)
        if rst(k) == 0
            q = 0;
        elseif isEdge(k) && pressed(k) == 1
            q = mod(q + 1, 3);
        end
        values(k) = q;
    end
    stateTrace = normalized_trace(t, values);
    nextTrace = normalized_trace(t, mod(values + double(pressed == 1), 3));
end


function out = model_vga_control(clock, reset, cfg)
% High sync pulses and the 1-pixel request-coordinate lead follow this VCD.
% The trace ends at line 31, before vertical active video starts at line 35.
% V_ACTIVE/V_FRONT therefore do not create any additional unseen frame.
    edges = rising_edges(clock);
    t = unique([0; edges; reset.t]);
    rst = sample_trace(reset, t);
    isEdge = ismember(t, edges);
    hTotal = cfg.H_SYNC + cfg.H_BACK + cfg.H_ACTIVE + cfg.H_FRONT;
    vTotal = cfg.V_SYNC + cfg.V_BACK + cfg.V_ACTIVE + cfg.V_FRONT;
    h = zeros(size(t)); v = zeros(size(t));
    hc = 0; vc = 0;
    for k = 1:numel(t)
        if rst(k) == 0
            hc = 0; vc = 0;
        elseif isEdge(k)
            hc = hc + 1;
            if hc >= hTotal
                hc = 0;
                vc = mod(vc + 1, vTotal);
            end
        end
        h(k) = hc; v(k) = vc;
    end
    hStart = cfg.H_SYNC + cfg.H_BACK;
    vStart = cfg.V_SYNC + cfg.V_BACK;
    horizontal = h >= hStart & h < hStart + cfg.H_ACTIVE;
    requestHorizontal = h >= hStart - 1 & h < hStart + cfg.H_ACTIVE - 1;
    vertical = v >= vStart & v < vStart + cfg.V_ACTIVE;
    x = repmat(cfg.invalidCoordinate, size(t));
    y = repmat(cfg.invalidCoordinate, size(t));
    x(requestHorizontal) = h(requestHorizontal) - (hStart - 1);
    y(vertical) = v(vertical) - vStart;
    out.h = normalized_trace(t, h);
    out.v = normalized_trace(t, v);
    out.hsync = normalized_trace(t, double(h < cfg.H_SYNC));
    out.vsync = normalized_trace(t, double(v < cfg.V_SYNC));
    out.request = normalized_trace(t, double(requestHorizontal & vertical & rst == 1));
    out.valid = normalized_trace(t, double(horizontal & vertical & rst == 1));
    out.x = normalized_trace(t, x);
    out.y = normalized_trace(t, y);
end


function pixel = model_pixel_samples(s)
% Use testbench exp as the oracle at requested rising clock edges.
% This models only the four recorded test points, not an unrecorded image.
% Inputs changing at a clock timestamp are sampled at their settled values.
    edges = rising_edges(s.clock);
    t = unique([0; edges; s.reset.t]);
    rst = sample_trace(s.reset, t);
    request = sample_trace(s.request, t);
    reference = sample_trace(s.pixel_expected, t);
    isEdge = ismember(t, edges);
    values = zeros(size(t));
    q = 0;
    for k = 1:numel(t)
        if rst(k) == 0
            q = 0;
        elseif isEdge(k) && request(k) == 1
            q = reference(k);
        end
        values(k) = q;
    end
    pixel = normalized_trace(t, values);
end


function p = panel(source, unit, rows)
    p.sourceFile = source.source;
    p.sourceSha256 = source.sha256;
    p.endTick = source.endTick;
    p.unit = unit;
    p.signals = struct('name', {}, 'role', {}, 'trace', {}, 'display', {});
    for k = 1:size(rows, 1)
        p.signals(k).name = rows{k, 1};
        p.signals(k).role = rows{k, 2};
        p.signals(k).trace = rows{k, 3};
        p.signals(k).display = rows{k, 4};
    end
end


function fig = plot_panel(p, name, unit, window, origin)
    n = numel(p.signals);
    fig = figure('Name', ['EXPECTED WAVEFORM | ', name], ...
        'NumberTitle', 'off', 'Visible', 'on', 'Color', [0, 0, 0], ...
        'InvertHardcopy', 'off', 'PaperPositionMode', 'auto', ...
        'Position', [80, 50, 1200, min(1080, 160 + 105 * n)]);
    axesList = gobjects(n, 1);
    factor = tick_to_unit(unit);
    for k = 1:n
        signal = p.signals(k);
        trace = clip_trace(signal.trace, window);
        ax = subplot(n, 1, k, 'Parent', fig);
        axesList(k) = ax;
        stairs(ax, (trace.t - origin) * factor, trace.v, ...
            'Color', [1, 1, 1], 'LineWidth', 1.25);
        set(ax, 'Color', [0, 0, 0], 'XColor', [1, 1, 1], ...
            'YColor', [1, 1, 1], 'GridColor', [1, 1, 1], ...
            'GridAlpha', 0.16, 'FontSize', 9, 'Box', 'on');
        grid(ax, 'on');
        titleText = sprintf('%s  |  %s', signal.name, signal.role);
        if k == 1
            titleText = sprintf('EXPECTED WAVEFORM | %s\n%s', name, titleText);
        end
        title(ax, titleText, 'Color', [1, 1, 1], ...
            'Interpreter', 'none', 'FontWeight', 'normal');
        ylabel(ax, 'value', 'Color', [1, 1, 1]);
        if strcmp(signal.display, 'logic')
            ylim(ax, [-0.2, 1.2]);
            set(ax, 'YTick', [0, 1]);
        elseif strcmp(signal.display, 'state')
            maximum = max([2; trace.v(isfinite(trace.v))]);
            ylim(ax, [-0.25, maximum + 0.3]);
            set(ax, 'YTick', 0:maximum);
        elseif strcmp(signal.display, 'hex')
            ylim(ax, [-4000, 76000]);
            set(ax, 'YTick', [0, 32768, 65535], ...
                'YTickLabel', {'0000', '8000', 'FFFF'});
            ylabel(ax, 'hex', 'Color', [1, 1, 1]);
            for j = 1:numel(trace.t) - 1
                if isfinite(trace.v(j)) && diff(trace.t(j:j + 1)) > diff(window) * 0.07
                    center = (trace.t(j) + trace.t(j + 1)) / 2;
                    text(ax, (center - origin) * factor, trace.v(j) + 3500, ...
                        sprintf('%04X', round(trace.v(j))), 'Color', [1, 1, 1], ...
                        'HorizontalAlignment', 'center', 'FontSize', 8);
                end
            end
        end
        if any(isnan(trace.v))
            text(ax, 0.01, 0.85, 'Unknown reference values shown as gaps', ...
                'Units', 'normalized', 'Color', [1, 1, 1], 'FontSize', 8);
        end
        xlim(ax, (window - origin) * factor);
        if k < n, set(ax, 'XTickLabel', []); end
    end
    linkaxes(axesList, 'x');
    if origin == 0
        label = ['Time (', unit, ')'];
    else
        label = sprintf('Time relative to %.8f ms (%s)', origin * 1e-9, unit);
    end
    xlabel(axesList(end), label, 'Color', [1, 1, 1]);
end


function save_if_requested(fig, folder, name)
    if isempty(folder), return; end
    % InvertHardcopy='off' preserves black backgrounds in exported PNGs.
    print(fig, fullfile(folder, [name, '.png']), '-dpng', '-r200');
end


function s = normalized_trace(t, v)
    t = t(:); v = v(:);
    [t, index] = unique(t, 'last');
    v = v(index);
    keep = [true; v(2:end) ~= v(1:end - 1)];
    s = struct('t', t(keep), 'v', v(keep));
end


function s = constant_trace(value)
    s = struct('t', 0, 'v', value);
end


function values = sample_trace(s, t)
    if numel(s.t) == 1
        values = repmat(s.v(1), size(t));
    else
        values = interp1(s.t, s.v, t, 'previous', 'extrap');
    end
end


function edges = rising_edges(s)
    mask = [false; s.v(2:end) == 1 & s.v(1:end - 1) == 0];
    edges = s.t(mask);
end


function s = clip_trace(source, window)
    inside = source.t > window(1) & source.t < window(2);
    s.t = [window(1); source.t(inside); window(2)];
    s.v = [sample_trace(source, window(1)); source.v(inside); sample_trace(source, window(2))];
end


function factor = tick_to_unit(unit)
    switch unit
        case 'ms', factor = 1e-9;
        case 'us', factor = 1e-6;
        case 'ns', factor = 1e-3;
        otherwise, error('lab4:TimeUnit', 'Unsupported unit: %s', unit);
    end
end


% ----- Exact source-input snapshot (local functions) -----
function stimulus = lab4_vcd_stimulus
%LAB4_VCD_STIMULUS Input-event snapshot of the six user-supplied VCD files.
% Generated by reading VCD text only. No MATLAB code has been executed.
% Time is in original 1 ps ticks. No DUT output waveform is copied here.
% pixel_expected is the testbench check_pixel.exp reference, not pix_data.
    stimulus.tickSeconds = 1e-12;

    % debounce_tb.vcd: recorded input events only.
    stimulus.debounce_tb.source = 'debounce_tb.vcd';
    stimulus.debounce_tb.sha256 = '60873b72885233a269e0327735925f93a914ba1f6e9a3bbea2461c4f7955123c';
    stimulus.debounce_tb.endTick = 194300000000;
    stimulus.debounce_tb.key = make_trace([ ...
        0, 1; ...
        1100000000, 0; ...
        21100000000, 1; ...
        41100000000, 0; ...
        41300000000, 1; ...
        41500000000, 0; ...
        41700000000, 1; ...
        41900000000, 0; ...
        42100000000, 1; ...
        42300000000, 0; ...
        42500000000, 1; ...
        42700000000, 0; ...
        42900000000, 1; ...
        43100000000, 0; ...
        58300000000, 1; ...
        78300000000, 0; ...
        128300000000, 1; ...
        148300000000, 0; ...
        174300000000, 1; ...
    ]);

    % lab4_top.vcd: recorded input events only.
    stimulus.lab4_top.source = 'lab4_top.vcd';
    stimulus.lab4_top.sha256 = '7fa3bba1cee61088102019ae8d118deaaddd380ba5baf69ef2ec0963bbe8977d';
    stimulus.lab4_top.endTick = 316300000000;
    stimulus.lab4_top.key = make_trace([ ...
        0, 1; ...
        1100000000, 0; ...
        21100000000, 1; ...
        41100000000, 0; ...
        41300000000, 1; ...
        41500000000, 0; ...
        41700000000, 1; ...
        41900000000, 0; ...
        42100000000, 1; ...
        42300000000, 0; ...
        42500000000, 1; ...
        42700000000, 0; ...
        42900000000, 1; ...
        43100000000, 0; ...
        58300000000, 1; ...
        78300000000, 0; ...
        128300000000, 1; ...
        148300000000, 0; ...
        168300000000, 1; ...
        190300000000, 0; ...
        210300000000, 1; ...
        230300000000, 0; ...
        250300000000, 1; ...
        270300000000, 0; ...
        296300000000, 1; ...
    ]);
    stimulus.lab4_top.reset = make_trace([ ...
        0, 0; ...
        100000000, 1; ...
        188300000000, 0; ...
        189300000000, 1; ...
        275300000000, 0; ...
        276300000000, 1; ...
    ]);

    % pll_tb.vcd: recorded input events only.
    stimulus.pll_tb.source = 'pll_tb.vcd';
    stimulus.pll_tb.sha256 = '6a9157d1463a0f27a47ea5d5855237a9214452b071a430d2e488596b7c3a1c28';
    stimulus.pll_tb.endTick = 445000;
    stimulus.pll_tb.clock = clock_trace(10000, 440000);
    stimulus.pll_tb.reset = make_trace([ ...
        0, 0; ...
        25000, 1; ...
        225000, 0; ...
        245000, 1; ...
    ]);

    % screen_fsm_tb.vcd: recorded input events only.
    stimulus.screen_fsm_tb.source = 'screen_fsm_tb.vcd';
    stimulus.screen_fsm_tb.sha256 = 'c6011925818ff7288d95bd4dddfa07598387d324c0f1cb0887cfe6c5c16bca6f';
    stimulus.screen_fsm_tb.endTick = 680000;
    stimulus.screen_fsm_tb.clock = clock_trace(10000, 680000);
    stimulus.screen_fsm_tb.reset = make_trace([ ...
        0, 0; ...
        50000, 1; ...
        580000, 0; ...
        630000, 1; ...
    ]);
    stimulus.screen_fsm_tb.press = make_trace([ ...
        0, 0; ...
        100000, 1; ...
        120000, 0; ...
        220000, 1; ...
        240000, 0; ...
        340000, 1; ...
        360000, 0; ...
        460000, 1; ...
        480000, 0; ...
    ]);

    % vga_control_tb.vcd: recorded input events only.
    stimulus.vga_control_tb.source = 'vga_control_tb.vcd';
    stimulus.vga_control_tb.sha256 = '799fcc6595fd47ccd61161d7c7716ce82a4e14925772f60d12775f187e2f5ffd';
    stimulus.vga_control_tb.endTick = 1000100000;
    stimulus.vga_control_tb.clock = clock_trace(20000, 1000100000);
    stimulus.vga_control_tb.reset = make_trace([ ...
        0, 0; ...
        100000, 1; ...
    ]);

    % vga_pic_tb.vcd: recorded input events only.
    stimulus.vga_pic_tb.source = 'vga_pic_tb.vcd';
    stimulus.vga_pic_tb.sha256 = '4e914ff4e0ba24c21c3d767edda0d9ec99ef2ed8760603523030c38cb669827f';
    stimulus.vga_pic_tb.endTick = 340000;
    stimulus.vga_pic_tb.clock = clock_trace(20000, 340000);
    stimulus.vga_pic_tb.reset = make_trace([ ...
        0, 0; ...
        50000, 1; ...
    ]);
    stimulus.vga_pic_tb.request = make_trace([ ...
        0, 0; ...
        50000, 1; ...
        61000, 0; ...
        100000, 1; ...
        141000, 0; ...
        180000, 1; ...
        221000, 0; ...
        260000, 1; ...
        301000, 0; ...
    ]);
    stimulus.vga_pic_tb.x = make_trace([ ...
        0, 0; ...
        100000, 144; ...
        180000, 192; ...
        260000, 160; ...
    ]);
    stimulus.vga_pic_tb.y = make_trace([ ...
        0, 0; ...
        100000, 208; ...
    ]);
    stimulus.vga_pic_tb.screen = make_trace([ ...
        0, 0; ...
        100000, 1; ...
        180000, 2; ...
        260000, 1; ...
    ]);
    stimulus.vga_pic_tb.pixel_expected = make_trace([ ...
        0, NaN; ...
        50000, 63488; ...
        100000, 65535; ...
        260000, 0; ...
    ]);

end

function s = make_trace(events)
    s = struct('t', events(:, 1), 'v', events(:, 2));
end

function s = clock_trace(halfPeriod, lastEdge)
    t = (0:halfPeriod:lastEdge)';
    s = struct('t', t, 'v', mod((0:numel(t) - 1)', 2));
end
