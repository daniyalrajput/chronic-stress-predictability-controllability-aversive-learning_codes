%% VKF learning-rate / volatility-update-rate associations with reaction time
% Healthy-control group — publication/repository version
%
% Purpose
%   Examine associations between VKF learning quantities and reaction time
%   (RT) in Healthy controls, comparing controllable and uncontrollable
%   sessions.
%
% Analyses
%   A. Volatility update rate (lambda) vs overall mean RT
%
%   B. Learning rate (Kalman gain) vs mean RT separately for:
%          - Highly predictable (HP)
%          - Moderately predictable (MP)
%          - Unpredictable (UP)
%
%   C. Volatility update rate (lambda) vs mean RT separately for:
%          - HP
%          - MP
%          - UP
%
% Sessions
%   S1 = Controllable
%   S2 = Uncontrollable
%
% Statistical approach
%   - Pearson correlations are estimated separately for S1 and S2.
%   - S1 and S2 correlations are compared using a participant-paired
%     bootstrap of the difference in correlations:
%         Delta r = r_Controllable - r_Uncontrollable
%   - Cohen's q is also reported.
%   - Optional >3 SD cleaning is applied jointly across the four variables
%     entering each paired S1/S2 comparison so the same participants are
%     retained for both sessions.
%
% Predictability mapping
%   HP: Block1, Block5, Block8, Block10
%   MP: Block3, Block4, Block7, Block9
%   UP: Block2, Block6
%
% Participant alignment
%   - S1 and S2 worksheets are matched by participant ID after removing
%     common session suffixes.
%   - VKF rows are indexed using the ORIGINAL worksheet position in each
%     workbook, preserving the mapping assumed by the original analysis.
%
%
% Required directory structure
%
%   data/VKF_RT_Healthy/
%       Correct_incorrect_S1.xlsx
%       Correct_incorrect_S2.xlsx
%       vkf_all_results_s1.mat
%       vkf_all_results_s2.mat
%
% Required MAT-file variables
%   kgain_mat
%   lambda_vec
%
% -------------------------------------------------------------------------
% Daniyal Rajput
% Probabilistic aversive-learning study
% -------------------------------------------------------------------------

clear; clc; close all;
rng(1,'twister');

%% ========================================================================
% Paths
% ========================================================================

scriptDir = fileparts(mfilename('fullpath'));
if isempty(scriptDir)
    scriptDir = pwd;
end

dataDir = fullfile(scriptDir,'data','VKF_RT_Healthy');

outDir   = fullfile(scriptDir,'results','VKF_RT_Healthy');
figDir   = fullfile(outDir,'figures');
statsDir = fullfile(outDir,'stats');

if ~exist(outDir,'dir'),   mkdir(outDir);   end
if ~exist(figDir,'dir'),   mkdir(figDir);   end
if ~exist(statsDir,'dir'), mkdir(statsDir); end

xlsS1 = fullfile(dataDir,'Correct_incorrect_S1.xlsx');
xlsS2 = fullfile(dataDir,'Correct_incorrect_S2.xlsx');

vkfS1File = fullfile(dataDir,'vkf_all_results_s1.mat');
vkfS2File = fullfile(dataDir,'vkf_all_results_s2.mat');

assert(isfile(xlsS1),'Missing input file: %s',xlsS1);
assert(isfile(xlsS2),'Missing input file: %s',xlsS2);
assert(isfile(vkfS1File),'Missing input file: %s',vkfS1File);
assert(isfile(vkfS2File),'Missing input file: %s',vkfS2File);

masterExcel = fullfile(statsDir,'VKF_RT_Healthy_results.xlsx');
masterMat   = fullfile(statsDir,'VKF_RT_Healthy_results.mat');

%% ========================================================================
% Data columns
% ========================================================================

RT_COL    = 5;
BLOCK_COL = 2;

%% ========================================================================
% Predictability blocks
% ========================================================================

HP_blocks = ["Block1","Block5","Block8","Block10"];
MP_blocks = ["Block3","Block4","Block7","Block9"];
UP_blocks = ["Block2","Block6"];

condNames = ["HP","MP","UP"];

