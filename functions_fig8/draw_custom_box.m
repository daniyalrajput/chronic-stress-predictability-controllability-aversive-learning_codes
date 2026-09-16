function draw_custom_box(x, y, col, boxWidth, box_alpha, jitterW, ms_dot, alpha_dot)
    y = y(:);
    y = y(~isnan(y));
    if isempty(y), return; end

    q1 = prctile(y,25);
    q2 = median(y);
    q3 = prctile(y,75);
    iqrV = q3-q1;
    lowW = max(min(y), q1-1.5*iqrV);
    hiW  = min(max(y), q3+1.5*iqrV);

    patch([x-boxWidth x+boxWidth x+boxWidth x-boxWidth], [q1 q1 q3 q3], ...
        col, 'FaceAlpha', box_alpha, 'EdgeColor', col, 'LineWidth', 1.4);
    plot([x-boxWidth x+boxWidth], [q2 q2], 'Color', col, 'LineWidth', 2);
    plot([x x], [q3 hiW], 'Color', col, 'LineWidth', 1.2);
    plot([x x], [q1 lowW], 'Color', col, 'LineWidth', 1.2);

    rng(1);
    scatter(x + (rand(size(y))-0.5)*2*jitterW, y, ms_dot*0.55, ...
        'MarkerFaceColor', col, 'MarkerEdgeColor', 'k', ...
        'MarkerFaceAlpha', alpha_dot, 'MarkerEdgeAlpha', alpha_dot);
end