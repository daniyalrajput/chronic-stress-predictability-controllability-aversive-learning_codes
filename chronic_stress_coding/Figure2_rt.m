%% Chronic stress study: Reaction-time analysis
% Publication/repository version
%
% Study design
%   Between-participant factor:
%       Group = Healthy controls vs Chronic stress
%
%   Within-participant factors:
%       Controllability = Controllable vs Uncontrollable
%       Predictability = High (HP) vs Moderate (MP) vs Unpredictable (UP)
%
% Primary analysis
%   2 (Group) x 2 (Controllability) x 3 (Predictability)
%   mixed repeated-measures ANOVA on participant-level reaction times.
%
% This script reproduces the reaction-time analysis used in the chronic
% stress study. It loads participant-level summary data, applies the same
% data-cleaning rules as the analysis script, computes descriptive
% statistics, performs the mixed repeated-measures ANOVA and planned
% follow-up tests, and exports the publication figure and analysis tables.
%
% Expected input MAT-file structure
%   results.Controllable.HP
%   results.Controllable.MP
%   results.Controllable.UP
%   results.Uncontrollable.HP
%   results.Uncontrollable.MP
%   results.Uncontrollable.UP
%
% Recommended folder structure
%   project/
%       RT_analysis_chronic_stress_publication.m
%       data/
%           RT_AllData_First5Trials_study1.mat
%           RT_AllData_chronic.mat
%       results/        % created automatically
%
%
% Author: Daniyal Rajput
% Study: Chronic stress, predictability, controllability and aversive learning
% -------------------------------------------------------------------------

clear; clc; close all;
rng(1, 'twister');  % reproducible jitter for figure only

%% ============================== PATHS ====================================
scriptDir = fileparts(mfilename('fullpath'));
if isempty(scriptDir)
    scriptDir = pwd;
end

dataDir = fullfile(scriptDir, 'data');
outDir  = fullfile(scriptDir, 'results', 'RT');
if ~exist(outDir, 'dir')
    mkdir(outDir);
end

healthyFile = fullfile(dataDir, 'RT_AllData_First5Trials_study1.mat');
chronicFile = fullfile(dataDir, 'RT_AllData_chronic.mat');

assert(isfile(healthyFile), 'Healthy-control data file not found: %s', healthyFile);
assert(isfile(chronicFile), 'Chronic-stress data file not found: %s', chronicFile);

excelFile = fullfile(outDir, 'RT_analysis_results.xlsx');
matFile   = fullfile(outDir, 'RT_cleaned_data.mat');

%% ============================== CLEANING SETTINGS ========================
use3SDRemoval = true;
manualRemoveTolerance = 1.0;

% Manual exclusions preserved from the original analysis.
% Values are matched to the nearest value within the specified cell.
manualRemove = struct();
manualRemove.H_HP_S1 = [];
manualRemove.H_MP_S1 = [];
manualRemove.H_UP_S1 = [];
manualRemove.H_HP_S2 = [];
manualRemove.H_MP_S2 = [];
manualRemove.H_UP_S2 = [];
manualRemove.C_HP_S1 = [];
manualRemove.C_MP_S1 = [];
manualRemove.C_UP_S1 = [];
manualRemove.C_HP_S2 = [];
manualRemove.C_MP_S2 = [];
manualRemove.C_UP_S2 = [];

%% ============================== FIGURE SETTINGS ==========================
figPos = [100 180 1550 650];
savePngDpi = 600;

boxWidth     = 0.30;
dotSize      = 42;
jitterWidth  = 0.075;
boxAlpha     = 0.45;
scatterAlpha = 0.80;

lwAxes    = 0.8;
lwBox     = 1.0;
lwWhisker = 1.0;
lwMedian  = 1.2;
lwSEM     = 1.0;
lwScatter = 0.6;
meanDotSize = 5;

fsTitle       = 18;
fsAxisLabel   = 18;
fsTick        = 15;
fsGroupLabel  = 15;
fsLegend      = 16;

yLabel = 'Reaction time (ms)';
nYTicks = 5;
yMin = 200;
yMax = 800;

leftMargin = 1.0;
gapWithinGroup = 0.6;
gapControlUncontrol = 1.0;
gapBetweenPredictability = 1.5;

% Colors retained from the manuscript figure script.
col.H_S1 = [0.00 0.20 0.70];
col.C_S1 = [0.85 0.35 0.05];
col.H_S2 = [0.35 0.60 0.90];
col.C_S2 = [0.95 0.70 0.35];