condLabels = [ ...
    "Highly predictable", ...
    "Moderately predictable", ...
    "Unpredictable"];

%% ========================================================================
% Analysis settings
% ========================================================================

APPLY_3SD = true;
SD_THRESHOLD = 3;

N_BOOT = 5000;
ALPHA = 0.05;

%% ========================================================================
% Figure settings
% ========================================================================

colS1 = [0.00 0.25 0.55];
colS2 = [0.85 0.33 0.00];

fs_tick_x  = 22;
fs_tick_y  = 22;
fs_label_x = 24;
fs_label_y = 24;
fs_legend  = 20;

lw_axes   = 1.6;
lw_fit    = 2.2;

ms_dot    = 55;
alpha_dot = 0.85;

png_dpi = 600;

fig_pos = [350 250 620 540];

% Fixed axes retained from the original figure preparation.
y_lim_RT   = [140 600];
y_ticks_RT = 140:115:600;

x_lim_LAM   = [0 0.9];
x_ticks_LAM = 0:0.3:0.9;

x_lim_LR   = [0.5 0.9];
x_ticks_LR = 0.5:0.1:0.9;

%% ========================================================================
% Load VKF
% ========================================================================

VKF1 = load(vkfS1File);
VKF2 = load(vkfS2File);

assert(isfield(VKF1,'kgain_mat') && isfield(VKF1,'lambda_vec'), ...
    'S1 VKF file must contain kgain_mat and lambda_vec.');

assert(isfield(VKF2,'kgain_mat') && isfield(VKF2,'lambda_vec'), ...
    'S2 VKF file must contain kgain_mat and lambda_vec.');

lrS1 = double(VKF1.kgain_mat);
lrS2 = double(VKF2.kgain_mat);

lambdaS1 = double(VKF1.lambda_vec(:));
lambdaS2 = double(VKF2.lambda_vec(:));

assert(size(lrS1,1) == numel(lambdaS1), ...
    'S1 kgain_mat rows and lambda_vec length do not match.');

assert(size(lrS2,1) == numel(lambdaS2), ...
    'S2 kgain_mat rows and lambda_vec length do not match.');

%% ========================================================================
% Match participants across sessions
% ========================================================================

sheetsS1 = string(sheetnames(xlsS1));
sheetsS2 = string(sheetnames(xlsS2));

assert(~isempty(sheetsS1),'No S1 worksheets found.');
assert(~isempty(sheetsS2),'No S2 worksheets found.');

idS1 = normalize_subject_id(sheetsS1);
idS2 = normalize_subject_id(sheetsS2);

[commonIDs,idxS1,idxS2] = intersect(idS1,idS2,'stable');

if isempty(commonIDs)
    fprintf('\nS1 sheet names:\n');
    disp(sheetsS1(:));

    fprintf('\nS2 sheet names:\n');
    disp(sheetsS2(:));

    error('No matching participants across S1 and S2.');
end

nParticipants = numel(commonIDs);

fprintf('Matched participants across S1/S2: %d\n',nParticipants);

assert(size(lrS1,1) >= max(idxS1), ...
    'S1 VKF rows do not cover all matched worksheet indices.');

assert(size(lrS2,1) >= max(idxS2), ...
    'S2 VKF rows do not cover all matched worksheet indices.');

assert(numel(lambdaS1) >= max(idxS1), ...
    'S1 lambda_vec does not cover all matched worksheet indices.');

assert(numel(lambdaS2) >= max(idxS2), ...
    'S2 lambda_vec does not cover all matched worksheet indices.');

ParticipantID = string(commonIDs(:));

participantMapping = table( ...
    ParticipantID, ...
    sheetsS1(idxS1).',idxS1(:), ...
    sheetsS2(idxS2).',idxS2(:), ...
    'VariableNames', { ...
        'ParticipantID', ...
        'S1_Worksheet','S1_WorkbookIndex', ...
        'S2_Worksheet','S2_WorkbookIndex'});

%% ========================================================================
% Extract participant-level RT and VKF measures
% ========================================================================

rtMeanS1 = nan(nParticipants,1);
rtMeanS2 = nan(nParticipants,1);

rtCondS1 = nan(nParticipants,3);
rtCondS2 = nan(nParticipants,3);

