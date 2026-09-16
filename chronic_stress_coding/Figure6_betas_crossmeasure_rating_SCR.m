%% Subjective-rating beta coefficients by predictor and controllability
% Publication/repository version
%
% Purpose
%   Examine participant-level regression coefficients from subjective
%   stress-rating GLMs separately for three computational models:
%
%       1. Surprise
%       2. Belief uncertainty
%       3. Volatility
%
% For each model, four predictor coefficients are analysed:
%       - Previous stress rating
%       - Prediction accuracy
%       - Computational model regressor
%       - Skin conductance response (SCR)
%
% Study design
%   Within-participant factors:
%       Controllability = Controllable (S1), Uncontrollable (S2)
%       Predictor       = Previous rating, Accuracy, Model regressor, SCR
%
% Primary analysis
%   2 (Controllability) x 4 (Predictor) repeated-measures ANOVA,
%   run separately for Surprise, Belief uncertainty, and Volatility.
%
% Follow-up analyses
%   1. Controllable vs Uncontrollable for each predictor
%   2. Pairwise predictor comparisons within Controllable
%   3. Pairwise predictor comparisons within Uncontrollable
%
% Cleaning
%   - S1 and S2 are paired within participant.
%   - If Subject/SubjectID columns are available in both sessions, pairing
%     uses those IDs.
%   - Otherwise, row-order pairing is used only when S1 and S2 have exactly
%   - Complete cases are required across all eight repeated-measures cells.
%   - Optional >3 SD cleaning is applied at the participant-row level:
%     if any of the eight beta values exceeds the threshold, that participant
%     is removed for that computational-model analysis.
%
% Figure
%   - One figure per computational model
%   - Same cleaned participant sample used for plotting and statistics
%   - Common y-axis limits across all three model figures
%   - Controllable and Uncontrollable shown side by side for each predictor
%
% Required input directory structure
%
%   data/Rating_Betas_4Predictor/
%       S1/
%           Betas_Surp_SRprev_Acc_U_SCR_s1.xlsx
%           Betas_Estim_SRprev_Acc_U_SCR_s1.xlsx
%           Betas_Vol_SRprev_Acc_U_SCR_s1.xlsx
%
%       S2/
%           Betas_Surp_SRprev_Acc_U_SCR_s2.xlsx
%           Betas_Estim_SRprev_Acc_U_SCR_s2.xlsx
%           Betas_Vol_SRprev_Acc_U_SCR_s2.xlsx
%
% Expected beta columns
%   Beta_SR_prev
%   Beta_Accuracy
%   Beta_U
%   Beta_SCR
%
% -------------------------------------------------------------------------
% Daniyal Rajput
% Probabilistic aversive-learning study
% -------------------------------------------------------------------------

clear; clc; close all;
rng(1,'twister');   % reproducible scatter jitter

%% Paths
scriptDir = fileparts(mfilename('fullpath'));
if isempty(scriptDir)
    scriptDir = pwd;
end

dataDir = fullfile(scriptDir,'data','Rating_Betas_4Predictor');

s1Dir = fullfile(dataDir,'S1');
s2Dir = fullfile(dataDir,'S2');

outDir   = fullfile(scriptDir,'results','Rating_Betas_4Predictor');
statsDir = fullfile(outDir,'stats');
cleanDir = fullfile(outDir,'cleaned_data');

if ~exist(outDir,'dir'),   mkdir(outDir);   end
if ~exist(statsDir,'dir'), mkdir(statsDir); end
if ~exist(cleanDir,'dir'), mkdir(cleanDir); end

%% Input files
modelNames = {'Surprise','Belief Uncertainty','Volatility'};

s1Files = {
    fullfile(s1Dir,'Betas_Surp_SRprev_Acc_U_SCR_s1.xlsx'), ...
    fullfile(s1Dir,'Betas_Estim_SRprev_Acc_U_SCR_s1.xlsx'), ...
    fullfile(s1Dir,'Betas_Vol_SRprev_Acc_U_SCR_s1.xlsx')
    };

s2Files = {
    fullfile(s2Dir,'Betas_Surp_SRprev_Acc_U_SCR_s2.xlsx'), ...
    fullfile(s2Dir,'Betas_Estim_SRprev_Acc_U_SCR_s2.xlsx'), ...
    fullfile(s2Dir,'Betas_Vol_SRprev_Acc_U_SCR_s2.xlsx')
    };

