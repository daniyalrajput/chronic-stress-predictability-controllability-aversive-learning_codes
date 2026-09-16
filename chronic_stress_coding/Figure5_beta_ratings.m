%% Beta-coefficient analysis: Chronic stress study
% Publication/repository version
%
% Purpose
%   Compare regression coefficients from subjective stress-rating GLMs
%   between Healthy controls and participants with Chronic stress.
%
% For each computational model (Surprise, Belief uncertainty, Volatility),
% participant-level coefficients are analysed for:
%   1. Previous stress rating
%   2. Prediction accuracy
%   3. Computational model regressor
%
% Study design
%   Between-participant factor:
%       Group = Healthy control, Chronic stress
%
%   Within-participant factors:
%       Controllability = Controllable (S1), Uncontrollable (S2)
%       Predictor = Previous rating, Accuracy, Model regressor
%
% Analysis
%   2 (Group) x 2 (Controllability) x 3 (Predictor)
%   mixed repeated-measures ANOVA, run separately for each computational
%   model.
%
% Follow-up analyses
%   A. Healthy vs Chronic stress for each of the six cells
%   B. Controllable vs Uncontrollable for each predictor within each group
%   C. Pairwise predictor comparisons within each Group x Controllability cell
%
% Cleaning
%   - S1 and S2 are paired by participant ID whenever a Subject column exists.
%   - Complete cases are required within each model because the RM-ANOVA uses
%     all six repeated-measures cells.
%   - Optional >3 SD exclusion is applied at the participant level: if any of
%     the six beta values for a participant exceeds the threshold within that
%     group/model, that participant is excluded from that model analysis.
%
%
% Expected columns in beta files
%   Subject
%   Beta_SR_prev
%   Beta_Accuracy
%   Beta_U
%
% Example subject labels
%   PS01_S1, PS01_S2
%
% Required directory structure
%
%   data/Beta_SubjectiveRatings/
%       Healthy/
%           S1/
%           S2/
%       Chronic/
%           S1/
%           S2/
%
% File names are defined below.
%
% -------------------------------------------------------------------------
% Daniyal Rajput
% Chronic stress / probabilistic aversive-learning study
% -------------------------------------------------------------------------

clear; clc; close all;
rng(1, 'twister');   % reproducible jitter only

%% Paths
scriptDir = fileparts(mfilename('fullpath'));
if isempty(scriptDir)
    scriptDir = pwd;
end

dataDir = fullfile(scriptDir, 'data', 'Beta_SubjectiveRatings');

healthyS1Dir = fullfile(dataDir, 'Healthy', 'S1');
healthyS2Dir = fullfile(dataDir, 'Healthy', 'S2');

chronicS1Dir = fullfile(dataDir, 'Chronic', 'S1');
chronicS2Dir = fullfile(dataDir, 'Chronic', 'S2');

outDir   = fullfile(scriptDir, 'results', 'Beta_SubjectiveRatings');
statsDir = fullfile(outDir, 'stats');

if ~exist(outDir, 'dir')
    mkdir(outDir);
end
if ~exist(statsDir, 'dir')
    mkdir(statsDir);
end

%% Input files
% Healthy controls
H_surp_s1  = fullfile(healthyS1Dir, 'Betas_Surp_Acc_U_SRprev_s1.xlsx');
H_bu_s1    = fullfile(healthyS1Dir, 'Betas_Estim_Acc_U_SRprev_s1.xlsx');
H_vol_s1   = fullfile(healthyS1Dir, 'Betas_Vol_Acc_U_SRprev_s1.xlsx');

H_surp_s2  = fullfile(healthyS2Dir, 'Betas_Surp_Acc_U_SRprev_s2.xlsx');
H_bu_s2    = fullfile(healthyS2Dir, 'Betas_Estim_Acc_U_SRprev_s2.xlsx');
H_vol_s2   = fullfile(healthyS2Dir, 'Betas_Vol_Acc_U_SRprev_s2.xlsx');