lrCondS1 = nan(nParticipants,3);
lrCondS2 = nan(nParticipants,3);

trialAudit = table();

for k = 1:nParticipants

    sheetS1 = sheetsS1(idxS1(k));
    sheetS2 = sheetsS2(idxS2(k));

    T1 = readtable( ...
        xlsS1, ...
        'Sheet',sheetS1, ...
        'VariableNamingRule','preserve');

    T2 = readtable( ...
        xlsS2, ...
        'Sheet',sheetS2, ...
        'VariableNamingRule','preserve');

    assert(width(T1) >= max(RT_COL,BLOCK_COL), ...
        'S1 worksheet %s does not contain required columns.',sheetS1);

    assert(width(T2) >= max(RT_COL,BLOCK_COL), ...
        'S2 worksheet %s does not contain required columns.',sheetS2);

    rt1 = to_numeric_vector(T1{:,RT_COL});
    rt2 = to_numeric_vector(T2{:,RT_COL});

    blocks1 = strtrim(string(T1{:,BLOCK_COL}));
    blocks2 = strtrim(string(T2{:,BLOCK_COL}));

    learningRate1 = lrS1(idxS1(k),:).';
    learningRate2 = lrS2(idxS2(k),:).';

    % Exact trial alignment is required.
    if numel(rt1) ~= numel(learningRate1)
        error(['Trial-count mismatch for %s, Controllable session.\n' ...
               'Behavioral RT rows = %d; VKF learning-rate values = %d.'], ...
               ParticipantID(k),numel(rt1),numel(learningRate1));
    end

    if numel(rt2) ~= numel(learningRate2)
        error(['Trial-count mismatch for %s, Uncontrollable session.\n' ...
               'Behavioral RT rows = %d; VKF learning-rate values = %d.'], ...
               ParticipantID(k),numel(rt2),numel(learningRate2));
    end

    % Overall RT is based on all valid RT trials.
    rtMeanS1(k) = mean(rt1,'omitnan');
    rtMeanS2(k) = mean(rt2,'omitnan');

    masks1 = { ...
        ismember(blocks1,HP_blocks), ...
        ismember(blocks1,MP_blocks), ...
        ismember(blocks1,UP_blocks)};

    masks2 = { ...
        ismember(blocks2,HP_blocks), ...
        ismember(blocks2,MP_blocks), ...
        ismember(blocks2,UP_blocks)};

    for c = 1:3

        valid1 = masks1{c} & ...
            isfinite(rt1) & ...
            isfinite(learningRate1);

        valid2 = masks2{c} & ...
            isfinite(rt2) & ...
            isfinite(learningRate2);

        if any(valid1)

            rtCondS1(k,c) = mean( ...
                rt1(valid1),'omitnan');

            lrCondS1(k,c) = mean( ...
                learningRate1(valid1),'omitnan');
        end

        if any(valid2)

            rtCondS2(k,c) = mean( ...
                rt2(valid2),'omitnan');

            lrCondS2(k,c) = mean( ...
                learningRate2(valid2),'omitnan');
        end
    end

    auditRow = table( ...
        ParticipantID(k), ...
        height(T1),numel(learningRate1), ...
        height(T2),numel(learningRate2), ...
        'VariableNames', { ...
            'ParticipantID', ...
            'S1_BehavioralTrials','S1_VKFTrials', ...
            'S2_BehavioralTrials','S2_VKFTrials'});

    trialAudit = [trialAudit;auditRow]; %#ok<AGROW>
end

lambdaMatchedS1 = lambdaS1(idxS1);
lambdaMatchedS2 = lambdaS2(idxS2);

%% ========================================================================
% Participant-level summary
% ========================================================================

