function results = lab4_vcd_waveforms(vcdDir)
%LAB4_VCD_WAVEFORMS Read and plot the six supplied Lab 4 VCD files.
% 中文说明：读取真实 VCD 事件，为 6 个模块分别绘制波形，不重建仿真。
% 将本文件与 6 个 VCD 放在同一文件夹，随后手动执行：
%   results = lab4_vcd_waveforms;
% 或指定 VCD 文件夹：
%   results = lab4_vcd_waveforms('/Users/zzy/Desktop/lab4');
%
% No third-party toolbox is required. Recommended: MATLAB R2018b or newer.
% All selected events are retained in results. Only large BUS plots are
% reduced for display; one-bit signals (including narrow pulses) are not.
%
% results.debounce_tb.signals(k):
%   name, aliases, width, varType, ticks, values, kind
% Time in seconds = ticks * results.debounce_tb.timescaleSeconds.
% kind: 0 = numeric, 1 = contains X, 2 = contains Z, 3 = contains X and Z.
% Unknown bus values are NaN. Known binary buses are interpreted unsigned.

    if nargin < 1 || isempty(vcdDir)
        vcdDir = fileparts(mfilename('fullpath'));
        if ~isfile(fullfile(vcdDir, 'debounce_tb.vcd'))
            vcdDir = uigetdir(vcdDir, 'Select the folder containing the six VCD files');
            if isequal(vcdDir, 0)
                results = struct();
                return;
            end
        end
    end
    vcdDir = char(vcdDir);

    % 可修改的绘图设置；不会改变 results 中保存的完整事件。
    maxBusPlotPoints = 24000;
    makePulseZoom = true;
    pulseZoomHalfWidthNs = 100;

    jobs = {
        'debounce_tb', 'ms', { ...
            'debounce_tb.key_in', 'debounce_tb.dut.key_deb', ...
            'debounce_tb.press_pulse', 'debounce_tb.pulse_cnt', ...
            'debounce_tb.dut.cnt'};
        'lab4_top', 'ms', { ...
            'lab4_top_tb.sys_rst_n', 'lab4_top_tb.key_in', ...
            'lab4_top_tb.dut.press_pulse', ...
            'lab4_top_tb.dut.u_screen_fsm.state'};
        'pll_tb', 'ns', { ...
            'pll_tb.sys_rst_n', 'pll_tb.sys_clk', 'pll_tb.vga_clk'};
        'screen_fsm_tb', 'ns', { ...
            'screen_fsm_tb.clk', 'screen_fsm_tb.rst_n', ...
            'screen_fsm_tb.press', 'screen_fsm_tb.dut.state', ...
            'screen_fsm_tb.dut.next_state', 'screen_fsm_tb.screen_sel'};
        'vga_control_tb', 'us', { ...
            'vga_control_tb.vga_clk', 'vga_control_tb.sys_rst_n', ...
            'vga_control_tb.hsync', 'vga_control_tb.vsync', ...
            'vga_control_tb.pix_data_req', 'vga_control_tb.rgb_valid', ...
            'vga_control_tb.pix_x', 'vga_control_tb.pix_y', ...
            'vga_control_tb.dut.cnt_h', 'vga_control_tb.dut.cnt_v'};
        'vga_pic_tb', 'ns', { ...
            'vga_pic_tb.vga_clk', 'vga_pic_tb.sys_rst_n', ...
            'vga_pic_tb.screen_sel', 'vga_pic_tb.pix_data_req', ...
            'vga_pic_tb.pix_x', 'vga_pic_tb.pix_y', ...
            'vga_pic_tb.pix_data', 'vga_pic_tb.check_pixel.exp'}
    };

    for j = 1:size(jobs, 1)
        filename = fullfile(vcdDir, [jobs{j, 1}, '.vcd']);
        if ~isfile(filename)
            error('lab4:MissingFile', 'VCD file not found: %s', filename);
        end
    end

    results = struct();
    for j = 1:size(jobs, 1)
        name = jobs{j, 1};
        filename = fullfile(vcdDir, [name, '.vcd']);
        fprintf('\nReading %s ...\n', filename);
        data = read_selected_vcd(filename, jobs{j, 3});
        results.(name) = data;
        fprintf('  Timescale: %s; duration: %.12g s\n', ...
            data.timescaleText, data.endTick * data.timescaleSeconds);
        for k = 1:numel(data.signals)
            fprintf('  %-48s %9d events\n', data.signals(k).name, ...
                numel(data.signals(k).ticks));
        end
        plot_vcd(data, name, jobs{j, 2}, [], 0, maxBusPlotPoints);
        if makePulseZoom && any(strcmp(name, {'debounce_tb', 'lab4_top'}))
            plot_first_pulse(data, name, pulseZoomHalfWidthNs, maxBusPlotPoints);
        end
    end
    fprintf('\nFinished. Full selected event data are available in results.\n');