% Chronic stress
C_surp_s1  = fullfile(chronicS1Dir, 'Betas_Surprise_s1.xlsx');
C_bu_s1    = fullfile(chronicS1Dir, 'Betas_Belief_Uncertainty_s1.xlsx');
C_vol_s1   = fullfile(chronicS1Dir, 'Betas_Volatility_s1.xlsx');

C_surp_s2  = fullfile(chronicS2Dir, 'Betas_Surprise_s2.xlsx');
C_bu_s2    = fullfile(chronicS2Dir, 'Betas_Belief_Uncertainty_s2.xlsx');
C_vol_s2   = fullfile(chronicS2Dir, 'Betas_Volatility_s2.xlsx');

requiredFiles = { ...
    H_surp_s1,H_bu_s1,H_vol_s1,H_surp_s2,H_bu_s2,H_vol_s2, ...
    C_surp_s1,C_bu_s1,C_vol_s1,C_surp_s2,C_bu_s2,C_vol_s2};

for i = 1:numel(requiredFiles)
    assert(isfile(requiredFiles{i}), 'Missing input file: %s', requiredFiles{i});
end

%% Model setup
modelNames = {'Surprise','Belief Uncertainty','Volatility'};

healthyS1Files = {H_surp_s1,H_bu_s1,H_vol_s1};
healthyS2Files = {H_surp_s2,H_bu_s2,H_vol_s2};

chronicS1Files = {C_surp_s1,C_bu_s1,C_vol_s1};
chronicS2Files = {C_surp_s2,C_bu_s2,C_vol_s2};

requiredColumns = {'Beta_SR_prev','Beta_Accuracy','Beta_U'};

%% Cleaning settings
apply3SD = true;
sdThreshold = 3;

%% Figure settings
% Box fill encodes controllability.
colorBoxS1 = [0.75 0.88 1.00];   % Controllable
colorBoxS2 = [1.00 0.85 0.72];   % Uncontrollable

% Dot color encodes group.
colorHealthy = [0.10 0.25 0.70];
colorChronic = [0.80 0.30 0.08];

fsXTick  = 18;
fsYTick  = 18;
fsLabel  = 20;
fsTitle  = 22;
fsLegend = 18;

lineAxes = 1.6;
lineBox  = 1.2;

dotSize    = 42;
boxAlpha   = 0.35;
dotAlpha   = 0.90;
xJitter    = 0.10;

pngDPI = 600;

