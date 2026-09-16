%% General questionnaire analysis: BAI, BDI, IUS Factor 1, IUS Factor 2
% Chronic stress study — publication/repository version
%
% Purpose
%   Run the same questionnaire analysis pipeline for multiple questionnaire
%   measures without hard-coding the script to a single scale.
%
% Questionnaire measures configured by default:
%   1. BAI       = anxiety
%   2. BDI       = depression
%   3. IUS_F1    = IUS Factor 1
%   4. IUS_F2    = IUS Factor 2
%
% For EACH questionnaire, the script performs:
%   A. Healthy vs Chronic-stress questionnaire group comparison
%      - Welch independent-samples t-test
%      - 95% confidence interval
%      - Cohen's d
%
%   B. Questionnaire correlations with task measures, separately for:
%      - Group: Healthy, Chronic stress
%      - Controllability: Controllable, Uncontrollable
%
%      Outcomes:
%         LR_HP, LR_MP, LR_UP
%         Accuracy_HP, Accuracy_MP, Accuracy_UP
%         Lambda
%
%      This gives:
%         2 groups x 2 controllability conditions x 7 outcomes
%         = 28 planned correlations per questionnaire.
%
% Shared task analyses are run ONCE because they do not depend on which
% questionnaire is being analysed:
%   - Learning-rate mixed-effects model:
%       Value ~ Group * Controllability * Predictability + (1|SubjectID)
%
%   - Accuracy mixed-effects model:
%       Value ~ Group * Controllability * Predictability + (1|SubjectID)
%
%   - Between-group follow-up comparisons within each of the six
%     Controllability x Predictability cells
%
% Multiple-comparison correction
%   By default, Bonferroni correction is applied WITHIN EACH QUESTIONNAIRE:
%       28 tests per questionnaire.
%
%   If your manuscript instead defines one family across all four
%   questionnaires, change:
%
%       CORRECTION_SCOPE = "across_all_questionnaires";
%
%   which gives:
%       4 questionnaires x 28 tests = 112 tests.
%
% Cleaning
%   - Task variables are cleaned once using an optional >3 SD rule.
%   - Each questionnaire is cleaned separately using the same rule.
%
% Participant alignment
%   - S1/S2 task worksheets are matched by participant ID.
%   - VKF rows are indexed using original workbook worksheet positions.
%   - Questionnaire files are matched by participant ID when an ID column
%     exists.
%
% Trial alignment
%   - Behavioral and VKF trial counts must match exactly.
%   - The script does NOT silently truncate with min(...).
%
% -------------------------------------------------------------------------
% IMPORTANT: QUESTIONNAIRE FILENAMES
%
% The BAI/BDI/IUS Factor 1 filenames below are configurable examples.
% If your actual files have different names, edit ONLY the QUESTIONNAIRE
% CONFIGURATION section below.
%
% The IUS Factor 2 filenames match the source script:
%   questionnaires_healthy_IUS_factor2.xlsx
%   questionnaires_CS_IUS_factor2.xlsx
% -------------------------------------------------------------------------
%
% Required directory structure
%
%   data/Questionnaires/
%       questionnaires_healthy_BAI.xlsx
%       questionnaires_CS_BAI.xlsx
%       questionnaires_healthy_BDI.xlsx
%       questionnaires_CS_BDI.xlsx
%       questionnaires_healthy_IUS_factor1.xlsx
%       questionnaires_CS_IUS_factor1.xlsx
%       questionnaires_healthy_IUS_factor2.xlsx
%       questionnaires_CS_IUS_factor2.xlsx
%
%       Healthy_correct_incorrect_S1.xlsx
%       Healthy_correct_incorrect_S2.xlsx
%       Chronic_correct_incorrect_scr_S1.xlsx
%       Chronic_correct_incorrect_scr_S2.xlsx
%
%       vkf_all_results_s1_healthy.mat
%       vkf_all_results_s2_healthy.mat
%       CS_vkf_all_results_s1.mat
%       CS_vkf_all_results_s2.mat
%
% -------------------------------------------------------------------------
% Daniyal Rajput
% Chronic stress / probabilistic aversive-learning study
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

dataDir = fullfile(scriptDir,'data','Questionnaires');

outDir = fullfile(scriptDir,'results','Questionnaire_Analysis_AllMeasures');

sharedDir = fullfile(outDir,'shared_task_analysis');
sharedFigDir = fullfile(sharedDir,'figures');
sharedStatsDir = fullfile(sharedDir,'stats');
sharedDataDir = fullfile(sharedDir,'cleaned_data');

if ~exist(outDir,'dir'), mkdir(outDir); end
if ~exist(sharedDir,'dir'), mkdir(sharedDir); end
if ~exist(sharedFigDir,'dir'), mkdir(sharedFigDir); end
if ~exist(sharedStatsDir,'dir'), mkdir(sharedStatsDir); end
if ~exist(sharedDataDir,'dir'), mkdir(sharedDataDir); end

sharedExcel = fullfile(sharedStatsDir,'Shared_Task_Results.xlsx');
sharedMat   = fullfile(sharedStatsDir,'Shared_Task_Results.mat');

combinedQuestionnaireExcel = ...
    fullfile(outDir,'All_Questionnaire_Results.xlsx');

%% ========================================================================
% QUESTIONNAIRE CONFIGURATION
% Edit filenames here if your actual files use different names.
% ========================================================================

Q = struct([]);

Q(1).Key = "BAI";
Q(1).Label = "BAI score";
Q(1).Description = "Anxiety";
Q(1).HealthyFile = "questionnaires_healthy_BAI.xlsx";
Q(1).ChronicFile = "questionnaires_CS_BAI.xlsx";
Q(1).ScoreColumn = 1;

Q(2).Key = "BDI";
Q(2).Label = "BDI score";
Q(2).Description = "Depression";
Q(2).HealthyFile = "questionnaires_healthy_BDI.xlsx";
Q(2).ChronicFile = "questionnaires_CS_BDI.xlsx";
Q(2).ScoreColumn = 1;

Q(3).Key = "IUS_F1";
Q(3).Label = "IUS Factor 1 score";
Q(3).Description = "Intolerance of uncertainty Factor 1";
Q(3).HealthyFile = "questionnaires_healthy_IUS_factor1.xlsx";
Q(3).ChronicFile = "questionnaires_CS_IUS_factor1.xlsx";
Q(3).ScoreColumn = 1;

Q(4).Key = "IUS_F2";
Q(4).Label = "IUS Factor 2 score";
Q(4).Description = "Intolerance of uncertainty Factor 2";
Q(4).HealthyFile = "questionnaires_healthy_IUS_factor2.xlsx";
Q(4).ChronicFile = "questionnaires_CS_IUS_factor2.xlsx";
Q(4).ScoreColumn = 1;

nQuestionnaires = numel(Q);

%% ========================================================================
% Multiple-comparison correction
% ========================================================================

% Options:
%   "within_questionnaire"       -> 28 tests separately for each measure
%   "across_all_questionnaires" -> 112 tests across BAI, BDI, IUS_F1, IUS_F2
CORRECTION_SCOPE = "within_questionnaire";

ALPHA = 0.05;
TESTS_PER_QUESTIONNAIRE = 28;

switch CORRECTION_SCOPE
    case "within_questionnaire"
        BONFERRONI_FAMILY_SIZE = TESTS_PER_QUESTIONNAIRE;

    case "across_all_questionnaires"
        BONFERRONI_FAMILY_SIZE = ...
            TESTS_PER_QUESTIONNAIRE*nQuestionnaires;

    otherwise
        error('Unknown CORRECTION_SCOPE: %s',CORRECTION_SCOPE);
end

BONFERRONI_ALPHA = ALPHA/BONFERRONI_FAMILY_SIZE;

%% ========================================================================
% Shared task input files
% ========================================================================

healthyS1File = fullfile(dataDir,'Healthy_correct_incorrect_S1.xlsx');
healthyS2File = fullfile(dataDir,'Healthy_correct_incorrect_S2.xlsx');

chronicS1File = fullfile(dataDir,'Chronic_correct_incorrect_scr_S1.xlsx');
chronicS2File = fullfile(dataDir,'Chronic_correct_incorrect_scr_S2.xlsx');

healthyVKFS1File = fullfile(dataDir,'vkf_all_results_s1_healthy.mat');
healthyVKFS2File = fullfile(dataDir,'vkf_all_results_s2_healthy.mat');

chronicVKFS1File = fullfile(dataDir,'CS_vkf_all_results_s1.mat');
chronicVKFS2File = fullfile(dataDir,'CS_vkf_all_results_s2.mat');

taskFiles = { ...
    healthyS1File,healthyS2File, ...
    chronicS1File,chronicS2File, ...
    healthyVKFS1File,healthyVKFS2File, ...
    chronicVKFS1File,chronicVKFS2File};

