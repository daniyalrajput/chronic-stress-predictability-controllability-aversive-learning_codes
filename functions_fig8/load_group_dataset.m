
function G = load_group_dataset(groupName, qfile, xls_s1, xls_s2, vkf_s1, vkf_s2, ...
    QCOL, BLOCK_COL, ACC_COL, HP_blocks, MP_blocks, UP_blocks)

    qTab = readtable(qfile, 'Sheet', 1);
    qscore = extract_questionnaire_score(qTab, QCOL);

    [~, sheets1] = xlsfinfo(xls_s1);
    [~, sheets2] = xlsfinfo(xls_s2);

    assert(~isempty(sheets1), '%s S1 workbook has no sheets.', groupName);
    assert(~isempty(sheets2), '%s S2 workbook has no sheets.', groupName);

    sheets1 = string(sheets1(:));
    sheets2 = string(sheets2(:));

    ids1 = canonicalize_sheet_id(sheets1);
    ids2 = canonicalize_sheet_id(sheets2);

    [commonIDs, ia1, ia2] = intersect(ids1, ids2, 'stable');
    assert(~isempty(commonIDs), 'No matching S1/S2 IDs found for %s.', groupName);

    S1 = load(vkf_s1);
    S2 = load(vkf_s2);

    assert(isfield(S1,'kgain_mat'), '%s S1 missing kgain_mat', groupName);
    assert(isfield(S2,'kgain_mat'), '%s S2 missing kgain_mat', groupName);

    assert(isfield(S1,'lambda_vec'), '%s S1 missing lambda_vec', groupName);
    assert(isfield(S2,'lambda_vec'), '%s S2 missing lambda_vec', groupName);

    assert(isfield(S1,'v0_vec'), '%s S1 missing v0_vec', groupName);
    assert(isfield(S2,'v0_vec'), '%s S2 missing v0_vec', groupName);

    assert(isfield(S1,'omega_vec'), '%s S1 missing omega_vec', groupName);
    assert(isfield(S2,'omega_vec'), '%s S2 missing omega_vec', groupName);

    kg1 = S1.kgain_mat;
    kg2 = S2.kgain_mat;

    lam1 = S1.lambda_vec(:);
    lam2 = S2.lambda_vec(:);
    v01  = S1.v0_vec(:);
    v02  = S2.v0_vec(:);
    om1  = S1.omega_vec(:);
    om2  = S2.omega_vec(:);

    nSheetMatch = numel(commonIDs);
    qscore = qscore(:);
    qscore = qscore(~isnan(qscore));
    nQ = numel(qscore);

    nUse = min(nSheetMatch, nQ);
    if nUse < 1
        error('%s usable N is zero.', groupName);
    end

    ia1 = ia1(1:nUse);
    ia2 = ia2(1:nUse);
    commonIDs = commonIDs(1:nUse);
    qscore = qscore(1:nUse);

    acc_s1 = nan(nUse,3);
    acc_s2 = nan(nUse,3);
    lr_s1  = nan(nUse,3);
    lr_s2  = nan(nUse,3);

    acc_mean_s1 = nan(nUse,1);
    acc_mean_s2 = nan(nUse,1);
    lr_mean_s1  = nan(nUse,1);
    lr_mean_s2  = nan(nUse,1);

    lambda_s1 = nan(nUse,1);
    lambda_s2 = nan(nUse,1);
    v0_s1     = nan(nUse,1);
    v0_s2     = nan(nUse,1);
    omega_s1  = nan(nUse,1);
    omega_s2  = nan(nUse,1);

    for i = 1:nUse
        T1 = readtable(xls_s1, 'Sheet', char(sheets1(ia1(i))));
        T2 = readtable(xls_s2, 'Sheet', char(sheets2(ia2(i))));

        blk1 = strtrim(string(T1{:,BLOCK_COL}));
        blk2 = strtrim(string(T2{:,BLOCK_COL}));

        acc1 = to_numeric_column(T1{:,ACC_COL});
        acc2 = to_numeric_column(T2{:,ACC_COL});

        lr1 = kg1(ia1(i), :).';
        lr2 = kg2(ia2(i), :).';

        n1 = min([height(T1), numel(acc1), numel(lr1)]);
        n2 = min([height(T2), numel(acc2), numel(lr2)]);

        blk1 = blk1(1:n1); acc1 = acc1(1:n1); lr1 = lr1(1:n1);
        blk2 = blk2(1:n2); acc2 = acc2(1:n2); lr2 = lr2(1:n2);

        acc_mean_s1(i) = 100*mean(acc1,'omitnan');
        acc_mean_s2(i) = 100*mean(acc2,'omitnan');
        lr_mean_s1(i)  = mean(lr1,'omitnan');
        lr_mean_s2(i)  = mean(lr2,'omitnan');

        lambda_s1(i) = lam1(ia1(i));
        lambda_s2(i) = lam2(ia2(i));
        v0_s1(i)     = v01(ia1(i));
        v0_s2(i)     = v02(ia2(i));
        omega_s1(i)  = om1(ia1(i));
        omega_s2(i)  = om2(ia2(i));

        m1 = {ismember(blk1,HP_blocks), ismember(blk1,MP_blocks), ismember(blk1,UP_blocks)};
        m2 = {ismember(blk2,HP_blocks), ismember(blk2,MP_blocks), ismember(blk2,UP_blocks)};

        for c = 1:3
            idxa1 = m1{c} & ~isnan(acc1);
            idxa2 = m2{c} & ~isnan(acc2);
            idxl1 = m1{c} & ~isnan(lr1);
            idxl2 = m2{c} & ~isnan(lr2);

            if any(idxa1), acc_s1(i,c) = 100*mean(acc1(idxa1),'omitnan'); end
            if any(idxa2), acc_s2(i,c) = 100*mean(acc2(idxa2),'omitnan'); end
            if any(idxl1), lr_s1(i,c)  = mean(lr1(idxl1),'omitnan');       end
            if any(idxl2), lr_s2(i,c)  = mean(lr2(idxl2),'omitnan');       end
        end
    end

    G = struct();
    G.Group = groupName;
    G.N = nUse;
    G.ID = commonIDs;
    G.Anxiety = qscore;

    G.Accuracy.S1 = acc_s1;
    G.Accuracy.S2 = acc_s2;
    G.AccuracyMean.S1 = acc_mean_s1;
    G.AccuracyMean.S2 = acc_mean_s2;

    G.LearningRate.S1 = lr_s1;
    G.LearningRate.S2 = lr_s2;
    G.LearningRateMean.S1 = lr_mean_s1;
    G.LearningRateMean.S2 = lr_mean_s2;

    G.Lambda.S1 = lambda_s1;
    G.Lambda.S2 = lambda_s2;
    G.V0.S1     = v0_s1;
    G.V0.S2     = v0_s2;
    G.Omega.S1  = omega_s1;
    G.Omega.S2  = omega_s2;

    G.SubjectTable = table( ...
        string(commonIDs(:)), qscore(:), ...
        acc_s1(:,1), acc_s1(:,2), acc_s1(:,3), ...
        acc_s2(:,1), acc_s2(:,2), acc_s2(:,3), ...
        lr_s1(:,1),  lr_s1(:,2),  lr_s1(:,3), ...
        lr_s2(:,1),  lr_s2(:,2),  lr_s2(:,3), ...
        lambda_s1(:), lambda_s2(:), ...
        v0_s1(:), v0_s2(:), ...
        omega_s1(:), omega_s2(:), ...
        'VariableNames', { ...
        'ID','Anxiety', ...
        'Acc_HP_S1','Acc_MP_S1','Acc_UP_S1', ...
        'Acc_HP_S2','Acc_MP_S2','Acc_UP_S2', ...
        'LR_HP_S1','LR_MP_S1','LR_UP_S1', ...
        'LR_HP_S2','LR_MP_S2','LR_UP_S2', ...
        'Lambda_S1','Lambda_S2', ...
        'V0_S1','V0_S2', ...
        'Omega_S1','Omega_S2'});
end
