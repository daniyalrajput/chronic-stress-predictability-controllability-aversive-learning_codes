function [xClean, y1Clean, y2Clean, S] = prep_corr_data_and_stats(x, y1, y2, APPLY_3SD)

    x  = x(:);
    y1 = y1(:);
    y2 = y2(:);

    keep = ~isnan(x) & ~isnan(y1) & ~isnan(y2);
    x  = x(keep);
    y1 = y1(keep);
    y2 = y2(keep);

    if APPLY_3SD && ~isempty(x)
        keep1 = true(size(x));
        keep2 = true(size(x));

        if numel(y1) > 2
            m1 = mean(y1, 'omitnan');
            s1 = std(y1, 'omitnan');
            if s1 > 0
                keep1 = abs(y1 - m1) <= 3*s1;
            end
        end

        if numel(y2) > 2
            m2 = mean(y2, 'omitnan');
            s2 = std(y2, 'omitnan');
            if s2 > 0
                keep2 = abs(y2 - m2) <= 3*s2;
            end
        end

        keep = keep1 & keep2;
        x  = x(keep);
        y1 = y1(keep);
        y2 = y2(keep);
    end

    xClean  = x;
    y1Clean = y1;
    y2Clean = y2;

    S = struct();

    [S.r_s1, S.p_s1, S.ci_low_s1, S.ci_high_s1, S.r2_s1, S.n_s1] = basic_pearson_stats(xClean, y1Clean);
    [S.r_s2, S.p_s2, S.ci_low_s2, S.ci_high_s2, S.r2_s2, S.n_s2] = basic_pearson_stats(xClean, y2Clean);
end