allFiles = [s1Files,s2Files];

for i = 1:numel(allFiles)
    assert(isfile(allFiles{i}),'Missing input file: %s',allFiles{i});
end

%% Required columns
requiredColumns = { ...
    'Beta_SR_prev', ...
    'Beta_Accuracy', ...
    'Beta_U', ...
    'Beta_SCR'};

%% Cleaning settings
apply3SD = true;
sdThreshold = 3;

%% Figure settings
colorS1 = [0.00 0.25 0.55];
colorS2 = [0.85 0.33 0.00];

fsXTick  = 20;
fsYTick  = 20;
fsLabel  = 22;
fsLegend = 16;

lineAxes = 1.6;
lineBox  = 1.2;

dotSize  = 30;
boxAlpha = 0.28;
dotAlpha = 0.85;

pngDPI = 600;

% Spacing
betweenPredictorGap = 0.80;
withinPredictorGap  = 0.16;
boxWidth            = 0.26;

jitterFractionOfHalfBox = 0.85;
dotJitter = (boxWidth/2)*jitterFractionOfHalfBox;

xStart  = 0.85;
leftPad = 0.35;
rightPad = 0.55;

if withinPredictorGap >= betweenPredictorGap/2
    withinPredictorGap = 0.45*(betweenPredictorGap/2);
end

%% Predictor labels
basePredictorLabels = { ...
    'Previous rating', ...
    'Accuracy', ...
    '', ...
    'SCR'};

predictorKeys = { ...
    'PreviousRating', ...
    'Accuracy', ...
    'ModelRegressor', ...
    'SCR'};

%% ========================================================================
% PASS 1: read, pair, complete-case clean, and apply >3 SD
% ========================================================================

Cleaned = struct();
allCleanValues = [];

for m = 1:numel(modelNames)

    T1 = read_beta_table(s1Files{m},requiredColumns);
    T2 = read_beta_table(s2Files{m},requiredColumns);

    [subjectIDs,Mraw,pairingMethod] = pair_sessions(T1,T2,requiredColumns);

    % Mraw column order:
    %   1 S1 Previous rating
    %   2 S1 Accuracy
    %   3 S1 Model regressor
    %   4 S1 SCR
    %   5 S2 Previous rating
    %   6 S2 Accuracy
    %   7 S2 Model regressor
    %   8 S2 SCR

    completeRows = all(isfinite(Mraw),2);

    Mcomplete = Mraw(completeRows,:);
    IDsComplete = subjectIDs(completeRows);

    incompleteIDs = subjectIDs(~completeRows);

    if apply3SD
        [Mclean,IDsClean,sdLog] = remove_rowwise_3sd( ...
            Mcomplete,IDsComplete,sdThreshold);
    else
        Mclean = Mcomplete;
        IDsClean = IDsComplete;
        sdLog = empty_sd_log();
    end

    Cleaned(m).Model = modelNames{m};
    Cleaned(m).PairingMethod = pairingMethod;

    Cleaned(m).Mraw = Mraw;
    Cleaned(m).RawSubjectIDs = subjectIDs;

    Cleaned(m).Mclean = Mclean;
    Cleaned(m).SubjectIDs = IDsClean;

    Cleaned(m).IncompleteSubjectIDs = incompleteIDs;
    Cleaned(m).SDRemovalLog = sdLog;

    Cleaned(m).N_Raw = size(Mraw,1);
    Cleaned(m).N_IncompleteRemoved = sum(~completeRows);
    Cleaned(m).N_3SDRemoved = height(sdLog);
    Cleaned(m).N_Final = size(Mclean,1);

    allCleanValues = [allCleanValues;Mclean(:)]; %#ok<AGROW>
end

allCleanValues = allCleanValues(isfinite(allCleanValues));

if isempty(allCleanValues)
    error('No valid data remained after cleaning.');
end

%% Common y-axis across all model figures
[yLimits,yTicks] = symmetric_axis_limits(allCleanValues,5);
yTickFormat = '%.2f';

%% ========================================================================
% MODEL-SPECIFIC ANALYSIS
% ========================================================================

