%% Cross-measure beta correlations: Subjective ratings vs reaction time
% Chronic stress study — publication/repository version
%
% Purpose
%   Examine cross-measure associations between participant-level
%   computational-model coefficients for subjective stress ratings and
%   reaction time (RT), separately for:
%
%       Group           = Healthy control, Chronic stress
%       Controllability = Controllable (S1), Uncontrollable (S2)
%       Model            = Surprise, Belief uncertainty, Volatility
%
% Correlation analysis
%   - Pearson correlation between Rating beta and RT beta
%   - Separate correlation for each Group x Controllability x Model cell
%   - Fisher r-to-z comparison of Healthy vs Chronic-stress correlations
%   - Optional participant-level >3 SD cleaning within each correlation cell
%
% Multiple-comparison correction
%   The manuscript-level correction is preserved from the original analysis:
%
%   Within-group correlations:
%       3 models x 2 controllability conditions x 2 groups
%       x 2 response-pair analyses (Rating-RT and Rating-SCR)
%       = 24 tests
%
%   Between-group Fisher r-to-z comparisons:
%       3 models x 2 controllability conditions
%       x 2 response-pair analyses (Rating-RT and Rating-SCR)
%       = 12 tests
%
%   This script computes the Rating-RT half of those families but applies
%   Bonferroni correction using the full manuscript-level family sizes
%   (24 and 12), matching the stated analysis plan.
%
% Additional coefficient ANOVAs
%   Separate 2 (Group) x 2 (Controllability) x 3 (Model) mixed
%   repeated-measures ANOVAs are run for:
%       1. Subjective-rating betas
%       2. RT betas
%
%
% Required directory structure
%
%   data/CrossMeasure_Rating_RT/
%       Rating/
%           Healthy/
%           Chronic/
%       RT/
%           Healthy/
%           Chronic/
%
% Exact filenames are defined below.
%
% -------------------------------------------------------------------------
% Daniyal Rajput
% Chronic stress / probabilistic aversive-learning study
% -------------------------------------------------------------------------

clear; clc; close all;
rng(1,'twister');   % reproducible jitter only

%% Paths
scriptDir = fileparts(mfilename('fullpath'));
if isempty(scriptDir)
    scriptDir = pwd;
end

dataDir = fullfile(scriptDir,'data','CrossMeasure_Rating_RT');

ratingHealthyDir = fullfile(dataDir,'Rating','Healthy');
ratingChronicDir = fullfile(dataDir,'Rating','Chronic');

rtHealthyDir = fullfile(dataDir,'RT','Healthy');
rtChronicDir = fullfile(dataDir,'RT','Chronic');

outDir   = fullfile(scriptDir,'results','CrossMeasure_Rating_RT');
figDir   = fullfile(outDir,'figures');
statsDir = fullfile(outDir,'stats');
cleanDir = fullfile(outDir,'cleaned_data');

if ~exist(figDir,'dir'),   mkdir(figDir);   end
if ~exist(statsDir,'dir'), mkdir(statsDir); end
if ~exist(cleanDir,'dir'), mkdir(cleanDir); end

masterExcel = fullfile(statsDir,'Rating_vs_RT_crossmeasure_results.xlsx');
masterMat   = fullfile(statsDir,'Rating_vs_RT_crossmeasure_results.mat');

%% Analysis settings
apply3SDCorrelation = true;
sdThresholdCorrelation = 3;

apply3SDAnova = true;
sdThresholdAnova = 3;

saveCleanedExcel = true;
saveCleanedMat = true;

pngDPI = 600;

%% Multiple-comparison correction
alphaFamilywise = 0.05;

% Full manuscript-level families, including the companion Rating-SCR
% cross-measure analysis.
nWithinTestsFullFamily  = 24;
nBetweenTestsFullFamily = 12;

alphaWithinBonferroni  = alphaFamilywise/nWithinTestsFullFamily;
alphaBetweenBonferroni = alphaFamilywise/nBetweenTestsFullFamily;

%% Figure settings
colorHealthy = [0.00 0.25 0.55];
colorChronic = [0.85 0.33 0.00];

dotSize    = 58;
dotAlpha   = 0.85;
fitLineWidth = 2.2;
axisLineWidth = 1.6;

fsTitle  = 18;
fsLabel  = 20;
fsTick   = 16;
fsLegend = 16;

%% Model/session/group labels
modelList = {'Surprise','BeliefUncertainty','Volatility'};
sessionList = {'S1','S2'};
groupList = {'Healthy','Chronic'};

plotModelNames = struct( ...
    'Surprise','Surprise', ...
    'BeliefUncertainty','Belief Uncertainty', ...
    'Volatility','Volatility');

%% Explicit file map
F = struct();

% ========================================================================
% SURPRISE
% ========================================================================

% Rating betas
F.Surprise.S1.Healthy.Rating = ...
    fullfile(ratingHealthyDir,'healthy_Betas_Rating_Suprise_s1.xlsx');

