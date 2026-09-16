function [use_ids, q_idx, b_idx, match_mode] = match_questionnaire_to_behavior(q_ids, q_score, beh_ids)

    if isempty(q_ids) || all(cellfun(@isempty, q_ids))
        n = min(numel(q_score), numel(beh_ids));
        use_ids = beh_ids(1:n);
        q_idx = (1:n).';
        b_idx = (1:n).';
        match_mode = 'row_order_fallback_no_ids';
        warning('Questionnaire IDs unavailable. Falling back to row-order matching.');
        return;
    end

    [use_ids, q_idx, b_idx] = intersect(q_ids, beh_ids, 'stable');

    if isempty(use_ids)
        n = min(numel(q_score), numel(beh_ids));
        use_ids = beh_ids(1:n);
        q_idx = (1:n).';
        b_idx = (1:n).';
        match_mode = 'row_order_fallback_id_mismatch';
        warning('Questionnaire IDs did not match behavior IDs. Falling back to row-order matching.');
    else
        match_mode = 'id_match';
    end
end