for i = 1:numel(taskFiles)
    assert(isfile(taskFiles{i}),'Missing task/VKF input file: %s',taskFiles{i});
end

%% ========================================================================
% Task settings
% ========================================================================

BLOCK_COL = 2;
ACC_COL   = 13;

HP_blocks = ["Block1","Block5","Block8","Block10"];
MP_blocks = ["Block3","Block4","Block7","Block9"];
UP_blocks = ["Block2","Block6"];

predictabilityNames = ["HP","MP","UP"];

predictabilityLabels = [ ...
    "Highly predictable", ...
    "Moderately predictable", ...
    "Unpredictable"];

%% ========================================================================
% Cleaning settings
% ========================================================================

APPLY_3SD_TASK = true;
APPLY_3SD_QUESTIONNAIRE = true;
SD_THRESHOLD = 3;

%% ========================================================================
% Figure settings
% ========================================================================

colH_S1 = [0.00 0.25 0.55];
colH_S2 = [0.70 0.82 0.97];

colC_S1 = [0.85 0.33 0.00];
colC_S2 = [1.00 0.80 0.65];

fs_xtick  = 18;
fs_ytick  = 18;
fs_label  = 20;
fs_legend = 16;
fs_title  = 18;

lw_axes = 1.6;
lw_fit  = 2.2;

ms_dot    = 55;
alpha_dot = 0.85;
box_alpha = 0.35;

png_dpi = 600;

%% ========================================================================
% Load VKF data
% ========================================================================

HS1 = load(healthyVKFS1File);
HS2 = load(healthyVKFS2File);

CS1 = load(chronicVKFS1File);
CS2 = load(chronicVKFS2File);

assert(isfield(HS1,'kgain_mat') && isfield(HS1,'lambda_vec'), ...
    'Healthy S1 VKF file must contain kgain_mat and lambda_vec.');

assert(isfield(HS2,'kgain_mat') && isfield(HS2,'lambda_vec'), ...
    'Healthy S2 VKF file must contain kgain_mat and lambda_vec.');

assert(isfield(CS1,'kgain_mat') && isfield(CS1,'lambda_vec'), ...
    'Chronic S1 VKF file must contain kgain_mat and lambda_vec.');

assert(isfield(CS2,'kgain_mat') && isfield(CS2,'lambda_vec'), ...
    'Chronic S2 VKF file must contain kgain_mat and lambda_vec.');

%% ========================================================================
% Match task participants across S1 and S2
% ========================================================================

H_sheets1 = string(sheetnames(healthyS1File));
H_sheets2 = string(sheetnames(healthyS2File));

C_sheets1 = string(sheetnames(chronicS1File));
C_sheets2 = string(sheetnames(chronicS2File));

[H_commonIDs,H_idxS1,H_idxS2] = ...
    match_session_sheets(H_sheets1,H_sheets2,"Healthy");

[C_commonIDs,C_idxS1,C_idxS2] = ...
    match_session_sheets(C_sheets1,C_sheets2,"Chronic");

fprintf('\nMatched task participants:\n');
fprintf('Healthy controls: %d\n',numel(H_commonIDs));
fprintf('Chronic stress:   %d\n\n',numel(C_commonIDs));

%% ========================================================================
% Extract shared task measures
% ========================================================================

[H_accS1,H_accS2,H_lrS1,H_lrS2,H_lambdaS1,H_lambdaS2,H_trialAudit] = ...
    extract_group_task_measures( ...
        healthyS1File,healthyS2File, ...
        H_sheets1,H_sheets2, ...
        H_commonIDs,H_idxS1,H_idxS2, ...
        HS1,HS2, ...
        BLOCK_COL,ACC_COL, ...
        HP_blocks,MP_blocks,UP_blocks, ...
        "Healthy");

[C_accS1,C_accS2,C_lrS1,C_lrS2,C_lambdaS1,C_lambdaS2,C_trialAudit] = ...
    extract_group_task_measures( ...
        chronicS1File,chronicS2File, ...
        C_sheets1,C_sheets2, ...
        C_commonIDs,C_idxS1,C_idxS2, ...
        CS1,CS2, ...
        BLOCK_COL,ACC_COL, ...
        HP_blocks,MP_blocks,UP_blocks, ...
        "Chronic");

%% ========================================================================
% Clean task variables ONCE
% ========================================================================

TaskCleaningLog = table();

for c = 1:3

    [H_lrS1(:,c),logT] = clean_vector_3sd( ...
        H_lrS1(:,c),H_commonIDs,"Healthy", ...
        "LR_"+predictabilityNames(c)+"_Controllable", ...
        APPLY_3SD_TASK,SD_THRESHOLD);
    TaskCleaningLog = [TaskCleaningLog;logT];

    [H_lrS2(:,c),logT] = clean_vector_3sd( ...
        H_lrS2(:,c),H_commonIDs,"Healthy", ...
        "LR_"+predictabilityNames(c)+"_Uncontrollable", ...
        APPLY_3SD_TASK,SD_THRESHOLD);
    TaskCleaningLog = [TaskCleaningLog;logT];

    [C_lrS1(:,c),logT] = clean_vector_3sd( ...
        C_lrS1(:,c),C_commonIDs,"Chronic", ...
        "LR_"+predictabilityNames(c)+"_Controllable", ...
        APPLY_3SD_TASK,SD_THRESHOLD);
    TaskCleaningLog = [TaskCleaningLog;logT];

    [C_lrS2(:,c),logT] = clean_vector_3sd( ...
        C_lrS2(:,c),C_commonIDs,"Chronic", ...
        "LR_"+predictabilityNames(c)+"_Uncontrollable", ...
        APPLY_3SD_TASK,SD_THRESHOLD);
    TaskCleaningLog = [TaskCleaningLog;logT];


    [H_accS1(:,c),logT] = clean_vector_3sd( ...
        H_accS1(:,c),H_commonIDs,"Healthy", ...
        "Accuracy_"+predictabilityNames(c)+"_Controllable", ...
        APPLY_3SD_TASK,SD_THRESHOLD);
    TaskCleaningLog = [TaskCleaningLog;logT];

    [H_accS2(:,c),logT] = clean_vector_3sd( ...
        H_accS2(:,c),H_commonIDs,"Healthy", ...
        "Accuracy_"+predictabilityNames(c)+"_Uncontrollable", ...
        APPLY_3SD_TASK,SD_THRESHOLD);
    TaskCleaningLog = [TaskCleaningLog;logT];

    [C_accS1(:,c),logT] = clean_vector_3sd( ...
        C_accS1(:,c),C_commonIDs,"Chronic", ...
        "Accuracy_"+predictabilityNames(c)+"_Controllable", ...
        APPLY_3SD_TASK,SD_THRESHOLD);
    TaskCleaningLog = [TaskCleaningLog;logT];

    [C_accS2(:,c),logT] = clean_vector_3sd( ...
        C_accS2(:,c),C_commonIDs,"Chronic", ...
        "Accuracy_"+predictabilityNames(c)+"_Uncontrollable", ...
        APPLY_3SD_TASK,SD_THRESHOLD);
    TaskCleaningLog = [TaskCleaningLog;logT];
end

[H_lambdaS1,logT] = clean_vector_3sd( ...
    H_lambdaS1,H_commonIDs,"Healthy","Lambda_Controllable", ...
    APPLY_3SD_TASK,SD_THRESHOLD);
TaskCleaningLog = [TaskCleaningLog;logT];

[H_lambdaS2,logT] = clean_vector_3sd( ...
    H_lambdaS2,H_commonIDs,"Healthy","Lambda_Uncontrollable", ...
    APPLY_3SD_TASK,SD_THRESHOLD);
TaskCleaningLog = [TaskCleaningLog;logT];

[C_lambdaS1,logT] = clean_vector_3sd( ...
    C_lambdaS1,C_commonIDs,"Chronic","Lambda_Controllable", ...
    APPLY_3SD_TASK,SD_THRESHOLD);
TaskCleaningLog = [TaskCleaningLog;logT];

[C_lambdaS2,logT] = clean_vector_3sd( ...
    C_lambdaS2,C_commonIDs,"Chronic","Lambda_Uncontrollable", ...
    APPLY_3SD_TASK,SD_THRESHOLD);
TaskCleaningLog = [TaskCleaningLog;logT];

%% ========================================================================
% Shared cleaned task tables
% ========================================================================

HealthyTaskData = make_task_subject_table( ...
    H_commonIDs,H_lrS1,H_lrS2,H_accS1,H_accS2,H_lambdaS1,H_lambdaS2);

