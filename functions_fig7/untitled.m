clear; clc; close all;

%% ========================= OUTPUT PATH =========================
out_dir = 'F:\Stress Study\Stress_studies_data\Chronic_Stress_Study_Data\figure analysis_study2\data_figure9\results_IUS_F2_healthy_CS_balanced_01_04_v';
if ~exist(out_dir,'dir'), mkdir(out_dir); end

figdir   = fullfile(out_dir, 'figures');
statsdir = fullfile(out_dir, 'stats');
datadir  = fullfile(out_dir, 'data');

if ~exist(figdir,'dir'), mkdir(figdir); end
if ~exist(statsdir,'dir'), mkdir(statsdir); end
if ~exist(datadir,'dir'), mkdir(datadir); end

stats_xlsx = fullfile(statsdir,'All_Stats.xlsx');
if exist(stats_xlsx,'file') == 2
    delete(stats_xlsx);
end

%% ========================= INPUTS =========================
base_dir = 'F:\Stress Study\Stress_studies_data\Chronic_Stress_Study_Data\figure analysis_study2\data_figure9';

H_quest_file = fullfile(base_dir, 'questionnaires_healthy_IUS_factor2.xlsx');
H_xls_s1     = fullfile(base_dir, 'Healthy_correct_incorrect_S1.xlsx');
H_xls_s2     = fullfile(base_dir, 'Healthy_correct_incorrect_S2.xlsx');
H_vkf_s1     = fullfile(base_dir, 'vkf_all_results_s1_healthy.mat');
H_vkf_s2     = fullfile(base_dir, 'vkf_all_results_s2_healthy.mat');

C_quest_file = fullfile(base_dir, 'questionnaires_CS_IUS_factor2.xlsx');
C_xls_s1     = fullfile(base_dir, 'Chronic_correct_incorrect_scr_S1.xlsx');
C_xls_s2     = fullfile(base_dir, 'Chronic_correct_incorrect_scr_S2.xlsx');
C_vkf_s1     = fullfile(base_dir, 'CS_vkf_all_results_s1.mat');
C_vkf_s2     = fullfile(base_dir, 'CS_vkf_all_results_s2.mat');

%% ========================= TASK SETTINGS =========================
BLOCK_COL = 2;
ACC_COL   = 13;

HP_blocks = ["Block1","Block5","Block8","Block10"];
MP_blocks = ["Block3","Block4","Block7","Block9"];
UP_blocks = ["Block2","Block6"];
condNames = ["HP","MP","UP"];

%% ========================= OUTLIER SETTINGS =========================
APPLY_3SD_ALL = true;
APPLY_3SD_QUESTIONNAIRE = true;
APPLY_3SD_PARAMETERS    = true;
APPLY_3SD_ACCURACY      = true;
APPLY_3SD_LAMBDA        = true;

%% =============================== STYLE ===============================
colH_S1 = [0.00 0.25 0.55];
colH_S2 = [0.70 0.82 0.97];
colC_S1 = [0.85 0.33 0.00];
colC_S2 = [1.00 0.80 0.65];

colQ_H  = colH_S1;
colQ_C  = colC_S1;

fs_xtick  = 18;
fs_ytick  = 18;
fs_label  = 20;
fs_legend = 16;
fs_title  = 18;

lw_axes = 1.6;
lw_fit  = 2.2;

ms_dot    = 55;
alpha_dot = 0.85;

png_dpi = 600;

fig_pos_box  = [120 90 1020 620];
fig_pos_corr = [120 90 760 620];
fig_pos_q    = [180 110 700 620];

box_alpha = 0.35;

%% ========================= SPACING VARIABLES FOR BOXPLOTS =========================
predictability_gap = 1.3;
healthy_chronic_gap = 0.47;
ctrl_unctrl_gap     = 0.20;

%% ========================= LEGEND SETTINGS =========================
legend_loc = 'northeast';
legend_x_shift = 0.04;
legend_y_shift = 0.03;

%% ========================= PLOT POSITION / SIZE CONTROLS =========================
x_left_shift            = 0.62;
main_box_width          = 0.075;
main_jitterW            = 0.018;
main_left_pad           = 0.55;
main_right_pad          = 1.55;

q_center_left_shift     = 0.28;
q_group_gap             = 0.70;
q_box_width             = 0.10;
q_jitterW               = 0.025;
q_left_pad              = 0.28;
q_right_pad             = 0.58;

%% ========================= BALANCING SETTINGS =========================
BALANCE_GROUPS = true;

%% ========================= ASSERT FILES =========================
reqFiles = {H_quest_file,H_xls_s1,H_xls_s2,H_vkf_s1,H_vkf_s2,...
            C_quest_file,C_xls_s1,C_xls_s2,C_vkf_s1,C_vkf_s2};

for i = 1:numel(reqFiles)
    assert(exist(reqFiles{i},'file')==2, 'Missing file:\n%s', reqFiles{i});
end

%% ========================= LOAD QUESTIONNAIRE SCORES =========================
Hq_raw = readcell(H_quest_file, 'Sheet', 1);
Cq_raw = readcell(C_quest_file, 'Sheet', 1);

H_q_score = to_numeric_column(Hq_raw(:,1));
C_q_score = to_numeric_column(Cq_raw(:,1));

H_q_score = H_q_score(:);
C_q_score = C_q_score(:);

H_q_score = H_q_score(~isnan(H_q_score));
C_q_score = C_q_score(~isnan(C_q_score));

%% ========================= LOAD VKF =========================
HS1 = load(H_vkf_s1);
HS2 = load(H_vkf_s2);
CS1 = load(C_vkf_s1);
CS2 = load(C_vkf_s2);

assert(isfield(HS1,'kgain_mat') && isfield(HS1,'lambda_vec'), 'Healthy S1 VKF missing fields');
assert(isfield(HS2,'kgain_mat') && isfield(HS2,'lambda_vec'), 'Healthy S2 VKF missing fields');
assert(isfield(CS1,'kgain_mat') && isfield(CS1,'lambda_vec'), 'Chronic S1 VKF missing fields');
assert(isfield(CS2,'kgain_mat') && isfield(CS2,'lambda_vec'), 'Chronic S2 VKF missing fields');

%% ========================= GET SHEETS =========================
[~, H_sheets1] = xlsfinfo(H_xls_s1);
[~, H_sheets2] = xlsfinfo(H_xls_s2);
[~, C_sheets1] = xlsfinfo(C_xls_s1);
[~, C_sheets2] = xlsfinfo(C_xls_s2);

H_sheets1 = string(H_sheets1(:));
H_sheets2 = string(H_sheets2(:));
C_sheets1 = string(C_sheets1(:));
C_sheets2 = string(C_sheets2(:));

assert(~isempty(H_sheets1), 'No Healthy S1 sheets found');
assert(~isempty(H_sheets2), 'No Healthy S2 sheets found');
assert(~isempty(C_sheets1), 'No Chronic S1 sheets found');
assert(~isempty(C_sheets2), 'No Chronic S2 sheets found');

%% ========================= MATCH IDS =========================
H_id1 = nan(numel(H_sheets1),1);
H_id2 = nan(numel(H_sheets2),1);

for i = 1:numel(H_sheets1)
    s = upper(strtrim(char(H_sheets1(i))));
    tok = regexp(s, '\d+', 'match', 'once');
    if ~isempty(tok), H_id1(i) = str2double(tok); end
end

for i = 1:numel(H_sheets2)
    s = upper(strtrim(char(H_sheets2(i))));
    tok = regexp(s, '\d+', 'match', 'once');
    if ~isempty(tok), H_id2(i) = str2double(tok); end
end

validH1 = ~isnan(H_id1);
validH2 = ~isnan(H_id2);

H_sheets1 = H_sheets1(validH1);
H_sheets2 = H_sheets2(validH2);
H_id1     = H_id1(validH1);
H_id2     = H_id2(validH2);

[H_commonIDs_num, H_ia1, H_ia2] = intersect(H_id1, H_id2, 'stable');
assert(~isempty(H_commonIDs_num), 'No matching Healthy S1/S2 IDs found. Check Healthy sheet names.');
H_commonIDs = string(compose('H%02d', H_commonIDs_num));