end


function data = read_selected_vcd(filename, requested)
% Stream the file line by line instead of loading its text into memory.
    fid = fopen(filename, 'rt');
    if fid < 0
        error('lab4:OpenFile', 'Cannot open %s', filename);
    end
    cleanup = onCleanup(@() fclose(fid)); %#ok<NASGU>
    scopes = {};
    decl = struct('name', {}, 'id', {}, 'width', {}, 'varType', {});
    timescaleSeconds = NaN;
    timescaleText = '';
    headerComplete = false;
    while true
        line = fgetl(fid);
        if ~ischar(line), break; end
        line = strtrim(line);
        if isempty(line), continue; end
        if line(1) ~= '$', continue; end
        block = read_directive(fid, line);
        words = strsplit(strtrim(block));
        switch words{1}
            case '$scope'
                scopes{end + 1} = words{3}; %#ok<AGROW>
            case '$upscope'
                if ~isempty(scopes), scopes(end) = []; end
            case '$var'
                d.name = strjoin([scopes, words(5)], '.');
                d.id = words{4};
                d.width = str2double(words{3});
                d.varType = words{2};
                decl(end + 1) = d; %#ok<AGROW>
            case '$timescale'
                tok = regexp(block, ...
                    '\$timescale\s*(\d+)\s*(s|ms|us|ns|ps|fs)\s*\$end', ...
                    'tokens', 'once');
                if isempty(tok)
                    error('lab4:Timescale', 'Invalid timescale in %s', filename);
                end
                timescaleSeconds = str2double(tok{1}) * time_unit_seconds(tok{2});
                timescaleText = [tok{1}, ' ', tok{2}];
            case '$enddefinitions'
                headerComplete = true;
                break;
        end
    end
    if ~headerComplete || ~isfinite(timescaleSeconds) || timescaleSeconds <= 0
        error('lab4:Header', 'Missing VCD header/timescale in %s', filename);
    end

    signals = struct('name', {}, 'aliases', {}, 'id', {}, 'width', {}, ...
        'varType', {}, 'ticks', {}, 'values', {}, 'kind', {});
    idMap = containers.Map('KeyType', 'char', 'ValueType', 'double');
    fastId = zeros(256, 1);
    for k = 1:numel(requested)
        hit = find(strcmp({decl.name}, requested{k}), 1);
        if isempty(hit)
            error('lab4:SignalMissing', 'Signal %s is absent from %s', requested{k}, filename);
        end
        d = decl(hit);
        if isKey(idMap, d.id), continue; end
        q = numel(signals) + 1;
        signals(q).name = d.name;
        signals(q).aliases = {decl(strcmp({decl.id}, d.id)).name};
        signals(q).id = d.id;
        signals(q).width = d.width;
        signals(q).varType = d.varType;
        if d.width > 53
            error('lab4:BusWidth', 'Exact double conversion supports at most 53 bits: %s', d.name);
        end
        idMap(d.id) = q;
        if numel(d.id) == 1 && double(d.id) < 256
            fastId(double(d.id) + 1) = q;
        end
    end

    nSignals = numel(signals);
    counts = zeros(1, nSignals);
    capacities = repmat(4096, 1, nSignals);
    ticks = cell(1, nSignals);
    values = cell(1, nSignals);
    kinds = cell(1, nSignals);
    for k = 1:nSignals
        ticks{k} = zeros(capacities(k), 1);
        values{k} = zeros(capacities(k), 1);
        kinds{k} = zeros(capacities(k), 1, 'uint8');
    end
    currentTick = 0;
    reportClock = tic;
    fileInfo = dir(filename);
    lineCount = 0;
    while true
        line = fgetl(fid);
        if ~ischar(line), break; end
        line = strtrim(line);
        if isempty(line), continue; end
        lineCount = lineCount + 1;
        if mod(lineCount, 200000) == 0 && toc(reportClock) > 5
            fprintf('  Reading: %.1f%%\n', 100 * ftell(fid) / fileInfo.bytes);
            drawnow;
            reportClock = tic;
        end
        tag = lower(line(1));
        if tag == '#'
            nextTick = str2double(line(2:end));
            if ~isfinite(nextTick) || nextTick < currentTick || ...
                    nextTick > flintmax || nextTick ~= fix(nextTick)
                error('lab4:Timestamp', 'Invalid or inexact timestamp: %s', line);
            end
            currentTick = nextTick;
            continue;
        elseif tag == '$'
            % These directives wrap value changes; retain the changes inside.
            if any(strcmp(line, {'$dumpvars', '$dumpall', '$dumpon', '$dumpoff', '$end'}))
                continue;
            end
            read_directive(fid, line);
            continue;
        elseif tag == 'b' || tag == 'r'
            splitAt = find(isspace(line), 1);
            if isempty(splitAt)
                error('lab4:ValueSyntax', 'Malformed VCD value: %s', line);
            end
            raw = lower(line(2:splitAt - 1));
            id = strtrim(line(splitAt + 1:end));
        elseif any(tag == '01xz')
            raw = tag;
            id = strtrim(line(2:end));
        else
            error('lab4:UnsupportedValue', 'Unsupported VCD record: %s', line);
        end
        q = 0;
        if numel(id) == 1 && double(id) < 256
            q = fastId(double(id) + 1);
        elseif isKey(idMap, id)
            q = idMap(id);
        end
        if q == 0, continue; end
        kind = uint8(any(raw == 'x')) + uint8(2 * any(raw == 'z'));
        if kind > 0
            value = NaN;
        elseif tag == 'r'
            value = str2double(raw);
        elseif numel(raw) == 1
            value = double(raw) - double('0');
        else
            value = bin2dec(raw);
        end
        append_event(q, currentTick, value, kind);
    end
    for k = 1:nSignals
        n = counts(k);
        signals(k).ticks = ticks{k}(1:n);
        signals(k).values = values{k}(1:n);
        signals(k).kind = kinds{k}(1:n);
    end
    data = struct('filename', filename, 'timescaleText', timescaleText, ...
        'timescaleSeconds', timescaleSeconds, 'endTick', currentTick, 'signals', signals);

    function append_event(q, t, v, kind)
        n = counts(q);
        % VCD delta-cycle ordering: keep the final value at an identical tick.
        if n > 0 && ticks{q}(n) == t
            values{q}(n) = v;
            kinds{q}(n) = kind;
            return;
        end
        if n >= capacities(q)
            capacities(q) = 2 * capacities(q);
            ticks{q}(capacities(q), 1) = 0;
            values{q}(capacities(q), 1) = 0;
            kinds{q}(capacities(q), 1) = uint8(0);
        end
        n = n + 1;
        ticks{q}(n) = t;
        values{q}(n) = v;
        kinds{q}(n) = kind;
        counts(q) = n;
    end
