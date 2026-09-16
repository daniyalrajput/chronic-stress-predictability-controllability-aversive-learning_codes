%% VKF learning-rate / volatility-update-rate associations with accuracy
% Chronic stress study — publication/repository version
%
% Purpose
%   Examine associations between computational learning quantities from the
%   Volatile Kalman Filter (VKF) and prediction accuracy in the Chronic
%   stress group, comparing controllable and uncontrollable sessions.
%
% Analyses
%   A. Volatility update rate (lambda) vs overall prediction accuracy
%
%   B. Trial-wise learning rate (Kalman gain) vs prediction accuracy,
%      separately for:
%          - Highly predictable (HP)
%          - Moderately predictable (MP)
%          - Unpredictable (UP)
%
%   C. Volatility update rate (lambda) vs prediction accuracy separately
%      for HP, MP, and UP blocks
%
% Sessions
%   S1 = Controllable
%   S2 = Uncontrollable
%
% Statistical approach
%   - Pearson correlations are estimated separately for S1 and S2.
%   - S1 and S2 are compared using a participant-paired bootstrap of the
%     difference in correlation coefficients (r_S1 - r_S2).
%   - Cohen's q is also reported for the S1-vs-S2 correlation difference.
%   - Optional >3 SD cleaning is applied jointly across the four paired
%     variables entering each S1-vs-S2 comparison so that the same
%     participants are retained in both sessions.
%
% Accuracy / block mapping
%   Accuracy column = column 13 of each participant worksheet
%   Block label     = column 2
%
%   Highly predictable:
%       Block1, Block5, Block8, Block10
%
%   Moderately predictable:
%       Block3, Block4, Block7, Block9
%
%   Unpredictable:
%       Block2, Block6
%
% Participant alignment
%   Participant IDs are parsed from worksheet names (e.g., CS01_S1_cleaned).
%   S1 and S2 worksheets are matched by numeric participant ID.
%
%   VKF rows are then indexed using the original worksheet order. This
%   preserves the alignment assumption used in the original analysis:
%   row k of kgain_mat/lambda_vec corresponds to worksheet k in the
%   respective behavioral workbook.
%
%
% Required directory structure
%
%   data/VKF_Accuracy_Chronic/
%       Chronic_correct_incorrect_scr_S1.xlsx
%       Chronic_correct_incorrect_scr_S2.xlsx
%       CS_vkf_all_results_s1.mat
%       CS_vkf_all_results_S2.mat
%
% Required MAT-file variables
%   kgain_mat
%   lambda_vec
%
% -------------------------------------------------------------------------
% Daniyal Rajput
% Chronic stress / probabilistic aversive-learning study
% -------------------------------------------------------------------------

clear; clc; close all;
rng(1,'twister');

%% Paths
scriptDir = fileparts(mfilename('fullpath'));
if isempty(scriptDir)
    scriptDir = pwd;
end

dataDir = fullfile(scriptDir,'data','VKF_Accuracy_Chronic');

outDir   = fullfile(scriptDir,'results','VKF_Accuracy_Chronic');
figDir   = fullfile(outDir,'figures');
statsDir = fullfile(outDir,'stats');

if ~exist(outDir,'dir'),   mkdir(outDir);   end
if ~exist(figDir,'dir'),   mkdir(figDir);   end
if ~exist(statsDir,'dir'), mkdir(statsDir); end

behaviorS1File = fullfile(dataDir,'Chronic_correct_incorrect_scr_S1.xlsx');
behaviorS2File = fullfile(dataDir,'Chronic_correct_incorrect_scr_S2.xlsx');

vkfS1File = fullfile(dataDir,'CS_vkf_all_results_s1.mat');
vkfS2File = fullfile(dataDir,'CS_vkf_all_results_S2.mat');

assert(isfile(behaviorS1File),'Missing file: %s',behaviorS1File);
assert(isfile(behaviorS2File),'Missing file: %s',behaviorS2File);
assert(isfile(vkfS1File),'Missing file: %s',vkfS1File);
assert(isfile(vkfS2File),'Missing file: %s',vkfS2File);