C_id1 = nan(numel(C_sheets1),1);
C_id2 = nan(numel(C_sheets2),1);

for i = 1:numel(C_sheets1)
    s = upper(strtrim(char(C_sheets1(i))));
    tok = regexp(s, '\d+', 'match', 'once');
    if ~isempty(tok), C_id1(i) = str2double(tok); end
end

for i = 1:numel(C_sheets2)
    s = upper(strtrim(char(C_sheets2(i))));
    tok = regexp(s, '\d+', 'match', 'once');
    if ~isempty(tok), C_id2(i) = str2double(tok); end
end

validC1 = ~isnan(C_id1);
validC2 = ~isnan(C_id2);

C_sheets1 = C_sheets1(validC1);
C_sheets2 = C_sheets2(validC2);
C_id1     = C_id1(validC1);
C_id2     = C_id2(validC2);

[C_commonIDs_num, C_ia1, C_ia2] = intersect(C_id1, C_id2, 'stable');
assert(~isempty(C_commonIDs_num), 'No matching Chronic S1/S2 IDs found. Check Chronic sheet names.');
C_commonIDs = string(compose('CS%02d', C_commonIDs_num));

nH = min(numel(H_commonIDs), numel(H_q_score));
nC = min(numel(C_commonIDs), numel(C_q_score));

assert(nH > 0, 'Healthy usable N is zero');
assert(nC > 0, 'Chronic usable N is zero');

H_commonIDs = H_commonIDs(1:nH);
H_ia1 = H_ia1(1:nH);
H_ia2 = H_ia2(1:nH);
H_q_score = H_q_score(1:nH);

C_commonIDs = C_commonIDs(1:nC);
C_ia1 = C_ia1(1:nC);
C_ia2 = C_ia2(1:nC);
C_q_score = C_q_score(1:nC);

fprintf('\nHealthy usable matched N = %d\n', nH);
fprintf('Chronic usable matched N = %d\n\n', nC);

%% ========================= PREALLOCATE =========================
H_acc_s1 = nan(nH,3); H_acc_s2 = nan(nH,3);
H_lr_s1  = nan(nH,3); H_lr_s2  = nan(nH,3);
H_lambda_s1 = nan(nH,1); H_lambda_s2 = nan(nH,1);

C_acc_s1 = nan(nC,3); C_acc_s2 = nan(nC,3);
C_lr_s1  = nan(nC,3); C_lr_s2  = nan(nC,3);
C_lambda_s1 = nan(nC,1); C_lambda_s2 = nan(nC,1);

%% ========================= HEALTHY LOOP =========================
for i = 1:nH
    sh1 = H_sheets1(H_ia1(i));
    sh2 = H_sheets2(H_ia2(i));

    T1 = readtable(H_xls_s1, 'Sheet', char(sh1));
    T2 = readtable(H_xls_s2, 'Sheet', char(sh2));

    blk1 = strtrim(string(T1{:,BLOCK_COL}));
    blk2 = strtrim(string(T2{:,BLOCK_COL}));

    acc1 = to_numeric_column(T1{:,ACC_COL});
    acc2 = to_numeric_column(T2{:,ACC_COL});

    lr1 = HS1.kgain_mat(H_ia1(i), :).';
    lr2 = HS2.kgain_mat(H_ia2(i), :).';

    n1 = min([height(T1), numel(acc1), numel(lr1)]);
    n2 = min([height(T2), numel(acc2), numel(lr2)]);

    blk1 = blk1(1:n1); acc1 = acc1(1:n1); lr1 = lr1(1:n1);
    blk2 = blk2(1:n2); acc2 = acc2(1:n2); lr2 = lr2(1:n2);

    H_lambda_s1(i) = HS1.lambda_vec(H_ia1(i));
    H_lambda_s2(i) = HS2.lambda_vec(H_ia2(i));

    masks1 = {ismember(blk1,HP_blocks), ismember(blk1,MP_blocks), ismember(blk1,UP_blocks)};
    masks2 = {ismember(blk2,HP_blocks), ismember(blk2,MP_blocks), ismember(blk2,UP_blocks)};

    for c = 1:3
        idx1a = masks1{c} & ~isnan(acc1);
        idx2a = masks2{c} & ~isnan(acc2);
        idx1l = masks1{c} & ~isnan(lr1);
        idx2l = masks2{c} & ~isnan(lr2);

        if any(idx1a), H_acc_s1(i,c) = 100 * mean(acc1(idx1a), 'omitnan'); end
        if any(idx2a), H_acc_s2(i,c) = 100 * mean(acc2(idx2a), 'omitnan'); end
        if any(idx1l), H_lr_s1(i,c)  = mean(lr1(idx1l), 'omitnan'); end
        if any(idx2l), H_lr_s2(i,c)  = mean(lr2(idx2l), 'omitnan'); end
    end
end

%% ========================= CHRONIC LOOP =========================
for i = 1:nC
    sh1 = C_sheets1(C_ia1(i));
    sh2 = C_sheets2(C_ia2(i));

    T1 = readtable(C_xls_s1, 'Sheet', char(sh1));
    T2 = readtable(C_xls_s2, 'Sheet', char(sh2));

    blk1 = strtrim(string(T1{:,BLOCK_COL}));
    blk2 = strtrim(string(T2{:,BLOCK_COL}));

    acc1 = to_numeric_column(T1{:,ACC_COL});
    acc2 = to_numeric_column(T2{:,ACC_COL});

    lr1 = CS1.kgain_mat(C_ia1(i), :).';
    lr2 = CS2.kgain_mat(C_ia2(i), :).';

    n1 = min([height(T1), numel(acc1), numel(lr1)]);
    n2 = min([height(T2), numel(acc2), numel(lr2)]);

    blk1 = blk1(1:n1); acc1 = acc1(1:n1); lr1 = lr1(1:n1);
    blk2 = blk2(1:n2); acc2 = acc2(1:n2); lr2 = lr2(1:n2);

    C_lambda_s1(i) = CS1.lambda_vec(C_ia1(i));
    C_lambda_s2(i) = CS2.lambda_vec(C_ia2(i));

    masks1 = {ismember(blk1,HP_blocks), ismember(blk1,MP_blocks), ismember(blk1,UP_blocks)};
    masks2 = {ismember(blk2,HP_blocks), ismember(blk2,MP_blocks), ismember(blk2,UP_blocks)};

    for c = 1:3
        idx1a = masks1{c} & ~isnan(acc1);
        idx2a = masks2{c} & ~isnan(acc2);
        idx1l = masks1{c} & ~isnan(lr1);
        idx2l = masks2{c} & ~isnan(lr2);

        if any(idx1a), C_acc_s1(i,c) = 100 * mean(acc1(idx1a), 'omitnan'); end
        if any(idx2a), C_acc_s2(i,c) = 100 * mean(acc2(idx2a), 'omitnan'); end
        if any(idx1l), C_lr_s1(i,c)  = mean(lr1(idx1l), 'omitnan'); end
        if any(idx2l), C_lr_s2(i,c)  = mean(lr2(idx2l), 'omitnan'); end
    end
end

%% ========================= APPLY 3SD BEFORE STATS AND PLOTS =========================
if APPLY_3SD_ALL
    if APPLY_3SD_QUESTIONNAIRE
        H_q_score = apply_3sd_vec(H_q_score);
        C_q_score = apply_3sd_vec(C_q_score);
    end

    if APPLY_3SD_PARAMETERS
        for c = 1:3
            H_lr_s1(:,c) = apply_3sd_vec(H_lr_s1(:,c));
            H_lr_s2(:,c) = apply_3sd_vec(H_lr_s2(:,c));
            C_lr_s1(:,c) = apply_3sd_vec(C_lr_s1(:,c));
            C_lr_s2(:,c) = apply_3sd_vec(C_lr_s2(:,c));
        end
    end

    if APPLY_3SD_ACCURACY
        for c = 1:3
            H_acc_s1(:,c) = apply_3sd_vec(H_acc_s1(:,c));
            H_acc_s2(:,c) = apply_3sd_vec(H_acc_s2(:,c));
            C_acc_s1(:,c) = apply_3sd_vec(C_acc_s1(:,c));
            C_acc_s2(:,c) = apply_3sd_vec(C_acc_s2(:,c));
        end
    end

    if APPLY_3SD_LAMBDA
        H_lambda_s1 = apply_3sd_vec(H_lambda_s1);
        H_lambda_s2 = apply_3sd_vec(H_lambda_s2);
        C_lambda_s1 = apply_3sd_vec(C_lambda_s1);
        C_lambda_s2 = apply_3sd_vec(C_lambda_s2);
    end