end


function block = read_directive(fid, firstLine)
    block = firstLine;
    while isempty(regexp(block, '\$end(\s|$)', 'once'))
        nextLine = fgetl(fid);
        if ~ischar(nextLine)
            error('lab4:UnexpectedEOF', 'Unterminated VCD directive.');
        end
        block = [block, ' ', strtrim(nextLine)]; %#ok<AGROW>
    end
end


function scale = time_unit_seconds(unit)
    units = {'s', 'ms', 'us', 'ns', 'ps', 'fs'};
    scales = [1, 1e-3, 1e-6, 1e-9, 1e-12, 1e-15];
    index = find(strcmp(units, unit), 1);
    if isempty(index), error('lab4:TimeUnit', 'Unknown time unit: %s', unit); end
    scale = scales(index);
end


function plot_vcd(data, plotName, unit, tickWindow, originTick, maxBusPoints)
    if isempty(tickWindow), tickWindow = [0, data.endTick]; end
    if tickWindow(2) <= tickWindow(1), tickWindow(2) = tickWindow(1) + 1; end
    n = numel(data.signals);
    fig = figure('Name', plotName, 'NumberTitle', 'off', 'Color', 'w', ...
        'Position', [70, 60, 1160, min(1000, 120 + 100 * n)]);
    axesList = gobjects(n, 1);
    colors = lines(n);
    factor = data.timescaleSeconds / time_unit_seconds(unit);
    for k = 1:n
        s = data.signals(k);
        [t, v, kind] = window_trace(s, tickWindow);
        reduced = false;
        if s.width > 1 && numel(t) > maxBusPoints
            keep = bus_display_indices(v, kind, maxBusPoints);
            t = t(keep); v = v(keep); kind = kind(keep);
            reduced = true;
        end
        ax = subplot(n, 1, k, 'Parent', fig);
        axesList(k) = ax;
        stairs(ax, (t - originTick) * factor, v, 'Color', colors(k, :), 'LineWidth', 1.05);
        hold(ax, 'on');
        grid(ax, 'on');
        ylabel(ax, 'value');
        label = sprintf('%s [%d bit]', s.name, s.width);
        if reduced, label = [label, '  (display reduced; full data in results)']; end
        title(ax, label, 'Interpreter', 'none', 'FontWeight', 'normal', 'FontSize', 9);
        if s.width == 1
            ylim(ax, [-0.2, 1.2]);
            set(ax, 'YTick', [0, 1]);
        elseif s.width <= 4
            ylim(ax, [-0.25, 2^s.width - 0.75]);
            set(ax, 'YTick', 0:2^s.width - 1);
        end
        if any(kind > 0)
            limits = ylim(ax);
            y = limits(1) + 0.88 * diff(limits);
            marks = {'x', 'o', 's'};
            labels = {'X', 'Z', 'X/Z'};
            handles = gobjects(0);
            entries = {};
            for state = 1:3
                mask = kind == state;
                if any(mask)
                    handles(end + 1) = plot(ax, (t(mask) - originTick) * factor, ...
                        repmat(y, sum(mask), 1), marks{state}, 'Color', [0.65, 0.15, 0.6]); %#ok<AGROW>
                    entries{end + 1} = labels{state}; %#ok<AGROW>
                end
            end
            legend(ax, handles, entries, 'Location', 'northeast');
        end
        xlim(ax, (tickWindow - originTick) * factor);
        if k < n, set(ax, 'XTickLabel', []); end
    end
    linkaxes(axesList, 'x');
    if originTick == 0
        xlabel(axesList(end), ['Time (', unit, ')']);
    else
        xlabel(axesList(end), sprintf('Time relative to %.12g ms (%s)', ...
            originTick * data.timescaleSeconds * 1e3, unit));
    end