masterExcel = fullfile(statsDir,'VKF_Accuracy_Chronic_results.xlsx');
masterMat   = fullfile(statsDir,'VKF_Accuracy_Chronic_results.mat');

%% Behavioral-data columns
accuracyColumn = 13;
blockColumn = 2;

%% Predictability block definitions
HPBlocks = ["Block1","Block5","Block8","Block10"];
MPBlocks = ["Block3","Block4","Block7","Block9"];
UPBlocks = ["Block2","Block6"];

predictabilityNames = ["HP","MP","UP"];
predictabilityLabels = [ ...
    "Highly predictable", ...
    "Moderately predictable", ...
    "Unpredictable"];

%% Analysis settings
apply3SD = true;
sdThreshold = 3;

nBootstrap = 5000;
alpha = 0.05;

%% Figure settings
colorS1 = [0.00 0.25 0.55];
colorS2 = [0.85 0.33 0.00];

fsTickX  = 22;
fsTickY  = 22;
fsLabelX = 24;
fsLabelY = 24;
fsLegend = 20;

axisLineWidth = 1.6;
fitLineWidth  = 2.2;

dotSize  = 55;
dotAlpha = 0.85;

pngDPI = 600;

figurePosition = [350 250 620 540];

% Fixed axes retained from the original figure preparation.
accuracyYLim   = [30 90];
accuracyYTicks = 30:15:90;

lambdaXLim   = [0 0.9];
lambdaXTicks = 0:0.3:0.9;

learningRateXLim   = [0.5 0.9];
learningRateXTicks = 0.5:0.1:0.9;

%% ========================================================================
% Load VKF results
% ========================================================================

VKF1 = load(vkfS1File);
VKF2 = load(vkfS2File);

assert(isfield(VKF1,'kgain_mat') && isfield(VKF1,'lambda_vec'), ...
    'S1 VKF file must contain kgain_mat and lambda_vec.');

assert(isfield(VKF2,'kgain_mat') && isfield(VKF2,'lambda_vec'), ...
    'S2 VKF file must contain kgain_mat and lambda_vec.');

learningRateS1 = double(VKF1.kgain_mat);
learningRateS2 = double(VKF2.kgain_mat);

lambdaS1 = double(VKF1.lambda_vec(:));
lambdaS2 = double(VKF2.lambda_vec(:));

assert(size(learningRateS1,1) == numel(lambdaS1), ...
    'S1 kgain_mat rows and lambda_vec length do not match.');

assert(size(learningRateS2,1) == numel(lambdaS2), ...
    'S2 kgain_mat rows and lambda_vec length do not match.');

%% ========================================================================
% Read workbook sheet names and match participants across sessions
% ========================================================================

sheetsS1 = string(sheetnames(behaviorS1File));
sheetsS2 = string(sheetnames(behaviorS2File));

assert(~isempty(sheetsS1),'No worksheets found in S1 workbook.');
assert(~isempty(sheetsS2),'No worksheets found in S2 workbook.');

subjectNumS1 = nan(numel(sheetsS1),1);
subjectNumS2 = nan(numel(sheetsS2),1);

for i = 1:numel(sheetsS1)
    subjectNumS1(i) = extract_subject_number(sheetsS1(i));
end

for i = 1:numel(sheetsS2)
    subjectNumS2(i) = extract_subject_number(sheetsS2(i));
end

validS1 = ~isnan(subjectNumS1);
validS2 = ~isnan(subjectNumS2);

if any(~validS1)
    warning('Ignoring S1 worksheets whose participant ID could not be parsed.');
    disp(sheetsS1(~validS1));
end

if any(~validS2)
    warning('Ignoring S2 worksheets whose participant ID could not be parsed.');
    disp(sheetsS2(~validS2));
end

sheetsS1Valid = sheetsS1(validS1);
sheetsS2Valid = sheetsS2(validS2);

