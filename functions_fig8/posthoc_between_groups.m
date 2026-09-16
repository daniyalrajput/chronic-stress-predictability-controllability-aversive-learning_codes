function T = posthoc_between_groups(LongT)
    conds = {'HP','MP','UP'};
    sess  = {'S1','S2'};

    rows = cell(0,9);

    for s = 1:numel(sess)
        for c = 1:numel(conds)
            x = LongT.Value(strcmp(LongT.Group,'Healthy') & strcmp(LongT.Control,sess{s}) & strcmp(LongT.Predictability,conds{c}));
            y = LongT.Value(strcmp(LongT.Group,'Chronic') & strcmp(LongT.Control,sess{s}) & strcmp(LongT.Predictability,conds{c}));

            x = x(~isnan(x));
            y = y(~isnan(y));

            if numel(x) >= 2 && numel(y) >= 2
                [~,p,ci,st] = ttest2(x,y,'Vartype','unequal');
                tval = st.tstat;
                df   = st.df;
                md   = mean(x,'omitnan') - mean(y,'omitnan');
                cil  = ci(1);
                cih  = ci(2);
            else
                p = NaN; tval = NaN; df = NaN; md = NaN; cil = NaN; cih = NaN;
            end

            rows(end+1,:) = {sess{s}, conds{c}, numel(x), numel(y), md, df, tval, p, p}; %#ok<AGROW>
        end
    end

    T = cell2table(rows, 'VariableNames', ...
        {'Control','Predictability','N_Healthy','N_Chronic','MeanDiff_HminusC','df','t','p_raw','p_bonf'});
    T.p_bonf = min(T.p_raw * height(T), 1);
end