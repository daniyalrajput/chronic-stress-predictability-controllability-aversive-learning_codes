%% ========================= LOCAL HELPER FOR P-VALUE LABELS =========================
function s = format_p(p)
% Journal-style p-value text for figure annotations.
    if isnan(p)
        s = '= NA';
    elseif p < 0.001
        s = '< 0.001';
    else
        s = sprintf('= %.3f', p);
    end
end