subjectNumS1Valid = subjectNumS1(validS1);
subjectNumS2Valid = subjectNumS2(validS2);

[commonSubjectNumbers,idxS1Valid,idxS2Valid] = intersect( ...
    subjectNumS1Valid,subjectNumS2Valid,'stable');

if isempty(commonSubjectNumbers)
    error('No participants could be matched across S1 and S2.');
end

matchedSheetsS1 = sheetsS1Valid(idxS1Valid);
matchedSheetsS2 = sheetsS2Valid(idxS2Valid);

nParticipants = numel(commonSubjectNumbers);

fprintf('Matched participants across S1 and S2: %d\n',nParticipants);

%% Map matched worksheets back to original workbook order
% VKF rows are assumed to follow the original workbook worksheet order.

originalIndexS1 = zeros(nParticipants,1);
originalIndexS2 = zeros(nParticipants,1);

for k = 1:nParticipants
    originalIndexS1(k) = find(sheetsS1 == matchedSheetsS1(k),1,'first');
    originalIndexS2(k) = find(sheetsS2 == matchedSheetsS2(k),1,'first');
end

assert(all(originalIndexS1 > 0), ...
    'Could not map all matched S1 sheets to original workbook order.');

assert(all(originalIndexS2 > 0), ...
    'Could not map all matched S2 sheets to original workbook order.');

assert(size(learningRateS1,1) >= max(originalIndexS1), ...
    ['S1 VKF rows (%d) do not cover the required workbook index (%d). ' ...
     'Check VKF-to-workbook participant ordering.'], ...
     size(learningRateS1,1),max(originalIndexS1));

assert(size(learningRateS2,1) >= max(originalIndexS2), ...
    ['S2 VKF rows (%d) do not cover the required workbook index (%d). ' ...
     'Check VKF-to-workbook participant ordering.'], ...
     size(learningRateS2,1),max(originalIndexS2));

%% Save participant mapping for reproducibility
ParticipantID = "CS" + compose("%02d",commonSubjectNumbers);

participantMapping = table( ...
    ParticipantID, ...
    commonSubjectNumbers(:), ...
    matchedSheetsS1(:), ...
    originalIndexS1(:), ...
    matchedSheetsS2(:), ...
    originalIndexS2(:), ...
    'VariableNames', { ...
        'ParticipantID','ParticipantNumber', ...
        'S1_Worksheet','S1_WorkbookIndex', ...
        'S2_Worksheet','S2_WorkbookIndex'});

%% ========================================================================
% Extract participant-level accuracy and VKF quantities
% ========================================================================

overallAccuracyS1 = nan(nParticipants,1);
overallAccuracyS2 = nan(nParticipants,1);

accuracyByPredictabilityS1 = nan(nParticipants,3);
accuracyByPredictabilityS2 = nan(nParticipants,3);

learningRateByPredictabilityS1 = nan(nParticipants,3);
learningRateByPredictabilityS2 = nan(nParticipants,3);

trialCounts = table();