%% ============================== LOAD DATA ================================
H = load(healthyFile);
C = load(chronicFile);

validate_input(H, 'Healthy');
validate_input(C, 'Chronic stress');

H_HP_S1 = H.results.Controllable.HP(:);
H_MP_S1 = H.results.Controllable.MP(:);
H_UP_S1 = H.results.Controllable.UP(:);
H_HP_S2 = H.results.Uncontrollable.HP(:);
H_MP_S2 = H.results.Uncontrollable.MP(:);
H_UP_S2 = H.results.Uncontrollable.UP(:);

C_HP_S1 = C.results.Controllable.HP(:);
C_MP_S1 = C.results.Controllable.MP(:);
C_UP_S1 = C.results.Controllable.UP(:);
C_HP_S2 = C.results.Uncontrollable.HP(:);
C_MP_S2 = C.results.Uncontrollable.MP(:);
C_UP_S2 = C.results.Uncontrollable.UP(:);

nH = numel(H_HP_S1);
nC = numel(C_HP_S1);

assert(all([numel(H_MP_S1), numel(H_UP_S1), numel(H_HP_S2), ...
            numel(H_MP_S2), numel(H_UP_S2)] == nH), ...
    'Healthy-control condition vectors have unequal participant counts.');
assert(all([numel(C_MP_S1), numel(C_UP_S1), numel(C_HP_S2), ...
            numel(C_MP_S2), numel(C_UP_S2)] == nC), ...
    'Chronic-stress condition vectors have unequal participant counts.');