F.Surprise.S2.Healthy.Rating = ...
    fullfile(ratingHealthyDir,'healthy_Betas_Rating_surprise_s2.xlsx');

F.Surprise.S1.Chronic.Rating = ...
    fullfile(ratingChronicDir,'SRating_Betas_Surpris_CS_S1.xlsx');

F.Surprise.S2.Chronic.Rating = ...
    fullfile(ratingChronicDir,'SRating_Betas_Surprise_CS_S2.xlsx');

% RT betas
F.Surprise.S1.Healthy.RT = ...
    fullfile(rtHealthyDir,'healthy_RT_betas_Surprise_s1.xlsx');

F.Surprise.S2.Healthy.RT = ...
    fullfile(rtHealthyDir,'healthy_RT_betas_Surprise_s2.xlsx');

F.Surprise.S1.Chronic.RT = ...
    fullfile(rtChronicDir,'subject_RT_betas_Surprise_CS_S1.xlsx');

F.Surprise.S2.Chronic.RT = ...
    fullfile(rtChronicDir,'subject_RT_betas_Surprise_CS_S2.xlsx');

% ========================================================================
% BELIEF UNCERTAINTY
% ========================================================================

% Rating betas
F.BeliefUncertainty.S1.Healthy.Rating = ...
    fullfile(ratingHealthyDir,'healthy_Betas_Rating_belief_s1.xlsx');

F.BeliefUncertainty.S2.Healthy.Rating = ...
    fullfile(ratingHealthyDir,'healthy_Betas_Rating_belief_s2.xlsx');

F.BeliefUncertainty.S1.Chronic.Rating = ...
    fullfile(ratingChronicDir,'SRating_Betas_Belief_Uncer_CS_S1.xlsx');

F.BeliefUncertainty.S2.Chronic.Rating = ...
    fullfile(ratingChronicDir,'SRating_Betas_Belief_Uncer_CS_S2.xlsx');

% RT betas
F.BeliefUncertainty.S1.Healthy.RT = ...
    fullfile(rtHealthyDir,'healthy_RT_betas_belief_s1.xlsx');

F.BeliefUncertainty.S2.Healthy.RT = ...
    fullfile(rtHealthyDir,'healthy_RT_betas_belief_s2.xlsx');

F.BeliefUncertainty.S1.Chronic.RT = ...
    fullfile(rtChronicDir,'subject_RT_betas_Estimated_CS_S1.xlsx');

F.BeliefUncertainty.S2.Chronic.RT = ...
    fullfile(rtChronicDir,'subject_RT_betas_Estimated_CS_S2.xlsx');

% ========================================================================
% VOLATILITY
% ========================================================================

% Rating betas
F.Volatility.S1.Healthy.Rating = ...
    fullfile(ratingHealthyDir,'healthy_Betas_Rating_volatility_s1.xlsx');

F.Volatility.S2.Healthy.Rating = ...
    fullfile(ratingHealthyDir,'healthy_Betas_Rating_volatility_s2.xlsx');

F.Volatility.S1.Chronic.Rating = ...
    fullfile(ratingChronicDir,'SRating_Betas_Volatility_CS_S1.xlsx');

F.Volatility.S2.Chronic.Rating = ...
    fullfile(ratingChronicDir,'SRating_Betas_Volatility_CS_S2.xlsx');

% RT betas
F.Volatility.S1.Healthy.RT = ...
    fullfile(rtHealthyDir,'healthy_RT_betas_Volatility_s1.xlsx');

F.Volatility.S2.Healthy.RT = ...
    fullfile(rtHealthyDir,'healthy_RT_betas_Volatility_s2.xlsx');

F.Volatility.S1.Chronic.RT = ...
    fullfile(rtChronicDir,'subject_RT_betas_Volatility_CS_S1.xlsx');

F.Volatility.S2.Chronic.RT = ...
    fullfile(rtChronicDir,'subject_RT_betas_Volatility_CS_S2.xlsx');

%% Validate input files
for m = 1:numel(modelList)
    modelName = modelList{m};

    for s = 1:numel(sessionList)
        sessionName = sessionList{s};

        for g = 1:numel(groupList)
            groupName = groupList{g};

            ratingFile = F.(modelName).(sessionName).(groupName).Rating;
            rtFile = F.(modelName).(sessionName).(groupName).RT;

            assert(isfile(ratingFile), ...
                'Missing Rating file: %s',ratingFile);

            assert(isfile(rtFile), ...
                'Missing RT file: %s',rtFile);
        end
    end
end

%% Read all raw data
RAW = struct();