end

%% ========================= BALANCE GROUPS TO SAME N =========================
validH = ~isnan(H_q_score);
validC = ~isnan(C_q_score);

validH = validH & ( ...
    any(~isnan(H_lr_s1),2) | any(~isnan(H_lr_s2),2) | ...
    any(~isnan(H_acc_s1),2) | any(~isnan(H_acc_s2),2) | ...
    ~isnan(H_lambda_s1) | ~isnan(H_lambda_s2) );

validC = validC & ( ...
    any(~isnan(C_lr_s1),2) | any(~isnan(C_lr_s2),2) | ...
    any(~isnan(C_acc_s1),2) | any(~isnan(C_acc_s2),2) | ...
    ~isnan(C_lambda_s1) | ~isnan(C_lambda_s2) );

H_commonIDs = H_commonIDs(validH);
H_q_score   = H_q_score(validH);
H_lr_s1     = H_lr_s1(validH,:);
H_lr_s2     = H_lr_s2(validH,:);
H_acc_s1    = H_acc_s1(validH,:);
H_acc_s2    = H_acc_s2(validH,:);
H_lambda_s1 = H_lambda_s1(validH);
H_lambda_s2 = H_lambda_s2(validH);

C_commonIDs = C_commonIDs(validC);
C_q_score   = C_q_score(validC);
C_lr_s1     = C_lr_s1(validC,:);
C_lr_s2     = C_lr_s2(validC,:);
C_acc_s1    = C_acc_s1(validC,:);
C_acc_s2    = C_acc_s2(validC,:);
C_lambda_s1 = C_lambda_s1(validC);
C_lambda_s2 = C_lambda_s2(validC);

nH_valid = numel(H_q_score);
nC_valid = numel(C_q_score);

fprintf('Healthy valid after cleaning = %d\n', nH_valid);
fprintf('Chronic valid after cleaning = %d\n', nC_valid);

if BALANCE_GROUPS
    targetN = min(nH_valid, nC_valid);
    assert(targetN > 0, 'Balanced target N is zero.');

    if nH_valid > targetN
        [~, ordH] = sort(abs(H_q_score - mean(H_q_score,'omitnan')), 'ascend');
        keepH = ordH(1:targetN);
    else
        keepH = (1:nH_valid)';
    end

    if nC_valid > targetN
        [~, ordC] = sort(abs(C_q_score - mean(C_q_score,'omitnan')), 'ascend');
        keepC = ordC(1:targetN);
    else
        keepC = (1:nC_valid)';
    end

    keepH = keepH(:);
    keepC = keepC(:);

    H_commonIDs = H_commonIDs(keepH);
    H_q_score   = H_q_score(keepH);
    H_lr_s1     = H_lr_s1(keepH,:);
    H_lr_s2     = H_lr_s2(keepH,:);
    H_acc_s1    = H_acc_s1(keepH,:);
    H_acc_s2    = H_acc_s2(keepH,:);
    H_lambda_s1 = H_lambda_s1(keepH);
    H_lambda_s2 = H_lambda_s2(keepH);

    C_commonIDs = C_commonIDs(keepC);
    C_q_score   = C_q_score(keepC);
    C_lr_s1     = C_lr_s1(keepC,:);
    C_lr_s2     = C_lr_s2(keepC,:);
    C_acc_s1    = C_acc_s1(keepC,:);
    C_acc_s2    = C_acc_s2(keepC,:);
    C_lambda_s1 = C_lambda_s1(keepC);
    C_lambda_s2 = C_lambda_s2(keepC);

    fprintf('Balanced N used in both groups = %d\n\n', targetN);
end

nH = numel(H_q_score);
nC = numel(C_q_score);

%% ========================= SAME AXIS LIMITS =========================
allQ   = [H_q_score(:); C_q_score(:)];
allLR  = [H_lr_s1(:); H_lr_s2(:); C_lr_s1(:); C_lr_s2(:)];
allACC = [H_acc_s1(:); H_acc_s2(:); C_acc_s1(:); C_acc_s2(:)];
allLAM = [H_lambda_s1(:); H_lambda_s2(:); C_lambda_s1(:); C_lambda_s2(:)];

xlim_corr   = round_limits(padded_limits(allQ), 0);
ylim_corrLR = round_limits(padded_limits(allLR), 2);
ylim_corrAC = round_limits(padded_limits(allACC), 0);
ylim_corrLA = round_limits(padded_limits(allLAM), 2);
ylim_q      = round_limits(padded_limits(allQ), 0);

%% ========================= SUBJECT-LEVEL TABLES =========================
Healthy_SubjectData = table(string(H_commonIDs(:)), H_q_score(:), ...
    H_lr_s1(:,1), H_lr_s1(:,2), H_lr_s1(:,3), ...
    H_lr_s2(:,1), H_lr_s2(:,2), H_lr_s2(:,3), ...
    H_acc_s1(:,1), H_acc_s1(:,2), H_acc_s1(:,3), ...
    H_acc_s2(:,1), H_acc_s2(:,2), H_acc_s2(:,3), ...
    H_lambda_s1(:), H_lambda_s2(:), ...
    'VariableNames', {'ID','IUS_Factor2', ...
    'LR_HP_S1','LR_MP_S1','LR_UP_S1','LR_HP_S2','LR_MP_S2','LR_UP_S2', ...
    'ACC_HP_S1','ACC_MP_S1','ACC_UP_S1','ACC_HP_S2','ACC_MP_S2','ACC_UP_S2', ...
    'Lambda_S1','Lambda_S2'});

Chronic_SubjectData = table(string(C_commonIDs(:)), C_q_score(:), ...
    C_lr_s1(:,1), C_lr_s1(:,2), C_lr_s1(:,3), ...
    C_lr_s2(:,1), C_lr_s2(:,2), C_lr_s2(:,3), ...
    C_acc_s1(:,1), C_acc_s1(:,2), C_acc_s1(:,3), ...
    C_acc_s2(:,1), C_acc_s2(:,2), C_acc_s2(:,3), ...
    C_lambda_s1(:), C_lambda_s2(:), ...
    'VariableNames', {'ID','IUS_Factor2', ...
    'LR_HP_S1','LR_MP_S1','LR_UP_S1','LR_HP_S2','LR_MP_S2','LR_UP_S2', ...
    'ACC_HP_S1','ACC_MP_S1','ACC_UP_S1','ACC_HP_S2','ACC_MP_S2','ACC_UP_S2', ...
    'Lambda_S1','Lambda_S2'});

writetable(Healthy_SubjectData, fullfile(datadir,'Healthy_SubjectData.csv'));
writetable(Chronic_SubjectData, fullfile(datadir,'Chronic_SubjectData.csv'));

%% ========================= LONG TABLES =========================
Subject = {};
Group = {};
Control = {};
Predictability = {};
Value = [];

for i = 1:nH
    sid = sprintf('Healthy_%s', char(H_commonIDs(i)));
    for c = 1:3
        Subject{end+1,1} = sid; Group{end+1,1} = 'Healthy'; Control{end+1,1} = 'S1'; Predictability{end+1,1} = char(condNames(c)); Value(end+1,1) = H_lr_s1(i,c);
        Subject{end+1,1} = sid; Group{end+1,1} = 'Healthy'; Control{end+1,1} = 'S2'; Predictability{end+1,1} = char(condNames(c)); Value(end+1,1) = H_lr_s2(i,c);
    end