participantSummary = table( ...
    ParticipantID, ...
    lambdaMatchedS1,lambdaMatchedS2, ...
    rtMeanS1,rtMeanS2, ...
    rtCondS1(:,1),rtCondS1(:,2),rtCondS1(:,3), ...
    rtCondS2(:,1),rtCondS2(:,2),rtCondS2(:,3), ...
    lrCondS1(:,1),lrCondS1(:,2),lrCondS1(:,3), ...
    lrCondS2(:,1),lrCondS2(:,2),lrCondS2(:,3), ...
    'VariableNames', { ...
        'ParticipantID', ...
        'Lambda_Controllable','Lambda_Uncontrollable', ...
        'MeanRT_Controllable','MeanRT_Uncontrollable', ...
        'MeanRT_HP_Controllable','MeanRT_MP_Controllable','MeanRT_UP_Controllable', ...
        'MeanRT_HP_Uncontrollable','MeanRT_MP_Uncontrollable','MeanRT_UP_Uncontrollable', ...
        'LearningRate_HP_Controllable','LearningRate_MP_Controllable','LearningRate_UP_Controllable', ...
        'LearningRate_HP_Uncontrollable','LearningRate_MP_Uncontrollable','LearningRate_UP_Uncontrollable'});

%% ========================================================================
% A. Lambda vs overall RT
% ========================================================================

[A_x1,A_y1,A_x2,A_y2,A_keep,A_removed] = ...
    paired_completecase_3sd( ...
        lambdaMatchedS1,rtMeanS1, ...
        lambdaMatchedS2,rtMeanS2, ...
        ParticipantID,APPLY_3SD,SD_THRESHOLD);

A_statsS1 = pearson_stats(A_x1,A_y1,ALPHA);
A_statsS2 = pearson_stats(A_x2,A_y2,ALPHA);

A_results = [
    pack_correlation_row( ...
        "Controllable", ...
        "Volatility update rate", ...
        "Mean reaction time (ms)", ...
        A_statsS1);
    pack_correlation_row( ...
        "Uncontrollable", ...
        "Volatility update rate", ...
        "Mean reaction time (ms)", ...
        A_statsS2)
    ];

A_compare = paired_bootstrap_correlation_difference( ...
    A_x1,A_y1,A_x2,A_y2,N_BOOT,ALPHA);

A_comparison = table( ...
    "Volatility update rate", ...
    "Mean reaction time (ms)", ...
    A_compare.DeltaR, ...
    A_compare.CI_Lower, ...
    A_compare.CI_Upper, ...
    A_compare.p, ...
    A_compare.CohensQ, ...
    numel(A_x1), ...
    strjoin(A_removed,", "), ...
    'VariableNames', { ...
        'X','Y', ...
        'DeltaR_ControllableMinusUncontrollable', ...
        'CI_Lower','CI_Upper','p','CohensQ', ...
        'N','RemovedParticipants'});

plot_two_session_correlation( ...
    A_x1,A_y1,A_x2,A_y2, ...
    colS1,colS2, ...
    x_lim_LAM,x_ticks_LAM, ...
    y_lim_RT,y_ticks_RT, ...
    'Volatility update rate','Reaction time (ms)', ...
    fullfile(figDir,'Correlation_Lambda_vs_MeanRT'), ...
    fig_pos,png_dpi, ...
    ms_dot,alpha_dot,lw_fit,lw_axes, ...
    fs_tick_x,fs_tick_y,fs_label_x,fs_label_y,fs_legend);

%% ========================================================================
% B. Learning rate vs RT by predictability
% ========================================================================

B_results = table();
B_comparisons = table();