for k = 1:nParticipants

    sheetS1 = matchedSheetsS1(k);
    sheetS2 = matchedSheetsS2(k);

    T1 = readtable(behaviorS1File, ...
        'Sheet',sheetS1, ...
        'VariableNamingRule','preserve');

    T2 = readtable(behaviorS2File, ...
        'Sheet',sheetS2, ...
        'VariableNamingRule','preserve');

    assert(width(T1) >= max(accuracyColumn,blockColumn), ...
        'S1 worksheet %s does not contain required columns.',sheetS1);

    assert(width(T2) >= max(accuracyColumn,blockColumn), ...
        'S2 worksheet %s does not contain required columns.',sheetS2);

    accuracyS1 = double(T1{:,accuracyColumn});
    accuracyS2 = double(T2{:,accuracyColumn});

    blocksS1 = strtrim(string(T1{:,blockColumn}));
    blocksS2 = strtrim(string(T2{:,blockColumn}));

    learningRateParticipantS1 = ...
        learningRateS1(originalIndexS1(k),:).';

    learningRateParticipantS2 = ...
        learningRateS2(originalIndexS2(k),:).';

    % Strict trial alignment: do not silently truncate.
    if numel(accuracyS1) ~= numel(learningRateParticipantS1)
        error(['Trial-count mismatch for %s, Controllable session.\n' ...
               'Behavioral rows = %d; VKF learning-rate values = %d.'], ...
               ParticipantID(k), ...
               numel(accuracyS1), ...
               numel(learningRateParticipantS1));
    end

    if numel(accuracyS2) ~= numel(learningRateParticipantS2)
        error(['Trial-count mismatch for %s, Uncontrollable session.\n' ...
               'Behavioral rows = %d; VKF learning-rate values = %d.'], ...
               ParticipantID(k), ...
               numel(accuracyS2), ...
               numel(learningRateParticipantS2));
    end

    overallAccuracyS1(k) = 100*mean(accuracyS1,'omitnan');
    overallAccuracyS2(k) = 100*mean(accuracyS2,'omitnan');

    masksS1 = { ...
        ismember(blocksS1,HPBlocks), ...
        ismember(blocksS1,MPBlocks), ...
        ismember(blocksS1,UPBlocks)};

    masksS2 = { ...
        ismember(blocksS2,HPBlocks), ...
        ismember(blocksS2,MPBlocks), ...
        ismember(blocksS2,UPBlocks)};

    for c = 1:3

        validTrialsS1 = masksS1{c} & ...
            isfinite(accuracyS1) & ...
            isfinite(learningRateParticipantS1);

        validTrialsS2 = masksS2{c} & ...
            isfinite(accuracyS2) & ...
            isfinite(learningRateParticipantS2);

        if any(validTrialsS1)
            accuracyByPredictabilityS1(k,c) = ...
                100*mean(accuracyS1(validTrialsS1),'omitnan');

            learningRateByPredictabilityS1(k,c) = ...
                mean(learningRateParticipantS1(validTrialsS1),'omitnan');
        end

        if any(validTrialsS2)
            accuracyByPredictabilityS2(k,c) = ...
                100*mean(accuracyS2(validTrialsS2),'omitnan');

            learningRateByPredictabilityS2(k,c) = ...
                mean(learningRateParticipantS2(validTrialsS2),'omitnan');
        end
    end

    trialRow = table( ...
        ParticipantID(k), ...
        height(T1), ...
        numel(learningRateParticipantS1), ...
        height(T2), ...
        numel(learningRateParticipantS2), ...
        'VariableNames', { ...
            'ParticipantID', ...
            'S1_BehavioralTrials','S1_VKFTrials', ...
            'S2_BehavioralTrials','S2_VKFTrials'});

    trialCounts = [trialCounts;trialRow]; %#ok<AGROW>
end

%% Align participant-level lambda values
lambdaMatchedS1 = lambdaS1(originalIndexS1);
lambdaMatchedS2 = lambdaS2(originalIndexS2);

%% Participant-level summary table
participantSummary = table( ...
    ParticipantID, ...
    lambdaMatchedS1,lambdaMatchedS2, ...
    overallAccuracyS1,overallAccuracyS2, ...
    accuracyByPredictabilityS1(:,1), ...
    accuracyByPredictabilityS1(:,2), ...
    accuracyByPredictabilityS1(:,3), ...
    accuracyByPredictabilityS2(:,1), ...
    accuracyByPredictabilityS2(:,2), ...
    accuracyByPredictabilityS2(:,3), ...
    learningRateByPredictabilityS1(:,1), ...
    learningRateByPredictabilityS1(:,2), ...
    learningRateByPredictabilityS1(:,3), ...
    learningRateByPredictabilityS2(:,1), ...
    learningRateByPredictabilityS2(:,2), ...
    learningRateByPredictabilityS2(:,3), ...
    'VariableNames', { ...
        'ParticipantID', ...
        'Lambda_Controllable','Lambda_Uncontrollable', ...
        'AccuracyOverall_Controllable','AccuracyOverall_Uncontrollable', ...
        'Accuracy_HP_Controllable','Accuracy_MP_Controllable','Accuracy_UP_Controllable', ...
        'Accuracy_HP_Uncontrollable','Accuracy_MP_Uncontrollable','Accuracy_UP_Uncontrollable', ...
        'LearningRate_HP_Controllable','LearningRate_MP_Controllable','LearningRate_UP_Controllable', ...
        'LearningRate_HP_Uncontrollable','LearningRate_MP_Uncontrollable','LearningRate_UP_Uncontrollable'});