end
for i = 1:nC
    sid = sprintf('Chronic_%s', char(C_commonIDs(i)));
    for c = 1:3
        Subject{end+1,1} = sid; Group{end+1,1} = 'Chronic'; Control{end+1,1} = 'S1'; Predictability{end+1,1} = char(condNames(c)); Value(end+1,1) = C_lr_s1(i,c);
        Subject{end+1,1} = sid; Group{end+1,1} = 'Chronic'; Control{end+1,1} = 'S2'; Predictability{end+1,1} = char(condNames(c)); Value(end+1,1) = C_lr_s2(i,c);
    end
end
LRLong = table(Subject, Group, Control, Predictability, Value);
LRLong = LRLong(~isnan(LRLong.Value), :);

Subject = {};
Group = {};
Control = {};
Predictability = {};
Value = [];

for i = 1:nH
    sid = sprintf('Healthy_%s', char(H_commonIDs(i)));
    for c = 1:3
        Subject{end+1,1} = sid; Group{end+1,1} = 'Healthy'; Control{end+1,1} = 'S1'; Predictability{end+1,1} = char(condNames(c)); Value(end+1,1) = H_acc_s1(i,c);
        Subject{end+1,1} = sid; Group{end+1,1} = 'Healthy'; Control{end+1,1} = 'S2'; Predictability{end+1,1} = char(condNames(c)); Value(end+1,1) = H_acc_s2(i,c);
    end
end
for i = 1:nC
    sid = sprintf('Chronic_%s', char(C_commonIDs(i)));
    for c = 1:3
        Subject{end+1,1} = sid; Group{end+1,1} = 'Chronic'; Control{end+1,1} = 'S1'; Predictability{end+1,1} = char(condNames(c)); Value(end+1,1) = C_acc_s1(i,c);
        Subject{end+1,1} = sid; Group{end+1,1} = 'Chronic'; Control{end+1,1} = 'S2'; Predictability{end+1,1} = char(condNames(c)); Value(end+1,1) = C_acc_s2(i,c);
    end
end
AccLong = table(Subject, Group, Control, Predictability, Value);
AccLong = AccLong(~isnan(AccLong.Value), :);

writetable(LRLong,  fullfile(datadir,'LR_Long.csv'));
writetable(AccLong, fullfile(datadir,'Accuracy_Long.csv'));

%% ========================= DESCRIPTIVE STATS =========================
descRows_LR = cell(0,7);
descRows_ACC = cell(0,7);

for g = 1:2
    if g == 1
        grp = 'Healthy';
        lrS1 = H_lr_s1; lrS2 = H_lr_s2;
        acS1 = H_acc_s1; acS2 = H_acc_s2;
    else
        grp = 'Chronic';
        lrS1 = C_lr_s1; lrS2 = C_lr_s2;
        acS1 = C_acc_s1; acS2 = C_acc_s2;
    end

    for s = 1:2
        if s == 1
            sess = 'S1';
            lrMat = lrS1;
            acMat = acS1;
        else
            sess = 'S2';
            lrMat = lrS2;
            acMat = acS2;
        end

        for c = 1:3
            x = lrMat(:,c); x = x(~isnan(x));
            descRows_LR(end+1,:) = {grp, sess, char(condNames(c)), numel(x), round(mean(x,'omitnan'),2), round(std(x,'omitnan'),2), round(std(x,'omitnan')/sqrt(max(numel(x),1)),2)};

            y = acMat(:,c); y = y(~isnan(y));
            descRows_ACC(end+1,:) = {grp, sess, char(condNames(c)), numel(y), round(mean(y,'omitnan'),0), round(std(y,'omitnan'),0), round(std(y,'omitnan')/sqrt(max(numel(y),1)),0)};
        end
    end
end

Desc_LR = cell2table(descRows_LR, 'VariableNames', {'Group','Control','Predictability','N','Mean','SD','SEM'});
Desc_ACC = cell2table(descRows_ACC, 'VariableNames', {'Group','Control','Predictability','N','Mean','SD','SEM'});

writetable(Desc_LR,  fullfile(statsdir,'Descriptives_LearningRate.csv'));
writetable(Desc_ACC, fullfile(statsdir,'Descriptives_Accuracy.csv'));

%% ========================= QUESTIONNAIRE GROUP COMPARISON =========================
[~, p_q, ci_q, st_q] = ttest2(H_q_score, C_q_score, 'Vartype', 'unequal');

meanH = round(mean(H_q_score,'omitnan'),0);
meanC = round(mean(C_q_score,'omitnan'),0);
sdH   = round(std(H_q_score,'omitnan'),0);
sdC   = round(std(C_q_score,'omitnan'),0);

sp = sqrt(((numel(H_q_score)-1)*(std(H_q_score,'omitnan')^2) + (numel(C_q_score)-1)*(std(C_q_score,'omitnan')^2)) / (numel(H_q_score)+numel(C_q_score)-2));
cohens_d = round((mean(H_q_score,'omitnan') - mean(C_q_score,'omitnan')) / sp, 2);

IUSF2_GroupComp = table( ...
    numel(H_q_score), meanH, sdH, ...
    numel(C_q_score), meanC, sdC, ...
    round(st_q.df,2), round(st_q.tstat,2), round(p_q,4), round(ci_q(1),2), round(ci_q(2),2), cohens_d, ...
    'VariableNames', {'N_Healthy','Mean_Healthy','SD_Healthy','N_Chronic','Mean_Chronic','SD_Chronic','df','t','p','CI_low','CI_high','Cohens_d'});

writetable(IUSF2_GroupComp, fullfile(statsdir,'Questionnaire_GroupComparison_IUSFactor2.csv'));

%% ========================= MIXED MODEL ANOVA =========================
LRLong_lme = LRLong;
AccLong_lme = AccLong;

LRLong_lme.Subject        = categorical(cellstr(LRLong_lme.Subject));
LRLong_lme.Group          = categorical(cellstr(LRLong_lme.Group));
LRLong_lme.Control        = categorical(cellstr(LRLong_lme.Control));
LRLong_lme.Predictability = categorical(cellstr(LRLong_lme.Predictability), {'HP','MP','UP'});

AccLong_lme.Subject        = categorical(cellstr(AccLong_lme.Subject));
AccLong_lme.Group          = categorical(cellstr(AccLong_lme.Group));
AccLong_lme.Control        = categorical(cellstr(AccLong_lme.Control));
AccLong_lme.Predictability = categorical(cellstr(AccLong_lme.Predictability), {'HP','MP','UP'});

lme_lr  = fitlme(LRLong_lme,  'Value ~ Group*Control*Predictability + (1|Subject)');
lme_acc = fitlme(AccLong_lme, 'Value ~ Group*Control*Predictability + (1|Subject)');

anova_lr_raw  = anova(lme_lr,  'DFMethod', 'satterthwaite');
anova_acc_raw = anova(lme_acc, 'DFMethod', 'satterthwaite');

% ---------- robust conversion to table ----------
anova_lr  = force_to_table(anova_lr_raw);
anova_acc = force_to_table(anova_acc_raw);