end


function [t, v, kind] = window_trace(s, limits)
% Preserve the value already in effect at the left edge of a zoom window.
    before = find(s.ticks <= limits(1), 1, 'last');
    if isempty(before)
        initialValue = NaN; initialKind = uint8(1);
    else
        initialValue = s.values(before); initialKind = s.kind(before);
    end
    inside = find(s.ticks > limits(1) & s.ticks <= limits(2));
    t = [limits(1); s.ticks(inside)];
    v = [initialValue; s.values(inside)];
    kind = [initialKind; s.kind(inside)];
    if t(end) < limits(2)
        t(end + 1, 1) = limits(2);
        v(end + 1, 1) = v(end);
        kind(end + 1, 1) = kind(end);
    end
end


function keep = bus_display_indices(values, kind, targetPoints)
% Retain first/last/min/max in each index bucket for a BUS overview.
% This is display reduction only. Do not measure timing from this overview.
    n = numel(values);
    buckets = max(1, floor(targetPoints / 4));
    edges = round(linspace(1, n + 1, buckets + 1));
    indices = zeros(4 * buckets, 1);
    used = 0;
    for b = 1:buckets
        first = edges(b); last = edges(b + 1) - 1;
        group = first:last;
        numeric = group(isfinite(values(group)));
        choices = [first, last];
        if ~isempty(numeric)
            [~, lo] = min(values(numeric));
            [~, hi] = max(values(numeric));
            choices = [choices, numeric(lo), numeric(hi)]; %#ok<AGROW>
        end
        indices(used + (1:numel(choices))) = choices;
        used = used + numel(choices);
    end
    % Keep both sides of X/Z transitions so unknown spans remain visible.
    changes = find(diff(double(kind)) ~= 0);
    keep = unique([1; indices(1:used); changes; changes + 1; n]);
end


function plot_first_pulse(data, name, halfWidthNs, maxBusPoints)
    index = find(~cellfun('isempty', regexp({data.signals.name}, '\.press_pulse$', 'once')), 1);
    if isempty(index), return; end
    s = data.signals(index);
    rising = find(s.values(2:end) == 1 & s.values(1:end - 1) == 0, 1) + 1;
    if isempty(rising), return; end
    center = s.ticks(rising);
    halfWidth = max(1, round(halfWidthNs * 1e-9 / data.timescaleSeconds));
    limits = [max(0, center - halfWidth), min(data.endTick, center + halfWidth)];
    plot_vcd(data, [name, ' - first press pulse zoom'], 'ns', limits, center, maxBusPoints);
end