%% ========================================================================
% A. Volatility update rate (lambda) vs overall accuracy
% ========================================================================

[A_S1_x,A_S1_y,A_S2_x,A_S2_y,A_keep,A_removed] = ...
    paired_completecase_3sd( ...
        lambdaMatchedS1,overallAccuracyS1, ...
        lambdaMatchedS2,overallAccuracyS2, ...
        ParticipantID,apply3SD,sdThreshold);

A_statsS1 = pearson_stats(A_S1_x,A_S1_y,alpha);
A_statsS2 = pearson_stats(A_S2_x,A_S2_y,alpha);

A_results = [
    pack_correlation_row( ...
        "Controllable","Volatility update rate", ...
        "Overall accuracy (%)",A_statsS1);
    pack_correlation_row( ...
        "Uncontrollable","Volatility update rate", ...
        "Overall accuracy (%)",A_statsS2)
    ];

A_compare = paired_bootstrap_correlation_difference( ...
    A_S1_x,A_S1_y,A_S2_x,A_S2_y,nBootstrap,alpha);

A_comparison = table( ...
    "Volatility update rate", ...
    "Overall accuracy (%)", ...
    A_compare.DeltaR, ...
    A_compare.CI_Lower, ...
    A_compare.CI_Upper, ...
    A_compare.p, ...
    A_compare.CohensQ, ...
    numel(A_S1_x), ...
    strjoin(A_removed,", "), ...
    'VariableNames', { ...
        'X','Y','DeltaR_ControllableMinusUncontrollable', ...
        'CI_Lower','CI_Upper','p','CohensQ', ...
        'N','RemovedParticipants'});

%% Plot A
plot_two_session_correlation( ...
    A_S1_x,A_S1_y,A_S2_x,A_S2_y, ...
    colorS1,colorS2, ...
    lambdaXLim,lambdaXTicks, ...
    accuracyYLim,accuracyYTicks, ...
    'Volatility update rate','Accuracy (%)', ...
    fullfile(figDir,'Correlation_Lambda_vs_OverallAccuracy'), ...
    figurePosition,pngDPI, ...
    dotSize,dotAlpha,fitLineWidth,axisLineWidth, ...
    fsTickX,fsTickY,fsLabelX,fsLabelY,fsLegend);

%% ========================================================================
% B. Learning rate vs accuracy by predictability
% ========================================================================

B_results = table();
B_comparisons = table();

