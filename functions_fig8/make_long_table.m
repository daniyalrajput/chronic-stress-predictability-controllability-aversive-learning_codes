function T = make_long_table(H, C, metricName)
    conds = {'HP','MP','UP'};
    rows = {};

    groups = {H,C};
    for g = 1:2
        G = groups{g};

        for s = 1:G.N
            subj = sprintf('%s_%s', G.Group, char(G.ID(s)));

            for c = 1:3
                if strcmpi(metricName,'Accuracy')
                    v1 = G.Accuracy.S1(s,c);
                    v2 = G.Accuracy.S2(s,c);
                else
                    v1 = G.LearningRate.S1(s,c);
                    v2 = G.LearningRate.S2(s,c);
                end

                rows(end+1,:) = {subj, G.Group, 'S1', conds{c}, v1, G.Anxiety(s)}; %#ok<AGROW>
                rows(end+1,:) = {subj, G.Group, 'S2', conds{c}, v2, G.Anxiety(s)}; %#ok<AGROW>
            end
        end
    end

    T = cell2table(rows, 'VariableNames', ...
        {'Subject','Group','Control','Predictability','Value','Anxiety'});
    T.Value = cell2mat(T.Value);
    T.Anxiety = cell2mat(T.Anxiety);
    T = T(~isnan(T.Value), :);
end