for m = 1:numel(modelList)
    modelName = modelList{m};

    for s = 1:numel(sessionList)
        sessionName = sessionList{s};

        for g = 1:numel(groupList)
            groupName = groupList{g};

            RAW.(modelName).(sessionName).(groupName).Rating = ...
                read_first_column_numeric( ...
                    F.(modelName).(sessionName).(groupName).Rating);

            RAW.(modelName).(sessionName).(groupName).RT = ...
                read_first_column_numeric( ...
                    F.(modelName).(sessionName).(groupName).RT);
        end
    end
end

%% ========================================================================
% Correlation data: pair by row and clean
% ========================================================================

DATA = struct();
allRT = [];
allRating = [];

correlationCleaningLog = table();

for m = 1:numel(modelList)

    modelName = modelList{m};

    for s = 1:numel(sessionList)

        sessionName = sessionList{s};

        for g = 1:numel(groupList)

            groupName = groupList{g};

            ratingVec = RAW.(modelName).(sessionName).(groupName).Rating;
            rtVec = RAW.(modelName).(sessionName).(groupName).RT;

            context = sprintf('%s | %s | %s', ...
                plotModelNames.(modelName),sessionName,groupName);

            pairTable = pair_by_row(ratingVec,rtVec,context);

            % Pairwise complete cases.
            pairTable = pairTable( ...
                isfinite(pairTable.Beta_Rating) & ...
                isfinite(pairTable.Beta_RT),:);

            originalN = height(pairTable);

            if apply3SDCorrelation
                [pairTable,removedTable] = clean_pair_3sd( ...
                    pairTable,sdThresholdCorrelation);
            else
                removedTable = pairTable([],:);
            end

            DATA.(modelName).(sessionName).(groupName).pairTable = pairTable;

            logRow = table( ...
                string(plotModelNames.(modelName)), ...
                string(session_to_label(sessionName)), ...
                string(group_to_label(groupName)), ...
                originalN, ...
                height(removedTable), ...
                height(pairTable), ...
                'VariableNames', { ...
                    'Model','Controllability','Group', ...
                    'N_Before3SD','N_Removed3SD','N_Final'});

            correlationCleaningLog = [correlationCleaningLog;logRow]; %#ok<AGROW>

            allRT = [allRT;pairTable.Beta_RT(:)]; %#ok<AGROW>
            allRating = [allRating;pairTable.Beta_Rating(:)]; %#ok<AGROW>
        end
    end
end

if isempty(allRT) || isempty(allRating)
    error('No valid paired Rating-RT beta values remained after cleaning.');
end

%% Global figure axes
xMin = min(allRT);
xMax = max(allRT);
yMin = min(allRating);
yMax = max(allRating);

xPad = 0.06*(xMax-xMin+eps);
yPad = 0.06*(yMax-yMin+eps);

globalXLim = [xMin-xPad,xMax+xPad];
globalYLim = [yMin-yPad,yMax+yPad];

%% ========================================================================
% Build participant-aligned wide data for coefficient ANOVAs
% ========================================================================

[wideRatingHealthy,anovaCleanRatingH] = build_wide_group_table( ...
    RAW,'Healthy','Rating',modelList, ...
    apply3SDAnova,sdThresholdAnova);

[wideRatingChronic,anovaCleanRatingC] = build_wide_group_table( ...
    RAW,'Chronic','Rating',modelList, ...
    apply3SDAnova,sdThresholdAnova);

[wideRTHealthy,anovaCleanRTH] = build_wide_group_table( ...
    RAW,'Healthy','RT',modelList, ...
    apply3SDAnova,sdThresholdAnova);

[wideRTChronic,anovaCleanRTC] = build_wide_group_table( ...
    RAW,'Chronic','RT',modelList, ...
    apply3SDAnova,sdThresholdAnova);

WideRating = [wideRatingHealthy;wideRatingChronic];
WideRT = [wideRTHealthy;wideRTChronic];

anovaCleaningLog = [
    anovaCleanRatingH;
    anovaCleanRatingC;
    anovaCleanRTH;
    anovaCleanRTC
    ];

%% Within-subject design
withinDesign = table( ...
    categorical({ ...
        'Surprise';'Surprise'; ...
        'Belief Uncertainty';'Belief Uncertainty'; ...
        'Volatility';'Volatility'}, ...
        {'Surprise','Belief Uncertainty','Volatility'}), ...
    categorical({ ...
        'Controllable';'Uncontrollable'; ...
        'Controllable';'Uncontrollable'; ...
        'Controllable';'Uncontrollable'}, ...
        {'Controllable','Uncontrollable'}), ...
    'VariableNames',{'Model','Controllability'});

%% Mixed ANOVA: subjective-rating betas
rmRating = fitrm( ...
    WideRating, ...
    'Surp_S1-Vol_S2 ~ Group', ...
    'WithinDesign',withinDesign);

anovaRatingWithin = ranova( ...
    rmRating, ...
    'WithinModel','Model*Controllability');

anovaRatingBetween = anova(rmRating);

anovaRatingWithinOut = add_row_names(anovaRatingWithin,'Effect');
anovaRatingBetweenOut = add_row_names(anovaRatingBetween,'Effect');

