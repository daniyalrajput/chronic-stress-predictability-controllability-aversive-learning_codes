function draw_custom_box(x, y, faceCol, boxWidth, boxAlpha, jitterW, ms_dot, alpha_dot)
    y = y(:);
    y = y(~isnan(y));
    if isempty(y), return; end

    q1 = prctile(y,25);
    q2 = median(y);
    q3 = prctile(y,75);
    iqrval = q3 - q1;

    lowWhisk  = max(min(y), q1 - 1.5*iqrval);
    highWhisk = min(max(y), q3 + 1.5*iqrval);

    patch([x-boxWidth/2 x+boxWidth/2 x+boxWidth/2 x-boxWidth/2], ...
          [q1 q1 q3 q3], faceCol, 'FaceAlpha', boxAlpha, 'EdgeColor', 'k', 'LineWidth', 1.2);

    plot([x-boxWidth/2 x+boxWidth/2], [q2 q2], 'k-', 'LineWidth', 1.4);
    plot([x x], [q3 highWhisk], 'k-', 'LineWidth', 1.1);
    plot([x x], [q1 lowWhisk],  'k-', 'LineWidth', 1.1);
    plot([x-boxWidth*0.22 x+boxWidth*0.22], [highWhisk highWhisk], 'k-', 'LineWidth', 1.1);
    plot([x-boxWidth*0.22 x+boxWidth*0.22], [lowWhisk lowWhisk],   'k-', 'LineWidth', 1.1);

    rng(1);
    jitter = (rand(size(y)) - 0.5) * 2 * jitterW;
    scatter(x + jitter, y, ms_dot, 'o', 'MarkerFaceColor', faceCol, 'MarkerEdgeColor', 'k', ...
        'MarkerFaceAlpha', alpha_dot, 'MarkerEdgeAlpha', alpha_dot);
end