ChronicTaskData = make_task_subject_table( ...
    C_commonIDs,C_lrS1,C_lrS2,C_accS1,C_accS2,C_lambdaS1,C_lambdaS2);

writetable(HealthyTaskData, ...
    fullfile(sharedDataDir,'Healthy_TaskData.csv'));

writetable(ChronicTaskData, ...
    fullfile(sharedDataDir,'Chronic_TaskData.csv'));

%% ========================================================================
% Shared long-format tables
% ========================================================================

LRLong = build_long_task_table( ...
    H_commonIDs,C_commonIDs, ...
    H_lrS1,H_lrS2,C_lrS1,C_lrS2, ...
    predictabilityNames,"LearningRate");

AccuracyLong = build_long_task_table( ...
    H_commonIDs,C_commonIDs, ...
    H_accS1,H_accS2,C_accS1,C_accS2, ...
    predictabilityNames,"Accuracy");

DescriptivesLR = make_task_descriptives(LRLong);
DescriptivesAccuracy = make_task_descriptives(AccuracyLong);

%% ========================================================================
% Shared mixed-effects models
% ========================================================================

LRLongLME = LRLong;
AccuracyLongLME = AccuracyLong;

LRLongLME.SubjectID = categorical(LRLongLME.SubjectID);
LRLongLME.Group = categorical( ...
    LRLongLME.Group,{'Healthy','Chronic'});
LRLongLME.Controllability = categorical( ...
    LRLongLME.Controllability,{'Controllable','Uncontrollable'});
LRLongLME.Predictability = categorical( ...
    LRLongLME.Predictability,{'HP','MP','UP'});

AccuracyLongLME.SubjectID = categorical(AccuracyLongLME.SubjectID);
AccuracyLongLME.Group = categorical( ...
    AccuracyLongLME.Group,{'Healthy','Chronic'});
AccuracyLongLME.Controllability = categorical( ...
    AccuracyLongLME.Controllability,{'Controllable','Uncontrollable'});
AccuracyLongLME.Predictability = categorical( ...
    AccuracyLongLME.Predictability,{'HP','MP','UP'});

lmeLearningRate = fitlme( ...
    LRLongLME, ...
    'Value ~ Group*Controllability*Predictability + (1|SubjectID)');

lmeAccuracy = fitlme( ...
    AccuracyLongLME, ...
    'Value ~ Group*Controllability*Predictability + (1|SubjectID)');

anovaLearningRate = anova( ...
    lmeLearningRate,'DFMethod','satterthwaite');

anovaAccuracy = anova( ...
    lmeAccuracy,'DFMethod','satterthwaite');

anovaLearningRateOut = add_effect_column(anovaLearningRate);
anovaAccuracyOut = add_effect_column(anovaAccuracy);

posthocLearningRate = between_group_posthocs( ...
    LRLong,predictabilityNames);

posthocAccuracy = between_group_posthocs( ...
    AccuracyLong,predictabilityNames);

%% ========================================================================
% Shared task figures
% ========================================================================

plot_task_boxfigure( ...
    H_lrS1,H_lrS2,C_lrS1,C_lrS2, ...
    predictabilityNames, ...
    'Learning rate', ...
    fullfile(sharedFigDir,'LearningRate_AllGroups'), ...
    colH_S1,colH_S2,colC_S1,colC_S2, ...
    fs_xtick,fs_ytick,fs_label,fs_legend,lw_axes, ...
    box_alpha,ms_dot,alpha_dot,png_dpi);

plot_task_boxfigure( ...
    H_accS1,H_accS2,C_accS1,C_accS2, ...
    predictabilityNames, ...
    'Accuracy (%)', ...
    fullfile(sharedFigDir,'Accuracy_AllGroups'), ...
    colH_S1,colH_S2,colC_S1,colC_S2, ...
    fs_xtick,fs_ytick,fs_label,fs_legend,lw_axes, ...
    box_alpha,ms_dot,alpha_dot,png_dpi);

%% ========================================================================
% Export shared task analysis
% ========================================================================

SharedAnalysisInfo = table( ...
    ["Learning-rate model"; ...
     "Accuracy model"; ...
     "Task 3-SD cleaning"; ...
     "SD threshold"; ...
     "Group balancing"; ...
     "Silent participant truncation"; ...
     "Silent trial truncation"], ...
    ["Group * Controllability * Predictability + (1|SubjectID)"; ...
     "Group * Controllability * Predictability + (1|SubjectID)"; ...
     string(APPLY_3SD_TASK); ...
     string(SD_THRESHOLD); ...
     "Not used"; ...
     "Not allowed"; ...
     "Not allowed"], ...
    'VariableNames',{'Item','Value'});

if isfile(sharedExcel)
    delete(sharedExcel);
end

writetable(SharedAnalysisInfo,sharedExcel,'Sheet','Analysis_Info');
writetable(DescriptivesLR,sharedExcel,'Sheet','Descriptives_LR');
writetable(DescriptivesAccuracy,sharedExcel,'Sheet','Descriptives_Accuracy');
writetable(anovaLearningRateOut,sharedExcel,'Sheet','LME_LearningRate');
writetable(anovaAccuracyOut,sharedExcel,'Sheet','LME_Accuracy');
writetable(posthocLearningRate,sharedExcel,'Sheet','PostHoc_LR');
writetable(posthocAccuracy,sharedExcel,'Sheet','PostHoc_Accuracy');
writetable(HealthyTaskData,sharedExcel,'Sheet','Healthy_TaskData');
writetable(ChronicTaskData,sharedExcel,'Sheet','Chronic_TaskData');
writetable(TaskCleaningLog,sharedExcel,'Sheet','Task_Cleaning');
writetable(H_trialAudit,sharedExcel,'Sheet','Healthy_TrialAudit');
writetable(C_trialAudit,sharedExcel,'Sheet','Chronic_TrialAudit');

save(sharedMat, ...
    'SharedAnalysisInfo', ...
    'HealthyTaskData','ChronicTaskData', ...
    'DescriptivesLR','DescriptivesAccuracy', ...
    'lmeLearningRate','lmeAccuracy', ...
    'anovaLearningRate','anovaAccuracy', ...
    'posthocLearningRate','posthocAccuracy', ...
    'TaskCleaningLog','H_trialAudit','C_trialAudit');

%% ========================================================================
% QUESTIONNAIRE LOOP
% ========================================================================

AllGroupComparisons = table();
AllCorrelations = table();
AllQuestionnaireCleaning = table();
AllQuestionnaireMapping = table();

