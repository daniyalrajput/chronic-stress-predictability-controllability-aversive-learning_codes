function v = extract_questionnaire_score(T, prefCol)
    v = [];
    if nargin >= 2 && ~isempty(prefCol) && prefCol <= width(T)
        cand = to_numeric_column(T{:,prefCol});
        if sum(~isnan(cand)) >= 3
            v = cand;
            return;
        end
    end

    bestN = -inf;
    bestV = [];
    for c = 1:width(T)
        cand = to_numeric_column(T{:,c});
        nGood = sum(~isnan(cand));
        if nGood > bestN
            bestN = nGood;
            bestV = cand;
        end
    end

    if isempty(bestV) || sum(~isnan(bestV)) < 1
        error('Could not detect questionnaire score column.');
    end
    v = bestV;
end