%% Read, pair, clean, analyse, and plot each computational model
for m = 1:3

    modelName = modelNames{m};
    safeModel = regexprep(modelName, '\s+', '_');

    fprintf('\n============================================================\n');
    fprintf('Model %d/3: %s\n', m, modelName);
    fprintf('============================================================\n');

    %% Read beta tables
    H1 = read_beta_table(healthyS1Files{m}, requiredColumns);
    H2 = read_beta_table(healthyS2Files{m}, requiredColumns);

    C1 = read_beta_table(chronicS1Files{m}, requiredColumns);
    C2 = read_beta_table(chronicS2Files{m}, requiredColumns);

    %% Pair S1 and S2 within each group
    [healthyIDs, MHraw] = pair_sessions(H1, H2, "Healthy");
    [chronicIDs, MCraw] = pair_sessions(C1, C2, "Chronic");

    % Matrix column order:
    %   1 S1 Previous rating
    %   2 S1 Accuracy
    %   3 S1 Model regressor
    %   4 S2 Previous rating
    %   5 S2 Accuracy
    %   6 S2 Model regressor

    %% Complete-case filtering
    keepHComplete = all(isfinite(MHraw), 2);
    keepCComplete = all(isfinite(MCraw), 2);

    MH = MHraw(keepHComplete,:);
    healthyIDsClean = healthyIDs(keepHComplete);

    MC = MCraw(keepCComplete,:);
    chronicIDsClean = chronicIDs(keepCComplete);

    %% Optional participant-level >3 SD exclusion
    if apply3SD
        [MH, healthyIDsClean, removalH] = remove_rowwise_3sd( ...
            MH, healthyIDsClean, sdThreshold, "Healthy");

        [MC, chronicIDsClean, removalC] = remove_rowwise_3sd( ...
            MC, chronicIDsClean, sdThreshold, "Chronic");
    else
        removalH = empty_removal_table();
        removalC = empty_removal_table();
    end

    removalLog = [removalH; removalC];

    nH = size(MH,1);
    nC = size(MC,1);

    if nH < 2 || nC < 2
        error('Too few participants after cleaning for model %s. Healthy=%d, Chronic=%d', ...
            modelName,nH,nC);
    end

    fprintf('Participants retained: Healthy=%d, Chronic=%d\n', nH, nC);

    %% Build repeated-measures table
    TH = table( ...
        categorical(healthyIDsClean), ...
        categorical(repmat("Healthy",nH,1), {'Healthy','Chronic'}), ...
        MH(:,1),MH(:,2),MH(:,3),MH(:,4),MH(:,5),MH(:,6), ...
        'VariableNames', { ...
            'SubjectID','Group', ...
            'S1_Prev','S1_Accuracy','S1_ModelReg', ...
            'S2_Prev','S2_Accuracy','S2_ModelReg'});

    TC = table( ...
        categorical(chronicIDsClean), ...
        categorical(repmat("Chronic",nC,1), {'Healthy','Chronic'}), ...
        MC(:,1),MC(:,2),MC(:,3),MC(:,4),MC(:,5),MC(:,6), ...
        'VariableNames', { ...
            'SubjectID','Group', ...
            'S1_Prev','S1_Accuracy','S1_ModelReg', ...
            'S2_Prev','S2_Accuracy','S2_ModelReg'});

    Tall = [TH; TC];

    withinDesign = table( ...
        categorical({'Controllable';'Controllable';'Controllable'; ...
                     'Uncontrollable';'Uncontrollable';'Uncontrollable'}, ...
                    {'Controllable','Uncontrollable'}), ...
        categorical({'PreviousRating';'Accuracy';'ModelRegressor'; ...
                     'PreviousRating';'Accuracy';'ModelRegressor'}, ...
                    {'PreviousRating','Accuracy','ModelRegressor'}), ...
        'VariableNames', {'Controllability','Predictor'});

    rm = fitrm(Tall, ...
        'S1_Prev-S2_ModelReg ~ Group', ...
        'WithinDesign', withinDesign);

    anovaWithin = ranova(rm, ...
        'WithinModel', 'Controllability*Predictor');

    anovaBetween = anova(rm);

    anovaWithinOut  = add_row_names(anovaWithin, 'Effect');
    anovaBetweenOut = add_row_names(anovaBetween, 'Effect');

    %% Post-hoc A: Healthy vs Chronic stress within each cell
    cellNames = [ ...
        "Controllable_PreviousRating";
        "Controllable_Accuracy";
        "Controllable_ModelRegressor";
        "Uncontrollable_PreviousRating";
        "Uncontrollable_Accuracy";
        "Uncontrollable_ModelRegressor"];

    tA  = nan(6,1);
    dfA = nan(6,1);
    pA  = nan(6,1);
    meanHealthy = nan(6,1);
    meanChronic = nan(6,1);
    meanDifference = nan(6,1);

    for i = 1:6
        [~,p,ci,st] = ttest2(MH(:,i),MC(:,i),'Vartype','unequal');

        tA(i) = st.tstat;
        dfA(i) = st.df;
        pA(i) = p;
        meanHealthy(i) = mean(MH(:,i));
        meanChronic(i) = mean(MC(:,i));
        meanDifference(i) = mean(MH(:,i))-mean(MC(:,i));
        ciLowerA(i,1) = ci(1); %#ok<AGROW>
        ciUpperA(i,1) = ci(2); %#ok<AGROW>
    end

    pBonfA = min(pA*6,1);

    postBetween = table( ...
        cellNames,meanHealthy,meanChronic,meanDifference, ...
        tA,dfA,pA,pBonfA,ciLowerA,ciUpperA, ...
        'VariableNames', { ...
            'Cell','Mean_Healthy','Mean_Chronic','MeanDifference', ...
            't','df','p','p_Bonferroni','CI_Lower','CI_Upper'});

    %% Post-hoc B: Controllable vs Uncontrollable within each group
    predictorNames = ["PreviousRating";"Accuracy";"ModelRegressor"];

    GroupB = [repmat("Healthy",3,1); repmat("Chronic",3,1)];
    PredictorB = repmat(predictorNames,2,1);

    tB  = nan(6,1);
    dfB = nan(6,1);
    pB  = nan(6,1);
    pBonfB = nan(6,1);
    meanS1B = nan(6,1);
    meanS2B = nan(6,1);
    meanDiffB = nan(6,1);
    ciLowerB = nan(6,1);
    ciUpperB = nan(6,1);

    for k = 1:3
        [~,p,ci,st] = ttest(MH(:,k),MH(:,k+3));

        tB(k) = st.tstat;
        dfB(k) = st.df;
        pB(k) = p;
        meanS1B(k) = mean(MH(:,k));
        meanS2B(k) = mean(MH(:,k+3));
        meanDiffB(k) = mean(MH(:,k)-MH(:,k+3));
        ciLowerB(k) = ci(1);
        ciUpperB(k) = ci(2);
    end
    pBonfB(1:3) = min(pB(1:3)*3,1);

    for k = 1:3
        idx = 3+k;
        [~,p,ci,st] = ttest(MC(:,k),MC(:,k+3));

        tB(idx) = st.tstat;
        dfB(idx) = st.df;
        pB(idx) = p;
        meanS1B(idx) = mean(MC(:,k));
        meanS2B(idx) = mean(MC(:,k+3));
        meanDiffB(idx) = mean(MC(:,k)-MC(:,k+3));
        ciLowerB(idx) = ci(1);
        ciUpperB(idx) = ci(2);
    end
    pBonfB(4:6) = min(pB(4:6)*3,1);

    postControl = table( ...
        GroupB,PredictorB,meanS1B,meanS2B,meanDiffB, ...
        tB,dfB,pB,pBonfB,ciLowerB,ciUpperB, ...
        'VariableNames', { ...
            'Group','Predictor','Mean_Controllable','Mean_Uncontrollable', ...
            'MeanDifference','t','df','p','p_Bonferroni', ...
            'CI_Lower','CI_Upper'});

    %% Post-hoc C: Predictor pairs within each Group x Controllability
    predictorPairs = [1 2;1 3;2 3];
    pairNames = [ ...
        "PreviousRating_vs_Accuracy";
        "PreviousRating_vs_ModelRegressor";
        "Accuracy_vs_ModelRegressor"];

    nRows = 12;

    GroupC = strings(nRows,1);
    ControllabilityC = strings(nRows,1);
    ComparisonC = strings(nRows,1);

    tC = nan(nRows,1);
    dfC = nan(nRows,1);
    pC = nan(nRows,1);
    pBonfC = nan(nRows,1);
    mean1C = nan(nRows,1);
    mean2C = nan(nRows,1);
    meanDiffC = nan(nRows,1);
    ciLowerC = nan(nRows,1);
    ciUpperC = nan(nRows,1);

    rr = 0;

    for g = 1:2

        if g == 1
            groupName = "Healthy";
            M = MH;
        else
            groupName = "Chronic";
            M = MC;
        end

        for cond = 1:2

            if cond == 1
                conditionName = "Controllable";
                offset = 0;
            else
                conditionName = "Uncontrollable";
                offset = 3;
            end

            familyRows = rr+(1:3);

            for i = 1:3
                rr = rr+1;

                idx1 = offset+predictorPairs(i,1);
                idx2 = offset+predictorPairs(i,2);

                [~,p,ci,st] = ttest(M(:,idx1),M(:,idx2));

                GroupC(rr) = groupName;
                ControllabilityC(rr) = conditionName;
                ComparisonC(rr) = pairNames(i);

                mean1C(rr) = mean(M(:,idx1));
                mean2C(rr) = mean(M(:,idx2));
                meanDiffC(rr) = mean(M(:,idx1)-M(:,idx2));

                tC(rr) = st.tstat;
                dfC(rr) = st.df;
                pC(rr) = p;
                ciLowerC(rr) = ci(1);
                ciUpperC(rr) = ci(2);
            end

            pBonfC(familyRows) = min(pC(familyRows)*3,1);
        end
    end

    postPredictor = table( ...
        GroupC,ControllabilityC,ComparisonC, ...
        mean1C,mean2C,meanDiffC,tC,dfC,pC,pBonfC,ciLowerC,ciUpperC, ...
        'VariableNames', { ...
            'Group','Controllability','Comparison', ...
            'Mean_1','Mean_2','MeanDifference', ...
            't','df','p','p_Bonferroni','CI_Lower','CI_Upper'});

    %% Plot
    [yLimits,yTicks] = symmetric_axis_limits([MH(:);MC(:)],5);

    columnTitles = {'Previous rating','Accuracy',modelName};

    fig = figure( ...
        'Color','w', ...
        'Units','pixels', ...
        'Position',[120 120 1750 840]);

    tiled = tiledlayout(fig,2,4, ...
        'TileSpacing','compact', ...
        'Padding','compact');

    % Legend tile
    axLegend = nexttile(tiled,4);
    axis(axLegend,'off');
    hold(axLegend,'on');

    hS1 = plot(axLegend,nan,nan,'s', ...
        'MarkerSize',12, ...
        'MarkerFaceColor',colorBoxS1, ...
        'MarkerEdgeColor','k', ...
        'LineStyle','none');

    hS2 = plot(axLegend,nan,nan,'s', ...
        'MarkerSize',12, ...
        'MarkerFaceColor',colorBoxS2, ...
        'MarkerEdgeColor','k', ...
        'LineStyle','none');

    hH = plot(axLegend,nan,nan,'o', ...
        'MarkerSize',10, ...
        'MarkerFaceColor',colorHealthy, ...
        'MarkerEdgeColor','k', ...
        'LineStyle','none');

    hC = plot(axLegend,nan,nan,'o', ...
        'MarkerSize',10, ...
        'MarkerFaceColor',colorChronic, ...
        'MarkerEdgeColor','k', ...
        'LineStyle','none');

    lgd = legend(axLegend,[hS1 hS2 hH hC], ...
        {'Controllable','Uncontrollable','Healthy controls','Chronic stress'}, ...
        'Location','northeast', ...
        'Box','off');

    lgd.FontSize = fsLegend;

    % Leave bottom-right tile blank.
    axBlank = nexttile(tiled,8);
    axis(axBlank,'off');

    % Six data panels.
    for r = 1:2
        for c = 1:3

            ax = nexttile(tiled,(r-1)*4+c);
            hold(ax,'on');

            if r == 1
                yH = MH(:,c);
                yC = MC(:,c);
                boxColor = colorBoxS1;
            else
                yH = MH(:,c+3);
                yC = MC(:,c+3);
                boxColor = colorBoxS2;
            end

            xH = 1;
            xC = 2;

            boxchart(ax,xH*ones(size(yH)),yH, ...
                'BoxFaceColor',boxColor, ...
                'BoxFaceAlpha',boxAlpha, ...
                'MarkerStyle','none', ...
                'WhiskerLineColor','k', ...
                'LineWidth',lineBox);

            boxchart(ax,xC*ones(size(yC)),yC, ...
                'BoxFaceColor',boxColor, ...
                'BoxFaceAlpha',boxAlpha, ...
                'MarkerStyle','none', ...
                'WhiskerLineColor','k', ...
                'LineWidth',lineBox);

            scatter(ax, ...
                xH+(rand(numel(yH),1)-0.5)*2*xJitter, ...
                yH,dotSize,colorHealthy,'filled', ...
                'MarkerEdgeColor','k', ...
                'MarkerFaceAlpha',dotAlpha);

            scatter(ax, ...
                xC+(rand(numel(yC),1)-0.5)*2*xJitter, ...
                yC,dotSize,colorChronic,'filled', ...
                'MarkerEdgeColor','k', ...
                'MarkerFaceAlpha',dotAlpha);

            ax.XLim = [0.5 2.5];
            ax.LineWidth = lineAxes;
            ax.TickDir = 'out';
            ax.Box = 'off';
            ax.FontSize = fsYTick;

            ylim(ax,yLimits);
            yticks(ax,yTicks);
            ytickformat(ax,'%.2f');

            if r == 1
                title(ax,columnTitles{c}, ...
                    'FontSize',fsTitle, ...
                    'FontWeight','bold');
            end

            if c == 1
                ylabel(ax,'\beta', ...
                    'FontSize',fsLabel, ...
                    'FontWeight','bold');
            end

            if r == 2
                ax.XTick = [1 2];
                ax.XTickLabel = {'Healthy','Chronic'};
                ax.XAxis.FontSize = fsXTick;
            else
                ax.XTick = [];
            end
        end
    end

    %% Save figure
    figureBase = fullfile(outDir, ...
        sprintf('Beta_SubjectiveRatings_Healthy_vs_Chronic_%s',safeModel));

    exportgraphics(fig,[figureBase '.png'], ...
        'Resolution',pngDPI);

    exportgraphics(fig,[figureBase '.tiff'], ...
        'Resolution',pngDPI);

    exportgraphics(fig,[figureBase '.pdf'], ...
        'ContentType','vector');

    %% Save model-specific data and statistics
    statsExcel = fullfile(statsDir, ...
        sprintf('Beta_SubjectiveRatings_%s_stats.xlsx',safeModel));

    statsText = fullfile(statsDir, ...
        sprintf('Beta_SubjectiveRatings_%s_stats.txt',safeModel));

    if isfile(statsExcel)
        delete(statsExcel);
    end

    writetable(TH,statsExcel,'Sheet','Healthy_Cleaned');
    writetable(TC,statsExcel,'Sheet','Chronic_Cleaned');
    writetable(removalLog,statsExcel,'Sheet','Removal_Log');

    writetable(anovaWithinOut,statsExcel,'Sheet','ANOVA_Within');
    writetable(anovaBetweenOut,statsExcel,'Sheet','ANOVA_Between');

    writetable(postBetween,statsExcel,'Sheet','PostHoc_Between');
    writetable(postControl,statsExcel,'Sheet','PostHoc_Control');
    writetable(postPredictor,statsExcel,'Sheet','PostHoc_Predictors');

    analysisInfo = table( ...
        ["Computational model"; ...
         "Analysis"; ...
         "Between-participant factor"; ...
         "Within-participant factor 1"; ...
         "Within-participant factor 2"; ...
         "3-SD removal"; ...
         "SD threshold"; ...
         "Healthy N"; ...
         "Chronic-stress N"; ...
         "Group balancing/down-sampling"], ...
        [string(modelName); ...
         "2 x 2 x 3 mixed repeated-measures ANOVA"; ...
         "Group: Healthy vs Chronic stress"; ...
         "Controllability: Controllable vs Uncontrollable"; ...
         "Predictor: Previous rating vs Accuracy vs Model regressor"; ...
         string(apply3SD); ...
         string(sdThreshold); ...
         string(nH); ...
         string(nC); ...
         "Not used"], ...
        'VariableNames',{'Item','Value'});

    writetable(analysisInfo,statsExcel,'Sheet','Analysis_Info');

    %% Text summary
    fid = fopen(statsText,'w');
    assert(fid ~= -1,'Unable to create stats text file.');

    fprintf(fid,'BETA-COEFFICIENT ANALYSIS: CHRONIC STRESS STUDY\n');
    fprintf(fid,'================================================\n\n');

    fprintf(fid,'Computational model: %s\n',modelName);
    fprintf(fid,'3-SD participant-level cleaning: %d (threshold = %g SD)\n', ...
        apply3SD,sdThreshold);
    fprintf(fid,'Healthy N = %d\n',nH);
    fprintf(fid,'Chronic-stress N = %d\n',nC);
    fprintf(fid,'No random group balancing/down-sampling was applied.\n\n');

    fprintf(fid,'WITHIN-SUBJECT / INTERACTION ANOVA TABLE\n');
    fprintf(fid,'%s\n',evalc('disp(anovaWithinOut)'));

    fprintf(fid,'\nBETWEEN-SUBJECT ANOVA TABLE\n');
    fprintf(fid,'%s\n',evalc('disp(anovaBetweenOut)'));

    fprintf(fid,'\nPOST-HOC A: GROUP DIFFERENCES WITHIN EACH CELL\n');
    fprintf(fid,'%s\n',evalc('disp(postBetween)'));

    fprintf(fid,'\nPOST-HOC B: CONTROLLABLE VS UNCONTROLLABLE WITHIN EACH GROUP\n');
    fprintf(fid,'%s\n',evalc('disp(postControl)'));

    fprintf(fid,'\nPOST-HOC C: PREDICTOR PAIRS WITHIN GROUP x CONTROLLABILITY\n');
    fprintf(fid,'%s\n',evalc('disp(postPredictor)'));

    fclose(fid);

    fprintf('Saved figure and statistics for %s.\n',modelName);

    close(fig);
