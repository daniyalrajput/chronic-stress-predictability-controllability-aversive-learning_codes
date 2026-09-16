%% Accuracy analysis: Chronic stress study
% Publication/repository version
%
% Study design
%   Between-participant factor:
%       Group = Healthy control, Chronic stress
%
%   Within-participant factors:
%       Controllability = Controllable, Uncontrollable
%       Predictability = High (HP), Moderate (MP), Unpredictable (UP)
%
% Primary analysis
%   Linear mixed-effects model:
%       Accuracy ~ Group * Controllability * Predictability + (1|SubjectID)
%
% Robustness analysis
%   2 (Group) x 2 (Controllability) x 3 (Predictability)
%   mixed repeated-measures ANOVA using complete cases.
%
% Follow-up analyses
%   1. Healthy vs Chronic stress within each Controllability x Predictability cell
%   2. Controllable vs Uncontrollable within each Group x Predictability cell
%   3. Predictability comparisons within each Group x Controllability cell
%
% Notes
%   - The repeated-measures ANOVA requires all six cells, so participants
%     with any missing cell are excluded from that robustness analysis.
%   - Bonferroni correction follows the original analysis families:
%       6 between-group tests, 6 controllability tests, 12 predictability tests.
%
% Required input files
%   data/Performance_Analysis_DynamicBlocks_healthy.mat
%   data/Performance_DynamicBlocks_Study2CS_Final.mat
%
% Required variables in each MAT file
%   perfS1_HP, perfS1_MP, perfS1_UP
%   perfS2_HP, perfS2_MP, perfS2_UP
%
% Session coding
%   S1 = Controllable
%   S2 = Uncontrollable
%
% -------------------------------------------------------------------------
% Daniyal Rajput
% Chronic stress / probabilistic aversive-learning study
% -------------------------------------------------------------------------

clear; clc; close all;
rng(1, 'twister');  % reproducible jitter in the figure

%% Paths
scriptDir = fileparts(mfilename('fullpath'));
if isempty(scriptDir)
    scriptDir = pwd;
end

dataDir = fullfile(scriptDir, 'data');
outDir  = fullfile(scriptDir, 'results', 'Accuracy');

if ~exist(outDir, 'dir')
    mkdir(outDir);
end

healthyFile = fullfile(dataDir, 'Performance_Analysis_DynamicBlocks_healthy.mat');
chronicFile = fullfile(dataDir, 'Performance_DynamicBlocks_Study2CS_Final.mat');

assert(isfile(healthyFile), 'Healthy-control data file not found: %s', healthyFile);
assert(isfile(chronicFile), 'Chronic-stress data file not found: %s', chronicFile);

excelFile = fullfile(outDir, 'Accuracy_analysis_results.xlsx');
textFile  = fullfile(outDir, 'Accuracy_analysis_results.txt');
matFile   = fullfile(outDir, 'Accuracy_cleaned_data.mat');

%% Load data
H = load(healthyFile);
C = load(chronicFile);

requiredVars = {'perfS1_HP','perfS1_MP','perfS1_UP', ...
                'perfS2_HP','perfS2_MP','perfS2_UP'};

for i = 1:numel(requiredVars)
    assert(isfield(H, requiredVars{i}), ...
        'Healthy-control file is missing variable "%s".', requiredVars{i});
    assert(isfield(C, requiredVars{i}), ...
        'Chronic-stress file is missing variable "%s".', requiredVars{i});
end

toColumn = @(x) double(x(:));

healthy = table( ...
    toColumn(H.perfS1_HP), ...
    toColumn(H.perfS1_MP), ...
    toColumn(H.perfS1_UP), ...
    toColumn(H.perfS2_HP), ...
    toColumn(H.perfS2_MP), ...
    toColumn(H.perfS2_UP), ...
    'VariableNames', {'HP_S1','MP_S1','UP_S1','HP_S2','MP_S2','UP_S2'});