for c = 1:3

    cond = predictabilityNames(c);
    condLabel = predictabilityLabels(c);

    [x1,y1,x2,y2,keepMask,removedIDs] = ...
        paired_completecase_3sd( ...
            learningRateByPredictabilityS1(:,c), ...
            accuracyByPredictabilityS1(:,c), ...
            learningRateByPredictabilityS2(:,c), ...
            accuracyByPredictabilityS2(:,c), ...
            ParticipantID,apply3SD,sdThreshold);

    statsS1 = pearson_stats(x1,y1,alpha);
    statsS2 = pearson_stats(x2,y2,alpha);

    B_results = [
        B_results;
        add_condition_column( ...
            pack_correlation_row( ...
                "Controllable", ...
                "Learning rate", ...
                "Accuracy (%)",statsS1), ...
            cond,condLabel);
        add_condition_column( ...
            pack_correlation_row( ...
                "Uncontrollable", ...
                "Learning rate", ...
                "Accuracy (%)",statsS2), ...
            cond,condLabel)
        ]; %#ok<AGROW>

    compare = paired_bootstrap_correlation_difference( ...
        x1,y1,x2,y2,nBootstrap,alpha);

    comparisonRow = table( ...
        cond,condLabel, ...
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

    figureBase = fullfile(figDir, ...
        sprintf('Correlation_LearningRate_vs_Accuracy_%s',cond));

    plot_two_session_correlation( ...
        x1,y1,x2,y2, ...
        colorS1,colorS2, ...
        learningRateXLim,learningRateXTicks, ...
        accuracyYLim,accuracyYTicks, ...
        'Learning rate','Accuracy (%)', ...
        figureBase, ...
        figurePosition,pngDPI, ...
        dotSize,dotAlpha,fitLineWidth,axisLineWidth, ...
        fsTickX,fsTickY,fsLabelX,fsLabelY,fsLegend);
end

%% ========================================================================
% C. Volatility update rate (lambda) vs accuracy by predictability
% ========================================================================

C_results = table();
C_comparisons = table();

for c = 1:3

    cond = predictabilityNames(c);
    condLabel = predictabilityLabels(c);

    [x1,y1,x2,y2,keepMask,removedIDs] = ...
        paired_completecase_3sd( ...
            lambdaMatchedS1, ...
            accuracyByPredictabilityS1(:,c), ...
            lambdaMatchedS2, ...
            accuracyByPredictabilityS2(:,c), ...
            ParticipantID,apply3SD,sdThreshold);

    statsS1 = pearson_stats(x1,y1,alpha);
    statsS2 = pearson_stats(x2,y2,alpha);

    C_results = [
        C_results;
        add_condition_column( ...
            pack_correlation_row( ...
                "Controllable", ...
                "Volatility update rate", ...
                "Accuracy (%)",statsS1), ...
            cond,condLabel);
        add_condition_column( ...
            pack_correlation_row( ...
                "Uncontrollable", ...
                "Volatility update rate", ...
                "Accuracy (%)",statsS2), ...
            cond,condLabel)
        ]; %#ok<AGROW>

    compare = paired_bootstrap_correlation_difference( ...
        x1,y1,x2,y2,nBootstrap,alpha);

    comparisonRow = table( ...
        cond,condLabel, ...
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

    figureBase = fullfile(figDir, ...
        sprintf('Correlation_Lambda_vs_Accuracy_%s',cond));

    plot_two_session_correlation( ...
        x1,y1,x2,y2, ...
        colorS1,colorS2, ...
        lambdaXLim,lambdaXTicks, ...
        accuracyYLim,accuracyYTicks, ...
        'Volatility update rate','Accuracy (%)', ...
        figureBase, ...
        figurePosition,pngDPI, ...
        dotSize,dotAlpha,fitLineWidth,axisLineWidth, ...
        fsTickX,fsTickY,fsLabelX,fsLabelY,fsLegend);
end

%% ========================================================================
% Analysis metadata
% ========================================================================

AnalysisInfo = table( ...
    ["Study group"; ...
     "Session 1"; ...
     "Session 2"; ...
     "Correlation method"; ...
     "S1-vs-S2 comparison"; ...
     "Bootstrap repetitions"; ...
     "3-SD cleaning"; ...
     "SD threshold"; ...
     "Predictability HP blocks"; ...
     "Predictability MP blocks"; ...
     "Predictability UP blocks"; ...
     "VKF-participant alignment"; ...
     "Trial-vector mismatch handling"], ...
    ["Chronic stress"; ...
     "Controllable"; ...
     "Uncontrollable"; ...
     "Pearson correlation"; ...
     "Participant-paired bootstrap of correlation difference"; ...
     string(nBootstrap); ...
     string(apply3SD); ...
     string(sdThreshold); ...
     strjoin(HPBlocks,", "); ...
     strjoin(MPBlocks,", "); ...
     strjoin(UPBlocks,", "); ...
     "VKF row = original workbook worksheet index"; ...
     "Analysis stops; no silent truncation"], ...
    'VariableNames',{'Item','Value'});

%% ========================================================================
% Export results
% ========================================================================

if isfile(masterExcel)
    delete(masterExcel);
end

writetable(AnalysisInfo,masterExcel,'Sheet','Analysis_Info');
writetable(participantMapping,masterExcel,'Sheet','Participant_Mapping');
writetable(trialCounts,masterExcel,'Sheet','Trial_Counts');
writetable(participantSummary,masterExcel,'Sheet','Participant_Summary');

writetable(A_results,masterExcel,'Sheet','Lambda_OverallAccuracy');
writetable(A_comparison,masterExcel,'Sheet','Lambda_Overall_Compare');

writetable(B_results,masterExcel,'Sheet','LearningRate_Accuracy');
writetable(B_comparisons,masterExcel,'Sheet','LearningRate_Compare');

writetable(C_results,masterExcel,'Sheet','Lambda_Accuracy_ByPred');
writetable(C_comparisons,masterExcel,'Sheet','Lambda_ByPred_Compare');

save(masterMat, ...
    'AnalysisInfo', ...
    'participantMapping','trialCounts','participantSummary', ...
    'learningRateS1','learningRateS2', ...
    'lambdaS1','lambdaS2', ...
    'overallAccuracyS1','overallAccuracyS2', ...
    'accuracyByPredictabilityS1','accuracyByPredictabilityS2', ...
    'learningRateByPredictabilityS1','learningRateByPredictabilityS2', ...
    'A_results','A_comparison', ...
    'B_results','B_comparisons', ...
    'C_results','C_comparisons');

fprintf('\n============================================================\n');
fprintf('VKF / accuracy analysis completed.\n');
fprintf('============================================================\n');
fprintf('Matched participants: %d\n',nParticipants);
fprintf('Results workbook:\n%s\n',masterExcel);
fprintf('Figures:\n%s\n\n',figDir);


%% ========================================================================
% Local functions
% ========================================================================

function id = extract_subject_number(sheetName)

    text = char(string(sheetName));

    % Prefer IDs following CS (e.g., CS01, CS34).
    token = regexp(text,'(?i)CS[_\- ]*0*(\d+)','tokens','once');

    if isempty(token)
        % Fallback: first integer appearing in the worksheet name.
        token = regexp(text,'(\d+)','tokens','once');
    end

    if isempty(token)
        id = NaN;
    else
        id = str2double(token{1});
    end
end


function [x1,y1,x2,y2,keepMask,removedIDs] = ...
    paired_completecase_3sd(x1Raw,y1Raw,x2Raw,y2Raw,participantIDs,apply3SD,threshold)

    x1Raw = double(x1Raw(:));
    y1Raw = double(y1Raw(:));
    x2Raw = double(x2Raw(:));
    y2Raw = double(y2Raw(:));

    participantIDs = string(participantIDs(:));

    n = numel(x1Raw);

    if any([numel(y1Raw),numel(x2Raw),numel(y2Raw),numel(participantIDs)] ~= n)
        error('Paired correlation vectors have inconsistent participant counts.');
    end

    M = [x1Raw,y1Raw,x2Raw,y2Raw];

    keepComplete = all(isfinite(M),2);

    if apply3SD && sum(keepComplete) >= 5

        Mcomplete = M(keepComplete,:);

        mu = mean(Mcomplete,1,'omitnan');
        sd = std(Mcomplete,0,1,'omitnan');
        sd(sd < eps) = eps;

        Z = abs((Mcomplete-mu)./sd);

        keepWithinComplete = ~any(Z > threshold,2);

        completeIndices = find(keepComplete);

        keepMask = false(n,1);
        keepMask(completeIndices(keepWithinComplete)) = true;

    else
        keepMask = keepComplete;
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

    [r,p] = corr(x,y,'Type','Pearson','Rows','complete');

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
        S.N,S.r,S.CI_Lower,S.CI_Upper,S.t,S.df,S.p,S.r2, ...
        'VariableNames', { ...
            'Controllability','X','Y', ...
            'N','r','r_CI_Lower','r_CI_Upper', ...
            't','df','p','r2'});
end


function T = add_condition_column(T,conditionName,conditionLabel)

    T.Predictability = repmat(string(conditionName),height(T),1);
    T.PredictabilityLabel = repmat(string(conditionLabel),height(T),1);

    T = movevars(T, ...
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

    % Cohen's q uses the Fisher-z difference.
    r1Safe = max(min(r1,1-eps),-1+eps);
    r2Safe = max(min(r2,1-eps),-1+eps);

    R.CohensQ = atanh(r1Safe)-atanh(r2Safe);

    bootstrapDelta = nan(nBootstrap,1);

    for b = 1:nBootstrap

        idx = randi(n,n,1);

        xb1 = x1(idx);
        yb1 = y1(idx);
        xb2 = x2(idx);
        yb2 = y2(idx);

        if std(xb1) == 0 || std(yb1) == 0 || ...
           std(xb2) == 0 || std(yb2) == 0
            continue
        end

        rb1 = corr(xb1,yb1,'Type','Pearson','Rows','complete');
        rb2 = corr(xb2,yb2,'Type','Pearson','Rows','complete');

        bootstrapDelta(b) = rb1-rb2;
    end

    bootstrapDelta = bootstrapDelta(isfinite(bootstrapDelta));

    if isempty(bootstrapDelta)
        return
    end

    ciPercent = 100*[alpha/2,1-alpha/2];

    ci = prctile(bootstrapDelta,ciPercent);

    R.CI_Lower = ci(1);
    R.CI_Upper = ci(2);

    % Two-sided bootstrap p-value based on the proportion on either side
    % of zero.
    proportionLE0 = mean(bootstrapDelta <= 0);
    proportionGE0 = mean(bootstrapDelta >= 0);

    R.p = min(1,2*min(proportionLE0,proportionGE0));
end


function plot_two_session_correlation( ...
    x1,y1,x2,y2, ...
    colorS1,colorS2, ...
    xLimits,xTicks,yLimits,yTicks, ...
    xLabelText,yLabelText, ...
    outputBase, ...
    figurePosition,pngDPI, ...
    dotSize,dotAlpha,fitLineWidth,axisLineWidth, ...
    fsTickX,fsTickY,fsLabelX,fsLabelY,fsLegend)

    fig = figure( ...
        'Color','w', ...
        'Position',figurePosition);

    ax = axes(fig);
    hold(ax,'on');

    hS1 = scatter(ax,x1,y1,dotSize,colorS1,'filled', ...
        'MarkerEdgeColor','k', ...
        'MarkerFaceAlpha',dotAlpha);

    hS2 = scatter(ax,x2,y2,dotSize,colorS2,'filled', ...
        'MarkerEdgeColor','k', ...
        'MarkerFaceAlpha',dotAlpha);

    add_fit_line(ax,x1,y1,colorS1,fitLineWidth,xLimits);
    add_fit_line(ax,x2,y2,colorS2,fitLineWidth,xLimits);

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
        'Location','best', ...
        'Box','off', ...
        'FontSize',fsLegend);

    exportgraphics(fig,[outputBase '.png'], ...
        'Resolution',pngDPI);

    exportgraphics(fig,[outputBase '.tiff'], ...
        'Resolution',pngDPI);

    exportgraphics(fig,[outputBase '.pdf'], ...
        'ContentType','vector');

    close(fig);
end


function add_fit_line(ax,x,y,lineColor,lineWidth,xLimits)

    x = double(x(:));
    y = double(y(:));

    valid = isfinite(x) & isfinite(y);

    x = x(valid);
    y = y(valid);

    if numel(x) < 2 || std(x) == 0
        return
    end

    coefficients = polyfit(x,y,1);

    xFit = linspace(xLimits(1),xLimits(2),200);
    yFit = polyval(coefficients,xFit);

    plot(ax,xFit,yFit, ...
        'Color',lineColor, ...
        'LineWidth',lineWidth);
end