healthyIDs = compose("H%02d", (1:nH)');
chronicIDs = compose("C%02d", (1:nC)');

% Keep the same column order as the original analysis because fitrm uses
% this order for the repeated-measures design.
healthyRaw = table(healthyIDs, H_HP_S1, H_HP_S2, H_MP_S1, H_MP_S2, H_UP_S1, H_UP_S2, ...
    'VariableNames', {'SubjectID','HP_S1','HP_S2','MP_S1','MP_S2','UP_S1','UP_S2'});
chronicRaw = table(chronicIDs, C_HP_S1, C_HP_S2, C_MP_S1, C_MP_S2, C_UP_S1, C_UP_S2, ...
    'VariableNames', {'SubjectID','HP_S1','HP_S2','MP_S1','MP_S2','UP_S1','UP_S2'});

writetable(healthyRaw, excelFile, 'Sheet', 'Healthy_Raw');
writetable(chronicRaw, excelFile, 'Sheet', 'Chronic_Raw');

%% ============================== CLEAN DATA ===============================
healthy = healthyRaw;
chronic = chronicRaw;

[healthy, chronic, removalLog] = apply_cleaning( ...
    healthy, chronic, manualRemove, manualRemoveTolerance, use3SDRemoval);

measureVars = {'HP_S1','HP_S2','MP_S1','MP_S2','UP_S1','UP_S2'};
healthy.CompleteCase = all(~isnan(healthy{:, measureVars}), 2);
chronic.CompleteCase = all(~isnan(chronic{:, measureVars}), 2);

healthyStats = healthy(healthy.CompleteCase,:);
chronicStats = chronic(chronic.CompleteCase,:);

writetable(healthy, excelFile, 'Sheet', 'Healthy_Cleaned');
writetable(chronic, excelFile, 'Sheet', 'Chronic_Cleaned');
writetable(removalLog, excelFile, 'Sheet', 'Removal_Log');

save(matFile, 'healthyRaw','chronicRaw','healthy','chronic', ...
    'healthyStats','chronicStats','manualRemove','manualRemoveTolerance', ...
    'use3SDRemoval','removalLog');

%% ============================== DESCRIPTIVES =============================
descriptives = make_descriptives(healthy, chronic, measureVars);
writetable(descriptives, excelFile, 'Sheet', 'Descriptives');

%% ============================== 2 x 2 x 3 MIXED RM-ANOVA =================
% Between-participant factor:
%   Group = Healthy control vs Chronic stress
%
% Within-participant factors:
%   Controllability = Controllable vs Uncontrollable
%   Predictability  = HP vs MP vs UP

allStats = [healthyStats; chronicStats];
Group = [repmat({'Healthy'}, height(healthyStats), 1); ...
         repmat({'Chronic'}, height(chronicStats), 1)];
allStats.Group = categorical(Group);
allStats = movevars(allStats, 'Group', 'Before', 'HP_S1');

% Column order in allStats:
% HP_S1, HP_S2, MP_S1, MP_S2, UP_S1, UP_S2
WithinDesign = table( ...
    categorical({'HP','HP','MP','MP','UP','UP'})', ...
    categorical({'Controllable','Uncontrollable', ...
                 'Controllable','Uncontrollable', ...
                 'Controllable','Uncontrollable'})', ...
    'VariableNames', {'Predictability','Controllability'});

rm = fitrm(allStats, 'HP_S1-UP_S2 ~ Group', 'WithinDesign', WithinDesign);

betweenTable = anova(rm);
withinTable  = ranova(rm, 'WithinModel', 'Controllability*Predictability');

% Preserve the native MATLAB ANOVA output for reproducibility.
writetable(with_row_names(betweenTable), excelFile, 'Sheet', 'ANOVA_Between');
writetable(with_row_names(withinTable), excelFile, 'Sheet', 'ANOVA_Within');

% Publication-friendly summary with denominator df and partial eta squared.
anovaSummary = summarize_anova(betweenTable, withinTable);
writetable(anovaSummary, excelFile, 'Sheet', 'ANOVA_Summary');

%% ============================== PLANNED FOLLOW-UP TESTS ==================
% Group comparisons within each Controllability x Predictability cell.
postGroup = group_simple_effects(healthyStats, chronicStats);
writetable(postGroup, excelFile, 'Sheet', 'Post_Group_byCell');

% Controllable vs Uncontrollable within each Group x Predictability cell.
postControllability = controllability_simple_effects(healthyStats, chronicStats);
writetable(postControllability, excelFile, 'Sheet', 'Post_Controllability');

% Predictability pairwise comparisons within each Group x Controllability cell.
postPredictability = predictability_simple_effects(healthyStats, chronicStats);
writetable(postPredictability, excelFile, 'Sheet', 'Post_Predictability');

%% ============================== CELL MEANS ===============================
cellMeans = make_cell_means(healthyStats, chronicStats);
writetable(cellMeans, excelFile, 'Sheet', 'Cell_Means');

%% ============================== PUBLICATION FIGURE =======================
plotData = {
    healthy.HP_S1(~isnan(healthy.HP_S1)), chronic.HP_S1(~isnan(chronic.HP_S1)), healthy.HP_S2(~isnan(healthy.HP_S2)), chronic.HP_S2(~isnan(chronic.HP_S2));
    healthy.MP_S1(~isnan(healthy.MP_S1)), chronic.MP_S1(~isnan(chronic.MP_S1)), healthy.MP_S2(~isnan(healthy.MP_S2)), chronic.MP_S2(~isnan(chronic.MP_S2));
    healthy.UP_S1(~isnan(healthy.UP_S1)), chronic.UP_S1(~isnan(chronic.UP_S1)), healthy.UP_S2(~isnan(healthy.UP_S2)), chronic.UP_S2(~isnan(chronic.UP_S2))
    };

panelTitles = {'Highly predictable','Moderately predictable','Unpredictable'};
plotCols = {col.H_S1, col.C_S1, col.H_S2, col.C_S2};

fig = figure('Color', 'w', 'Position', figPos);
ax = axes(fig);
hold(ax, 'on');

posBlock = [ ...
    leftMargin, ...
    leftMargin + gapWithinGroup, ...
    leftMargin + gapWithinGroup + gapControlUncontrol, ...
    leftMargin + 2*gapWithinGroup + gapControlUncontrol];
blockWidth = 2*gapWithinGroup + gapControlUncontrol;

panelCenters = zeros(1,3);
ctrlCenters = zeros(1,3);
unctrlCenters = zeros(1,3);
yRange = yMax - yMin;

for p = 1:3
    pos = posBlock + (p-1)*(blockWidth + gapBetweenPredictability);

    panelCenters(p) = mean(pos([1 4]));
    ctrlCenters(p) = mean(pos(1:2));
    unctrlCenters(p) = mean(pos(3:4));

    yAll = [];
    gAll = [];
    for j = 1:4
        yy = plotData{p,j};
        yAll = [yAll; yy(:)]; %#ok<AGROW>
        gAll = [gAll; repmat(j, numel(yy), 1)]; %#ok<AGROW>
    end

    boxplot(ax, yAll, gAll, ...
        'Positions', pos, ...
        'Widths', boxWidth, ...
        'Labels', {'','','',''}, ...
        'Symbol', '', ...
        'Whisker', 1.5, ...
        'Colors', 'k');

    delete(findobj(ax, 'Tag', 'Outliers'));
    set(findobj(ax, 'Tag', 'Box'), 'LineWidth', lwBox, 'Color', 'k');
    set(findobj(ax, 'Tag', 'Whisker'), 'LineWidth', lwWhisker, 'Color', 'k');
    set(findobj(ax, 'Tag', 'Median'), 'LineWidth', lwMedian, 'Color', 'k');
    set(findobj(ax, 'Tag', 'Upper Adjacent Value'), 'LineWidth', lwWhisker, 'Color', 'k');
    set(findobj(ax, 'Tag', 'Lower Adjacent Value'), 'LineWidth', lwWhisker, 'Color', 'k');

    hb = findobj(ax, 'Tag', 'Box');
    hb = flipud(hb(1:4));

    for j = 1:4
        patch(get(hb(j), 'XData'), get(hb(j), 'YData'), plotCols{j}, ...
            'FaceAlpha', boxAlpha, 'EdgeColor', 'k', 'LineWidth', lwBox);

        yy = plotData{p,j};
        xx = pos(j) + (rand(size(yy))-0.5)*2*jitterWidth;
        scatter(ax, xx, yy, dotSize, ...
            'MarkerFaceColor', plotCols{j}, ...
            'MarkerEdgeColor', 'k', ...
            'MarkerFaceAlpha', scatterAlpha, ...
            'LineWidth', lwScatter);

        if ~isempty(yy)
            m = mean(yy, 'omitnan');
            se = std(yy, 'omitnan')/sqrt(numel(yy));
            plot(ax, pos(j), m, 'ko', 'MarkerFaceColor', 'k', 'MarkerSize', meanDotSize);
            line(ax, [pos(j) pos(j)], [m-se m+se], 'Color', 'k', 'LineWidth', lwSEM);
        end
    end

    text(panelCenters(p), yMax + 0.03*yRange, panelTitles{p}, ...
        'HorizontalAlignment', 'center', ...
        'FontSize', fsTitle, ...
        'FontWeight', 'bold');
end

ax.Box = 'off';
ax.LineWidth = lwAxes;
ax.FontSize = fsTick;
ax.TickDir = 'out';
ax.XTick = [];
ax.YGrid = 'off';
ax.XGrid = 'off';
ax.Layer = 'top';

xMax = posBlock(end) + 2*(blockWidth + gapBetweenPredictability) + 0.8;
xlim(ax, [0.4 xMax]);
ylim(ax, [yMin yMax]);
yticks(ax, round(linspace(yMin, yMax, nYTicks)));
ylabel(ax, yLabel, 'FontSize', fsAxisLabel, 'FontWeight', 'bold');

labelY = yMin - 0.06*yRange;
for p = 1:3
    text(ctrlCenters(p), labelY, 'Controllable', ...
        'HorizontalAlignment', 'center', 'VerticalAlignment', 'top', ...
        'FontSize', fsGroupLabel);
    text(unctrlCenters(p), labelY, 'Uncontrollable', ...
        'HorizontalAlignment', 'center', 'VerticalAlignment', 'top', ...
        'FontSize', fsGroupLabel);
end

pL1 = patch(nan, nan, col.H_S1, 'FaceAlpha', boxAlpha, 'EdgeColor', 'k');
pL2 = patch(nan, nan, col.C_S1, 'FaceAlpha', boxAlpha, 'EdgeColor', 'k');
legend(ax, [pL1 pL2], {'Healthy controls','Chronic stress'}, ...
    'Box', 'off', 'FontSize', fsLegend, 'Location', 'northeast');

exportgraphics(fig, fullfile(outDir, 'RT_figure.png'), 'Resolution', savePngDpi);
exportgraphics(fig, fullfile(outDir, 'RT_figure.pdf'), 'ContentType', 'vector');
exportgraphics(fig, fullfile(outDir, 'RT_figure.tiff'), 'Resolution', savePngDpi);

%% ============================== ANALYSIS SUMMARY =========================
summaryTable = table( ...
    {'Analysis type'; ...
     'Between-participant factor'; ...
     'Within-participant factor 1'; ...
     'Within-participant factor 2'; ...
     'Healthy raw N'; ...
     'Chronic-stress raw N'; ...
     'Healthy complete-case N'; ...
     'Chronic-stress complete-case N'; ...
     '3-SD removal used'; ...
     'Manual exclusion tolerance'; ...
     'Output workbook'; ...
     'Cleaned MAT file'}, ...
    {'2 x 2 x 3 mixed repeated-measures ANOVA'; ...
     'Group = Healthy controls vs Chronic stress'; ...
     'Controllability = Controllable vs Uncontrollable'; ...
     'Predictability = HP vs MP vs UP'; ...
     num2str(height(healthyRaw)); ...
     num2str(height(chronicRaw)); ...
     num2str(height(healthyStats)); ...
     num2str(height(chronicStats)); ...
     yes_no(use3SDRemoval); ...
     num2str(manualRemoveTolerance); ...
     excelFile; ...
     matFile}, ...
    'VariableNames', {'Item','Value'});

writetable(summaryTable, excelFile, 'Sheet', 'Analysis_Summary');

fprintf('\n============================================================\n');
fprintf('Reaction-time analysis complete.\n');
fprintf('Healthy complete-case N = %d\n', height(healthyStats));
fprintf('Chronic-stress complete-case N = %d\n', height(chronicStats));
fprintf('Results saved to: %s\n', outDir);
fprintf('============================================================\n\n');


%% ========================================================================
% LOCAL FUNCTIONS
% ========================================================================

function validate_input(S, label)
    assert(isfield(S, 'results'), '%s file is missing results.', label);
    assert(isfield(S.results, 'Controllable'), ...
        '%s file is missing results.Controllable.', label);
    assert(isfield(S.results, 'Uncontrollable'), ...
        '%s file is missing results.Uncontrollable.', label);

    required = {'HP','MP','UP'};
    for i = 1:numel(required)
        assert(isfield(S.results.Controllable, required{i}), ...
            '%s file is missing results.Controllable.%s.', label, required{i});
        assert(isfield(S.results.Uncontrollable, required{i}), ...
            '%s file is missing results.Uncontrollable.%s.', label, required{i});
    end
end


function [healthy, chronic, removalLog] = apply_cleaning( ...
    healthy, chronic, manualRemove, tolerance, use3SD)

    conditionMap = {
        'H_HP_S1', 'healthy', 'HP_S1';
        'H_HP_S2', 'healthy', 'HP_S2';
        'H_MP_S1', 'healthy', 'MP_S1';
        'H_MP_S2', 'healthy', 'MP_S2';
        'H_UP_S1', 'healthy', 'UP_S1';
        'H_UP_S2', 'healthy', 'UP_S2';
        'C_HP_S1', 'chronic', 'HP_S1';
        'C_HP_S2', 'chronic', 'HP_S2';
        'C_MP_S1', 'chronic', 'MP_S1';
        'C_MP_S2', 'chronic', 'MP_S2';
        'C_UP_S1', 'chronic', 'UP_S1';
        'C_UP_S2', 'chronic', 'UP_S2'};

    logGroup = strings(0,1);
    logSubject = strings(0,1);
    logCell = strings(0,1);
    logType = strings(0,1);
    logRequested = zeros(0,1);
    logRemoved = zeros(0,1);
    logDifference = zeros(0,1);

    % Recorded manual exclusions.
    for i = 1:size(conditionMap,1)
        conditionName = conditionMap{i,1};
        groupName = conditionMap{i,2};
        variableName = conditionMap{i,3};

        if strcmp(groupName, 'healthy')
            T = healthy;
            displayGroup = "Healthy";
        else
            T = chronic;
            displayGroup = "Chronic";
        end

        x = T.(variableName);
        subjectID = T.SubjectID;
        requestedValues = manualRemove.(conditionName)(:);

        for k = 1:numel(requestedValues)
            target = requestedValues(k);
            validIdx = find(~isnan(x));
            if isempty(validIdx)
                continue;
            end

            [minDiff, loc] = min(abs(x(validIdx)-target));
            idx = validIdx(loc);

            if minDiff <= tolerance
                logGroup(end+1,1) = displayGroup;
                logSubject(end+1,1) = string(subjectID(idx));
                logCell(end+1,1) = string(variableName);
                logType(end+1,1) = "Recorded manual exclusion";
                logRequested(end+1,1) = target;
                logRemoved(end+1,1) = x(idx);
                logDifference(end+1,1) = minDiff;
                x(idx) = NaN;
            end
        end

        T.(variableName) = x;
        if strcmp(groupName, 'healthy')
            healthy = T;
        else
            chronic = T;
        end
    end

    % Optional >3-SD exclusion, applied separately within each group x cell.
    if use3SD
        for i = 1:size(conditionMap,1)
            groupName = conditionMap{i,2};
            variableName = conditionMap{i,3};

            if strcmp(groupName, 'healthy')
                T = healthy;
                displayGroup = "Healthy";
            else
                T = chronic;
                displayGroup = "Chronic";
            end

            x = T.(variableName);
            subjectID = T.SubjectID;
            mu = mean(x, 'omitnan');
            sd = std(x, 'omitnan');

            if ~(isnan(sd) || sd == 0)
                outIdx = find(abs(x-mu) > 3*sd);
                for j = 1:numel(outIdx)
                    idx = outIdx(j);
                    logGroup(end+1,1) = displayGroup;
                    logSubject(end+1,1) = string(subjectID(idx));
                    logCell(end+1,1) = string(variableName);
                    logType(end+1,1) = ">3 SD from cell mean";
                    logRequested(end+1,1) = NaN;
                    logRemoved(end+1,1) = x(idx);
                    logDifference(end+1,1) = abs(x(idx)-mu);
                end
                x(outIdx) = NaN;
            end

            T.(variableName) = x;
            if strcmp(groupName, 'healthy')
                healthy = T;
            else
                chronic = T;
            end
        end
    end

    removalLog = table(logGroup, logSubject, logCell, logType, ...
        logRequested, logRemoved, logDifference, ...
        'VariableNames', {'Group','SubjectID','Cell','RemovalType', ...
                          'RequestedValue','RemovedValue','AbsoluteDifference'});
end


function out = make_descriptives(healthy, chronic, variables)
    Group = strings(0,1);
    Cell = strings(0,1);
    N = zeros(0,1);
    Mean = zeros(0,1);
    SD = zeros(0,1);
    SEM = zeros(0,1);
    Median = zeros(0,1);
    Minimum = zeros(0,1);
    Maximum = zeros(0,1);

    for g = 1:2
        if g == 1
            T = healthy;
            groupName = "Healthy";
        else
            T = chronic;
            groupName = "Chronic";
        end

        for i = 1:numel(variables)
            x = T.(variables{i});
            x = x(~isnan(x));

            Group(end+1,1) = groupName;
            Cell(end+1,1) = string(variables{i});
            N(end+1,1) = numel(x);
            Mean(end+1,1) = mean(x);
            SD(end+1,1) = std(x);
            SEM(end+1,1) = std(x)/sqrt(numel(x));
            Median(end+1,1) = median(x);
            Minimum(end+1,1) = min(x);
            Maximum(end+1,1) = max(x);
        end
    end

    out = table(Group, Cell, N, Mean, SD, SEM, Median, Minimum, Maximum);
end


function T = with_row_names(T)
    if isempty(T.Properties.RowNames)
        return;
    end
    Effect = string(T.Properties.RowNames);
    T.Effect = Effect;
    T = movevars(T, 'Effect', 'Before', 1);
end


function out = summarize_anova(betweenTable, withinTable)
    Effect = strings(0,1);
    df1 = zeros(0,1);
    df2 = zeros(0,1);
    F = zeros(0,1);
    p = zeros(0,1);
    pGG = zeros(0,1);
    PartialEtaSquared = zeros(0,1);

    % Group effect.
    bRows = string(betweenTable.Properties.RowNames);
    groupRow = find(strcmpi(bRows, 'Group'), 1);
    errorRow = find(contains(lower(bRows), 'error'), 1);

    if ~isempty(groupRow) && ~isempty(errorRow)
        [d1,d2,Fv,pv,eta] = extract_between(betweenTable, groupRow, errorRow);
        Effect(end+1,1) = "Group";
        df1(end+1,1) = d1;
        df2(end+1,1) = d2;
        F(end+1,1) = Fv;
        p(end+1,1) = pv;
        pGG(end+1,1) = NaN;
        PartialEtaSquared(end+1,1) = eta;
    end

    specs = {
        'Controllability', 'Controllability';
        'Group x Controllability', 'Group:Controllability';
        'Predictability', 'Predictability';
        'Group x Predictability', 'Group:Predictability';
        'Controllability x Predictability', 'Controllability:Predictability';
        'Group x Controllability x Predictability', 'Group:Controllability:Predictability'};

    for i = 1:size(specs,1)
        [d1,d2,Fv,pv,pGGv,eta] = extract_within(withinTable, specs{i,2});
        if ~isnan(Fv)
            Effect(end+1,1) = string(specs{i,1});
            df1(end+1,1) = d1;
            df2(end+1,1) = d2;
            F(end+1,1) = Fv;
            p(end+1,1) = pv;
            pGG(end+1,1) = pGGv;
            PartialEtaSquared(end+1,1) = eta;
        end
    end

    out = table(Effect, df1, df2, F, p, pGG, PartialEtaSquared);
end


function [df1,df2,Fv,pv,eta] = extract_between(T, effectRow, errorRow)
    vars = string(T.Properties.VariableNames);
    df1 = get_table_value(T, effectRow, vars, 'DF');
    df2 = get_table_value(T, errorRow, vars, 'DF');
    Fv  = get_table_value(T, effectRow, vars, 'F');
    pv  = get_table_value(T, effectRow, vars, 'pValue');

    ssEffect = get_table_value(T, effectRow, vars, 'SumSq');
    ssError  = get_table_value(T, errorRow, vars, 'SumSq');

    if ~isnan(ssEffect) && ~isnan(ssError)
        eta = ssEffect/(ssEffect+ssError);
    elseif ~isnan(Fv) && ~isnan(df1) && ~isnan(df2)
        eta = (Fv*df1)/(Fv*df1+df2);
    else
        eta = NaN;
    end
end


function [df1,df2,Fv,pv,pGGv,eta] = extract_within(T, effectKey)
    rows = string(T.Properties.RowNames);
    vars = string(T.Properties.VariableNames);

    normalized = erase(rows, '(Intercept):');
    effectRow = find(strcmpi(normalized, effectKey), 1);

    if isempty(effectRow)
        df1 = NaN; df2 = NaN; Fv = NaN; pv = NaN; pGGv = NaN; eta = NaN;
        return;
    end

    if contains(effectKey, 'Controllability') && contains(effectKey, 'Predictability')
        errorKey = 'Error(Controllability:Predictability)';
    elseif contains(effectKey, 'Controllability')
        errorKey = 'Error(Controllability)';
    elseif contains(effectKey, 'Predictability')
        errorKey = 'Error(Predictability)';
    else
        errorKey = '';
    end

    errorRow = find(strcmpi(rows, errorKey), 1);

    df1 = get_table_value(T, effectRow, vars, 'DF');
    Fv  = get_table_value(T, effectRow, vars, 'F');
    pv  = get_table_value(T, effectRow, vars, 'pValue');
    pGGv = get_table_value(T, effectRow, vars, 'pValueGG');

    if isempty(errorRow)
        df2 = NaN;
        ssError = NaN;
    else
        df2 = get_table_value(T, errorRow, vars, 'DF');
        ssError = get_table_value(T, errorRow, vars, 'SumSq');
    end

    ssEffect = get_table_value(T, effectRow, vars, 'SumSq');
    if ~isnan(ssEffect) && ~isnan(ssError)
        eta = ssEffect/(ssEffect+ssError);
    elseif ~isnan(Fv) && ~isnan(df1) && ~isnan(df2)
        eta = (Fv*df1)/(Fv*df1+df2);
    else
        eta = NaN;
    end
end


function value = get_table_value(T, row, variableNames, requestedName)
    idx = find(strcmpi(variableNames, requestedName), 1);
    if isempty(idx) || isempty(row)
        value = NaN;
    else
        value = T{row, idx};
        if isempty(value)
            value = NaN;
        end
    end
end


function out = group_simple_effects(H, C)
    cells = {'HP_S1','MP_S1','UP_S1','HP_S2','MP_S2','UP_S2'};

    Comparison = strings(numel(cells),1);
    MeanDifference = nan(numel(cells),1);
    t = nan(numel(cells),1);
    df = nan(numel(cells),1);
    p = nan(numel(cells),1);
    CI_Lower = nan(numel(cells),1);
    CI_Upper = nan(numel(cells),1);

    for i = 1:numel(cells)
        x = H.(cells{i});
        y = C.(cells{i});
        [~,p(i),ci,st] = ttest2(x,y);

        Comparison(i) = "Healthy vs Chronic | " + string(cells{i});
        MeanDifference(i) = mean(x,'omitnan') - mean(y,'omitnan');
        t(i) = st.tstat;
        df(i) = st.df;
        CI_Lower(i) = ci(1);
        CI_Upper(i) = ci(2);
    end

    % Same correction family as the original script: six cell-wise tests.
    p_Bonferroni = min(p*6, 1);
    out = table(Comparison, MeanDifference, t, df, p, p_Bonferroni, CI_Lower, CI_Upper);
end


function out = controllability_simple_effects(H, C)
    groups = {'Healthy', H; 'Chronic', C};
    pred = {'HP','MP','UP'};

    Group = strings(0,1);
    Predictability = strings(0,1);
    MeanDifference = zeros(0,1);
    t = zeros(0,1);
    df = zeros(0,1);
    p = zeros(0,1);
    CI_Lower = zeros(0,1);
    CI_Upper = zeros(0,1);

    for g = 1:size(groups,1)
        T = groups{g,2};
        for j = 1:numel(pred)
            x = T.([pred{j} '_S1']);
            y = T.([pred{j} '_S2']);
            [~,pv,ci,st] = ttest(x,y);

            Group(end+1,1) = string(groups{g,1});
            Predictability(end+1,1) = string(pred{j});
            MeanDifference(end+1,1) = mean(x-y,'omitnan');
            t(end+1,1) = st.tstat;
            df(end+1,1) = st.df;
            p(end+1,1) = pv;
            CI_Lower(end+1,1) = ci(1);
            CI_Upper(end+1,1) = ci(2);
        end
    end

    % Same correction family as the original script: six tests.
    p_Bonferroni = min(p*6, 1);
    out = table(Group, Predictability, MeanDifference, t, df, p, ...
        p_Bonferroni, CI_Lower, CI_Upper);
end


function out = predictability_simple_effects(H, C)
    groups = {'Healthy', H; 'Chronic', C};
    sessions = {'S1','S2'};

    Group = strings(0,1);
    Controllability = strings(0,1);
    Comparison = strings(0,1);
    MeanDifference = zeros(0,1);
    t = zeros(0,1);
    df = zeros(0,1);
    p = zeros(0,1);
    p_Bonferroni = zeros(0,1);
    CI_Lower = zeros(0,1);
    CI_Upper = zeros(0,1);

    for g = 1:size(groups,1)
        T = groups{g,2};
        for s = 1:numel(sessions)
            suffix = sessions{s};
            HP = T.(['HP_' suffix]);
            MP = T.(['MP_' suffix]);
            UP = T.(['UP_' suffix]);

            comparisons = {
                'HP vs MP', HP, MP;
                'HP vs UP', HP, UP;
                'MP vs UP', MP, UP};

            for k = 1:3
                x = comparisons{k,2};
                y = comparisons{k,3};
                [~,pv,ci,st] = ttest(x,y);

                Group(end+1,1) = string(groups{g,1});
                if strcmp(suffix, 'S1')
                    Controllability(end+1,1) = "Controllable";
                else
                    Controllability(end+1,1) = "Uncontrollable";
                end
                Comparison(end+1,1) = string(comparisons{k,1});
                MeanDifference(end+1,1) = mean(x-y,'omitnan');
                t(end+1,1) = st.tstat;
                df(end+1,1) = st.df;
                p(end+1,1) = pv;
                p_Bonferroni(end+1,1) = min(pv*3,1);
                CI_Lower(end+1,1) = ci(1);
                CI_Upper(end+1,1) = ci(2);
            end
        end
    end

    out = table(Group, Controllability, Comparison, MeanDifference, t, df, ...
        p, p_Bonferroni, CI_Lower, CI_Upper);
end


function out = make_cell_means(H, C)
    groups = {'Healthy',H; 'Chronic',C};
    cells = {'HP_S1','MP_S1','UP_S1','HP_S2','MP_S2','UP_S2'};

    Group = strings(0,1);
    Cell = strings(0,1);
    N = zeros(0,1);
    Mean = zeros(0,1);
    SEM = zeros(0,1);

    for g = 1:size(groups,1)
        T = groups{g,2};
        for i = 1:numel(cells)
            x = T.(cells{i});
            x = x(~isnan(x));

            Group(end+1,1) = string(groups{g,1});
            Cell(end+1,1) = string(cells{i});
            N(end+1,1) = numel(x);
            Mean(end+1,1) = mean(x);
            SEM(end+1,1) = std(x)/sqrt(numel(x));
        end
    end

    out = table(Group, Cell, N, Mean, SEM);
end


function txt = yes_no(tf)
    if tf
        txt = 'Yes';
    else
        txt = 'No';
    end
end
