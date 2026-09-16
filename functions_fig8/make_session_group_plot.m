function make_session_group_plot(T, sessionLabel, ylab, titlePrefix, ...
    colHealthy, colChronic, dotEdge, dotAlpha, boxAlpha, ...
    fs_title, fs_label, fs_tick, fs_legend, lw_axes, ...
    boxWidth, jitterW, groupGap, withinGap, fig_pos, png_dpi, ...
    pngFile, pdfFile, apply3sd)

    T = T(strcmp(T.Control, sessionLabel), :);

    conds = {'HP','MP','UP'};
    xposBase = [1, 1+groupGap, 1+2*groupGap];

    figure('Color','w','Position',fig_pos); hold on;

    for c = 1:3
        xH = xposBase(c) - withinGap;
        xC = xposBase(c) + withinGap;

        yH = T.Value(strcmp(T.Group,'Healthy') & strcmp(T.Predictability,conds{c}));
        yC = T.Value(strcmp(T.Group,'Chronic') & strcmp(T.Predictability,conds{c}));

        if apply3sd
            yH = remove_3sd(yH);
            yC = remove_3sd(yC);
        end

        draw_box_scatter(xH, yH, colHealthy, dotEdge, dotAlpha, boxAlpha, boxWidth, jitterW);
        draw_box_scatter(xC, yC, colChronic, dotEdge, dotAlpha, boxAlpha, boxWidth, jitterW);
    end

    set(gca,'XTick',xposBase,'XTickLabel',conds,'FontSize',fs_tick,'LineWidth',lw_axes,'Box','off');
    ax = gca;
    ax.TickDir = 'out';
    ax.XColor = [0 0 0];
    ax.YColor = [0 0 0];
    ax.FontName = 'Arial';

    xlabel('Predictability', 'FontSize', fs_label);
    ylabel(ylab, 'FontSize', fs_label);
    title(sprintf('%s', titlePrefix), 'FontSize', fs_title, 'FontWeight','bold');

    legend({'Healthy','Chronic'}, 'Location','northeast', 'Box','off', 'FontSize', fs_legend);

    xlim([xposBase(1)-0.55, xposBase(end)+0.55]);

    % 5 y-ticks
    yl = ylim;
    yt = linspace(yl(1), yl(2), 5);
    set(gca, 'YTick', yt);

    exportgraphics(gcf, pngFile, 'Resolution', png_dpi);
    exportgraphics(gcf, pdfFile, 'ContentType','vector');
    close(gcf);
end