for q = 1:nQuestionnaires

    key = Q(q).Key;
    label = Q(q).Label;
    description = Q(q).Description;

    fprintf('\n============================================================\n');
    fprintf('Questionnaire %d/%d: %s\n',q,nQuestionnaires,key);
    fprintf('============================================================\n');

    measureDir = fullfile(outDir,char(key));
    measureFigDir = fullfile(measureDir,'figures');
    measureStatsDir = fullfile(measureDir,'stats');
    measureDataDir = fullfile(measureDir,'cleaned_data');

    if ~exist(measureDir,'dir'), mkdir(measureDir); end
    if ~exist(measureFigDir,'dir'), mkdir(measureFigDir); end
    if ~exist(measureStatsDir,'dir'), mkdir(measureStatsDir); end
    if ~exist(measureDataDir,'dir'), mkdir(measureDataDir); end

    measureExcel = fullfile( ...
        measureStatsDir, ...
        char(key+"_Results.xlsx"));

    measureMat = fullfile( ...
        measureStatsDir, ...
        char(key+"_Results.mat"));

    healthyQFile = fullfile(dataDir,Q(q).HealthyFile);
    chronicQFile = fullfile(dataDir,Q(q).ChronicFile);

    assert(isfile(healthyQFile), ...
        ['Missing Healthy questionnaire file for %s:\n%s\n' ...
         'Edit the QUESTIONNAIRE CONFIGURATION section if the filename differs.'], ...
         key,healthyQFile);

    assert(isfile(chronicQFile), ...
        ['Missing Chronic questionnaire file for %s:\n%s\n' ...
         'Edit the QUESTIONNAIRE CONFIGURATION section if the filename differs.'], ...
         key,chronicQFile);

    %% Align questionnaire scores to task participants
    [H_q,H_mapping,H_method] = align_questionnaire_to_task( ...
        healthyQFile,H_commonIDs,Q(q).ScoreColumn,"Healthy");

    [C_q,C_mapping,C_method] = align_questionnaire_to_task( ...
        chronicQFile,C_commonIDs,Q(q).ScoreColumn,"Chronic");

    %% Questionnaire-specific 3-SD cleaning
    [H_q,H_cleanLog] = clean_vector_3sd( ...
        H_q,H_commonIDs,"Healthy",key, ...
        APPLY_3SD_QUESTIONNAIRE,SD_THRESHOLD);

    [C_q,C_cleanLog] = clean_vector_3sd( ...
        C_q,C_commonIDs,"Chronic",key, ...
        APPLY_3SD_QUESTIONNAIRE,SD_THRESHOLD);

    QuestionnaireCleaning = [H_cleanLog;C_cleanLog];

    %% Questionnaire group comparison
    H_valid = H_q(isfinite(H_q));
    C_valid = C_q(isfinite(C_q));

    assert(numel(H_valid) >= 2 && numel(C_valid) >= 2, ...
        'Insufficient valid questionnaire observations for %s.',key);

    [~,pGroup,ciGroup,statsGroup] = ...
        ttest2(H_valid,C_valid,'Vartype','unequal');

    meanH = mean(H_valid);
    meanC = mean(C_valid);

    sdH = std(H_valid);
    sdC = std(C_valid);

    nH = numel(H_valid);
    nC = numel(C_valid);

    pooledSD = sqrt( ...
        ((nH-1)*sdH^2 + (nC-1)*sdC^2) / ...
        (nH+nC-2));

    cohensD = (meanH-meanC)/pooledSD;

    GroupComparison = table( ...
        key,label,description, ...
        nH,meanH,sdH, ...
        nC,meanC,sdC, ...
        meanH-meanC, ...
        statsGroup.tstat,statsGroup.df,pGroup, ...
        ciGroup(1),ciGroup(2),cohensD, ...
        'VariableNames', { ...
            'Questionnaire','QuestionnaireLabel','Description', ...
            'N_Healthy','Mean_Healthy','SD_Healthy', ...
            'N_Chronic','Mean_Chronic','SD_Chronic', ...
            'MeanDifference_HealthyMinusChronic', ...
            't','df','p','CI_Lower','CI_Upper','Cohens_d'});

    %% Correlations
    outcomeNames = [ ...
        "LR_HP","LR_MP","LR_UP", ...
        "Accuracy_HP","Accuracy_MP","Accuracy_UP", ...
        "Lambda"];

    Correlations = table();

    Correlations = [
        Correlations;
        questionnaire_correlations( ...
            H_q,[H_lrS1,H_accS1,H_lambdaS1], ...
            key,label,"Healthy","Controllable", ...
            H_commonIDs,outcomeNames)
        ]; %#ok<AGROW>

    Correlations = [
        Correlations;
        questionnaire_correlations( ...
            H_q,[H_lrS2,H_accS2,H_lambdaS2], ...
            key,label,"Healthy","Uncontrollable", ...
            H_commonIDs,outcomeNames)
        ]; %#ok<AGROW>

    Correlations = [
        Correlations;
        questionnaire_correlations( ...
            C_q,[C_lrS1,C_accS1,C_lambdaS1], ...
            key,label,"Chronic","Controllable", ...
            C_commonIDs,outcomeNames)
        ]; %#ok<AGROW>

    Correlations = [
        Correlations;
        questionnaire_correlations( ...
            C_q,[C_lrS2,C_accS2,C_lambdaS2], ...
            key,label,"Chronic","Uncontrollable", ...
            C_commonIDs,outcomeNames)
        ]; %#ok<AGROW>

    assert(height(Correlations) == TESTS_PER_QUESTIONNAIRE, ...
        'Expected 28 correlations for %s; found %d.', ...
        key,height(Correlations));

    validP = isfinite(Correlations.p);

    Correlations.p_Bonferroni = nan(height(Correlations),1);

    Correlations.p_Bonferroni(validP) = min( ...
        Correlations.p(validP)*BONFERRONI_FAMILY_SIZE,1);

    Correlations.Significant_Raw = ...
        Correlations.p < ALPHA;

    Correlations.Significant_Bonferroni = ...
        Correlations.p_Bonferroni < ALPHA;

    Correlations.BonferroniFamilySize = repmat( ...
        BONFERRONI_FAMILY_SIZE,height(Correlations),1);

    Correlations.BonferroniAlpha = repmat( ...
        BONFERRONI_ALPHA,height(Correlations),1);

    Correlations.CorrectionScope = repmat( ...
        CORRECTION_SCOPE,height(Correlations),1);

    %% Questionnaire-specific subject tables
    HealthyQuestionnaireData = table( ...
        string(H_commonIDs(:)),H_q(:), ...
        'VariableNames',{'SubjectID','QuestionnaireScore'});

    ChronicQuestionnaireData = table( ...
        string(C_commonIDs(:)),C_q(:), ...
        'VariableNames',{'SubjectID','QuestionnaireScore'});

    writetable( ...
        HealthyQuestionnaireData, ...
        fullfile(measureDataDir,'Healthy_QuestionnaireScores.csv'));

    writetable( ...
        ChronicQuestionnaireData, ...
        fullfile(measureDataDir,'Chronic_QuestionnaireScores.csv'));

    %% Questionnaire group figure
    fig = figure('Color','w','Position',[180 110 700 620]);
    ax = axes(fig);
    hold(ax,'on');

    draw_box_with_points( ...
        ax,1,H_valid,colH_S1, ...
        box_alpha,ms_dot,alpha_dot);

    draw_box_with_points( ...
        ax,2,C_valid,colC_S1, ...
        box_alpha,ms_dot,alpha_dot);

    xlim(ax,[0.45 2.55]);

    ax.XTick = [1 2];
    ax.XTickLabel = {'Healthy controls','Chronic stress'};

    ylabel(ax,label, ...
        'FontSize',fs_label, ...
        'FontWeight','bold');

    style_axes(ax,fs_xtick,fs_ytick,lw_axes);

    exportgraphics( ...
        fig, ...
        fullfile(measureFigDir,char(key+"_GroupComparison.png")), ...
        'Resolution',png_dpi);

    exportgraphics( ...
        fig, ...
        fullfile(measureFigDir,char(key+"_GroupComparison.tiff")), ...
        'Resolution',png_dpi);

    exportgraphics( ...
        fig, ...
        fullfile(measureFigDir,char(key+"_GroupComparison.pdf")), ...
        'ContentType','vector');

    close(fig);

    %% Correlation figures
    questionnaireXLim = padded_limits([H_q(:);C_q(:)]);

    allLR = [H_lrS1(:);H_lrS2(:);C_lrS1(:);C_lrS2(:)];
    allAccuracy = [H_accS1(:);H_accS2(:);C_accS1(:);C_accS2(:)];
    allLambda = [H_lambdaS1(:);H_lambdaS2(:);C_lambdaS1(:);C_lambdaS2(:)];

    yLimitsLR = padded_limits(allLR);
    yLimitsAccuracy = padded_limits(allAccuracy);
    yLimitsLambda = padded_limits(allLambda);

    for s = 1:2

        if s == 1
            controllability = "Controllable";
            H_Y = [H_lrS1,H_accS1,H_lambdaS1];
            C_Y = [C_lrS1,C_accS1,C_lambdaS1];
            colorH = colH_S1;
            colorC = colC_S1;
        else
            controllability = "Uncontrollable";
            H_Y = [H_lrS2,H_accS2,H_lambdaS2];
            C_Y = [C_lrS2,C_accS2,C_lambdaS2];
            colorH = colH_S2;
            colorC = colC_S2;
        end

        for k = 1:7

            if k <= 3
                yLabelText = 'Learning rate';
                yLimits = yLimitsLR;
                plotTitle = predictabilityLabels(k);

            elseif k <= 6
                yLabelText = 'Accuracy (%)';
                yLimits = yLimitsAccuracy;
                plotTitle = predictabilityLabels(k-3);

            else
                yLabelText = 'Volatility update rate';
                yLimits = yLimitsLambda;
                plotTitle = 'Volatility update rate';
            end

            [xH,yH] = pairwise_complete(H_q,H_Y(:,k));
            [xC,yC] = pairwise_complete(C_q,C_Y(:,k));

            fig = figure('Color','w','Position',[120 90 860 680]);
            ax = axes(fig);
            hold(ax,'on');

            hH = scatter( ...
                ax,xH,yH,ms_dot,colorH,'filled', ...
                'Marker','o', ...
                'MarkerEdgeColor','k', ...
                'MarkerFaceAlpha',alpha_dot);

            hC = scatter( ...
                ax,xC,yC,ms_dot,colorC,'filled', ...
                'Marker','s', ...
                'MarkerEdgeColor','k', ...
                'MarkerFaceAlpha',alpha_dot);

            add_fit_line(ax,xH,yH,colorH,lw_fit);
            add_fit_line(ax,xC,yC,colorC,lw_fit);

            xlim(ax,questionnaireXLim);
            ylim(ax,yLimits);

            xlabel(ax,label, ...
                'FontSize',fs_label, ...
                'FontWeight','bold');

            ylabel(ax,yLabelText, ...
                'FontSize',fs_label, ...
                'FontWeight','bold');

            title(ax,plotTitle, ...
                'FontSize',fs_title, ...
                'FontWeight','bold');

            style_axes(ax,fs_xtick,fs_ytick,lw_axes);

            legend(ax,[hH hC], ...
                {'Healthy controls','Chronic stress'}, ...
                'Location','best', ...
                'Box','off', ...
                'FontSize',fs_legend);

            idxH = ...
                Correlations.Group == "Healthy" & ...
                Correlations.Controllability == controllability & ...
                Correlations.Outcome == outcomeNames(k);

            idxC = ...
                Correlations.Group == "Chronic" & ...
                Correlations.Controllability == controllability & ...
                Correlations.Outcome == outcomeNames(k);

            xl = xlim(ax);
            yl = ylim(ax);

            if any(idxH)

                txtH = sprintf( ...
                    'Healthy: r = %.2f, p = %s, Bonf. p = %s', ...
                    Correlations.r(idxH), ...
                    format_p(Correlations.p(idxH)), ...
                    format_p(Correlations.p_Bonferroni(idxH)));

                text(ax, ...
                    xl(1)+0.03*range(xl), ...
                    yl(2)-0.05*range(yl), ...
                    txtH, ...
                    'Color',colorH, ...
                    'FontSize',fs_legend, ...
                    'FontWeight','bold', ...
                    'VerticalAlignment','top');
            end

            if any(idxC)

                txtC = sprintf( ...
                    'Chronic: r = %.2f, p = %s, Bonf. p = %s', ...
                    Correlations.r(idxC), ...
                    format_p(Correlations.p(idxC)), ...
                    format_p(Correlations.p_Bonferroni(idxC)));

                text(ax, ...
                    xl(1)+0.03*range(xl), ...
                    yl(2)-0.12*range(yl), ...
                    txtC, ...
                    'Color',colorC, ...
                    'FontSize',fs_legend, ...
                    'FontWeight','bold', ...
                    'VerticalAlignment','top');
            end

            figureBase = fullfile( ...
                measureFigDir, ...
                char(key+"_"+controllability+"_"+outcomeNames(k)));

            exportgraphics(fig,[figureBase '.png'], ...
                'Resolution',png_dpi);

            exportgraphics(fig,[figureBase '.tiff'], ...
                'Resolution',png_dpi);

            exportgraphics(fig,[figureBase '.pdf'], ...
                'ContentType','vector');

            close(fig);
        end
    end

    %% Questionnaire metadata
    QuestionnaireInfo = table( ...
        ["Questionnaire key"; ...
         "Questionnaire label"; ...
         "Description"; ...
         "Healthy file"; ...
         "Chronic file"; ...
         "Healthy alignment"; ...
         "Chronic alignment"; ...
         "Group comparison"; ...
         "Correlation method"; ...
         "Planned correlations for this questionnaire"; ...
         "Correction scope"; ...
         "Correction family size"; ...
         "Bonferroni alpha"; ...
         "Questionnaire 3-SD cleaning"; ...
         "SD threshold"; ...
         "Group balancing"], ...
        [key; ...
         label; ...
         description; ...
         string(Q(q).HealthyFile); ...
         string(Q(q).ChronicFile); ...
         H_method; ...
         C_method; ...
         "Welch independent-samples t-test"; ...
         "Pearson correlation"; ...
         string(TESTS_PER_QUESTIONNAIRE); ...
         CORRECTION_SCOPE; ...
         string(BONFERRONI_FAMILY_SIZE); ...
         string(BONFERRONI_ALPHA); ...
         string(APPLY_3SD_QUESTIONNAIRE); ...
         string(SD_THRESHOLD); ...
         "Not used"], ...
        'VariableNames',{'Item','Value'});

    %% Export questionnaire-specific results
    if isfile(measureExcel)
        delete(measureExcel);
    end

    writetable(QuestionnaireInfo, ...
        measureExcel,'Sheet','Analysis_Info');

    writetable(GroupComparison, ...
        measureExcel,'Sheet','Group_Comparison');

    writetable(Correlations, ...
        measureExcel,'Sheet','Correlations');

    writetable(HealthyQuestionnaireData, ...
        measureExcel,'Sheet','Healthy_Scores');

    writetable(ChronicQuestionnaireData, ...
        measureExcel,'Sheet','Chronic_Scores');

    writetable(H_mapping, ...
        measureExcel,'Sheet','Healthy_Mapping');

    writetable(C_mapping, ...
        measureExcel,'Sheet','Chronic_Mapping');

    writetable(QuestionnaireCleaning, ...
        measureExcel,'Sheet','Cleaning_Log');

    save(measureMat, ...
        'QuestionnaireInfo','GroupComparison','Correlations', ...
        'HealthyQuestionnaireData','ChronicQuestionnaireData', ...
        'H_mapping','C_mapping','QuestionnaireCleaning');

    %% Add to combined results
    AllGroupComparisons = [
        AllGroupComparisons;
        GroupComparison
        ]; %#ok<AGROW>

    AllCorrelations = [
        AllCorrelations;
        Correlations
        ]; %#ok<AGROW>

    if ~isempty(QuestionnaireCleaning)

        QuestionnaireCleaning.Questionnaire = repmat( ...
            key,height(QuestionnaireCleaning),1);

        QuestionnaireCleaning = movevars( ...
            QuestionnaireCleaning,'Questionnaire','Before',1);

        AllQuestionnaireCleaning = [
            AllQuestionnaireCleaning;
            QuestionnaireCleaning
            ]; %#ok<AGROW>
    end

    H_map_export = H_mapping;
    H_map_export.Questionnaire = repmat(key,height(H_map_export),1);
    H_map_export.Group = repmat("Healthy",height(H_map_export),1);

    C_map_export = C_mapping;
    C_map_export.Questionnaire = repmat(key,height(C_map_export),1);
    C_map_export.Group = repmat("Chronic",height(C_map_export),1);

    H_map_export = movevars( ...
        H_map_export,{'Questionnaire','Group'},'Before',1);

    C_map_export = movevars( ...
        C_map_export,{'Questionnaire','Group'},'Before',1);

    AllQuestionnaireMapping = [
        AllQuestionnaireMapping;
        harmonize_mapping_table(H_map_export);
        harmonize_mapping_table(C_map_export)
        ]; %#ok<AGROW>

    fprintf('%s complete: Healthy N=%d, Chronic N=%d.\n', ...
        key,nH,nC);

    fprintf('Bonferroni family size=%d, alpha=%.8f.\n', ...
        BONFERRONI_FAMILY_SIZE,BONFERRONI_ALPHA);