chronic = table( ...
    toColumn(C.perfS1_HP), ...
    toColumn(C.perfS1_MP), ...
    toColumn(C.perfS1_UP), ...
    toColumn(C.perfS2_HP), ...
    toColumn(C.perfS2_MP), ...
    toColumn(C.perfS2_UP), ...
    'VariableNames', {'HP_S1','MP_S1','UP_S1','HP_S2','MP_S2','UP_S2'});

validate_equal_lengths(healthy, 'Healthy-control');
validate_equal_lengths(chronic, 'Chronic-stress');

healthy.SubjectID = compose("H%02d", (1:height(healthy))');
chronic.SubjectID = compose("C%02d", (1:height(chronic))');

healthy = movevars(healthy, 'SubjectID', 'Before', 1);
chronic = movevars(chronic, 'SubjectID', 'Before', 1);

healthyRaw = healthy;
chronicRaw = chronic;

%% Recorded manual exclusions
% These values are copied from the original analysis script.
% A target is matched to the nearest value in the specified cell.
% "manualTolerance" prevents an unrelated value being removed if the
% supplied target cannot be found to the expected numerical precision.

manualTolerance = 1.0;

manualExclusions = table( ...
    ["Healthy";"Healthy";"Healthy";"Healthy";"Healthy";"Healthy"; ...
     "Chronic";"Chronic";"Chronic";"Chronic";"Chronic";"Chronic"], ...
    ["HP_S1";"MP_S1";"UP_S1";"HP_S2";"MP_S2";"UP_S2"; ...
     "HP_S1";"MP_S1";"UP_S1";"HP_S2";"MP_S2";"UP_S2"], ...
    [], ...
    'VariableNames', {'Group','Variable','TargetValue'});

[healthy, chronic, removalLog] = apply_manual_exclusions( ...
    healthy, chronic, manualExclusions, manualTolerance);

%% Descriptive statistics after cell-wise exclusions
measureVars = {'HP_S1','MP_S1','UP_S1','HP_S2','MP_S2','UP_S2'};

descriptives = make_descriptives(healthy, chronic, measureVars);

%% ========================================================================
% Primary analysis: Linear mixed-effects model
% ========================================================================

longData = make_long_table(healthy, chronic);

% Remove only rows in which accuracy is missing. This retains the other
% valid observations from the same participant.
longData = rmmissing(longData, 'DataVariables', 'Accuracy');

% Use explicit categorical reference levels for reproducibility.
longData.Group = reordercats(longData.Group, {'Healthy','Chronic'});
longData.Controllability = reordercats(longData.Controllability, ...
    {'Controllable','Uncontrollable'});
longData.Predictability = reordercats(longData.Predictability, ...
    {'HP','MP','UP'});

lme = fitlme(longData, ...
    'Accuracy ~ Group*Controllability*Predictability + (1|SubjectID)');

% Satterthwaite denominator degrees of freedom give the fractional dfs
% typically reported for the primary accuracy model.
lmeAnova = anova(lme, 'DFMethod', 'satterthwaite');
lmeAnovaOut = add_row_names(lmeAnova, 'Effect');

%% ========================================================================
% Robustness analysis: 2 x 2 x 3 mixed repeated-measures ANOVA
% ========================================================================

healthy.CompleteCase = all(~ismissing(healthy(:,measureVars)), 2);
chronic.CompleteCase = all(~ismissing(chronic(:,measureVars)), 2);

healthyRM = healthy(healthy.CompleteCase,:);
chronicRM = chronic(chronic.CompleteCase,:);

nH = height(healthyRM);
nC = height(chronicRM);

% Wide table: one row per participant.
Group = categorical([repmat("Healthy",nH,1); repmat("Chronic",nC,1)], ...
    {'Healthy','Chronic'});

SubjectID = categorical([healthyRM.SubjectID; chronicRM.SubjectID]);

HP_S1 = [healthyRM.HP_S1; chronicRM.HP_S1];
MP_S1 = [healthyRM.MP_S1; chronicRM.MP_S1];
UP_S1 = [healthyRM.UP_S1; chronicRM.UP_S1];
HP_S2 = [healthyRM.HP_S2; chronicRM.HP_S2];
MP_S2 = [healthyRM.MP_S2; chronicRM.MP_S2];
UP_S2 = [healthyRM.UP_S2; chronicRM.UP_S2];

wideRM = table(SubjectID,Group,HP_S1,MP_S1,UP_S1,HP_S2,MP_S2,UP_S2);

withinDesign = table( ...
    categorical({'Controllable';'Controllable';'Controllable'; ...
                 'Uncontrollable';'Uncontrollable';'Uncontrollable'}, ...
                {'Controllable','Uncontrollable'}), ...
    categorical({'HP';'MP';'UP';'HP';'MP';'UP'}, {'HP','MP','UP'}), ...
    'VariableNames', {'Controllability','Predictability'});

rm = fitrm(wideRM, ...
    'HP_S1-UP_S2 ~ Group', ...
    'WithinDesign', withinDesign);

rmWithin  = ranova(rm, 'WithinModel', 'Controllability*Predictability');
rmBetween = anova(rm);

rmWithinOut  = add_row_names(rmWithin, 'Effect');
rmBetweenOut = add_row_names(rmBetween, 'Effect');

%% ========================================================================
% Planned follow-up tests
% ========================================================================

% Follow-up tests use the cell-wise cleaned data rather than the
% complete-case subset, matching the cell-specific logic of the original
% script. Paired tests automatically omit pairs containing NaN after the
% pair-wise valid cases are selected below.

posthocBetween = between_group_posthocs(healthy, chronic);
posthocControl = controllability_posthocs(healthy, chronic);
posthocPredict = predictability_posthocs(healthy, chronic);

%% Cell means
cellMeans = make_cell_means(healthy, chronic);

%% ========================================================================
% Export analysis outputs
% ========================================================================

if isfile(excelFile)
    delete(excelFile);
end

writetable(healthyRaw, excelFile, 'Sheet', 'Healthy_Raw');
writetable(chronicRaw, excelFile, 'Sheet', 'Chronic_Raw');
writetable(healthy, excelFile, 'Sheet', 'Healthy_Cleaned');
writetable(chronic, excelFile, 'Sheet', 'Chronic_Cleaned');
writetable(removalLog, excelFile, 'Sheet', 'Removal_Log');
writetable(descriptives, excelFile, 'Sheet', 'Descriptives');
writetable(longData, excelFile, 'Sheet', 'LME_LongData');
writetable(lmeAnovaOut, excelFile, 'Sheet', 'LME_ANOVA');
writetable(rmWithinOut, excelFile, 'Sheet', 'RM_ANOVA_Within');
writetable(rmBetweenOut, excelFile, 'Sheet', 'RM_ANOVA_Between');
writetable(posthocBetween, excelFile, 'Sheet', 'PostHoc_Between');
writetable(posthocControl, excelFile, 'Sheet', 'PostHoc_Control');
writetable(posthocPredict, excelFile, 'Sheet', 'PostHoc_Predict');
writetable(cellMeans, excelFile, 'Sheet', 'Cell_Means');

analysisSummary = table( ...
    ["Primary analysis"; ...
     "Primary model"; ...
     "LME denominator df"; ...
     "Robustness analysis"; ...
     "Between-participant factor"; ...
     "Within-participant factor 1"; ...
     "Within-participant factor 2"; ...
     "Healthy raw N"; ...
     "Chronic-stress raw N"; ...
     "Healthy complete-case N for RM-ANOVA"; ...
     "Chronic complete-case N for RM-ANOVA"; ...
     "Manual exclusion tolerance"; ...
     "Between-group Bonferroni family"; ...
     "Controllability Bonferroni family"; ...
     "Predictability Bonferroni family"], ...
    ["Linear mixed-effects model"; ...
     "Accuracy ~ Group*Controllability*Predictability + (1|SubjectID)"; ...
     "Satterthwaite"; ...
     "2 x 2 x 3 mixed repeated-measures ANOVA"; ...
     "Group: Healthy vs Chronic stress"; ...
     "Controllability: Controllable vs Uncontrollable"; ...
     "Predictability: HP vs MP vs UP"; ...
     string(height(healthyRaw)); ...
     string(height(chronicRaw)); ...
     string(nH); ...
     string(nC); ...
     string(manualTolerance); ...
     "6 tests"; ...
     "6 tests"; ...
     "12 tests"], ...
    'VariableNames', {'Item','Value'});

writetable(analysisSummary, excelFile, 'Sheet', 'Analysis_Summary');

save(matFile, ...
    'healthyRaw','chronicRaw','healthy','chronic','removalLog', ...
    'manualExclusions','manualTolerance','descriptives', ...
    'longData','lme','lmeAnova', ...
    'healthyRM','chronicRM','wideRM','withinDesign','rm', ...
    'rmWithin','rmBetween','posthocBetween','posthocControl', ...
    'posthocPredict','cellMeans','analysisSummary');

%% Text summary
fid = fopen(textFile, 'w');
assert(fid ~= -1, 'Could not open text output file.');

fprintf(fid, 'ACCURACY ANALYSIS: CHRONIC STRESS STUDY\n');
fprintf(fid, '======================================\n\n');

fprintf(fid, 'Primary analysis: linear mixed-effects model\n');
fprintf(fid, 'Accuracy ~ Group*Controllability*Predictability + (1|SubjectID)\n');
fprintf(fid, 'Denominator df: Satterthwaite\n\n');
fprintf(fid, '%s\n', evalc('disp(lmeAnovaOut)'));

fprintf(fid, '\nRobustness analysis: 2 x 2 x 3 mixed repeated-measures ANOVA\n');
fprintf(fid, 'Healthy complete-case N: %d / %d\n', nH, height(healthyRaw));
fprintf(fid, 'Chronic-stress complete-case N: %d / %d\n\n', nC, height(chronicRaw));

fprintf(fid, 'Within-participant effects:\n');
fprintf(fid, '%s\n', evalc('disp(rmWithinOut)'));

fprintf(fid, '\nBetween-participant effects:\n');
fprintf(fid, '%s\n', evalc('disp(rmBetweenOut)'));

fprintf(fid, '\nBetween-group follow-up tests:\n');
fprintf(fid, '%s\n', evalc('disp(posthocBetween)'));

fprintf(fid, '\nControllability follow-up tests:\n');
fprintf(fid, '%s\n', evalc('disp(posthocControl)'));

fprintf(fid, '\nPredictability follow-up tests:\n');
fprintf(fid, '%s\n', evalc('disp(posthocPredict)'));

fclose(fid);

%% ========================================================================
% Publication figure
% ========================================================================

make_accuracy_figure(healthy, chronic, outDir);

fprintf('\nAccuracy analysis complete.\n');
fprintf('Primary LME observations: %d\n', height(longData));
fprintf('Healthy complete-case N for RM-ANOVA: %d\n', nH);
fprintf('Chronic-stress complete-case N for RM-ANOVA: %d\n', nC);
fprintf('Outputs saved to: %s\n\n', outDir);


%% ========================================================================
% Local functions
% ========================================================================

function validate_equal_lengths(T, groupName)
    vars = T.Properties.VariableNames;
    n = height(T);

    for i = 1:numel(vars)
        if height(T(:,vars(i))) ~= n
            error('%s condition vectors have inconsistent lengths.', groupName);
        end
    end
end


function [healthy, chronic, logTable] = apply_manual_exclusions( ...
    healthy, chronic, exclusionTable, tolerance)

    Group = strings(0,1);
    SubjectID = strings(0,1);
    Variable = strings(0,1);
    TargetValue = zeros(0,1);
    RemovedValue = zeros(0,1);
    AbsDifference = zeros(0,1);
    Removed = false(0,1);

    for i = 1:height(exclusionTable)
        grp = exclusionTable.Group(i);
        vn = exclusionTable.Variable(i);
        target = exclusionTable.TargetValue(i);

        if grp == "Healthy"
            T = healthy;
        else
            T = chronic;
        end

        x = T.(char(vn));
        validIdx = find(~isnan(x));

        Group(end+1,1) = grp;
        Variable(end+1,1) = vn;
        TargetValue(end+1,1) = target;

        if isempty(validIdx)
            SubjectID(end+1,1) = "";
            RemovedValue(end+1,1) = NaN;
            AbsDifference(end+1,1) = NaN;
            Removed(end+1,1) = false;
            continue
        end

        [minDiff, localIdx] = min(abs(x(validIdx) - target));
        idx = validIdx(localIdx);

        if minDiff <= tolerance
            SubjectID(end+1,1) = string(T.SubjectID(idx));
            RemovedValue(end+1,1) = x(idx);
            AbsDifference(end+1,1) = minDiff;
            Removed(end+1,1) = true;

            x(idx) = NaN;
            T.(char(vn)) = x;

            if grp == "Healthy"
                healthy = T;
            else
                chronic = T;
            end
        else
            SubjectID(end+1,1) = "";
            RemovedValue(end+1,1) = NaN;
            AbsDifference(end+1,1) = minDiff;
            Removed(end+1,1) = false;
        end
    end

    logTable = table(Group,SubjectID,Variable,TargetValue, ...
        RemovedValue,AbsDifference,Removed);
end


function D = make_descriptives(healthy, chronic, variables)
    Group = strings(0,1);
    Cell = strings(0,1);
    N = zeros(0,1);
    Mean = zeros(0,1);
    SD = zeros(0,1);
    SEM = zeros(0,1);
    Median = zeros(0,1);
    Minimum = zeros(0,1);
    Maximum = zeros(0,1);

    groupTables = {healthy, chronic};
    groupNames = ["Healthy","Chronic"];

    for g = 1:2
        T = groupTables{g};

        for i = 1:numel(variables)
            x = T.(variables{i});
            x = x(~isnan(x));

            Group(end+1,1) = groupNames(g);
            Cell(end+1,1) = string(variables{i});
            N(end+1,1) = numel(x);

            if isempty(x)
                Mean(end+1,1) = NaN;
                SD(end+1,1) = NaN;
                SEM(end+1,1) = NaN;
                Median(end+1,1) = NaN;
                Minimum(end+1,1) = NaN;
                Maximum(end+1,1) = NaN;
            else
                Mean(end+1,1) = mean(x);
                SD(end+1,1) = std(x);
                SEM(end+1,1) = std(x)/sqrt(numel(x));
                Median(end+1,1) = median(x);
                Minimum(end+1,1) = min(x);
                Maximum(end+1,1) = max(x);
            end
        end
    end

    D = table(Group,Cell,N,Mean,SD,SEM,Median,Minimum,Maximum);
end


function longData = make_long_table(healthy, chronic)
    groupTables = {healthy, chronic};
    groupNames = ["Healthy","Chronic"];

    SubjectID = strings(0,1);
    Group = strings(0,1);
    Controllability = strings(0,1);
    Predictability = strings(0,1);
    Accuracy = zeros(0,1);

    cells = {
        'HP_S1','Controllable','HP';
        'MP_S1','Controllable','MP';
        'UP_S1','Controllable','UP';
        'HP_S2','Uncontrollable','HP';
        'MP_S2','Uncontrollable','MP';
        'UP_S2','Uncontrollable','UP'
        };

    for g = 1:2
        T = groupTables{g};

        for s = 1:height(T)
            for c = 1:size(cells,1)
                SubjectID(end+1,1) = string(T.SubjectID(s));
                Group(end+1,1) = groupNames(g);
                Controllability(end+1,1) = string(cells{c,2});
                Predictability(end+1,1) = string(cells{c,3});
                Accuracy(end+1,1) = T.(cells{c,1})(s);
            end
        end
    end

    longData = table( ...
        categorical(SubjectID), ...
        categorical(Group, {'Healthy','Chronic'}), ...
        categorical(Controllability, {'Controllable','Uncontrollable'}), ...
        categorical(Predictability, {'HP','MP','UP'}), ...
        Accuracy, ...
        'VariableNames', {'SubjectID','Group','Controllability', ...
                          'Predictability','Accuracy'});
end


function T = add_row_names(T, newName)
    T.(newName) = string(T.Properties.RowNames);
    T = movevars(T, newName, 'Before', 1);
end


function out = between_group_posthocs(H,C)
    cells = {
        'Controllable','HP','HP_S1';
        'Controllable','MP','MP_S1';
        'Controllable','UP','UP_S1';
        'Uncontrollable','HP','HP_S2';
        'Uncontrollable','MP','MP_S2';
        'Uncontrollable','UP','UP_S2'
        };

    Controllability = strings(6,1);
    Predictability = strings(6,1);
    N_Healthy = zeros(6,1);
    N_Chronic = zeros(6,1);
    Mean_Healthy = zeros(6,1);
    Mean_Chronic = zeros(6,1);
    MeanDifference = zeros(6,1);
    t = zeros(6,1);
    df = zeros(6,1);
    p = zeros(6,1);
    CI_Lower = zeros(6,1);
    CI_Upper = zeros(6,1);

    for i = 1:6
        x = H.(cells{i,3});
        y = C.(cells{i,3});

        x = x(~isnan(x));
        y = y(~isnan(y));

        [~,p(i),ci,st] = ttest2(x,y);

        Controllability(i) = string(cells{i,1});
        Predictability(i) = string(cells{i,2});
        N_Healthy(i) = numel(x);
        N_Chronic(i) = numel(y);
        Mean_Healthy(i) = mean(x);
        Mean_Chronic(i) = mean(y);
        MeanDifference(i) = mean(x)-mean(y);
        t(i) = st.tstat;
        df(i) = st.df;
        CI_Lower(i) = ci(1);
        CI_Upper(i) = ci(2);
    end

    p_Bonferroni = min(p*6,1);

    out = table(Controllability,Predictability,N_Healthy,N_Chronic, ...
        Mean_Healthy,Mean_Chronic,MeanDifference,t,df,p,p_Bonferroni, ...
        CI_Lower,CI_Upper);
end


function out = controllability_posthocs(H,C)
    groups = {"Healthy",H; "Chronic",C};
    predictions = {'HP','MP','UP'};

    Group = strings(0,1);
    Predictability = strings(0,1);
    N = zeros(0,1);
    Mean_Controllable = zeros(0,1);
    Mean_Uncontrollable = zeros(0,1);
    MeanDifference = zeros(0,1);
    t = zeros(0,1);
    df = zeros(0,1);
    p = zeros(0,1);
    CI_Lower = zeros(0,1);
    CI_Upper = zeros(0,1);

    for g = 1:2
        T = groups{g,2};

        for j = 1:3
            pred = predictions{j};
            x = T.([pred '_S1']);
            y = T.([pred '_S2']);

            valid = ~isnan(x) & ~isnan(y);
            x = x(valid);
            y = y(valid);

            [~,pv,ci,st] = ttest(x,y);

            Group(end+1,1) = string(groups{g,1});
            Predictability(end+1,1) = string(pred);
            N(end+1,1) = numel(x);
            Mean_Controllable(end+1,1) = mean(x);
            Mean_Uncontrollable(end+1,1) = mean(y);
            MeanDifference(end+1,1) = mean(x-y);
            t(end+1,1) = st.tstat;
            df(end+1,1) = st.df;
            p(end+1,1) = pv;
            CI_Lower(end+1,1) = ci(1);
            CI_Upper(end+1,1) = ci(2);
        end
    end

    p_Bonferroni = min(p*6,1);

    out = table(Group,Predictability,N,Mean_Controllable, ...
        Mean_Uncontrollable,MeanDifference,t,df,p,p_Bonferroni, ...
        CI_Lower,CI_Upper);
end


function out = predictability_posthocs(H,C)
    groups = {"Healthy",H; "Chronic",C};
    sessions = {
        'Controllable','S1';
        'Uncontrollable','S2'
        };

    comparisons = {
        'HP_vs_MP','HP','MP';
        'HP_vs_UP','HP','UP';
        'MP_vs_UP','MP','UP'
        };

    Group = strings(0,1);
    Controllability = strings(0,1);
    Comparison = strings(0,1);
    N = zeros(0,1);
    Mean_1 = zeros(0,1);
    Mean_2 = zeros(0,1);
    MeanDifference = zeros(0,1);
    t = zeros(0,1);
    df = zeros(0,1);
    p = zeros(0,1);
    CI_Lower = zeros(0,1);
    CI_Upper = zeros(0,1);

    for g = 1:2
        T = groups{g,2};

        for s = 1:2
            suffix = sessions{s,2};

            for k = 1:3
                pred1 = comparisons{k,2};
                pred2 = comparisons{k,3};

                x = T.([pred1 '_' suffix]);
                y = T.([pred2 '_' suffix]);

                valid = ~isnan(x) & ~isnan(y);
                x = x(valid);
                y = y(valid);

                [~,pv,ci,st] = ttest(x,y);

                Group(end+1,1) = string(groups{g,1});
                Controllability(end+1,1) = string(sessions{s,1});
                Comparison(end+1,1) = string(comparisons{k,1});
                N(end+1,1) = numel(x);
                Mean_1(end+1,1) = mean(x);
                Mean_2(end+1,1) = mean(y);
                MeanDifference(end+1,1) = mean(x-y);
                t(end+1,1) = st.tstat;
                df(end+1,1) = st.df;
                p(end+1,1) = pv;
                CI_Lower(end+1,1) = ci(1);
                CI_Upper(end+1,1) = ci(2);
            end
        end
    end

    p_Bonferroni = min(p*12,1);

    out = table(Group,Controllability,Comparison,N,Mean_1,Mean_2, ...
        MeanDifference,t,df,p,p_Bonferroni,CI_Lower,CI_Upper);
end


function out = make_cell_means(H,C)
    groups = {"Healthy",H; "Chronic",C};

    cells = {
        'Controllable','HP','HP_S1';
        'Controllable','MP','MP_S1';
        'Controllable','UP','UP_S1';
        'Uncontrollable','HP','HP_S2';
        'Uncontrollable','MP','MP_S2';
        'Uncontrollable','UP','UP_S2'
        };

    Group = strings(0,1);
    Controllability = strings(0,1);
    Predictability = strings(0,1);
    N = zeros(0,1);
    Mean = zeros(0,1);
    SEM = zeros(0,1);

    for g = 1:2
        T = groups{g,2};

        for i = 1:size(cells,1)
            x = T.(cells{i,3});
            x = x(~isnan(x));

            Group(end+1,1) = string(groups{g,1});
            Controllability(end+1,1) = string(cells{i,1});
            Predictability(end+1,1) = string(cells{i,2});
            N(end+1,1) = numel(x);
            Mean(end+1,1) = mean(x);
            SEM(end+1,1) = std(x)/sqrt(numel(x));
        end
    end

    out = table(Group,Controllability,Predictability,N,Mean,SEM);
end


function make_accuracy_figure(H,C,outDir)
    % The figure retains the visual structure of the original analysis.

    colors = [
        0.00 0.25 0.85;   % Healthy, controllable
        0.90 0.40 0.05;   % Chronic, controllable
        0.60 0.80 1.00;   % Healthy, uncontrollable
        1.00 0.78 0.50    % Chronic, uncontrollable
        ];

    fillAlpha = 0.55;
    dotSize = 50;
    jitter = 0.10;

    yMin = 0;
    yMax = 100;
    yTicks = linspace(yMin,yMax,5);

    figPos = [200 200 1650 580];

    data = {
        {H.HP_S1(~isnan(H.HP_S1)), C.HP_S1(~isnan(C.HP_S1)), ...
         H.HP_S2(~isnan(H.HP_S2)), C.HP_S2(~isnan(C.HP_S2))};
        {H.MP_S1(~isnan(H.MP_S1)), C.MP_S1(~isnan(C.MP_S1)), ...
         H.MP_S2(~isnan(H.MP_S2)), C.MP_S2(~isnan(C.MP_S2))};
        {H.UP_S1(~isnan(H.UP_S1)), C.UP_S1(~isnan(C.UP_S1)), ...
         H.UP_S2(~isnan(H.UP_S2)), C.UP_S2(~isnan(C.UP_S2))}
        };

    titles = {'Highly predictable','Moderately predictable','Unpredictable'};

    panelWidth = 5;
    pairGap = 0.55;
    pairDistance = 2.2;
    panelStart = 1.0;

    basePos = [panelStart, ...
               panelStart+pairGap, ...
               panelStart+pairDistance, ...
               panelStart+pairDistance+pairGap];

    fig = figure('Color','w','Position',figPos);
    ax = axes(fig);
    hold(ax,'on');

    for k = 1:3
        pos = basePos + (k-1)*panelWidth;
        D = data{k};

        allY = [];
        groupCode = [];

        for j = 1:4
            y = D{j};
            allY = [allY; y(:)]; %#ok<AGROW>
            groupCode = [groupCode; repmat(j,numel(y),1)]; %#ok<AGROW>
        end

        boxplot(ax,allY,groupCode, ...
            'Positions',pos, ...
            'Labels',{'','','',''}, ...
            'Widths',0.35, ...
            'Whisker',1.5, ...
            'Symbol','', ...
            'Colors','k');

        delete(findobj(ax,'Tag','Lower Whisker'));
        delete(findobj(ax,'Tag','Upper Whisker'));
        delete(findobj(ax,'Tag','Lower Adjacent Value'));
        delete(findobj(ax,'Tag','Upper Adjacent Value'));
        delete(findobj(ax,'Tag','Median'));
        delete(findobj(ax,'Tag','Outliers'));

        boxes = findobj(ax,'Tag','Box');
        boxes = flipud(boxes(1:4));

        for j = 1:4
            patch(get(boxes(j),'XData'),get(boxes(j),'YData'),colors(j,:), ...
                'FaceAlpha',fillAlpha, ...
                'EdgeColor','k', ...
                'LineWidth',1.0);

            y = D{j};
            x = pos(j) + (rand(size(y))-0.5)*2*jitter;

            scatter(ax,x,y,dotSize, ...
                'MarkerFaceColor',colors(j,:), ...
                'MarkerEdgeColor','k', ...
                'MarkerFaceAlpha',0.85);

            if ~isempty(y)
                m = mean(y);
                se = std(y)/sqrt(numel(y));

                plot(ax,pos(j),m,'ko', ...
                    'MarkerFaceColor','k', ...
                    'MarkerSize',5);

                line(ax,[pos(j) pos(j)],[m-se m+se], ...
                    'Color','k','LineWidth',1.3);
            end
        end

        text(ax,mean(pos([1 4])),yMax+3,titles{k}, ...
            'HorizontalAlignment','center', ...
            'FontSize',18, ...
            'FontWeight','bold');
    end

    ax.LineWidth = 1.6;
    ax.FontSize = 20;
    ax.TickDir = 'out';
    ax.Layer = 'top';
    ax.YTick = yTicks;
    ax.XTick = [];
    ax.YGrid = 'off';
    ax.XGrid = 'off';
    ax.Box = 'off';

    xlim(ax,[0,panelWidth*3-0.5]);
    ylim(ax,[yMin,yMax]);

    ylabel(ax,'Accuracy (%)','FontSize',20,'FontWeight','bold');

    labelY = yMin-6;

    for k = 1:3
        pos = basePos + (k-1)*panelWidth;

        text(ax,mean(pos(1:2)),labelY,'Controllable', ...
            'HorizontalAlignment','center','FontSize',16);

        text(ax,mean(pos(3:4)),labelY,'Uncontrollable', ...
            'HorizontalAlignment','center','FontSize',16);
    end

    p1 = patch(ax,nan,nan,colors(1,:), ...
        'FaceAlpha',fillAlpha,'EdgeColor','k');
    p2 = patch(ax,nan,nan,colors(2,:), ...
        'FaceAlpha',fillAlpha,'EdgeColor','k');

    legend(ax,[p1 p2],{'Healthy controls','Chronic stress'}, ...
        'Box','off','FontSize',14,'Location','northeast');

    exportgraphics(fig,fullfile(outDir,'Accuracy_figure.png'),'Resolution',600);
    exportgraphics(fig,fullfile(outDir,'Accuracy_figure.tiff'),'Resolution',600);
    exportgraphics(fig,fullfile(outDir,'Accuracy_figure.pdf'),'ContentType','vector');
end