%% Mixed ANOVA: RT betas
rmRT = fitrm( ...
    WideRT, ...
    'Surp_S1-Vol_S2 ~ Group', ...
    'WithinDesign',withinDesign);

anovaRTWithin = ranova( ...
    rmRT, ...
    'WithinModel','Model*Controllability');

anovaRTBetween = anova(rmRT);

anovaRTWithinOut = add_row_names(anovaRTWithin,'Effect');
anovaRTBetweenOut = add_row_names(anovaRTBetween,'Effect');

%% ========================================================================
% Correlation statistics and figures
% ========================================================================

AllCorrelationResults = table();
AllGroupComparisonResults = table();

for m = 1:numel(modelList)

    modelName = modelList{m};
    displayModel = plotModelNames.(modelName);
    safeModel = regexprep(displayModel,'[^\w]+','_');

    H_S1 = DATA.(modelName).S1.Healthy.pairTable;
    C_S1 = DATA.(modelName).S1.Chronic.pairTable;
    H_S2 = DATA.(modelName).S2.Healthy.pairTable;
    C_S2 = DATA.(modelName).S2.Chronic.pairTable;

    ST_H_S1 = corr_stats(H_S1.Beta_RT,H_S1.Beta_Rating);
    ST_C_S1 = corr_stats(C_S1.Beta_RT,C_S1.Beta_Rating);

    ST_H_S2 = corr_stats(H_S2.Beta_RT,H_S2.Beta_Rating);
    ST_C_S2 = corr_stats(C_S2.Beta_RT,C_S2.Beta_Rating);

    CMP_S1 = compare_independent_correlations( ...
        ST_H_S1.r,ST_H_S1.N, ...
        ST_C_S1.r,ST_C_S1.N);

    CMP_S2 = compare_independent_correlations( ...
        ST_H_S2.r,ST_H_S2.N, ...
        ST_C_S2.r,ST_C_S2.N);

    %% Figure
    fig = figure( ...
        'Color','w', ...
        'Position',[120 120 1300 560]);

    tiled = tiledlayout(fig,1,2, ...
        'TileSpacing','compact', ...
        'Padding','compact');

    % Controllable
    ax1 = nexttile(tiled,1);
    hold(ax1,'on');

    scatter(ax1,H_S1.Beta_RT,H_S1.Beta_Rating, ...
        dotSize,colorHealthy,'filled', ...
        'MarkerEdgeColor','k', ...
        'MarkerFaceAlpha',dotAlpha, ...
        'LineWidth',0.6);

    scatter(ax1,C_S1.Beta_RT,C_S1.Beta_Rating, ...
        dotSize,colorChronic,'filled', ...
        'MarkerEdgeColor','k', ...
        'MarkerFaceAlpha',dotAlpha, ...
        'LineWidth',0.6);

    add_fit_line(ax1,H_S1.Beta_RT,H_S1.Beta_Rating, ...
        colorHealthy,fitLineWidth,globalXLim);

    add_fit_line(ax1,C_S1.Beta_RT,C_S1.Beta_Rating, ...
        colorChronic,fitLineWidth,globalXLim);

    style_axes(ax1,globalXLim,globalYLim,fsTick,axisLineWidth);

    xlabel(ax1,'\beta_{RT}', ...
        'FontSize',fsLabel, ...
        'FontWeight','bold');

    ylabel(ax1,'\beta_{Rating}', ...
        'FontSize',fsLabel, ...
        'FontWeight','bold');

    title(ax1,'Controllable', ...
        'FontSize',fsTitle, ...
        'FontWeight','bold');

    % Uncontrollable
    ax2 = nexttile(tiled,2);
    hold(ax2,'on');

    hHealthy = scatter(ax2,H_S2.Beta_RT,H_S2.Beta_Rating, ...
        dotSize,colorHealthy,'filled', ...
        'MarkerEdgeColor','k', ...
        'MarkerFaceAlpha',dotAlpha, ...
        'LineWidth',0.6);

    hChronic = scatter(ax2,C_S2.Beta_RT,C_S2.Beta_Rating, ...
        dotSize,colorChronic,'filled', ...
        'MarkerEdgeColor','k', ...
        'MarkerFaceAlpha',dotAlpha, ...
        'LineWidth',0.6);

    add_fit_line(ax2,H_S2.Beta_RT,H_S2.Beta_Rating, ...
        colorHealthy,fitLineWidth,globalXLim);

    add_fit_line(ax2,C_S2.Beta_RT,C_S2.Beta_Rating, ...
        colorChronic,fitLineWidth,globalXLim);

    style_axes(ax2,globalXLim,globalYLim,fsTick,axisLineWidth);

    xlabel(ax2,'\beta_{RT}', ...
        'FontSize',fsLabel, ...
        'FontWeight','bold');

    ylabel(ax2,'\beta_{Rating}', ...
        'FontSize',fsLabel, ...
        'FontWeight','bold');

    title(ax2,'Uncontrollable', ...
        'FontSize',fsTitle, ...
        'FontWeight','bold');

    legend(ax2,[hHealthy,hChronic], ...
        {'Healthy controls','Chronic stress'}, ...
        'Location','northeastoutside', ...
        'Box','off', ...
        'FontSize',fsLegend);

    title(tiled,displayModel, ...
        'FontSize',17, ...
        'FontWeight','bold');

    figureBase = fullfile(figDir, ...
        sprintf('Correlation_Rating_vs_RT_%s',safeModel));

    exportgraphics(fig,[figureBase '.png'], ...
        'Resolution',pngDPI);

    exportgraphics(fig,[figureBase '.tiff'], ...
        'Resolution',pngDPI);

    exportgraphics(fig,[figureBase '.pdf'], ...
        'ContentType','vector');

    close(fig);

    %% Correlation results table
    CorrTbl = table( ...
        repmat(string(displayModel),4,1), ...
        ["Controllable";"Controllable";"Uncontrollable";"Uncontrollable"], ...
        ["Healthy";"Chronic";"Healthy";"Chronic"], ...
        [ST_H_S1.N;ST_C_S1.N;ST_H_S2.N;ST_C_S2.N], ...
        [ST_H_S1.r;ST_C_S1.r;ST_H_S2.r;ST_C_S2.r], ...
        [ST_H_S1.r_CI_low;ST_C_S1.r_CI_low; ...
         ST_H_S2.r_CI_low;ST_C_S2.r_CI_low], ...
        [ST_H_S1.r_CI_high;ST_C_S1.r_CI_high; ...
         ST_H_S2.r_CI_high;ST_C_S2.r_CI_high], ...
        [ST_H_S1.t;ST_C_S1.t;ST_H_S2.t;ST_C_S2.t], ...
        [ST_H_S1.df;ST_C_S1.df;ST_H_S2.df;ST_C_S2.df], ...
        [ST_H_S1.p;ST_C_S1.p;ST_H_S2.p;ST_C_S2.p], ...
        [ST_H_S1.r2;ST_C_S1.r2;ST_H_S2.r2;ST_C_S2.r2], ...
        'VariableNames', { ...
            'Model','Controllability','Group','N','r', ...
            'r_CI_Lower','r_CI_Upper','t','df','p','r2'});

    CompareTbl = table( ...
        repmat(string(displayModel),2,1), ...
        ["Controllable";"Uncontrollable"], ...
        [ST_H_S1.r;ST_H_S2.r], ...
        [ST_H_S1.N;ST_H_S2.N], ...
        [ST_C_S1.r;ST_C_S2.r], ...
        [ST_C_S1.N;ST_C_S2.N], ...
        [CMP_S1.z;CMP_S2.z], ...
        [CMP_S1.p;CMP_S2.p], ...
        'VariableNames', { ...
            'Model','Controllability', ...
            'r_Healthy','N_Healthy', ...
            'r_Chronic','N_Chronic', ...
            'Fisher_z','p'});

    AllCorrelationResults = [AllCorrelationResults;CorrTbl]; %#ok<AGROW>
    AllGroupComparisonResults = [AllGroupComparisonResults;CompareTbl]; %#ok<AGROW>

    %% Save cell-level cleaned data
    if saveCleanedExcel

        cleanedExcel = fullfile(cleanDir, ...
            sprintf('Cleaned_Rating_RT_%s.xlsx',safeModel));

        if isfile(cleanedExcel)
            delete(cleanedExcel);
        end

        writetable(H_S1,cleanedExcel,'Sheet','Healthy_Controllable');
        writetable(C_S1,cleanedExcel,'Sheet','Chronic_Controllable');

        writetable(H_S2,cleanedExcel,'Sheet','Healthy_Uncontrollable');
        writetable(C_S2,cleanedExcel,'Sheet','Chronic_Uncontrollable');
    end

    if saveCleanedMat

        Cleaned = struct();
        Cleaned.Model = displayModel;

        Cleaned.Controllable.Healthy = H_S1;
        Cleaned.Controllable.Chronic = C_S1;

        Cleaned.Uncontrollable.Healthy = H_S2;
        Cleaned.Uncontrollable.Chronic = C_S2;

        save(fullfile(cleanDir, ...
            sprintf('Cleaned_Rating_RT_%s.mat',safeModel)), ...
            'Cleaned');
    end