end

%% ========================================================================
% Combined questionnaire export
% ========================================================================

CombinedAnalysisInfo = table( ...
    ["Questionnaires"; ...
     "Number of questionnaires"; ...
     "Planned correlations per questionnaire"; ...
     "Correction scope"; ...
     "Bonferroni family size"; ...
     "Bonferroni alpha"; ...
     "Questionnaire 3-SD cleaning"; ...
     "Task 3-SD cleaning"; ...
     "SD threshold"; ...
     "Group balancing"], ...
    ["BAI, BDI, IUS Factor 1, IUS Factor 2"; ...
     string(nQuestionnaires); ...
     string(TESTS_PER_QUESTIONNAIRE); ...
     CORRECTION_SCOPE; ...
     string(BONFERRONI_FAMILY_SIZE); ...
     string(BONFERRONI_ALPHA); ...
     string(APPLY_3SD_QUESTIONNAIRE); ...
     string(APPLY_3SD_TASK); ...
     string(SD_THRESHOLD); ...
     "Not used"], ...
    'VariableNames',{'Item','Value'});

if isfile(combinedQuestionnaireExcel)
    delete(combinedQuestionnaireExcel);
end

writetable(CombinedAnalysisInfo, ...
    combinedQuestionnaireExcel,'Sheet','Analysis_Info');

writetable(AllGroupComparisons, ...
    combinedQuestionnaireExcel,'Sheet','Group_Comparisons');

writetable(AllCorrelations, ...
    combinedQuestionnaireExcel,'Sheet','All_Correlations');

if ~isempty(AllQuestionnaireCleaning)
    writetable(AllQuestionnaireCleaning, ...
        combinedQuestionnaireExcel,'Sheet','Questionnaire_Cleaning');
end

if ~isempty(AllQuestionnaireMapping)
    writetable(AllQuestionnaireMapping, ...
        combinedQuestionnaireExcel,'Sheet','Questionnaire_Mapping');
end

fprintf('\n============================================================\n');
fprintf('GENERAL QUESTIONNAIRE ANALYSIS COMPLETE\n');
fprintf('============================================================\n');