for c = 1:3

    condition = condNames(c);
    conditionLabel = condLabels(c);

    [x1,y1,x2,y2,keepMask,removedIDs] = ...
        paired_completecase_3sd( ...
            lrCondS1(:,c),rtCondS1(:,c), ...
            lrCondS2(:,c),rtCondS2(:,c), ...
            ParticipantID,APPLY_3SD,SD_THRESHOLD);

    statsS1 = pearson_stats(x1,y1,ALPHA);
    statsS2 = pearson_stats(x2,y2,ALPHA);

    B_results = [
        B_results;
        add_predictability_columns( ...
            pack_correlation_row( ...
                "Controllable", ...
                "Learning rate", ...
                "Mean reaction time (ms)", ...
                statsS1), ...
            condition,conditionLabel);
        add_predictability_columns( ...
            pack_correlation_row( ...
                "Uncontrollable", ...
                "Learning rate", ...
                "Mean reaction time (ms)", ...
                statsS2), ...
            condition,conditionLabel)
        ]; %#ok<AGROW>

    compare = paired_bootstrap_correlation_difference( ...
        x1,y1,x2,y2,N_BOOT,ALPHA);

    comparisonRow = table( ...
        condition,conditionLabel, ...
        compare.DeltaR, ...
        compare.CI_Lower, ...
        compare.CI_Upper, ...
        compare.p, ...
        compare.CohensQ, ...
        numel(x1), ...
        strjoin(removedIDs,", "), ...
        'VariableNames', { ...
            'Predictability','PredictabilityLabel', ...
            'DeltaR_ControllableMinusUncontrollable', ...
            'CI_Lower','CI_Upper','p','CohensQ', ...
            'N','RemovedParticipants'});

    B_comparisons = [B_comparisons;comparisonRow]; %#ok<AGROW>

    figureBase = fullfile( ...
        figDir, ...
        sprintf('Correlation_LearningRate_vs_MeanRT_%s',condition));

    plot_two_session_correlation( ...
        x1,y1,x2,y2, ...
        colS1,colS2, ...
        x_lim_LR,x_ticks_LR, ...
        y_lim_RT,y_ticks_RT, ...
        'Learning rate','Reaction time (ms)', ...
        figureBase, ...
        fig_pos,png_dpi, ...
        ms_dot,alpha_dot,lw_fit,lw_axes, ...
        fs_tick_x,fs_tick_y,fs_label_x,fs_label_y,fs_legend);
end

%% ========================================================================
% C. Lambda vs RT by predictability
% ========================================================================

C_results = table();
C_comparisons = table();

for c = 1:3

    condition = condNames(c);
    conditionLabel = condLabels(c);

    [x1,y1,x2,y2,keepMask,removedIDs] = ...
        paired_completecase_3sd( ...
            lambdaMatchedS1,rtCondS1(:,c), ...
            lambdaMatchedS2,rtCondS2(:,c), ...
            ParticipantID,APPLY_3SD,SD_THRESHOLD);

    statsS1 = pearson_stats(x1,y1,ALPHA);
    statsS2 = pearson_stats(x2,y2,ALPHA);

    C_results = [
        C_results;
        add_predictability_columns( ...
            pack_correlation_row( ...
                "Controllable", ...
                "Volatility update rate", ...
                "Mean reaction time (ms)", ...
                statsS1), ...
            condition,conditionLabel);
        add_predictability_columns( ...
            pack_correlation_row( ...
                "Uncontrollable", ...
                "Volatility update rate", ...
                "Mean reaction time (ms)", ...
                statsS2), ...
            condition,conditionLabel)
        ]; %#ok<AGROW>

    compare = paired_bootstrap_correlation_difference( ...
        x1,y1,x2,y2,N_BOOT,ALPHA);

    comparisonRow = table( ...
        condition,conditionLabel, ...
        compare.DeltaR, ...
        compare.CI_Lower, ...
        compare.CI_Upper, ...
        compare.p, ...
        compare.CohensQ, ...
        numel(x1), ...
        strjoin(removedIDs,", "), ...
        'VariableNames', { ...
            'Predictability','PredictabilityLabel', ...
            'DeltaR_ControllableMinusUncontrollable', ...
            'CI_Lower','CI_Upper','p','CohensQ', ...
            'N','RemovedParticipants'});

    C_comparisons = [C_comparisons;comparisonRow]; %#ok<AGROW>

    figureBase = fullfile( ...
        figDir, ...
        sprintf('Correlation_Lambda_vs_MeanRT_%s',condition));

    plot_two_session_correlation( ...
        x1,y1,x2,y2, ...
        colS1,colS2, ...
        x_lim_LAM,x_ticks_LAM, ...
        y_lim_RT,y_ticks_RT, ...
        'Volatility update rate','Reaction time (ms)', ...
        figureBase, ...
        fig_pos,png_dpi, ...
        ms_dot,alpha_dot,lw_fit,lw_axes, ...
        fs_tick_x,fs_tick_y,fs_label_x,fs_label_y,fs_legend);
end

%% ========================================================================
% Analysis metadata
% ========================================================================