end

%% ========================================================================
% Manuscript-level Bonferroni correction
% ========================================================================

AllCorrelationResults.Properties.VariableNames{'p'} = 'p_Uncorrected';

AllCorrelationResults.p_Bonferroni = min( ...
    AllCorrelationResults.p_Uncorrected*nWithinTestsFullFamily,1);

AllCorrelationResults.Alpha_Bonferroni = repmat( ...
    alphaWithinBonferroni, ...
    height(AllCorrelationResults),1);

AllCorrelationResults.Significant_Uncorrected = ...
    AllCorrelationResults.p_Uncorrected < alphaFamilywise;

AllCorrelationResults.Significant_Bonferroni = ...
    AllCorrelationResults.p_Bonferroni < alphaFamilywise;

AllCorrelationResults.CorrectionFamilySize = repmat( ...
    nWithinTestsFullFamily, ...
    height(AllCorrelationResults),1);

AllCorrelationResults.CorrectionMethod = repmat( ...
    "Bonferroni FWER", ...
    height(AllCorrelationResults),1);


AllGroupComparisonResults.Properties.VariableNames{'p'} = 'p_Uncorrected';

AllGroupComparisonResults.p_Bonferroni = min( ...
    AllGroupComparisonResults.p_Uncorrected*nBetweenTestsFullFamily,1);