end

fprintf('\nAll beta-coefficient analyses completed.\n');
fprintf('Figures: %s\n',outDir);
fprintf('Statistics: %s\n',statsDir);


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

    % Convert beta columns to double if imported as another numeric type.
    for i = 1:numel(requiredColumns)
        vn = requiredColumns{i};
        T.(vn) = double(T.(vn));
    end
end


function [baseIDs,M] = pair_sessions(T1,T2,groupName)

    required = {'Beta_SR_prev','Beta_Accuracy','Beta_U'};

    if ismember('Subject',T1.Properties.VariableNames) && ...
       ismember('Subject',T2.Properties.VariableNames)

        id1 = normalize_subject_id(string(T1.Subject));
        id2 = normalize_subject_id(string(T2.Subject));

        [baseIDs,i1,i2] = intersect(id1,id2,'stable');

        if isempty(baseIDs)
            error('No S1/S2 participant matches found for %s.',groupName);
        end

    else
        warning(['Subject column missing for %s. Pairing S1 and S2 by row ' ...
                 'order. Verify that row order is identical across sessions.'], ...
                 groupName);

        n = min(height(T1),height(T2));

        i1 = (1:n)';
        i2 = (1:n)';
        baseIDs = groupName + "_" + compose("%02d",(1:n)');
    end

    M = [ ...
        T1.(required{1})(i1), ...
        T1.(required{2})(i1), ...
        T1.(required{3})(i1), ...
        T2.(required{1})(i2), ...
        T2.(required{2})(i2), ...
        T2.(required{3})(i2)];
end


function id = normalize_subject_id(id)

    id = strtrim(id);

    % Remove common session suffixes without otherwise changing IDs.
    id = regexprep(id,'(?i)_S[12]$','');
    id = regexprep(id,'(?i)-S[12]$','');
    id = regexprep(id,'(?i)\s*S[12]$','');
end


function [Mclean,IDsClean,logTable] = remove_rowwise_3sd( ...
    M,IDs,threshold,groupName)

    if size(M,1) < 5
        Mclean = M;
        IDsClean = IDs;
        logTable = empty_removal_table();
        return
    end

    mu = mean(M,1,'omitnan');
    sd = std(M,0,1,'omitnan');
    sd(sd < eps) = eps;

    Z = abs((M-mu)./sd);
    removeRows = any(Z > threshold,2);

    removedIdx = find(removeRows);

    Group = repmat(string(groupName),numel(removedIdx),1);
    SubjectID = string(IDs(removedIdx));
    MaxAbsZ = max(Z(removedIdx,:),[],2);

    if isempty(removedIdx)
        logTable = empty_removal_table();
    else
        logTable = table(Group,SubjectID,MaxAbsZ);
    end

    Mclean = M(~removeRows,:);
    IDsClean = IDs(~removeRows);
end


function T = empty_removal_table()

    T = table( ...
        strings(0,1), ...
        strings(0,1), ...
        zeros(0,1), ...
        'VariableNames',{'Group','SubjectID','MaxAbsZ'});
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