fprintf('Questionnaires analysed: ');
fprintf('%s ',Q.Key);
fprintf('\n');

fprintf('Correction scope: %s\n',CORRECTION_SCOPE);
fprintf('Bonferroni family size: %d\n',BONFERRONI_FAMILY_SIZE);
fprintf('Bonferroni alpha: %.8f\n',BONFERRONI_ALPHA);

fprintf('\nCombined questionnaire results:\n%s\n',combinedQuestionnaireExcel);
fprintf('Shared task results:\n%s\n',sharedExcel);
fprintf('Output folder:\n%s\n\n',outDir);


%% ========================================================================
% Local functions
% ========================================================================

function [commonIDs,idxS1,idxS2] = ...
    match_session_sheets(sheetsS1,sheetsS2,groupName)

    idS1 = normalize_subject_id(sheetsS1);
    idS2 = normalize_subject_id(sheetsS2);

    [commonIDs,idxS1,idxS2] = intersect( ...
        idS1,idS2,'stable');

    if isempty(commonIDs)
        error('No matching S1/S2 participants found for %s.',groupName);
    end
end


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


function [scores,mapping,method] = ...
    align_questionnaire_to_task( ...
        questionnaireFile,taskIDs,scoreColumn,groupName)

    T = readtable( ...
        questionnaireFile, ...
        'VariableNamingRule','preserve');

    if height(T) == 0
        error('Questionnaire file is empty: %s',questionnaireFile);
    end

    if scoreColumn < 1 || scoreColumn > width(T)
        error( ...
            'Configured questionnaire score column %d is invalid for %s.', ...
            scoreColumn,questionnaireFile);
    end

    scoreVariable = T.Properties.VariableNames{scoreColumn};
    scoresRaw = to_numeric_vector(T.(scoreVariable));

    idColumn = find_id_column(T);

    if ~isempty(idColumn) && ~strcmp(idColumn,scoreVariable)

        questionnaireIDs = normalize_subject_id( ...
            string(T.(idColumn)));

        taskIDsNormalized = normalize_subject_id(taskIDs);

        [matchedIDs,taskIdx,qIdx] = intersect( ...
            taskIDsNormalized, ...
            questionnaireIDs, ...
            'stable');

        if numel(matchedIDs) ~= numel(taskIDsNormalized)

            missingIDs = setdiff( ...
                taskIDsNormalized, ...
                matchedIDs, ...
                'stable');

            error(['Questionnaire IDs do not cover all matched %s task participants.\n' ...
                   'Missing IDs: %s'], ...
                   groupName,strjoin(missingIDs,", "));
        end

        scores = nan(numel(taskIDs),1);
        scores(taskIdx) = scoresRaw(qIdx);

        mapping = table( ...
            string(taskIDs(:)), ...
            string(questionnaireIDs(qIdx)), ...
            scores(taskIdx), ...
            'VariableNames', { ...
                'TaskSubjectID', ...
                'QuestionnaireSubjectID', ...
                'QuestionnaireScore'});

        method = "Subject ID";

    else

        finiteRows = isfinite(scoresRaw);
        numericScores = scoresRaw(finiteRows);

        if numel(numericScores) ~= numel(taskIDs)

            error(['No usable questionnaire-ID column was detected for %s and ' ...
                   'the numeric score count does not equal the task N.\n' ...
                   'Questionnaire numeric N = %d; task N = %d.\n' ...
                   'The script will not silently truncate participants.'], ...
                   groupName,numel(numericScores),numel(taskIDs));
        end

        scores = numericScores(:);

        mapping = table( ...
            string(taskIDs(:)), ...
            scores, ...
            'VariableNames', { ...
                'TaskSubjectID', ...
                'QuestionnaireScore'});

        method = "Row order (equal N verified)";
    end
end


function name = find_id_column(T)

    candidates = { ...
        'Subject','SubjectID', ...
        'Participant','ParticipantID', ...
        'ID','subject','subject_id', ...
        'participant_id'};

    name = '';

    for i = 1:numel(candidates)

        if ismember(candidates{i},T.Properties.VariableNames)
            name = candidates{i};
            return
        end
    end
end


function x = to_numeric_vector(x)

    if isnumeric(x) || islogical(x)
        x = double(x(:));
    else
        x = str2double(string(x(:)));
    end
end