for m = 1:numel(modelNames)

    modelName = modelNames{m};
    safeModel = regexprep(modelName,'\s+','_');

    fprintf('\n============================================================\n');
    fprintf('Model %d/%d: %s\n',m,numel(modelNames),modelName);
    fprintf('============================================================\n');

    M = Cleaned(m).Mclean;
    subjectIDs = Cleaned(m).SubjectIDs;
    nSubjects = size(M,1);

    if nSubjects < 2
        error('Too few participants after cleaning for %s (N=%d).', ...
            modelName,nSubjects);
    end

    predictorLabels = basePredictorLabels;
    predictorLabels{3} = modelName;

    %% Cleaned-data table
    cleanedTable = table( ...
        string(subjectIDs), ...
        M(:,1),M(:,2),M(:,3),M(:,4), ...
        M(:,5),M(:,6),M(:,7),M(:,8), ...
        'VariableNames', { ...
            'SubjectID', ...
            'S1_PreviousRating','S1_Accuracy','S1_ModelRegressor','S1_SCR', ...
            'S2_PreviousRating','S2_Accuracy','S2_ModelRegressor','S2_SCR'});

    %% Descriptive statistics
    descriptives = build_descriptives(M,predictorLabels);

    %% Follow-up 1: Controllable vs Uncontrollable
    conditionTests = table( ...
        string(predictorLabels(:)), ...
        nan(4,1),nan(4,1),nan(4,1), ...
        nan(4,1),nan(4,1),nan(4,1),nan(4,1),nan(4,1), ...
        'VariableNames', { ...
            'Predictor', ...
            'Mean_Controllable','Mean_Uncontrollable','MeanDifference', ...
            't','df','p','CI_Lower','CI_Upper'});

    if nSubjects >= 2
        for p = 1:4
            [~,pv,ci,st] = ttest(M(:,p),M(:,p+4));

            conditionTests.Mean_Controllable(p) = mean(M(:,p));
            conditionTests.Mean_Uncontrollable(p) = mean(M(:,p+4));
            conditionTests.MeanDifference(p) = mean(M(:,p)-M(:,p+4));

            conditionTests.t(p) = st.tstat;
            conditionTests.df(p) = st.df;
            conditionTests.p(p) = pv;
            conditionTests.CI_Lower(p) = ci(1);
            conditionTests.CI_Upper(p) = ci(2);
        end
    end

    %% Follow-up 2/3: Predictor pairs within each condition
    predictorPairs = [ ...
        1 2; ...
        1 3; ...
        1 4; ...
        2 3; ...
        2 4; ...
        3 4];

    pairNames = strings(6,1);

    for i = 1:6
        pairNames(i) = predictorLabels{predictorPairs(i,1)} + ...
            " vs " + predictorLabels{predictorPairs(i,2)};
    end

    withinS1 = make_pairwise_table(pairNames);
    withinS2 = make_pairwise_table(pairNames);

    if nSubjects >= 2
        for i = 1:6

            a = predictorPairs(i,1);
            b = predictorPairs(i,2);

            % Controllable
            [~,pv,ci,st] = ttest(M(:,a),M(:,b));

            withinS1.Mean_1(i) = mean(M(:,a));
            withinS1.Mean_2(i) = mean(M(:,b));
            withinS1.MeanDifference(i) = mean(M(:,a)-M(:,b));

            withinS1.t(i) = st.tstat;
            withinS1.df(i) = st.df;
            withinS1.p(i) = pv;
            withinS1.CI_Lower(i) = ci(1);
            withinS1.CI_Upper(i) = ci(2);

            % Uncontrollable
            a2 = a+4;
            b2 = b+4;

            [~,pv,ci,st] = ttest(M(:,a2),M(:,b2));

            withinS2.Mean_1(i) = mean(M(:,a2));
            withinS2.Mean_2(i) = mean(M(:,b2));
            withinS2.MeanDifference(i) = mean(M(:,a2)-M(:,b2));

            withinS2.t(i) = st.tstat;
            withinS2.df(i) = st.df;
            withinS2.p(i) = pv;
            withinS2.CI_Lower(i) = ci(1);
            withinS2.CI_Upper(i) = ci(2);
        end
    end

    %% 2 x 4 repeated-measures ANOVA
    if nSubjects >= 3

        SubjectID = categorical(string(subjectIDs));

        wideTable = table( ...
            SubjectID, ...
            M(:,1),M(:,2),M(:,3),M(:,4), ...
            M(:,5),M(:,6),M(:,7),M(:,8), ...
            'VariableNames', { ...
                'SubjectID', ...
                'S1_PreviousRating','S1_Accuracy','S1_ModelRegressor','S1_SCR', ...
                'S2_PreviousRating','S2_Accuracy','S2_ModelRegressor','S2_SCR'});

        withinDesign = table( ...
            categorical({ ...
                'Controllable';'Controllable';'Controllable';'Controllable'; ...
                'Uncontrollable';'Uncontrollable';'Uncontrollable';'Uncontrollable'}, ...
                {'Controllable','Uncontrollable'}), ...
            categorical({ ...
                'PreviousRating';'Accuracy';'ModelRegressor';'SCR'; ...
                'PreviousRating';'Accuracy';'ModelRegressor';'SCR'}, ...
                predictorKeys), ...
            'VariableNames',{'Controllability','Predictor'});

        rm = fitrm( ...
            wideTable, ...
            'S1_PreviousRating-S2_SCR ~ 1', ...
            'WithinDesign',withinDesign);

        anovaTable = ranova( ...
            rm, ...
            'WithinModel','Controllability*Predictor');

        anovaOut = add_row_names(anovaTable,'Effect');

    else
        wideTable = cleanedTable;
        withinDesign = table();
        rm = [];
        anovaTable = table();
        anovaOut = table( ...
            "Repeated-measures ANOVA not run: fewer than 3 participants.", ...
            'VariableNames',{'Note'});
    end

    %% Cleaning log
    incompleteIDs = string(Cleaned(m).IncompleteSubjectIDs);

    if isempty(incompleteIDs)
        incompleteText = "";
    else
        incompleteText = strjoin(incompleteIDs,", ");
    end

    cleaningSummary = table( ...
        ["Model"; ...
         "Pairing method"; ...
         "Raw paired N"; ...
         "Incomplete rows removed"; ...
         "3-SD cleaning"; ...
         "SD threshold"; ...
         "Participants removed by 3-SD"; ...
         "Final N"; ...
         "Incomplete-case Subject IDs"], ...
        [string(modelName); ...
         string(Cleaned(m).PairingMethod); ...
         string(Cleaned(m).N_Raw); ...
         string(Cleaned(m).N_IncompleteRemoved); ...
         string(apply3SD); ...
         string(sdThreshold); ...
         string(Cleaned(m).N_3SDRemoved); ...
         string(Cleaned(m).N_Final); ...
         incompleteText], ...
        'VariableNames',{'Item','Value'});

    %% Figure
    centers = xStart+(0:3)*betweenPredictorGap;

    S1 = {M(:,1),M(:,2),M(:,3),M(:,4)};
    S2 = {M(:,5),M(:,6),M(:,7),M(:,8)};

    fig = figure( ...
        'Color','w', ...
        'Units','pixels', ...
        'Position',[220 240 1200 520]);

    ax = axes(fig);
    hold(ax,'on');

    % Legend proxies
    hS1 = scatter(ax,nan,nan,dotSize,colorS1,'filled', ...
        'MarkerEdgeColor','k', ...
        'MarkerFaceAlpha',dotAlpha);

    hS2 = scatter(ax,nan,nan,dotSize,colorS2,'filled', ...
        'MarkerEdgeColor','k', ...
        'MarkerFaceAlpha',dotAlpha);

    for p = 1:4

        x1 = centers(p)-withinPredictorGap;
        x2 = centers(p)+withinPredictorGap;

        boxchart(ax,x1*ones(size(S1{p})),S1{p}, ...
            'BoxWidth',boxWidth, ...
            'BoxFaceColor',colorS1, ...
            'BoxFaceAlpha',boxAlpha, ...
            'MarkerStyle','none', ...
            'WhiskerLineColor','k', ...
            'LineWidth',lineBox);

        scatter(ax, ...
            x1+(rand(numel(S1{p}),1)-0.5)*2*dotJitter, ...
            S1{p},dotSize,colorS1,'filled', ...
            'MarkerEdgeColor','k', ...
            'MarkerFaceAlpha',dotAlpha);

        boxchart(ax,x2*ones(size(S2{p})),S2{p}, ...
            'BoxWidth',boxWidth, ...
            'BoxFaceColor',colorS2, ...
            'BoxFaceAlpha',boxAlpha, ...
            'MarkerStyle','none', ...
            'WhiskerLineColor','k', ...
            'LineWidth',lineBox);

        scatter(ax, ...
            x2+(rand(numel(S2{p}),1)-0.5)*2*dotJitter, ...
            S2{p},dotSize,colorS2,'filled', ...
            'MarkerEdgeColor','k', ...
            'MarkerFaceAlpha',dotAlpha);
    end

    ax.XTick = centers;
    ax.XTickLabel = predictorLabels;

    ax.XAxis.FontSize = fsXTick;
    ax.YAxis.FontSize = fsYTick;

    ax.LineWidth = lineAxes;
    ax.TickDir = 'out';
    ax.Box = 'off';
    ax.XGrid = 'off';
    ax.YGrid = 'off';

    ylim(ax,yLimits);
    yticks(ax,yTicks);
    ytickformat(ax,yTickFormat);

    xlabel(ax,'Subjective rating model regressor', ...
        'FontSize',fsLabel, ...
        'FontWeight','bold');

    ylabel(ax,'\beta', ...
        'FontSize',fsLabel, ...
        'FontWeight','bold');

    allBoxCenters = reshape( ...
        [centers-withinPredictorGap;centers+withinPredictorGap], ...
        1,[]);

    leftEdge = min(allBoxCenters)-boxWidth/2-leftPad;
    rightEdge = max(allBoxCenters)+boxWidth/2+rightPad;

    xlim(ax,[max(0,leftEdge),rightEdge]);

    legend(ax,[hS1,hS2], ...
        {'Controllable','Uncontrollable'}, ...
        'Location','northeast', ...
        'Box','off', ...
        'FontSize',fsLegend);

    %% Export figure
    figureBase = fullfile(outDir, ...
        sprintf('Rating_Betas_ByPredictor_%s',safeModel));

    exportgraphics(fig,[figureBase '.png'], ...
        'Resolution',pngDPI);

    exportgraphics(fig,[figureBase '.tiff'], ...
        'Resolution',pngDPI);

    exportgraphics(fig,[figureBase '.pdf'], ...
        'ContentType','vector');

    close(fig);

    %% Save model-specific statistics
    statsExcel = fullfile(statsDir, ...
        sprintf('Rating_Betas_ByPredictor_%s_stats.xlsx',safeModel));

    statsText = fullfile(statsDir, ...
        sprintf('Rating_Betas_ByPredictor_%s_stats.txt',safeModel));

    statsMat = fullfile(statsDir, ...
        sprintf('Rating_Betas_ByPredictor_%s_stats.mat',safeModel));

    cleanedExcel = fullfile(cleanDir, ...
        sprintf('Rating_Betas_ByPredictor_%s_cleaned.xlsx',safeModel));

    if isfile(statsExcel)
        delete(statsExcel);
    end
    if isfile(cleanedExcel)
        delete(cleanedExcel);
    end

    writetable(cleanedTable,cleanedExcel,'Sheet','Cleaned_Data');
    writetable(Cleaned(m).SDRemovalLog,cleanedExcel,'Sheet','Removed_3SD');

    writetable(descriptives,statsExcel,'Sheet','Descriptives');
    writetable(conditionTests,statsExcel,'Sheet','Controllable_vs_Uncontrollable');
    writetable(withinS1,statsExcel,'Sheet','PredictorPairs_Controllable');
    writetable(withinS2,statsExcel,'Sheet','PredictorPairs_Uncontrollable');
    writetable(anovaOut,statsExcel,'Sheet','RM_ANOVA');
    writetable(cleaningSummary,statsExcel,'Sheet','Cleaning_Info');
    writetable(cleanedTable,statsExcel,'Sheet','Cleaned_Data');

    %% Text summary
    fid = fopen(statsText,'w');
    assert(fid ~= -1,'Unable to create text summary file.');

    fprintf(fid,'SUBJECTIVE-RATING BETA ANALYSIS\n');
    fprintf(fid,'===============================\n\n');

    fprintf(fid,'Computational model: %s\n',modelName);
    fprintf(fid,'Pairing method: %s\n',Cleaned(m).PairingMethod);
    fprintf(fid,'3-SD participant-level cleaning: %d (threshold = %g SD)\n', ...
        apply3SD,sdThreshold);
    fprintf(fid,'Final N = %d\n\n',nSubjects);

    fprintf(fid,'DESCRIPTIVE STATISTICS\n');
    fprintf(fid,'%s\n',evalc('disp(descriptives)'));

    fprintf(fid,'\nCONTROLLABLE VS UNCONTROLLABLE\n');
    fprintf(fid,'%s\n',evalc('disp(conditionTests)'));

    fprintf(fid,'\nPREDICTOR PAIRS: CONTROLLABLE\n');
    fprintf(fid,'%s\n',evalc('disp(withinS1)'));

    fprintf(fid,'\nPREDICTOR PAIRS: UNCONTROLLABLE\n');
    fprintf(fid,'%s\n',evalc('disp(withinS2)'));

    fprintf(fid,'\n2 x 4 REPEATED-MEASURES ANOVA\n');
    fprintf(fid,'%s\n',evalc('disp(anovaOut)'));

    fclose(fid);

    save(statsMat, ...
        'modelName','M','subjectIDs', ...
        'descriptives','conditionTests','withinS1','withinS2', ...
        'wideTable','withinDesign','rm','anovaTable','anovaOut', ...
        'cleaningSummary');

    fprintf('Saved figure and statistics for %s.\n',modelName);
