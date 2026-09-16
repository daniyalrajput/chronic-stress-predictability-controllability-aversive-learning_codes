function draw_box_scatter(x, y, boxColor, dotEdge, dotAlpha, boxAlpha, boxWidth, jitterW)
    y = y(~isnan(y));
    if isempty(y), return; end

    q1 = prctile(y,25);
    q2 = median(y);
    q3 = prctile(y,75);
    iqrV = q3 - q1;
    lowW = max(min(y), q1 - 1.5*iqrV);
    hiW  = min(max(y), q3 + 1.5*iqrV);

    patch([x-boxWidth x+boxWidth x+boxWidth x-boxWidth], [q1 q1 q3 q3], ...
        boxColor, 'FaceAlpha', boxAlpha, 'EdgeColor', boxColor, 'LineWidth', 1.4);

    plot([x-boxWidth x+boxWidth],[q2 q2], 'Color', boxColor, 'LineWidth', 2.0);
    plot([x x],[q3 hiW], 'Color', boxColor, 'LineWidth', 1.3);
    plot([x x],[q1 lowW], 'Color', boxColor, 'LineWidth', 1.3);
    plot([x-boxWidth/2 x+boxWidth/2],[hiW hiW], 'Color', boxColor, 'LineWidth', 1.3);
    plot([x-boxWidth/2 x+boxWidth/2],[lowW lowW], 'Color', boxColor, 'LineWidth', 1.3);

    rng(1);
    xj = x + (rand(size(y))-0.5)*2*jitterW;
    scatter(xj, y, 36, 'MarkerFaceColor', boxColor, 'MarkerEdgeColor', dotEdge, ...
        'MarkerFaceAlpha', dotAlpha, 'MarkerEdgeAlpha', dotAlpha, 'LineWidth', 0.7);
end