AnalysisInfo = table( ...
    ["Study group"; ...
     "Session 1"; ...
     "Session 2"; ...
     "RT column"; ...
     "Block column"; ...
     "Correlation method"; ...
     "Session-correlation comparison"; ...
     "Bootstrap repetitions"; ...
     "3-SD cleaning"; ...
     "SD threshold"; ...
     "HP blocks"; ...
     "MP blocks"; ...
     "UP blocks"; ...
     "VKF participant alignment"; ...
     "Trial-vector mismatch handling"], ...
    ["Healthy controls"; ...
     "Controllable"; ...
     "Uncontrollable"; ...
     string(RT_COL); ...
     string(BLOCK_COL); ...
     "Pearson correlation"; ...
     "Participant-paired bootstrap of correlation difference"; ...
     string(N_BOOT); ...
     string(APPLY_3SD); ...
     string(SD_THRESHOLD); ...
     strjoin(HP_blocks,", "); ...
     strjoin(MP_blocks,", "); ...
     strjoin(UP_blocks,", "); ...
     "VKF row = original workbook worksheet index"; ...
     "Analysis stops; no silent truncation"], ...
    'VariableNames',{'Item','Value'});

%% ========================================================================
% Export
% ========================================================================

if isfile(masterExcel)
    delete(masterExcel);
end

writetable(AnalysisInfo, ...
    masterExcel,'Sheet','Analysis_Info');

writetable(participantMapping, ...
    masterExcel,'Sheet','Participant_Mapping');

writetable(trialAudit, ...
    masterExcel,'Sheet','Trial_Audit');

writetable(participantSummary, ...
    masterExcel,'Sheet','Participant_Summary');

writetable(A_results, ...
    masterExcel,'Sheet','Lambda_OverallRT');

writetable(A_comparison, ...
    masterExcel,'Sheet','Lambda_OverallRT_Compare');

writetable(B_results, ...
    masterExcel,'Sheet','LearningRate_RT');

writetable(B_comparisons, ...
    masterExcel,'Sheet','LearningRate_Compare');

writetable(C_results, ...
    masterExcel,'Sheet','Lambda_RT_ByPred');

writetable(C_comparisons, ...
    masterExcel,'Sheet','Lambda_ByPred_Compare');

save(masterMat, ...
    'AnalysisInfo', ...
    'participantMapping','trialAudit','participantSummary', ...
    'lrS1','lrS2','lambdaS1','lambdaS2', ...
    'rtMeanS1','rtMeanS2', ...
    'rtCondS1','rtCondS2', ...
    'lrCondS1','lrCondS2', ...
    'A_results','A_comparison', ...
    'B_results','B_comparisons', ...
    'C_results','C_comparisons');

fprintf('\n============================================================\n');
fprintf('VKF / RT analysis complete.\n');
fprintf('============================================================\n');
fprintf('Matched participants: %d\n',nParticipants);
fprintf('Results workbook:\n%s\n',masterExcel);
fprintf('Figures:\n%s\n\n',figDir);


%% ========================================================================
% Local functions
% ========================================================================

function ids = normalize_subject_id(ids)

    ids = upper(strtrim(string(ids)));

    ids = regexprep(ids,'(?i)_S1_CLEANED$','');
    ids = regexprep(ids,'(?i)_S2_CLEANED$','');

    ids = regexprep(ids,'(?i)_S1$','');
    ids = regexprep(ids,'(?i)_S2$','');

    ids = regexprep(ids,'(?i)-S1$','');
    ids = regexprep(ids,'(?i)-S2$','');

    ids = regexprep(ids,'\s+','');
end


function x = to_numeric_vector(x)

    if isnumeric(x) || islogical(x)
        x = double(x(:));
    else
        x = str2double(string(x(:)));
    end
end