end

fprintf('\nAll four-predictor subjective-rating beta analyses completed.\n');
fprintf('Figures/results: %s\n',outDir);
fprintf('Statistics: %s\n',statsDir);
fprintf('Cleaned data: %s\n\n',cleanDir);


%% ========================================================================
% Local functions
% ========================================================================

function T = read_beta_table(filePath,requiredColumns)

    T = readtable(filePath,'VariableNamingRule','preserve');

    missingColumns = requiredColumns( ...
        ~ismember(requiredColumns,T.Properties.VariableNames));

    if ~isempty(missingColumns)
        error('File %s is missing required columns: %s', ...
            filePath,strjoin(missingColumns,', '));
    end

    for i = 1:numel(requiredColumns)
        vn = requiredColumns{i};
        T.(vn) = double(T.(vn));
    end
end


function [subjectIDs,M,pairingMethod] = pair_sessions(T1,T2,requiredColumns)

    idName1 = find_subject_column(T1);
    idName2 = find_subject_column(T2);

    if ~isempty(idName1) && ~isempty(idName2)

        id1 = normalize_subject_id(string(T1.(idName1)));
        id2 = normalize_subject_id(string(T2.(idName2)));

        [subjectIDs,i1,i2] = intersect(id1,id2,'stable');

        if isempty(subjectIDs)
            error('No participant matches were found between S1 and S2.');
        end

        pairingMethod = "Subject ID";

    else

        if height(T1) ~= height(T2)
            error(['Subject identifiers are unavailable and S1/S2 row counts differ.\n' ...
                   'S1 N = %d, S2 N = %d.\n' ...
                   'Row-order pairing would be unsafe, so the analysis was stopped.'], ...
                   height(T1),height(T2));
        end

        warning(['Subject identifiers were not available in both files. ' ...
                 'S1 and S2 are being paired by row order. Verify that row ' ...
                 'order represents identical participants across sessions.']);

        n = height(T1);

        i1 = (1:n)';
        i2 = (1:n)';

        subjectIDs = "P" + compose("%03d",(1:n)');
        pairingMethod = "Row order";
    end

    M = [ ...
        T1.(requiredColumns{1})(i1), ...
        T1.(requiredColumns{2})(i1), ...
        T1.(requiredColumns{3})(i1), ...
        T1.(requiredColumns{4})(i1), ...
        T2.(requiredColumns{1})(i2), ...
        T2.(requiredColumns{2})(i2), ...
        T2.(requiredColumns{3})(i2), ...
        T2.(requiredColumns{4})(i2)];
end


function name = find_subject_column(T)

    candidates = { ...
        'Subject', ...
        'SubjectID', ...
        'Participant', ...
        'ParticipantID'};

    name = '';

    for i = 1:numel(candidates)
        if ismember(candidates{i},T.Properties.VariableNames)
            name = candidates{i};
            return
        end
    end
end


function id = normalize_subject_id(id)

    id = strtrim(id);

    id = regexprep(id,'(?i)_S1_cleaned$','');
    id = regexprep(id,'(?i)_S2_cleaned$','');
    id = regexprep(id,'(?i)_S[12]$','');
    id = regexprep(id,'(?i)-S[12]$','');
    id = regexprep(id,'(?i)\s*S[12]$','');
end


function [Mclean,IDsClean,logTable] = remove_rowwise_3sd( ...
    M,IDs,threshold)

    if size(M,1) < 5
        Mclean = M;
        IDsClean = IDs;
        logTable = empty_sd_log();
        return
    end

    mu = mean(M,1,'omitnan');
    sd = std(M,0,1,'omitnan');

    sd(sd < eps) = eps;

    Z = abs((M-mu)./sd);

    removeRows = any(Z > threshold,2);
    removedIdx = find(removeRows);

    if isempty(removedIdx)
        logTable = empty_sd_log();
    else
        SubjectID = string(IDs(removedIdx));
        MaxAbsZ = max(Z(removedIdx,:),[],2);

        logTable = table(SubjectID,MaxAbsZ);
    end

    Mclean = M(~removeRows,:);
    IDsClean = IDs(~removeRows);
end


function T = empty_sd_log()

    T = table( ...
        strings(0,1), ...
        zeros(0,1), ...
        'VariableNames',{'SubjectID','MaxAbsZ'});
end


function D = build_descriptives(M,predictorLabels)

    Controllability = strings(8,1);
    Predictor = strings(8,1);
    N = zeros(8,1);
    Mean = zeros(8,1);
    SD = zeros(8,1);
    SEM = zeros(8,1);
    Median = zeros(8,1);

    row = 0;

    for p = 1:4

        row = row+1;

        x = M(:,p);

        Controllability(row) = "Controllable";
        Predictor(row) = string(predictorLabels{p});
        N(row) = numel(x);
        Mean(row) = mean(x);
        SD(row) = std(x);
        SEM(row) = std(x)/sqrt(numel(x));
        Median(row) = median(x);

        row = row+1;

        x = M(:,p+4);

        Controllability(row) = "Uncontrollable";
        Predictor(row) = string(predictorLabels{p});
        N(row) = numel(x);
        Mean(row) = mean(x);
        SD(row) = std(x);
        SEM(row) = std(x)/sqrt(numel(x));
        Median(row) = median(x);
    end

    D = table( ...
        Controllability,Predictor,N,Mean,SD,SEM,Median);
end


function T = make_pairwise_table(pairNames)

    T = table( ...
        pairNames(:), ...
        nan(6,1),nan(6,1),nan(6,1), ...
        nan(6,1),nan(6,1),nan(6,1),nan(6,1),nan(6,1), ...
        'VariableNames', { ...
            'Comparison', ...
            'Mean_1','Mean_2','MeanDifference', ...
            't','df','p','CI_Lower','CI_Upper'});
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


function [limits,ticks] = symmetric_axis_limits(values,nTicks)

    values = values(isfinite(values));

    if isempty(values)
        limits = [-1 1];
        ticks = linspace(-1,1,nTicks);
        return
    end

    minValue = min(values);
    maxValue = max(values);

    padding = 0.03*(maxValue-minValue+eps);

    maxAbs = max(abs([minValue-padding,maxValue+padding]));

    rawStep = (2*maxAbs)/(nTicks-1);

    magnitude = 10^floor(log10(rawStep+eps));
    candidates = [1 2 2.5 5 10]*magnitude;

    [~,idx] = min(abs(candidates-rawStep));
    step = candidates(idx);

    maxAbsNice = ceil(maxAbs/step)*step;

    limits = [-maxAbsNice,maxAbsNice];
    ticks = linspace(limits(1),limits(2),nTicks);
    ticks = round(ticks,4);
end
