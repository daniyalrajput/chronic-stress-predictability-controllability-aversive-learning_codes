function T = posthoc_predictability_pairs(LongT)
    pairs = {'HP','MP'; 'HP','UP'; 'MP','UP'};
    groups = {'Healthy','Chronic'};
    sess   = {'S1','S2'};
    rows = cell(0,10);

    for g = 1:numel(groups)
        for s = 1:numel(sess)
            Sub = LongT(strcmp(LongT.Group,groups{g}) & strcmp(LongT.Control,sess{s}), :);

            for p = 1:size(pairs,1)
                A = pairs{p,1};
                B = pairs{p,2};

                Ta = Sub(strcmp(Sub.Predictability,A), {'Subject','Value'});
                Tb = Sub(strcmp(Sub.Predictability,B), {'Subject','Value'});
                M = innerjoin(Ta, Tb, 'Keys','Subject');

                x = M.Value_Ta;
                y = M.Value_Tb;

                if numel(x) >= 2
                    [~,pv,ci,st] = ttest(x,y);
                    tval = st.tstat;
                    df   = st.df;
                    md   = mean(x-y,'omitnan');
                    cil  = ci(1);
                    cih  = ci(2);
                else
                    pv = NaN; tval = NaN; df = NaN; md = NaN; cil = NaN; cih = NaN;
                end

                rows(end+1,:) = {groups{g}, sess{s}, A, B, numel(x), md, df, tval, pv, pv}; %#ok<AGROW>
            end
        end
    end

    T = cell2table(rows, 'VariableNames', ...
        {'Group','Control','CondA','CondB','N_Paired','MeanDiff_AminusB','df','t','p_raw','p_bonf'});
    T.p_bonf = min(T.p_raw * height(T), 1);
end