function [x1,y1,x2,y2,keepMask,removedIDs] = ...
    paired_completecase_3sd( ...
        x1Raw,y1Raw,x2Raw,y2Raw,participantIDs,apply3SD,threshold)

    x1Raw = double(x1Raw(:));
    y1Raw = double(y1Raw(:));

    x2Raw = double(x2Raw(:));
    y2Raw = double(y2Raw(:));

    participantIDs = string(participantIDs(:));

    n = numel(x1Raw);

    if any([ ...
            numel(y1Raw), ...
            numel(x2Raw), ...
            numel(y2Raw), ...
            numel(participantIDs)] ~= n)

        error('Paired correlation vectors have inconsistent participant counts.');
    end

    M = [x1Raw,y1Raw,x2Raw,y2Raw];

    completeMask = all(isfinite(M),2);

    if apply3SD && sum(completeMask) >= 5

        Mcomplete = M(completeMask,:);

        mu = mean(Mcomplete,1,'omitnan');

        sdValues = std(Mcomplete,0,1,'omitnan');
        sdValues(sdValues < eps) = eps;

        Z = abs((Mcomplete-mu)./sdValues);

        keepWithinComplete = ~any(Z > threshold,2);

        completeIndices = find(completeMask);

        keepMask = false(n,1);
        keepMask(completeIndices(keepWithinComplete)) = true;

    else

        keepMask = completeMask;
    end

    removedIDs = participantIDs(~keepMask);

    x1 = x1Raw(keepMask);
    y1 = y1Raw(keepMask);

    x2 = x2Raw(keepMask);
    y2 = y2Raw(keepMask);
end


function S = pearson_stats(x,y,alpha)

    x = double(x(:));
    y = double(y(:));

    valid = isfinite(x) & isfinite(y);

    x = x(valid);
    y = y(valid);

    N = numel(x);

    S.N = N;
    S.r = NaN;
    S.p = NaN;
    S.t = NaN;
    S.df = NaN;
    S.r2 = NaN;
    S.CI_Lower = NaN;
    S.CI_Upper = NaN;

    if N < 3 || std(x) == 0 || std(y) == 0
        return
    end

    [r,p] = corr( ...
        x,y, ...
        'Type','Pearson', ...
        'Rows','complete');

    S.r = r;
    S.p = p;

    S.df = N-2;
    S.r2 = r^2;

    if abs(r) < 1
        S.t = r*sqrt((N-2)/(1-r^2));
    end

    if N > 3 && abs(r) < 1

        z = atanh(r);
        se = 1/sqrt(N-3);

        zCritical = norminv(1-alpha/2);

        S.CI_Lower = tanh(z-zCritical*se);
        S.CI_Upper = tanh(z+zCritical*se);
    end
end


function T = pack_correlation_row(sessionName,xName,yName,S)

    T = table( ...
        string(sessionName), ...
        string(xName), ...
        string(yName), ...
        S.N,S.r,S.CI_Lower,S.CI_Upper, ...
        S.t,S.df,S.p,S.r2, ...
        'VariableNames', { ...
            'Controllability','X','Y', ...
            'N','r','r_CI_Lower','r_CI_Upper', ...
            't','df','p','r2'});
end


function T = add_predictability_columns( ...
    T,predictability,predictabilityLabel)

    T.Predictability = repmat( ...
        string(predictability),height(T),1);

    T.PredictabilityLabel = repmat( ...
        string(predictabilityLabel),height(T),1);

    T = movevars( ...
        T, ...
        {'Predictability','PredictabilityLabel'}, ...
        'Before','Controllability');
end