AllGroupComparisonResults.Alpha_Bonferroni = repmat( ...
    alphaBetweenBonferroni, ...
    height(AllGroupComparisonResults),1);

AllGroupComparisonResults.Significant_Uncorrected = ...
    AllGroupComparisonResults.p_Uncorrected < alphaFamilywise;

AllGroupComparisonResults.Significant_Bonferroni = ...
    AllGroupComparisonResults.p_Bonferroni < alphaFamilywise;

AllGroupComparisonResults.CorrectionFamilySize = repmat( ...
    nBetweenTestsFullFamily, ...
    height(AllGroupComparisonResults),1);

AllGroupComparisonResults.CorrectionMethod = repmat( ...
    "Bonferroni FWER", ...
    height(AllGroupComparisonResults),1);

%% Correction metadata
CorrectionInfo = table( ...
    ["Within-group Pearson correlations"; ...
     "Between-group Fisher r-to-z comparisons"], ...
    [nWithinTestsFullFamily; ...
     nBetweenTestsFullFamily], ...
    [alphaWithinBonferroni; ...
     alphaBetweenBonferroni], ...
    ["3 models x 2 controllability conditions x 2 groups x 2 response pairs"; ...
     "3 models x 2 controllability conditions x 2 response pairs"], ...
    'VariableNames', { ...
        'TestFamily','NumberOfTests','BonferroniAlpha','FamilyDefinition'});

%% Analysis metadata
AnalysisInfo = table( ...
    ["Cross-measure analysis"; ...
     "X variable"; ...
     "Y variable"; ...
     "Groups"; ...
     "Controllability"; ...
     "Models"; ...
     "Correlation cleaning"; ...
     "Correlation SD threshold"; ...
     "Rating-beta ANOVA"; ...
     "RT-beta ANOVA"; ...
     "ANOVA cleaning"; ...
     "ANOVA SD threshold"; ...
     "Participant pairing"; ...
     "Silent truncation of unequal files"], ...
    ["Rating vs RT computational coefficients"; ...
     "RT beta"; ...
     "Subjective-rating beta"; ...
     "Healthy controls vs Chronic stress"; ...
     "Controllable vs Uncontrollable"; ...
     "Surprise, Belief uncertainty, Volatility"; ...
     string(apply3SDCorrelation); ...
     string(sdThresholdCorrelation); ...
     "2 x 2 x 3 Group x Controllability x Model RM-ANOVA"; ...
     "2 x 2 x 3 Group x Controllability x Model RM-ANOVA"; ...
     string(apply3SDAnova); ...
     string(sdThresholdAnova); ...
     "Row order, because source files contain no consistent participant IDs"; ...
     "Not allowed; unequal lengths trigger an error"], ...
    'VariableNames',{'Item','Value'});

%% ========================================================================
% Export master results
% ========================================================================

if isfile(masterExcel)
    delete(masterExcel);
end

writetable(AllCorrelationResults, ...
    masterExcel,'Sheet','Correlations');

writetable(AllGroupComparisonResults, ...
    masterExcel,'Sheet','Group_Correlation_Compare');

writetable(CorrectionInfo, ...
    masterExcel,'Sheet','Correction_Info');

writetable(correlationCleaningLog, ...
    masterExcel,'Sheet','Correlation_Cleaning');

writetable(WideRating, ...
    masterExcel,'Sheet','Wide_Rating');

writetable(WideRT, ...
    masterExcel,'Sheet','Wide_RT');

writetable(anovaCleaningLog, ...
    masterExcel,'Sheet','ANOVA_Cleaning');

writetable(anovaRatingWithinOut, ...
    masterExcel,'Sheet','ANOVA_Rating_Within');

writetable(anovaRatingBetweenOut, ...
    masterExcel,'Sheet','ANOVA_Rating_Between');

writetable(anovaRTWithinOut, ...
    masterExcel,'Sheet','ANOVA_RT_Within');

writetable(anovaRTBetweenOut, ...
    masterExcel,'Sheet','ANOVA_RT_Between');