% ---------- add clear term labels if missing ----------
if ~ismember('Term', anova_lr.Properties.VariableNames)
    if ~isempty(anova_lr.Properties.RowNames)
        anova_lr = addvars(anova_lr, string(anova_lr.Properties.RowNames), ...
            'Before', 1, 'NewVariableNames', 'Term');
    else
        anova_lr = addvars(anova_lr, string((1:height(anova_lr)).'), ...
            'Before', 1, 'NewVariableNames', 'Term');
    end
end

if ~ismember('Term', anova_acc.Properties.VariableNames)
    if ~isempty(anova_acc.Properties.RowNames)
        anova_acc = addvars(anova_acc, string(anova_acc.Properties.RowNames), ...
            'Before', 1, 'NewVariableNames', 'Term');
    else
        anova_acc = addvars(anova_acc, string((1:height(anova_acc)).'), ...
            'Before', 1, 'NewVariableNames', 'Term');
    end
end

anova_lr.Properties.RowNames  = {};
anova_acc.Properties.RowNames = {};

% ---------- round numeric columns ----------
vn = anova_lr.Properties.VariableNames;
for i = 1:numel(vn)
    if isnumeric(anova_lr.(vn{i}))
        anova_lr.(vn{i}) = round(anova_lr.(vn{i}), 2);
    end
end

vn = anova_acc.Properties.VariableNames;
for i = 1:numel(vn)
    if isnumeric(anova_acc.(vn{i}))
        anova_acc.(vn{i}) = round(anova_acc.(vn{i}), 2);
    end
end

writetable(anova_lr,  fullfile(statsdir,'ANOVA_LearningRate_MixedModel.csv'));
writetable(anova_acc, fullfile(statsdir,'ANOVA_Accuracy_MixedModel.csv'));




%% ========================= POST HOC BETWEEN GROUPS =========================
PostHoc_Group_LR = cell(0,9);
PostHoc_Group_ACC = cell(0,9);

for s = 1:2
    sesslab = sprintf('S%d', s);

    for c = 1:3
        clab = char(condNames(c));

        x = LRLong.Value(strcmp(LRLong.Group,'Healthy') & strcmp(LRLong.Control,sesslab) & strcmp(LRLong.Predictability,clab));
        y = LRLong.Value(strcmp(LRLong.Group,'Chronic') & strcmp(LRLong.Control,sesslab) & strcmp(LRLong.Predictability,clab));
        x = x(~isnan(x)); y = y(~isnan(y));

        if numel(x)>=2 && numel(y)>=2
            [~,p,~,st] = ttest2(x,y,'Vartype','unequal');
            PostHoc_Group_LR(end+1,:) = {sesslab, clab, numel(x), numel(y), round(mean(x)-mean(y),2), round(st.df,2), round(st.tstat,2), round(p,4), round(min(p*6,1),4)};
        else
            PostHoc_Group_LR(end+1,:) = {sesslab, clab, numel(x), numel(y), NaN, NaN, NaN, NaN, NaN};
        end

        x = AccLong.Value(strcmp(AccLong.Group,'Healthy') & strcmp(AccLong.Control,sesslab) & strcmp(AccLong.Predictability,clab));
        y = AccLong.Value(strcmp(AccLong.Group,'Chronic') & strcmp(AccLong.Control,sesslab) & strcmp(AccLong.Predictability,clab));
        x = x(~isnan(x)); y = y(~isnan(y));

        if numel(x)>=2 && numel(y)>=2
            [~,p,~,st] = ttest2(x,y,'Vartype','unequal');
            PostHoc_Group_ACC(end+1,:) = {sesslab, clab, numel(x), numel(y), round(mean(x)-mean(y),0), round(st.df,2), round(st.tstat,2), round(p,4), round(min(p*6,1),4)};
        else
            PostHoc_Group_ACC(end+1,:) = {sesslab, clab, numel(x), numel(y), NaN, NaN, NaN, NaN, NaN};
        end
    end
end

PostHoc_Group_LR = cell2table(PostHoc_Group_LR, 'VariableNames', ...
    {'Control','Predictability','N_Healthy','N_Chronic','MeanDiff_HminusC','df','t','p_raw','p_bonf'});
PostHoc_Group_ACC = cell2table(PostHoc_Group_ACC, 'VariableNames', ...
    {'Control','Predictability','N_Healthy','N_Chronic','MeanDiff_HminusC','df','t','p_raw','p_bonf'});

writetable(PostHoc_Group_LR, fullfile(statsdir,'PostHoc_BetweenGroups_LearningRate.csv'));
writetable(PostHoc_Group_ACC, fullfile(statsdir,'PostHoc_BetweenGroups_Accuracy.csv'));

%% ========================= RAW CORRELATION ANALYSIS =========================
CorrRows_H = cell(0,11);
CorrRows_C = cell(0,11);

OutcomeNames = {'LR_HP','LR_MP','LR_UP','ACC_HP','ACC_MP','ACC_UP','Lambda'};

Ymat = [H_lr_s1, H_acc_s1, H_lambda_s1];
for k = 1:7
    [x,y] = clean_pair_for_corr(H_q_score(:), Ymat(:,k), APPLY_3SD_ALL);
    [r,p,ciL,ciH,r2] = corr_with_ci(x,y);
    CorrRows_H(end+1,:) = {'Healthy','S1',OutcomeNames{k},numel(x),round(r,2),round(p,4),round(ciL,2),round(ciH,2),round(r2,2),round(mean(x,'omitnan'),2),round(mean(y,'omitnan'),2)};
end

Ymat = [H_lr_s2, H_acc_s2, H_lambda_s2];
for k = 1:7
    [x,y] = clean_pair_for_corr(H_q_score(:), Ymat(:,k), APPLY_3SD_ALL);
    [r,p,ciL,ciH,r2] = corr_with_ci(x,y);
    CorrRows_H(end+1,:) = {'Healthy','S2',OutcomeNames{k},numel(x),round(r,2),round(p,4),round(ciL,2),round(ciH,2),round(r2,2),round(mean(x,'omitnan'),2),round(mean(y,'omitnan'),2)};
end

Ymat = [C_lr_s1, C_acc_s1, C_lambda_s1];
for k = 1:7
    [x,y] = clean_pair_for_corr(C_q_score(:), Ymat(:,k), APPLY_3SD_ALL);
    [r,p,ciL,ciH,r2] = corr_with_ci(x,y);
    CorrRows_C(end+1,:) = {'Chronic','S1',OutcomeNames{k},numel(x),round(r,2),round(p,4),round(ciL,2),round(ciH,2),round(r2,2),round(mean(x,'omitnan'),2),round(mean(y,'omitnan'),2)};
end

Ymat = [C_lr_s2, C_acc_s2, C_lambda_s2];
for k = 1:7
    [x,y] = clean_pair_for_corr(C_q_score(:), Ymat(:,k), APPLY_3SD_ALL);
    [r,p,ciL,ciH,r2] = corr_with_ci(x,y);
    CorrRows_C(end+1,:) = {'Chronic','S2',OutcomeNames{k},numel(x),round(r,2),round(p,4),round(ciL,2),round(ciH,2),round(r2,2),round(mean(x,'omitnan'),2),round(mean(y,'omitnan'),2)};
end

CorrTable_Healthy = cell2table(CorrRows_H, 'VariableNames', ...
    {'Group','Control','Outcome','N','r','p','CI_low','CI_high','R2','Xmean','Ymean'});
CorrTable_Chronic = cell2table(CorrRows_C, 'VariableNames', ...
    {'Group','Control','Outcome','N','r','p','CI_low','CI_high','R2','Xmean','Ymean'});
CorrTable_All = [CorrTable_Healthy; CorrTable_Chronic];

writetable(CorrTable_Healthy, fullfile(statsdir,'Correlations_Healthy.csv'));
writetable(CorrTable_Chronic, fullfile(statsdir,'Correlations_Chronic.csv'));
writetable(CorrTable_All,     fullfile(statsdir,'Correlations_All.csv'));

%% ========================= DIFFERENCE-SCORE CORRELATION ANALYSIS =========================
DiffRows_H = cell(0,11);
DiffRows_C = cell(0,11);

H_diff_lr_ctrl_HP  = H_lr_s2(:,1) - H_lr_s1(:,1);
H_diff_lr_ctrl_MP  = H_lr_s2(:,2) - H_lr_s1(:,2);
H_diff_lr_ctrl_UP  = H_lr_s2(:,3) - H_lr_s1(:,3);
H_diff_lr_S1_UP_HP = H_lr_s1(:,3) - H_lr_s1(:,1);
H_diff_lr_S1_MP_HP = H_lr_s1(:,2) - H_lr_s1(:,1);
H_diff_lr_S2_UP_HP = H_lr_s2(:,3) - H_lr_s2(:,1);
H_diff_lr_S2_MP_HP = H_lr_s2(:,2) - H_lr_s2(:,1);
H_diff_lambda_ctrl = H_lambda_s2 - H_lambda_s1;

C_diff_lr_ctrl_HP  = C_lr_s2(:,1) - C_lr_s1(:,1);
C_diff_lr_ctrl_MP  = C_lr_s2(:,2) - C_lr_s1(:,2);
C_diff_lr_ctrl_UP  = C_lr_s2(:,3) - C_lr_s1(:,3);
C_diff_lr_S1_UP_HP = C_lr_s1(:,3) - C_lr_s1(:,1);
C_diff_lr_S1_MP_HP = C_lr_s1(:,2) - C_lr_s1(:,1);
C_diff_lr_S2_UP_HP = C_lr_s2(:,3) - C_lr_s2(:,1);
C_diff_lr_S2_MP_HP = C_lr_s2(:,2) - C_lr_s2(:,1);
C_diff_lambda_ctrl = C_lambda_s2 - C_lambda_s1;

DiffOutcomeNames = { ...
    'LR_S2minusS1_HP', ...
    'LR_S2minusS1_MP', ...
    'LR_S2minusS1_UP', ...
    'LR_S1_UPminusHP', ...
    'LR_S1_MPminusHP', ...
    'LR_S2_UPminusHP', ...
    'LR_S2_MPminusHP', ...
    'Lambda_S2minusS1'};

YHdiff = [ ...
    H_diff_lr_ctrl_HP, ...
    H_diff_lr_ctrl_MP, ...
    H_diff_lr_ctrl_UP, ...
    H_diff_lr_S1_UP_HP, ...
    H_diff_lr_S1_MP_HP, ...
    H_diff_lr_S2_UP_HP, ...
    H_diff_lr_S2_MP_HP, ...
    H_diff_lambda_ctrl];

YCdiff = [ ...
    C_diff_lr_ctrl_HP, ...
    C_diff_lr_ctrl_MP, ...
    C_diff_lr_ctrl_UP, ...
    C_diff_lr_S1_UP_HP, ...
    C_diff_lr_S1_MP_HP, ...
    C_diff_lr_S2_UP_HP, ...
    C_diff_lr_S2_MP_HP, ...
    C_diff_lambda_ctrl];

for k = 1:size(YHdiff,2)
    [x,y] = clean_pair_for_corr(H_q_score(:), YHdiff(:,k), APPLY_3SD_ALL);
    [r,p,ciL,ciH,r2] = corr_with_ci(x,y);
    DiffRows_H(end+1,:) = {'Healthy', DiffOutcomeNames{k}, numel(x), round(r,2), round(p,4), round(ciL,2), round(ciH,2), round(r2,2), round(mean(x,'omitnan'),2), round(mean(y,'omitnan'),2), round(std(y,'omitnan'),2)};
end

for k = 1:size(YCdiff,2)
    [x,y] = clean_pair_for_corr(C_q_score(:), YCdiff(:,k), APPLY_3SD_ALL);
    [r,p,ciL,ciH,r2] = corr_with_ci(x,y);
    DiffRows_C(end+1,:) = {'Chronic', DiffOutcomeNames{k}, numel(x), round(r,2), round(p,4), round(ciL,2), round(ciH,2), round(r2,2), round(mean(x,'omitnan'),2), round(mean(y,'omitnan'),2), round(std(y,'omitnan'),2)};
end

DiffCorr_Healthy = cell2table(DiffRows_H, 'VariableNames', ...
    {'Group','Outcome','N','r','p','CI_low','CI_high','R2','Xmean','Ymean','Ysd'});
DiffCorr_Chronic = cell2table(DiffRows_C, 'VariableNames', ...
    {'Group','Outcome','N','r','p','CI_low','CI_high','R2','Xmean','Ymean','Ysd'});
DiffCorr_All = [DiffCorr_Healthy; DiffCorr_Chronic];

writetable(DiffCorr_Healthy, fullfile(statsdir,'DiffScore_Correlations_Healthy.csv'));
writetable(DiffCorr_Chronic, fullfile(statsdir,'DiffScore_Correlations_Chronic.csv'));
writetable(DiffCorr_All,     fullfile(statsdir,'DiffScore_Correlations_All.csv'));

%% ========================= CORRELATION PLOTS: RAW SCORES =========================
plot_names = {'LR_HP','LR_MP','LR_UP','ACC_HP','ACC_MP','ACC_UP','Lambda'};
plot_titles = {'HP','MP','UP','HP','MP','UP',''};
plot_ylabels = {'Learning rate','Learning rate','Learning rate', ...
                'Accuracy (%)','Accuracy (%)','Accuracy (%)', ...
                'Volatility update rate'};

YH = {H_lr_s1(:,1), H_lr_s1(:,2), H_lr_s1(:,3), H_acc_s1(:,1), H_acc_s1(:,2), H_acc_s1(:,3), H_lambda_s1};
YC = {C_lr_s1(:,1), C_lr_s1(:,2), C_lr_s1(:,3), C_acc_s1(:,1), C_acc_s1(:,2), C_acc_s1(:,3), C_lambda_s1};

for k = 1:7
    figure('Color','w','Position',fig_pos_corr); hold on;

    [xH,yH] = clean_pair_for_corr(H_q_score(:), YH{k}(:), APPLY_3SD_ALL);
    [xC,yC] = clean_pair_for_corr(C_q_score(:), YC{k}(:), APPLY_3SD_ALL);

    scatter(xH,yH,ms_dot,'o','MarkerFaceColor',colH_S1,'MarkerEdgeColor','k','MarkerFaceAlpha',alpha_dot,'MarkerEdgeAlpha',alpha_dot);
    scatter(xC,yC,ms_dot,'s','MarkerFaceColor',colC_S1,'MarkerEdgeColor','k','MarkerFaceAlpha',alpha_dot,'MarkerEdgeAlpha',alpha_dot);

    if numel(xH)>=2 && std(xH)>0 && std(yH)>0
        pfit = polyfit(xH,yH,1);
        xx = linspace(min(xH),max(xH),100);
        yy = polyval(pfit,xx);
        plot(xx,yy,'-','Color',colH_S1,'LineWidth',lw_fit);
    end
    if numel(xC)>=2 && std(xC)>0 && std(yC)>0
        pfit = polyfit(xC,yC,1);
        xx = linspace(min(xC),max(xC),100);
        yy = polyval(pfit,xx);
        plot(xx,yy,'-','Color',colC_S1,'LineWidth',lw_fit);
    end

    xlabel('IUS factor 2 score','FontSize',fs_label);
    ylabel(plot_ylabels{k},'FontSize',fs_label);

    if ~isempty(plot_titles{k})
        title(plot_titles{k},'FontSize',fs_title,'FontWeight','bold');
    end

    if k <= 3
        ylim(ylim_corrLR); yfmt = '%.2f';
    elseif k <= 6
        ylim(ylim_corrAC); yfmt = '%.0f';
    else
        ylim(ylim_corrLA); yfmt = '%.2f';
    end

    xlim(xlim_corr);
    apply_tick_format(gca,'y',yfmt,5);
    apply_tick_format(gca,'x','%.0f',5);

    ax = gca;
    ax.TickDir = 'out';
    ax.XAxis.FontSize = fs_xtick;
    ax.YAxis.FontSize = fs_ytick;
    set(gca,'Box','off','LineWidth',lw_axes);

    lgd = legend(make_corr_legend_proxies(colH_S1,colC_S1), ...
        {'Healthy controllable','Chronic stress controllable'}, ...
        'Location',legend_loc,'Box','off','FontSize',fs_legend);
    shift_legend(lgd, legend_x_shift, legend_y_shift);

    exportgraphics(gcf, fullfile(figdir,['Corr_Controllable_' plot_names{k} '.png']),'Resolution',png_dpi);
    exportgraphics(gcf, fullfile(figdir,['Corr_Controllable_' plot_names{k} '.pdf']),'ContentType','vector');
end

YH = {H_lr_s2(:,1), H_lr_s2(:,2), H_lr_s2(:,3), H_acc_s2(:,1), H_acc_s2(:,2), H_acc_s2(:,3), H_lambda_s2};
YC = {C_lr_s2(:,1), C_lr_s2(:,2), C_lr_s2(:,3), C_acc_s2(:,1), C_acc_s2(:,2), C_acc_s2(:,3), C_lambda_s2};

for k = 1:7
    figure('Color','w','Position',fig_pos_corr); hold on;

    [xH,yH] = clean_pair_for_corr(H_q_score(:), YH{k}(:), APPLY_3SD_ALL);
    [xC,yC] = clean_pair_for_corr(C_q_score(:), YC{k}(:), APPLY_3SD_ALL);

    scatter(xH,yH,ms_dot,'o','MarkerFaceColor',colH_S2,'MarkerEdgeColor','k','MarkerFaceAlpha',alpha_dot,'MarkerEdgeAlpha',alpha_dot);
    scatter(xC,yC,ms_dot,'s','MarkerFaceColor',colC_S2,'MarkerEdgeColor','k','MarkerFaceAlpha',alpha_dot,'MarkerEdgeAlpha',alpha_dot);

    if numel(xH)>=2 && std(xH)>0 && std(yH)>0
        pfit = polyfit(xH,yH,1);
        xx = linspace(min(xH),max(xH),100);
        yy = polyval(pfit,xx);
        plot(xx,yy,'-','Color',colH_S2,'LineWidth',lw_fit);
    end
    if numel(xC)>=2 && std(xC)>0 && std(yC)>0
        pfit = polyfit(xC,yC,1);
        xx = linspace(min(xC),max(xC),100);
        yy = polyval(pfit,xx);
        plot(xx,yy,'-','Color',colC_S2,'LineWidth',lw_fit);
    end

    xlabel('IUS factor 2 score','FontSize',fs_label);
    ylabel(plot_ylabels{k},'FontSize',fs_label);

    if ~isempty(plot_titles{k})
        title(plot_titles{k},'FontSize',fs_title,'FontWeight','bold');
    end

    if k <= 3
        ylim(ylim_corrLR); yfmt = '%.2f';
    elseif k <= 6
        ylim(ylim_corrAC); yfmt = '%.0f';
    else
        ylim(ylim_corrLA); yfmt = '%.2f';
    end

    xlim(xlim_corr);
    apply_tick_format(gca,'y',yfmt,5);
    apply_tick_format(gca,'x','%.0f',5);

    ax = gca;
    ax.TickDir = 'out';
    ax.XAxis.FontSize = fs_xtick;
    ax.YAxis.FontSize = fs_ytick;
    set(gca,'Box','off','LineWidth',lw_axes);

    lgd = legend(make_corr_legend_proxies(colH_S2,colC_S2), ...
        {'Healthy uncontrollable','Chronic stress uncontrollable'}, ...
        'Location',legend_loc,'Box','off','FontSize',fs_legend);
    shift_legend(lgd, legend_x_shift, legend_y_shift);

    exportgraphics(gcf, fullfile(figdir,['Corr_Uncontrollable_' plot_names{k} '.png']),'Resolution',png_dpi);
    exportgraphics(gcf, fullfile(figdir,['Corr_Uncontrollable_' plot_names{k} '.pdf']),'ContentType','vector');
end

%% ========================= CORRELATION PLOTS: DIFFERENCE SCORES =========================
diff_plot_names = { ...
    'LR_S2minusS1_HP', ...
    'LR_S2minusS1_MP', ...
    'LR_S2minusS1_UP', ...
    'LR_S1_UPminusHP', ...
    'LR_S1_MPminusHP', ...
    'LR_S2_UPminusHP', ...
    'LR_S2_MPminusHP', ...
    'Lambda_S2minusS1'};

diff_plot_titles = { ...
    'HP', 'MP', 'UP', ...
    'Controllable', 'Controllable', ...
    'Uncontrollable', 'Uncontrollable', ...
    ''};

diff_ylabels = { ...
    'Learning rate difference (S2 - S1)', ...
    'Learning rate difference (S2 - S1)', ...
    'Learning rate difference (S2 - S1)', ...
    'Learning rate difference (UP - HP)', ...
    'Learning rate difference (MP - HP)', ...
    'Learning rate difference (UP - HP)', ...
    'Learning rate difference (MP - HP)', ...
    'Volatility update rate difference (S2 - S1)'};

YHdiff_cell = { ...
    H_diff_lr_ctrl_HP, ...
    H_diff_lr_ctrl_MP, ...
    H_diff_lr_ctrl_UP, ...
    H_diff_lr_S1_UP_HP, ...
    H_diff_lr_S1_MP_HP, ...
    H_diff_lr_S2_UP_HP, ...
    H_diff_lr_S2_MP_HP, ...
    H_diff_lambda_ctrl};

YCdiff_cell = { ...
    C_diff_lr_ctrl_HP, ...
    C_diff_lr_ctrl_MP, ...
    C_diff_lr_ctrl_UP, ...
    C_diff_lr_S1_UP_HP, ...
    C_diff_lr_S1_MP_HP, ...
    C_diff_lr_S2_UP_HP, ...
    C_diff_lr_S2_MP_HP, ...
    C_diff_lambda_ctrl};

allDiffLR = [H_diff_lr_ctrl_HP; H_diff_lr_ctrl_MP; H_diff_lr_ctrl_UP; ...
             H_diff_lr_S1_UP_HP; H_diff_lr_S1_MP_HP; H_diff_lr_S2_UP_HP; H_diff_lr_S2_MP_HP; ...
             C_diff_lr_ctrl_HP; C_diff_lr_ctrl_MP; C_diff_lr_ctrl_UP; ...
             C_diff_lr_S1_UP_HP; C_diff_lr_S1_MP_HP; C_diff_lr_S2_UP_HP; C_diff_lr_S2_MP_HP];

allDiffLAM = [H_diff_lambda_ctrl; C_diff_lambda_ctrl];

ylim_diffLR = round_limits(padded_limits(allDiffLR), 2);
ylim_diffLA = round_limits(padded_limits(allDiffLAM), 2);

for k = 1:8
    figure('Color','w','Position',fig_pos_corr); hold on;

    [xH,yH] = clean_pair_for_corr(H_q_score(:), YHdiff_cell{k}(:), APPLY_3SD_ALL);
    [xC,yC] = clean_pair_for_corr(C_q_score(:), YCdiff_cell{k}(:), APPLY_3SD_ALL);

    scatter(xH,yH,ms_dot,'o','MarkerFaceColor',colH_S1,'MarkerEdgeColor','k','MarkerFaceAlpha',alpha_dot,'MarkerEdgeAlpha',alpha_dot);
    scatter(xC,yC,ms_dot,'s','MarkerFaceColor',colC_S1,'MarkerEdgeColor','k','MarkerFaceAlpha',alpha_dot,'MarkerEdgeAlpha',alpha_dot);

    if numel(xH)>=2 && std(xH)>0 && std(yH)>0
        pfit = polyfit(xH,yH,1);
        xx = linspace(min(xH),max(xH),100);
        yy = polyval(pfit,xx);
        plot(xx,yy,'-','Color',colH_S1,'LineWidth',lw_fit);
    end

    if numel(xC)>=2 && std(xC)>0 && std(yC)>0
        pfit = polyfit(xC,yC,1);
        xx = linspace(min(xC),max(xC),100);
        yy = polyval(pfit,xx);
        plot(xx,yy,'-','Color',colC_S1,'LineWidth',lw_fit);
    end

    xlabel('IUS factor 2 score','FontSize',fs_label);
    ylabel(diff_ylabels{k},'FontSize',fs_label);

    if ~isempty(diff_plot_titles{k})
        title(diff_plot_titles{k},'FontSize',fs_title,'FontWeight','bold');
    end

    xlim(xlim_corr);

    if k <= 7
        ylim(ylim_diffLR);
        apply_tick_format(gca,'y','%.2f',5);
    else
        ylim(ylim_diffLA);
        apply_tick_format(gca,'y','%.2f',5);
    end

    apply_tick_format(gca,'x','%.0f',5);

    ax = gca;
    ax.TickDir = 'out';
    ax.XAxis.FontSize = fs_xtick;
    ax.YAxis.FontSize = fs_ytick;
    set(gca,'Box','off','LineWidth',lw_axes);

    lgd = legend(make_corr_legend_proxies(colH_S1,colC_S1), ...
        {'Healthy','Chronic stress'}, ...
        'Location',legend_loc,'Box','off','FontSize',fs_legend);
    shift_legend(lgd, legend_x_shift, legend_y_shift);

    exportgraphics(gcf, fullfile(figdir,['DiffCorr_' diff_plot_names{k} '.png']),'Resolution',png_dpi);
    exportgraphics(gcf, fullfile(figdir,['DiffCorr_' diff_plot_names{k} '.pdf']),'ContentType','vector');
end

%% ========================= BOXPLOT POSITION HELPERS =========================
xposBase = [1, 1 + predictability_gap, 1 + 2*predictability_gap] - x_left_shift;

xH1 = xposBase - (healthy_chronic_gap/2 + ctrl_unctrl_gap/2);
xH2 = xposBase - (healthy_chronic_gap/2 - ctrl_unctrl_gap/2);
xC1 = xposBase + (healthy_chronic_gap/2 - ctrl_unctrl_gap/2);
xC2 = xposBase + (healthy_chronic_gap/2 + ctrl_unctrl_gap/2);

%% ========================= LEARNING RATE BOXPLOT =========================
figure('Color','w','Position',fig_pos_box); hold on;
for c = 1:3
    draw_custom_box(xH1(c), H_lr_s1(:,c), colH_S1, main_box_width, box_alpha, main_jitterW, ms_dot, alpha_dot);
    draw_custom_box(xH2(c), H_lr_s2(:,c), colH_S2, main_box_width, box_alpha, main_jitterW, ms_dot, alpha_dot);
    draw_custom_box(xC1(c), C_lr_s1(:,c), colC_S1, main_box_width, box_alpha, main_jitterW, ms_dot, alpha_dot);
    draw_custom_box(xC2(c), C_lr_s2(:,c), colC_S2, main_box_width, box_alpha, main_jitterW, ms_dot, alpha_dot);
end

set(gca,'XTick',xposBase,'XTickLabel',cellstr(condNames),'Box','off','LineWidth',lw_axes,'FontSize',fs_xtick);
ax = gca; ax.TickDir = 'out'; ax.YAxis.FontSize = fs_ytick;

xlabel('Predictability','FontSize',fs_label);
ylabel('Learning rate','FontSize',fs_label);

lgd = legend(make_box_legend_proxies(colH_S1,colH_S2,colC_S1,colC_S2,box_alpha), ...
    {'Healthy controllable','Healthy uncontrollable','Chronic stress controllable','Chronic stress uncontrollable'}, ...
    'Location',legend_loc,'Box','off','FontSize',fs_legend);
shift_legend(lgd, legend_x_shift, legend_y_shift);

xlim([xposBase(1)-main_left_pad, xposBase(end)+main_right_pad]);
ylim(ylim_corrLR);
apply_tick_format(gca,'y','%.2f',5);

exportgraphics(gcf, fullfile(figdir,'LearningRate_AllGroups_S1S2_sameplot.png'),'Resolution',png_dpi);
exportgraphics(gcf, fullfile(figdir,'LearningRate_AllGroups_S1S2_sameplot.pdf'),'ContentType','vector');

%% ========================= ACCURACY BOXPLOT =========================
figure('Color','w','Position',fig_pos_box); hold on;
for c = 1:3
    draw_custom_box(xH1(c), H_acc_s1(:,c), colH_S1, main_box_width, box_alpha, main_jitterW, ms_dot, alpha_dot);
    draw_custom_box(xH2(c), H_acc_s2(:,c), colH_S2, main_box_width, box_alpha, main_jitterW, ms_dot, alpha_dot);
    draw_custom_box(xC1(c), C_acc_s1(:,c), colC_S1, main_box_width, box_alpha, main_jitterW, ms_dot, alpha_dot);
    draw_custom_box(xC2(c), C_acc_s2(:,c), colC_S2, main_box_width, box_alpha, main_jitterW, ms_dot, alpha_dot);
end

set(gca,'XTick',xposBase,'XTickLabel',cellstr(condNames),'Box','off','LineWidth',lw_axes,'FontSize',fs_xtick);
ax = gca; ax.TickDir = 'out'; ax.YAxis.FontSize = fs_ytick;

xlabel('Predictability','FontSize',fs_label);
ylabel('Accuracy (%)','FontSize',fs_label);

lgd = legend(make_box_legend_proxies(colH_S1,colH_S2,colC_S1,colC_S2,box_alpha), ...
    {'Healthy controllable','Healthy uncontrollable','Chronic stress controllable','Chronic stress uncontrollable'}, ...
    'Location',legend_loc,'Box','off','FontSize',fs_legend);
shift_legend(lgd, legend_x_shift, legend_y_shift);

xlim([xposBase(1)-main_left_pad, xposBase(end)+main_right_pad]);
ylim(ylim_corrAC);
apply_tick_format(gca,'y','%.0f',5);

exportgraphics(gcf, fullfile(figdir,'Accuracy_AllGroups_S1S2_sameplot.png'),'Resolution',png_dpi);
exportgraphics(gcf, fullfile(figdir,'Accuracy_AllGroups_S1S2_sameplot.pdf'),'ContentType','vector');

%% ========================= QUESTIONNAIRE GROUP PLOT =========================
figure('Color','w','Position',fig_pos_q); hold on;

q_center = 1.45 - q_center_left_shift;
q_xH = q_center - q_group_gap/2;
q_xC = q_center + q_group_gap/2;

draw_custom_box(q_xH, H_q_score(:), colQ_H, q_box_width, box_alpha, q_jitterW, ms_dot, alpha_dot);
draw_custom_box(q_xC, C_q_score(:), colQ_C, q_box_width, box_alpha, q_jitterW, ms_dot, alpha_dot);

set(gca,'XTick',[q_xH q_xC],'XTickLabel',{'Healthy','Chronic stress'}, ...
    'Box','off','LineWidth',lw_axes,'FontSize',fs_xtick);
ax = gca; ax.TickDir = 'out'; ax.YAxis.FontSize = fs_ytick;

ylabel('IUS factor 2 score','FontSize',fs_label);

xlim([q_xH-q_left_pad, q_xC+q_right_pad]);
ylim(ylim_q);
apply_tick_format(gca,'y','%.0f',5);

exportgraphics(gcf, fullfile(figdir,'Questionnaire_GroupComparison_IUSFactor2.png'),'Resolution',png_dpi);
exportgraphics(gcf, fullfile(figdir,'Questionnaire_GroupComparison_IUSFactor2.pdf'),'ContentType','vector');

%% ========================= SAFE EXCEL WRITE =========================
try
    outTables = { ...
        Healthy_SubjectData, ...
        Chronic_SubjectData, ...
        Desc_LR, ...
        Desc_ACC, ...
        IUSF2_GroupComp, ...
        anova_lr, ...
        anova_acc, ...
        PostHoc_Group_LR, ...
        PostHoc_Group_ACC, ...
        CorrTable_Healthy, ...
        CorrTable_Chronic, ...
        CorrTable_All, ...
        DiffCorr_Healthy, ...
        DiffCorr_Chronic, ...
        DiffCorr_All};

    outSheets = { ...
        '01_Healthy_SubjectData', ...
        '02_Chronic_SubjectData', ...
        '03_Desc_LearningRate', ...
        '04_Desc_Accuracy', ...
        '05_IUSF2_GroupDiff', ...
        '06_ANOVA_LearningRate', ...
        '07_ANOVA_Accuracy', ...
        '08_PostHoc_BetweenGrp_LR', ...
        '09_PostHoc_BetweenGrp_ACC', ...
        '10_Corr_Healthy_Raw', ...
        '11_Corr_Chronic_Raw', ...
        '12_Corr_All_Raw', ...
        '13_Corr_Healthy_Diff', ...
        '14_Corr_Chronic_Diff', ...
        '15_Corr_All_Diff'};

    for i = 1:numel(outTables)
        T = outTables{i};

        if istable(T)
            writetable(T, stats_xlsx, 'Sheet', outSheets{i});
        elseif isstruct(T)
            writetable(struct2table(T), stats_xlsx, 'Sheet', outSheets{i});
        elseif isnumeric(T)
            writetable(array2table(T), stats_xlsx, 'Sheet', outSheets{i});
        else
            warning('Skipping sheet %s because variable is not table-convertible.', outSheets{i});
        end
    end

catch ME
    warning('Excel write issue: %s', ME.message);
end

fprintf('\nDone. Main script finished successfully.\n');
fprintf('Helper functions remain unchanged and should stay in their separate files.\n');