function R = paired_bootstrap_correlation_difference( ...
    x1,y1,x2,y2,nBootstrap,alpha)

    x1 = double(x1(:));
    y1 = double(y1(:));

    x2 = double(x2(:));
    y2 = double(y2(:));

    n = numel(x1);

    R.DeltaR = NaN;
    R.CI_Lower = NaN;
    R.CI_Upper = NaN;
    R.p = NaN;
    R.CohensQ = NaN;

    if n < 4
        return
    end

    r1 = corr(x1,y1,'Type','Pearson','Rows','complete');
    r2 = corr(x2,y2,'Type','Pearson','Rows','complete');

    R.DeltaR = r1-r2;

    r1Safe = max(min(r1,1-eps),-1+eps);
    r2Safe = max(min(r2,1-eps),-1+eps);

    R.CohensQ = atanh(r1Safe)-atanh(r2Safe);

    bootstrapDelta = nan(nBootstrap,1);

    for b = 1:nBootstrap

        sampleIndex = randi(n,n,1);

        xb1 = x1(sampleIndex);
        yb1 = y1(sampleIndex);

        xb2 = x2(sampleIndex);
        yb2 = y2(sampleIndex);

        if std(xb1) == 0 || std(yb1) == 0 || ...
           std(xb2) == 0 || std(yb2) == 0

            continue
        end

        rb1 = corr( ...
            xb1,yb1, ...
            'Type','Pearson', ...
            'Rows','complete');

        rb2 = corr( ...
            xb2,yb2, ...
            'Type','Pearson', ...
            'Rows','complete');

        bootstrapDelta(b) = rb1-rb2;
    end

    bootstrapDelta = bootstrapDelta(isfinite(bootstrapDelta));

    if isempty(bootstrapDelta)
        return
    end

    ciPercentiles = 100*[alpha/2,1-alpha/2];

    ci = prctile(bootstrapDelta,ciPercentiles);

    R.CI_Lower = ci(1);
    R.CI_Upper = ci(2);

    proportionLE0 = mean(bootstrapDelta <= 0);
    proportionGE0 = mean(bootstrapDelta >= 0);

    R.p = min( ...
        1, ...
        2*min(proportionLE0,proportionGE0));
end


function plot_two_session_correlation( ...
    x1,y1,x2,y2, ...
    colorS1,colorS2, ...
    xLimits,xTicks, ...
    yLimits,yTicks, ...
    xLabelText,yLabelText, ...
    outputBase, ...
    figurePosition,pngDPI, ...
    dotSize,dotAlpha, ...
    fitLineWidth,axisLineWidth, ...
    fsTickX,fsTickY, ...
    fsLabelX,fsLabelY,fsLegend)

    fig = figure( ...
        'Color','w', ...
        'Position',figurePosition);

    ax = axes(fig);
    hold(ax,'on');

    hS1 = scatter( ...
        ax,x1,y1,dotSize,colorS1,'filled', ...
        'MarkerEdgeColor','k', ...
        'MarkerFaceAlpha',dotAlpha);

    hS2 = scatter( ...
        ax,x2,y2,dotSize,colorS2,'filled', ...
        'MarkerEdgeColor','k', ...
        'MarkerFaceAlpha',dotAlpha);

    add_fit_line( ...
        ax,x1,y1,colorS1,fitLineWidth,xLimits);

    add_fit_line( ...
        ax,x2,y2,colorS2,fitLineWidth,xLimits);

    ax.XAxis.FontSize = fsTickX;
    ax.YAxis.FontSize = fsTickY;

    ax.LineWidth = axisLineWidth;
    ax.TickDir = 'out';
    ax.Box = 'off';

    ax.XGrid = 'off';
    ax.YGrid = 'off';

    xlim(ax,xLimits);
    ylim(ax,yLimits);

    xticks(ax,xTicks);
    yticks(ax,yTicks);

    xlabel(ax,xLabelText, ...
        'FontSize',fsLabelX, ...
        'FontWeight','bold');

    ylabel(ax,yLabelText, ...
        'FontSize',fsLabelY, ...
        'FontWeight','bold');

    legend(ax,[hS1,hS2], ...
        {'Controllable','Uncontrollable'}, ...
        'Location','northeast', ...
        'Box','off', ...
        'FontSize',fsLegend);

    exportgraphics( ...
        fig,[outputBase '.png'], ...
        'Resolution',pngDPI);

    exportgraphics( ...
        fig,[outputBase '.tiff'], ...
        'Resolution',pngDPI);

    exportgraphics( ...
        fig,[outputBase '.pdf'], ...
        'ContentType','vector');

    close(fig);
end


function add_fit_line( ...
    ax,x,y,lineColor,lineWidth,xLimits)

    x = double(x(:));
    y = double(y(:));

    valid = isfinite(x) & isfinite(y);

    x = x(valid);
    y = y(valid);

    if numel(x) < 2 || std(x) == 0
        return
    end

    coefficients = polyfit(x,y,1);

    xFit = linspace( ...
        xLimits(1),xLimits(2),200);

    yFit = polyval(coefficients,xFit);

    plot( ...
        ax,xFit,yFit, ...
        'Color',lineColor, ...
        'LineWidth',lineWidth);
end