writetable(AnalysisInfo, ...
    masterExcel,'Sheet','Analysis_Info');

save(masterMat, ...
    'RAW','DATA', ...
    'AllCorrelationResults','AllGroupComparisonResults', ...
    'CorrectionInfo','correlationCleaningLog', ...
    'WideRating','WideRT','anovaCleaningLog', ...
    'rmRating','anovaRatingWithin','anovaRatingBetween', ...
    'rmRT','anovaRTWithin','anovaRTBetween', ...
    'AnalysisInfo');

%% Console summary
fprintf('\n============================================================\n');
fprintf('Rating vs RT cross-measure analysis complete.\n');
fprintf('============================================================\n');

fprintf('Within-group Bonferroni family: %d tests; alpha = %.8f\n', ...
    nWithinTestsFullFamily,alphaWithinBonferroni);

fprintf('Between-group Bonferroni family: %d tests; alpha = %.8f\n', ...
    nBetweenTestsFullFamily,alphaBetweenBonferroni);

fprintf('Significant within-group correlations after correction: %d / %d\n', ...
    sum(AllCorrelationResults.Significant_Bonferroni), ...
    height(AllCorrelationResults));

fprintf('Significant between-group differences after correction: %d / %d\n', ...
    sum(AllGroupComparisonResults.Significant_Bonferroni), ...
    height(AllGroupComparisonResults));

fprintf('\nMaster results:\n%s\n',masterExcel);
fprintf('Figures:\n%s\n',figDir);
fprintf('Cleaned data:\n%s\n\n',cleanDir);


%% ========================================================================
% Local functions
% ========================================================================

function x = read_first_column_numeric(filePath)

    T = readtable(filePath,'VariableNamingRule','preserve');

    if width(T) < 1
        error('No columns found in file: %s',filePath);
    end

    raw = T{:,1};

    if isnumeric(raw) || islogical(raw)
        x = double(raw(:));

    elseif iscell(raw)
        x = str2double(string(raw(:)));

    elseif isstring(raw) || ischar(raw) || iscategorical(raw)
        x = str2double(string(raw(:)));

    else
        error('First column is not convertible to numeric values: %s',filePath);
    end
end


function T = pair_by_row(ratingVec,rtVec,context)

    ratingVec = double(ratingVec(:));
    rtVec = double(rtVec(:));

    if numel(ratingVec) ~= numel(rtVec)
        error(['Unequal vector lengths for %s.\n' ...
               'Rating N = %d, RT N = %d.\n' ...
               'Row-order pairing would be unsafe, so the analysis was stopped.'], ...
               context,numel(ratingVec),numel(rtVec));
    end

    RowID = (1:numel(ratingVec))';
    Beta_Rating = ratingVec;
    Beta_RT = rtVec;

    T = table(RowID,Beta_Rating,Beta_RT);
end


function [cleaned,removed] = clean_pair_3sd(T,threshold)

    if height(T) < 5
        cleaned = T;
        removed = T([],:);
        return
    end

    x = [T.Beta_Rating,T.Beta_RT];

    mu = mean(x,1,'omitnan');
    sd = std(x,0,1,'omitnan');
    sd(sd < eps) = eps;

    Z = abs((x-mu)./sd);

    removeRows = any(Z > threshold,2);

    removed = T(removeRows,:);
    cleaned = T(~removeRows,:);
end


