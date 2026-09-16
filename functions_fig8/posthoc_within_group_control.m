function T = posthoc_within_group_control(LongT)
    conds  = {'HP','MP','UP'};
    groups = {'Healthy','Chronic'};
    rows = cell(0,9);

    for g = 1:numel(groups)
        for c = 1:numel(conds)
            Ta = LongT(strcmp(LongT.Group,groups{g}) & strcmp(LongT.Predictability,conds{c}), {'Subject','Control','Value'});
            S1 = Ta(strcmp(Ta.Control,'S1'), {'Subject','Value'});
            S2 = Ta(strcmp(Ta.Control,'S2'), {'Subject','Value'});

            M = innerjoin(S1, S2, 'Keys','Subject');
            x = M.Value_S1;
            y = M.Value_S2;

            if numel(x) >= 2
                [~,p,ci,st] = ttest(x,y);
                tval = st.tstat;
                df   = st.df;
                md   = mean(x-y,'omitnan');
                cil  = ci(1);
                cih  = ci(2);
            else
                p = NaN; tval = NaN; df = NaN; md = NaN; cil = NaN; cih = NaN;
            end

            rows(end+1,:) = {groups{g}, conds{c}, numel(x), md, df, tval, p, cil, cih}; %#ok<AGROW>
        end
    end

    T = cell2table(rows, 'VariableNames', ...
        {'Group','Predictability','N_Paired','MeanDiff_S1minusS2','df','t','p_raw','CI_low','CI_high'});
    T.p_bonf = min(T.p_raw * height(T), 1);
end