function [accS1,accS2,lrS1,lrS2,lambdaS1,lambdaS2,trialAudit] = ...
    extract_group_task_measures( ...
        workbookS1,workbookS2, ...
        sheetsS1,sheetsS2, ...
        commonIDs,idxS1,idxS2, ...
        VKFS1,VKFS2, ...
        blockColumn,accuracyColumn, ...
        HPBlocks,MPBlocks,UPBlocks, ...
        groupName)

    n = numel(commonIDs);

    accS1 = nan(n,3);
    accS2 = nan(n,3);

    lrS1 = nan(n,3);
    lrS2 = nan(n,3);

    lambdaS1 = nan(n,1);
    lambdaS2 = nan(n,1);

    trialAudit = table();

    assert(size(VKFS1.kgain_mat,1) >= max(idxS1), ...
        '%s S1 VKF rows do not cover all matched workbook indices.',groupName);

    assert(size(VKFS2.kgain_mat,1) >= max(idxS2), ...
        '%s S2 VKF rows do not cover all matched workbook indices.',groupName);

    assert(numel(VKFS1.lambda_vec) >= max(idxS1), ...
        '%s S1 lambda_vec does not cover all matched workbook indices.',groupName);

    assert(numel(VKFS2.lambda_vec) >= max(idxS2), ...
        '%s S2 lambda_vec does not cover all matched workbook indices.',groupName);

    for i = 1:n

        sheetS1 = sheetsS1(idxS1(i));
        sheetS2 = sheetsS2(idxS2(i));

        T1 = readtable( ...
            workbookS1, ...
            'Sheet',sheetS1, ...
            'VariableNamingRule','preserve');

        T2 = readtable( ...
            workbookS2, ...
            'Sheet',sheetS2, ...
            'VariableNamingRule','preserve');

        assert(width(T1) >= max(blockColumn,accuracyColumn), ...
            '%s S1 worksheet %s lacks required columns.',groupName,sheetS1);

        assert(width(T2) >= max(blockColumn,accuracyColumn), ...
            '%s S2 worksheet %s lacks required columns.',groupName,sheetS2);

        blocks1 = strtrim(string(T1{:,blockColumn}));
        blocks2 = strtrim(string(T2{:,blockColumn}));

        accuracy1 = to_numeric_vector(T1{:,accuracyColumn});
        accuracy2 = to_numeric_vector(T2{:,accuracyColumn});

        learningRate1 = double(VKFS1.kgain_mat(idxS1(i),:).');
        learningRate2 = double(VKFS2.kgain_mat(idxS2(i),:).');

        if numel(accuracy1) ~= numel(learningRate1)

            error(['Trial-count mismatch for %s %s, Controllable.\n' ...
                   'Behavioral trials = %d; VKF trials = %d.'], ...
                   groupName,commonIDs(i), ...
                   numel(accuracy1),numel(learningRate1));
        end

        if numel(accuracy2) ~= numel(learningRate2)

            error(['Trial-count mismatch for %s %s, Uncontrollable.\n' ...
                   'Behavioral trials = %d; VKF trials = %d.'], ...
                   groupName,commonIDs(i), ...
                   numel(accuracy2),numel(learningRate2));
        end

        lambdaS1(i) = double(VKFS1.lambda_vec(idxS1(i)));
        lambdaS2(i) = double(VKFS2.lambda_vec(idxS2(i)));

        masks1 = { ...
            ismember(blocks1,HPBlocks), ...
            ismember(blocks1,MPBlocks), ...
            ismember(blocks1,UPBlocks)};

        masks2 = { ...
            ismember(blocks2,HPBlocks), ...
            ismember(blocks2,MPBlocks), ...
            ismember(blocks2,UPBlocks)};

        for c = 1:3

            validAccuracy1 = masks1{c} & isfinite(accuracy1);
            validAccuracy2 = masks2{c} & isfinite(accuracy2);

            validLR1 = masks1{c} & isfinite(learningRate1);
            validLR2 = masks2{c} & isfinite(learningRate2);

            if any(validAccuracy1)

                accS1(i,c) = 100*mean( ...
                    accuracy1(validAccuracy1),'omitnan');
            end

            if any(validAccuracy2)

                accS2(i,c) = 100*mean( ...
                    accuracy2(validAccuracy2),'omitnan');
            end

            if any(validLR1)

                lrS1(i,c) = mean( ...
                    learningRate1(validLR1),'omitnan');
            end

            if any(validLR2)

                lrS2(i,c) = mean( ...
                    learningRate2(validLR2),'omitnan');
            end
        end

        auditRow = table( ...
            string(groupName), ...
            string(commonIDs(i)), ...
            height(T1),numel(learningRate1), ...
            height(T2),numel(learningRate2), ...
            'VariableNames', { ...
                'Group','SubjectID', ...
                'S1_BehavioralTrials','S1_VKFTrials', ...
                'S2_BehavioralTrials','S2_VKFTrials'});

        trialAudit = [trialAudit;auditRow]; %#ok<AGROW>
    end
end


function [x,logTable] = clean_vector_3sd( ...
    x,subjectIDs,groupName,variableName,applyCleaning,threshold)

    x = double(x(:));
    subjectIDs = string(subjectIDs(:));

    logTable = table( ...
        strings(0,1),strings(0,1),strings(0,1), ...
        zeros(0,1),zeros(0,1), ...
        'VariableNames', { ...
            'Group','SubjectID','Variable', ...
            'RemovedValue','AbsZ'});

    if ~applyCleaning
        return
    end

    valid = isfinite(x);

    if sum(valid) < 5
        return
    end

    mu = mean(x(valid));
    sdValue = std(x(valid));

    if ~isfinite(sdValue) || sdValue <= eps
        return
    end

    z = abs((x-mu)/sdValue);

    remove = valid & z > threshold;

    if any(remove)

        logTable = table( ...
            repmat(string(groupName),sum(remove),1), ...
            subjectIDs(remove), ...
            repmat(string(variableName),sum(remove),1), ...
            x(remove), ...
            z(remove), ...
            'VariableNames', { ...
                'Group','SubjectID','Variable', ...
                'RemovedValue','AbsZ'});

        x(remove) = NaN;
    end
end


function T = make_task_subject_table( ...
    IDs,lrS1,lrS2,accS1,accS2,lambdaS1,lambdaS2)

    T = table( ...
        string(IDs(:)), ...
        lrS1(:,1),lrS1(:,2),lrS1(:,3), ...
        lrS2(:,1),lrS2(:,2),lrS2(:,3), ...
        accS1(:,1),accS1(:,2),accS1(:,3), ...
        accS2(:,1),accS2(:,2),accS2(:,3), ...
        lambdaS1(:),lambdaS2(:), ...
        'VariableNames', { ...
            'SubjectID', ...
            'LR_HP_Controllable','LR_MP_Controllable','LR_UP_Controllable', ...
            'LR_HP_Uncontrollable','LR_MP_Uncontrollable','LR_UP_Uncontrollable', ...
            'Accuracy_HP_Controllable','Accuracy_MP_Controllable','Accuracy_UP_Controllable', ...
            'Accuracy_HP_Uncontrollable','Accuracy_MP_Uncontrollable','Accuracy_UP_Uncontrollable', ...
            'Lambda_Controllable','Lambda_Uncontrollable'});
end


function T = build_long_task_table( ...
    healthyIDs,chronicIDs, ...
    H_S1,H_S2,C_S1,C_S2, ...
    predictabilityNames,outcomeName)

    SubjectID = strings(0,1);
    Group = strings(0,1);
    Controllability = strings(0,1);
    Predictability = strings(0,1);
    Value = zeros(0,1);

    for i = 1:numel(healthyIDs)

        for c = 1:3

            SubjectID(end+1,1) = "Healthy_"+string(healthyIDs(i));
            Group(end+1,1) = "Healthy";
            Controllability(end+1,1) = "Controllable";
            Predictability(end+1,1) = predictabilityNames(c);
            Value(end+1,1) = H_S1(i,c);

            SubjectID(end+1,1) = "Healthy_"+string(healthyIDs(i));
            Group(end+1,1) = "Healthy";
            Controllability(end+1,1) = "Uncontrollable";
            Predictability(end+1,1) = predictabilityNames(c);
            Value(end+1,1) = H_S2(i,c);
        end
    end

    for i = 1:numel(chronicIDs)

        for c = 1:3

            SubjectID(end+1,1) = "Chronic_"+string(chronicIDs(i));
            Group(end+1,1) = "Chronic";
            Controllability(end+1,1) = "Controllable";
            Predictability(end+1,1) = predictabilityNames(c);
            Value(end+1,1) = C_S1(i,c);

            SubjectID(end+1,1) = "Chronic_"+string(chronicIDs(i));
            Group(end+1,1) = "Chronic";
            Controllability(end+1,1) = "Uncontrollable";
            Predictability(end+1,1) = predictabilityNames(c);
            Value(end+1,1) = C_S2(i,c);
        end
    end

    Outcome = repmat(string(outcomeName),numel(Value),1);

    T = table( ...
        SubjectID,Group,Controllability,Predictability,Value,Outcome);

    T = T(isfinite(T.Value),:);
end


function D = make_task_descriptives(T)

    groupNames = ["Healthy","Chronic"];
    controlNames = ["Controllable","Uncontrollable"];
    predictabilityNames = ["HP","MP","UP"];

    Group = strings(0,1);
    Controllability = strings(0,1);
    Predictability = strings(0,1);

    N = zeros(0,1);
    Mean = zeros(0,1);
    SD = zeros(0,1);
    SEM = zeros(0,1);

    for g = 1:2
        for s = 1:2
            for p = 1:3

                idx = ...
                    T.Group == groupNames(g) & ...
                    T.Controllability == controlNames(s) & ...
                    T.Predictability == predictabilityNames(p);

                x = T.Value(idx);

                Group(end+1,1) = groupNames(g);
                Controllability(end+1,1) = controlNames(s);
                Predictability(end+1,1) = predictabilityNames(p);

                N(end+1,1) = numel(x);
                Mean(end+1,1) = mean(x,'omitnan');
                SD(end+1,1) = std(x,'omitnan');
                SEM(end+1,1) = std(x,'omitnan')/sqrt(max(numel(x),1));
            end
        end
    end

    D = table( ...
        Group,Controllability,Predictability,N,Mean,SD,SEM);
end


function T = add_effect_column(T)

    rowNames = string(T.Properties.RowNames);

    if isempty(rowNames)
        rowNames = "Row_"+string((1:height(T))');
    end

    T.Effect = rowNames;
    T = movevars(T,'Effect','Before',1);
    T.Properties.RowNames = {};
end


function T = between_group_posthocs(longTable,predictabilityNames)

    Controllability = strings(0,1);
    Predictability = strings(0,1);

    N_Healthy = zeros(0,1);
    N_Chronic = zeros(0,1);

    Mean_Healthy = zeros(0,1);
    Mean_Chronic = zeros(0,1);
    MeanDifference = zeros(0,1);

    t = zeros(0,1);
    df = zeros(0,1);
    p = zeros(0,1);

    CI_Lower = zeros(0,1);
    CI_Upper = zeros(0,1);

    controlNames = ["Controllable","Uncontrollable"];

    for s = 1:2
        for c = 1:3

            idxH = ...
                longTable.Group == "Healthy" & ...
                longTable.Controllability == controlNames(s) & ...
                longTable.Predictability == predictabilityNames(c);

            idxC = ...
                longTable.Group == "Chronic" & ...
                longTable.Controllability == controlNames(s) & ...
                longTable.Predictability == predictabilityNames(c);

            x = longTable.Value(idxH);
            y = longTable.Value(idxC);

            Controllability(end+1,1) = controlNames(s);
            Predictability(end+1,1) = predictabilityNames(c);

            N_Healthy(end+1,1) = numel(x);
            N_Chronic(end+1,1) = numel(y);

            Mean_Healthy(end+1,1) = mean(x,'omitnan');
            Mean_Chronic(end+1,1) = mean(y,'omitnan');

            if numel(x) >= 2 && numel(y) >= 2

                [~,pv,ci,st] = ttest2( ...
                    x,y,'Vartype','unequal');

                MeanDifference(end+1,1) = mean(x)-mean(y);

                t(end+1,1) = st.tstat;
                df(end+1,1) = st.df;
                p(end+1,1) = pv;

                CI_Lower(end+1,1) = ci(1);
                CI_Upper(end+1,1) = ci(2);

            else

                MeanDifference(end+1,1) = NaN;

                t(end+1,1) = NaN;
                df(end+1,1) = NaN;
                p(end+1,1) = NaN;

                CI_Lower(end+1,1) = NaN;
                CI_Upper(end+1,1) = NaN;
            end
        end
    end

    p_Bonferroni = min(p*6,1);

    T = table( ...
        Controllability,Predictability, ...
        N_Healthy,N_Chronic, ...
        Mean_Healthy,Mean_Chronic,MeanDifference, ...
        t,df,p,p_Bonferroni,CI_Lower,CI_Upper);
end


function T = questionnaire_correlations( ...
    questionnaire,Y,questionnaireKey,questionnaireLabel, ...
    groupName,controllability,subjectIDs,outcomeNames)

    Questionnaire = repmat( ...
        string(questionnaireKey),7,1);

    QuestionnaireLabel = repmat( ...
        string(questionnaireLabel),7,1);

    Group = repmat( ...
        string(groupName),7,1);

    Controllability = repmat( ...
        string(controllability),7,1);

    Outcome = outcomeNames(:);

    N = nan(7,1);
    df = nan(7,1);

    r = nan(7,1);
    p = nan(7,1);
    r2 = nan(7,1);

    r_CI_Lower = nan(7,1);
    r_CI_Upper = nan(7,1);

    QuestionnaireMean = nan(7,1);
    OutcomeMean = nan(7,1);

    IncludedParticipants = strings(7,1);

    for k = 1:7

        [x,y,ids] = pairwise_complete( ...
            questionnaire,Y(:,k),subjectIDs);

        stats = pearson_stats(x,y);

        N(k) = stats.N;
        df(k) = stats.df;

        r(k) = stats.r;
        p(k) = stats.p;
        r2(k) = stats.r2;

        r_CI_Lower(k) = stats.CI_Lower;
        r_CI_Upper(k) = stats.CI_Upper;

        QuestionnaireMean(k) = mean(x,'omitnan');
        OutcomeMean(k) = mean(y,'omitnan');

        IncludedParticipants(k) = strjoin( ...
            string(ids),", ");
    end

    T = table( ...
        Questionnaire,QuestionnaireLabel, ...
        Group,Controllability,Outcome, ...
        N,df,r,r_CI_Lower,r_CI_Upper,p,r2, ...
        QuestionnaireMean,OutcomeMean,IncludedParticipants);
end


function S = pearson_stats(x,y)

    x = double(x(:));
    y = double(y(:));

    valid = isfinite(x) & isfinite(y);

    x = x(valid);
    y = y(valid);

    S.N = numel(x);
    S.df = S.N-2;

    S.r = NaN;
    S.p = NaN;
    S.r2 = NaN;

    S.CI_Lower = NaN;
    S.CI_Upper = NaN;

    if S.N < 3 || std(x) == 0 || std(y) == 0
        return
    end

    [S.r,S.p] = corr( ...
        x,y, ...
        'Type','Pearson', ...
        'Rows','complete');

    S.r2 = S.r^2;

    if S.N > 3 && abs(S.r) < 1

        z = atanh(S.r);
        se = 1/sqrt(S.N-3);

        zCritical = norminv(0.975);

        S.CI_Lower = tanh(z-zCritical*se);
        S.CI_Upper = tanh(z+zCritical*se);
    end
end


function [x,y,ids] = pairwise_complete(xRaw,yRaw,subjectIDs)

    xRaw = double(xRaw(:));
    yRaw = double(yRaw(:));

    if nargin < 3
        subjectIDs = string((1:numel(xRaw))');
    else
        subjectIDs = string(subjectIDs(:));
    end

    if numel(xRaw) ~= numel(yRaw) || ...
       numel(subjectIDs) ~= numel(xRaw)

        error('Pairwise vectors have inconsistent participant counts.');
    end

    valid = isfinite(xRaw) & isfinite(yRaw);

    x = xRaw(valid);
    y = yRaw(valid);
    ids = subjectIDs(valid);
end


function limits = padded_limits(x)

    x = x(isfinite(x));

    if isempty(x)
        limits = [0 1];
        return
    end

    xmin = min(x);
    xmax = max(x);

    if xmin == xmax

        delta = max(abs(xmin)*0.10,1);

        limits = [ ...
            xmin-delta, ...
            xmax+delta];

        return
    end

    padding = 0.08*(xmax-xmin);

    limits = [ ...
        xmin-padding, ...
        xmax+padding];
end


function draw_box_with_points( ...
    ax,xPosition,y,color,boxAlpha,dotSize,dotAlpha)

    y = y(isfinite(y));

    if isempty(y)
        return
    end

    boxchart(ax, ...
        xPosition*ones(size(y)),y, ...
        'BoxWidth',0.24, ...
        'BoxFaceColor',color, ...
        'BoxFaceAlpha',boxAlpha, ...
        'WhiskerLineColor','k', ...
        'MarkerStyle','none');

    jitter = (rand(size(y))-0.5)*0.12;

    scatter(ax, ...
        xPosition+jitter,y,dotSize,color,'filled', ...
        'MarkerEdgeColor','k', ...
        'MarkerFaceAlpha',dotAlpha);
end


function plot_task_boxfigure( ...
    H_S1,H_S2,C_S1,C_S2, ...
    predictabilityNames, ...
    yLabelText,outputBase, ...
    colorH1,colorH2,colorC1,colorC2, ...
    fsXTick,fsYTick,fsLabel,fsLegend,axisLineWidth, ...
    boxAlpha,dotSize,dotAlpha,pngDPI)

    fig = figure( ...
        'Color','w', ...
        'Position',[120 90 1020 620]);

    ax = axes(fig);
    hold(ax,'on');

    centers = [1 2.3 3.6];
    offsets = [-0.30 -0.10 0.10 0.30];

    colors = { ...
        colorH1,colorH2, ...
        colorC1,colorC2};

    datasets = { ...
        H_S1,H_S2, ...
        C_S1,C_S2};

    for c = 1:3
        for d = 1:4

            y = datasets{d}(:,c);
            y = y(isfinite(y));

            x = centers(c)+offsets(d);

            if isempty(y)
                continue
            end

            boxchart(ax, ...
                x*ones(size(y)),y, ...
                'BoxWidth',0.16, ...
                'BoxFaceColor',colors{d}, ...
                'BoxFaceAlpha',boxAlpha, ...
                'WhiskerLineColor','k', ...
                'MarkerStyle','none');

            jitter = (rand(size(y))-0.5)*0.07;

            scatter(ax, ...
                x+jitter,y,dotSize,colors{d},'filled', ...
                'MarkerEdgeColor','k', ...
                'MarkerFaceAlpha',dotAlpha);
        end
    end

    ax.XTick = centers;
    ax.XTickLabel = cellstr(predictabilityNames);

    xlabel(ax,'Predictability', ...
        'FontSize',fsLabel, ...
        'FontWeight','bold');

    ylabel(ax,yLabelText, ...
        'FontSize',fsLabel, ...
        'FontWeight','bold');

    style_axes(ax,fsXTick,fsYTick,axisLineWidth);

    h1 = patch(ax,nan,nan,colorH1, ...
        'FaceAlpha',boxAlpha,'EdgeColor','k');

    h2 = patch(ax,nan,nan,colorH2, ...
        'FaceAlpha',boxAlpha,'EdgeColor','k');

    h3 = patch(ax,nan,nan,colorC1, ...
        'FaceAlpha',boxAlpha,'EdgeColor','k');

    h4 = patch(ax,nan,nan,colorC2, ...
        'FaceAlpha',boxAlpha,'EdgeColor','k');

    legend(ax,[h1 h2 h3 h4], ...
        {'Healthy controllable','Healthy uncontrollable', ...
         'Chronic controllable','Chronic uncontrollable'}, ...
        'Location','northeastoutside', ...
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


function add_fit_line(ax,x,y,color,lineWidth)

    x = double(x(:));
    y = double(y(:));

    valid = isfinite(x) & isfinite(y);

    x = x(valid);
    y = y(valid);

    if numel(x) < 2 || std(x) == 0
        return
    end

    coefficients = polyfit(x,y,1);

    xFit = linspace(min(x),max(x),100);
    yFit = polyval(coefficients,xFit);

    plot(ax,xFit,yFit, ...
        'Color',color, ...
        'LineWidth',lineWidth);
end


function style_axes(ax,fsXTick,fsYTick,lineWidth)

    ax.Box = 'off';
    ax.LineWidth = lineWidth;
    ax.TickDir = 'out';

    ax.XAxis.FontSize = fsXTick;
    ax.YAxis.FontSize = fsYTick;

    ax.XGrid = 'off';
    ax.YGrid = 'off';
end


function txt = format_p(p)

    if ~isfinite(p)
        txt = 'NA';

    elseif p < 0.001
        txt = '< .001';

    else
        txt = sprintf('= %.3f',p);
    end
end


function T = harmonize_mapping_table(T)

    if ~ismember('QuestionnaireSubjectID',T.Properties.VariableNames)
        T.QuestionnaireSubjectID = repmat("",height(T),1);
    end

    wanted = { ...
        'Questionnaire','Group', ...
        'TaskSubjectID','QuestionnaireSubjectID', ...
        'QuestionnaireScore'};

    T = T(:,wanted);
end
