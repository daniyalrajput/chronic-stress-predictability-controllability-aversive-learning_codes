function make_corr_plot(x, y1, y2, xLabelStr, yLabelStr, ...
    xlim_use, ylim_use, ...
    colS1, colS2, fig_pos, ax_pos, ...
    fs_tick_x, fs_tick_y, fs_label_x, fs_label_y, ...
    lw_axes, lw_fit, ms_dot, alpha_dot, png_dpi, out_png, out_pdf, ...
    addLegend, fs_legend, leg_x, leg_y)

%% ================= USER-CONTROLLED LABEL POSITION =================
X_LABEL_Y = -0.11;     % move x label up/down

Y_LABEL_X = -0.11;     % move y label left/right
Y_LABEL_Y = 0.50;      % move y label up/down (0.5 = center)

AX_LOOSE_INSET = [0.10 0.10 0.05 0.05];
%% ================================================================

xtick_vals = linspace(xlim_use(1), xlim_use(2), 5);
ytick_vals = linspace(ylim_use(1), ylim_use(2), 5);

fig = figure('Color','w','Position',fig_pos);
set(fig,'PaperPositionMode','auto');
set(fig,'InvertHardcopy','off');
clf;
hold on;

s1 = scatter(x, y1, ms_dot, colS1, 'filled', ...
    'MarkerEdgeColor','k', 'MarkerFaceAlpha',alpha_dot);

s2 = scatter(x, y2, ms_dot, colS2, 'filled', ...
    'MarkerEdgeColor','k', 'MarkerFaceAlpha',alpha_dot);

if numel(x) >= 2
    b1 = polyfit(x, y1, 1);
    b2 = polyfit(x, y2, 1);
    xf = linspace(xlim_use(1), xlim_use(2), 200);

    plot(xf, polyval(b1, xf), 'Color', colS1, 'LineWidth', lw_fit);
    plot(xf, polyval(b2, xf), 'Color', colS2, 'LineWidth', lw_fit);
end

ax = gca;
ax.LineWidth = lw_axes;
ax.TickDir   = 'out';
ax.Box       = 'off';

ax.XAxis.FontSize = fs_tick_x;
ax.YAxis.FontSize = fs_tick_y;

xlim(xlim_use);
ylim(ylim_use);

xticks(xtick_vals);
yticks(ytick_vals);

xtickformat('%.0f');
apply_y_tick_format(ytick_vals);

xlabel(xLabelStr,'FontSize',fs_label_x,'FontWeight','bold');
ylabel(yLabelStr,'FontSize',fs_label_y,'FontWeight','bold');

ax.Position   = ax_pos;
ax.LooseInset = AX_LOOSE_INSET;
ax.Clipping   = 'off';

%% ----- Adjust X label -----
xh = get(gca,'XLabel');
xh.Units = 'normalized';
xh.Position(2) = X_LABEL_Y;

%% ----- Adjust Y label -----
yh = get(gca,'YLabel');
yh.Units = 'normalized';
yh.Position = [Y_LABEL_X Y_LABEL_Y 0];

%% ----- Optional legend -----
if addLegend
    lgd = legend([s1 s2],{'Controllable','Uncontrollable'}, ...
        'Location','northeast','Box','off','FontSize',fs_legend);

    lgd.Units = 'normalized';
    lgd.Position(1) = leg_x;
    lgd.Position(2) = leg_y;
end

exportgraphics(fig,out_png,'Resolution',png_dpi);
exportgraphics(fig,out_pdf,'ContentType','vector');

close(fig);
end