function [T,logTable] = build_wide_group_table( ...
    RAW,groupName,measureName,modelList,apply3SD,threshold)

    vectors = cell(1,6);

    vectors{1} = RAW.(modelList{1}).S1.(groupName).(measureName);
    vectors{2} = RAW.(modelList{1}).S2.(groupName).(measureName);

    vectors{3} = RAW.(modelList{2}).S1.(groupName).(measureName);
    vectors{4} = RAW.(modelList{2}).S2.(groupName).(measureName);

    vectors{5} = RAW.(modelList{3}).S1.(groupName).(measureName);
    vectors{6} = RAW.(modelList{3}).S2.(groupName).(measureName);

    lengths = cellfun(@numel,vectors);

    if numel(unique(lengths)) ~= 1
        error(['Unequal source-vector lengths for %s %s ANOVA.\n' ...
               'Lengths [Surp_S1 Surp_S2 BU_S1 BU_S2 Vol_S1 Vol_S2] = %s.\n' ...
               'The script does not silently truncate repeated-measures data.'], ...
               groupName,measureName,mat2str(lengths));
    end

    n = lengths(1);

    M = nan(n,6);

    for i = 1:6
        M(:,i) = double(vectors{i}(:));
    end

    if groupName == "Healthy"
        prefix = "H";
    else
        prefix = "C";
    end

    SubjectID = prefix + compose("%03d",(1:n)');

    completeRows = all(isfinite(M),2);

    M = M(completeRows,:);
    SubjectID = SubjectID(completeRows);

    nBefore3SD = size(M,1);

    if apply3SD && size(M,1) >= 5

        mu = mean(M,1,'omitnan');
        sd = std(M,0,1,'omitnan');
        sd(sd < eps) = eps;

        Z = abs((M-mu)./sd);

        removeRows = any(Z > threshold,2);

    else
        Z = nan(size(M));
        removeRows = false(size(M,1),1);
    end

    removedIDs = SubjectID(removeRows);

    if isempty(removedIDs)
        removedText = "";
    else
        removedText = strjoin(removedIDs,", ");
    end

    M = M(~removeRows,:);
    SubjectID = SubjectID(~removeRows);

    Group = categorical( ...
        repmat(string(group_to_label(groupName)),numel(SubjectID),1), ...
        {'Healthy controls','Chronic stress'});

    T = table( ...
        SubjectID,Group, ...
        M(:,1),M(:,2),M(:,3),M(:,4),M(:,5),M(:,6), ...
        'VariableNames', { ...
            'SubjectID','Group', ...
            'Surp_S1','Surp_S2', ...
            'BU_S1','BU_S2', ...
            'Vol_S1','Vol_S2'});

    logTable = table( ...
        string(group_to_label(groupName)), ...
        string(measureName), ...
        n, ...
        n-sum(completeRows), ...
        nBefore3SD, ...
        sum(removeRows), ...
        height(T), ...
        removedText, ...
        'VariableNames', { ...
            'Group','Measure','N_Raw','N_IncompleteRemoved', ...
            'N_Before3SD','N_Removed3SD','N_Final','RemovedSubjectIDs'});
end


function ST = corr_stats(x,y)

    x = double(x(:));
    y = double(y(:));

    valid = isfinite(x) & isfinite(y);

    x = x(valid);
    y = y(valid);

    N = numel(x);

    ST.N = N;
    ST.r = NaN;
    ST.p = NaN;
    ST.t = NaN;
    ST.df = NaN;
    ST.r2 = NaN;
    ST.r_CI_low = NaN;
    ST.r_CI_high = NaN;

    if N < 3
        return
    end

    if std(x) == 0 || std(y) == 0
        return
    end

    [r,p] = corr(x,y,'Type','Pearson','Rows','complete');

    ST.r = r;
    ST.p = p;
    ST.df = N-2;
    ST.r2 = r^2;

    if abs(r) < 1
        ST.t = r*sqrt((N-2)/(1-r^2));
    end

    % Fisher-z 95% CI for r.
    if N > 3 && abs(r) < 1
        z = atanh(r);
        se = 1/sqrt(N-3);

        zLow = z-1.96*se;
        zHigh = z+1.96*se;

        ST.r_CI_low = tanh(zLow);
        ST.r_CI_high = tanh(zHigh);
    end
end


function CMP = compare_independent_correlations(r1,n1,r2,n2)

    CMP.z = NaN;
    CMP.p = NaN;

    if n1 <= 3 || n2 <= 3
        return
    end

    if ~isfinite(r1) || ~isfinite(r2)
        return
    end

    % Protect atanh from exactly +/-1.
    r1 = max(min(r1,1-eps),-1+eps);
    r2 = max(min(r2,1-eps),-1+eps);

    z1 = atanh(r1);
    z2 = atanh(r2);

    se = sqrt(1/(n1-3)+1/(n2-3));

    z = (z1-z2)/se;
    p = 2*(1-normcdf(abs(z),0,1));

    CMP.z = z;
    CMP.p = p;
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

    coeff = polyfit(x,y,1);

    xFit = linspace(xLimits(1),xLimits(2),100);
    yFit = polyval(coeff,xFit);

    plot(ax,xFit,yFit, ...
        'Color',lineColor, ...
        'LineWidth',lineWidth);
end


function style_axes(ax,xLimits,yLimits,fontSize,lineWidth)

    xlim(ax,xLimits);
    ylim(ax,yLimits);

    ax.Box = 'off';
    ax.LineWidth = lineWidth;
    ax.TickDir = 'out';
    ax.FontSize = fontSize;
    ax.Layer = 'top';

    ax.XGrid = 'off';
    ax.YGrid = 'off';
end


function T = add_row_names(T,newName)

    rowNames = string(T.Properties.RowNames);

    if isempty(rowNames)
        rowNames = "Row_" + string((1:height(T))');
    end

    T.(newName) = rowNames;
    T = movevars(T,newName,'Before',1);
    T.Properties.RowNames = {};

    T.(newName) = replace(T.(newName),':',' x ');
end


function label = session_to_label(sessionName)

    if strcmpi(sessionName,'S1')
        label = 'Controllable';
    else
        label = 'Uncontrollable';
    end
end


function label = group_to_label(groupName)

    if strcmpi(groupName,'Healthy')
        label = 'Healthy controls';
    else
        label = 'Chronic stress';
    end
end
