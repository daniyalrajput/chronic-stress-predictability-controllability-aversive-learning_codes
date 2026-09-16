%% RT beta-coefficient analysis: Chronic stress study
% Publication/repository version
%
% Purpose
%   Compare participant-level reaction-time GLM coefficients between
%   Healthy controls and participants with Chronic stress.
%
% For each computational model:
%   1. Surprise
%   2. Belief uncertainty
%   3. Volatility
%
% coefficients are analysed for:
%   - Prediction accuracy (Beta_Cor)
%   - Computational model regressor (Beta_Unc)
%
% Study design
%   Between-participant factor:
%       Group = Healthy control, Chronic stress
%
%   Within-participant factors:
%       Controllability = Controllable (S1), Uncontrollable (S2)
%       Predictor = Accuracy beta, Model beta
%
% Primary analysis
%   2 (Group) x 2 (Controllability) x 2 (Predictor)
%   mixed repeated-measures ANOVA, run separately for each computational model.
%
% Follow-up analyses
%   A. Healthy vs Chronic stress within each of the four cells
%   B. Controllable vs Uncontrollable within each predictor and group
%   C. Accuracy beta vs Model beta within each group and controllability condition
%
% Cleaning
%   - S1 and S2 are paired within participant.
%   - Healthy controls are paired by Subject ID when available; otherwise
%     row order is used with a warning.
%   - Chronic-stress participants are paired by Subject ID after removing
%     session suffixes such as "_S1_cleaned" and "_S2_cleaned".
%   - Optional >3 SD exclusion is also applied at the participant-row level:
%     if any of the four beta values exceeds the threshold within that group
%     and model, the participant is excluded from that model analysis.
%
%
% Data mapping
%   Beta_Cor = prediction-accuracy coefficient
%   Beta_Unc = computational-model coefficient
%
% Required directory structure
%
%   data/RT_Betas/
%       Healthy/
%           S1/
%           S2/
%       Chronic/
%           S1/
%           S2/
%
% -------------------------------------------------------------------------
% Daniyal Rajput
% Chronic stress / probabilistic aversive-learning study
% -------------------------------------------------------------------------

clear; clc; close all;
rng(1, 'twister');  % reproducible jitter only

%% Paths
scriptDir = fileparts(mfilename('fullpath'));
if isempty(scriptDir)
    scriptDir = pwd;
end

dataDir = fullfile(scriptDir, 'data', 'RT_Betas');

healthyS1Dir = fullfile(dataDir, 'Healthy', 'S1');
healthyS2Dir = fullfile(dataDir, 'Healthy', 'S2');

chronicS1Dir = fullfile(dataDir, 'Chronic', 'S1');
chronicS2Dir = fullfile(dataDir, 'Chronic', 'S2');

outDir   = fullfile(scriptDir, 'results', 'RT_Betas');
statsDir = fullfile(outDir, 'stats');

if ~exist(outDir, 'dir')
    mkdir(outDir);
end
if ~exist(statsDir, 'dir')
    mkdir(statsDir);
end

%% Model files
modelNames = {'Surprise','Belief Uncertainty','Volatility'};

healthyS1Files = {
    fullfile(healthyS1Dir,'healthy_betas_Surprise_s1.xlsx'), ...
    fullfile(healthyS1Dir,'healthy_betas_Estimated_s1.xlsx'), ...
    fullfile(healthyS1Dir,'healthy_betas_Volatility_s1.xlsx')
    };

healthyS2Files = {
    fullfile(healthyS2Dir,'healthy_betas_Surprise_s2.xlsx'), ...
    fullfile(healthyS2Dir,'healthy_betas_Estimated_s2.xlsx'), ...
    fullfile(healthyS2Dir,'healthy_betas_Volatility_s2.xlsx')
    };

chronicS1Files = {
    fullfile(chronicS1Dir,'subject_betas_Surprise_CS_S1.xlsx'), ...
    fullfile(chronicS1Dir,'subject_betas_Estimated_CS_S1.xlsx'), ...
    fullfile(chronicS1Dir,'subject_betas_Volatility_CS_S1.xlsx')
    };

chronicS2Files = {
    fullfile(chronicS2Dir,'subject_betas_Surprise_CS_S2.xlsx'), ...
    fullfile(chronicS2Dir,'subject_betas_Estimated_CS_S2.xlsx'), ...
    fullfile(chronicS2Dir,'subject_betas_Volatility_CS_S2.xlsx')
    };

allFiles = [healthyS1Files, healthyS2Files, chronicS1Files, chronicS2Files];

for i = 1:numel(allFiles)
    assert(isfile(allFiles{i}), 'Missing input file: %s', allFiles{i});
end

%% Required beta columns
requiredColumns = {'Beta_Cor','Beta_Unc'};

%% Cleaning settings
apply3SD = true;
sdThreshold = 3;

% Nearest-value matching tolerance for manual exclusions.
% The values below were specified in the original script and are preserved.
manualTolerance = 0.02;

%% Recorded manual exclusions
% Internal column order:
%   1 = S1 Accuracy
%   2 = S1 Model
%   3 = S2 Accuracy
%   4 = S2 Model
%
% A matched value leads to exclusion of the entire participant row within
% that model, preserving the repeated-measures structure.

manualRemove = repmat(struct(),3,1);

% ---------------- Model 1: Surprise
manualRemove(1).H_S1_Acc   = [];
manualRemove(1).H_S1_Model = [];
manualRemove(1).H_S2_Acc   = [];
manualRemove(1).H_S2_Model = [];

manualRemove(1).C_S1_Acc   = [];
manualRemove(1).C_S1_Model = [];
manualRemove(1).C_S2_Acc   = [];
manualRemove(1).C_S2_Model = [];

% ---------------- Model 2: Belief uncertainty
manualRemove(2).H_S1_Acc   = [];
manualRemove(2).H_S1_Model = [];
manualRemove(2).H_S2_Acc   = [];
manualRemove(2).H_S2_Model = [];

manualRemove(2).C_S1_Acc   = [];
manualRemove(2).C_S1_Model = [];
manualRemove(2).C_S2_Acc   = [];
manualRemove(2).C_S2_Model = [];

% ---------------- Model 3: Volatility
manualRemove(3).H_S1_Acc   = [];
manualRemove(3).H_S1_Model = [];
manualRemove(3).H_S2_Acc   = [];
manualRemove(3).H_S2_Model = [];

manualRemove(3).C_S1_Acc   = [];
manualRemove(3).C_S1_Model = [];
manualRemove(3).C_S2_Acc   = [];
manualRemove(3).C_S2_Model = [];

%% Figure settings
FIG_POS = [120 120 1500 820];
PNG_DPI = 600;

gapHealthyChronic = 0.35;
gapS1S2           = 0.80;
gapPredictor      = 1.00;

boxWidth = 0.26;
xJitter  = 0.06;

useFixedYLim = true;
fixedYLim = [-0.78 0.50];
fixedYTicks = linspace(fixedYLim(1),fixedYLim(2),5);
fixedYTickFormat = '%.2f';

% Box fill encodes controllability.
colorBoxS1 = [0.75 0.88 1.00];
colorBoxS2 = [1.00 0.85 0.72];

% Dot color encodes group.
colorHealthy = [0.10 0.25 0.70];
colorChronic = [0.75 0.15 0.15];

fsXTick  = 18;
fsYTick  = 18;
fsLabel  = 20;
fsTitle  = 22;
fsLegend = 18;

lineAxes = 1.6;
lineBox  = 1.2;
lineMean = 1.2;

dotSize  = 55;
meanSize = 45;

boxAlpha = 0.35;
dotAlpha = 0.90;

%% ========================================================================
% Main analysis loop
% ========================================================================

for m = 1:3

    modelName = modelNames{m};
    safeModel = regexprep(modelName,'\s+','_');

    fprintf('\n============================================================\n');
    fprintf('RT beta model %d/3: %s\n',m,modelName);
    fprintf('============================================================\n');

    %% Read data
    H1 = read_beta_table(healthyS1Files{m},requiredColumns);
    H2 = read_beta_table(healthyS2Files{m},requiredColumns);

    C1 = read_beta_table(chronicS1Files{m},requiredColumns);
    C2 = read_beta_table(chronicS2Files{m},requiredColumns);

    %% Pair sessions
    [healthyIDs,MH0] = pair_sessions(H1,H2,"Healthy");
    [chronicIDs,MC0] = pair_sessions(C1,C2,"Chronic");

    % Complete cases across all four repeated-measures cells.
    keepHComplete = all(isfinite(MH0),2);
    keepCComplete = all(isfinite(MC0),2);

    MH0 = MH0(keepHComplete,:);
    healthyIDs = healthyIDs(keepHComplete);

    MC0 = MC0(keepCComplete,:);
    chronicIDs = chronicIDs(keepCComplete);

    %% Manual participant-level exclusions
    [MH1,healthyIDs1,manualLogH] = apply_manual_row_exclusions( ...
        MH0,healthyIDs,manualRemove(m),"Healthy",manualTolerance);

    [MC1,chronicIDs1,manualLogC] = apply_manual_row_exclusions( ...
        MC0,chronicIDs,manualRemove(m),"Chronic",manualTolerance);

    manualLog = [manualLogH;manualLogC];

    %% Optional >3 SD participant-level exclusion
    if apply3SD
        [MH2,healthyIDs2,sdLogH] = remove_rowwise_3sd( ...
            MH1,healthyIDs1,sdThreshold,"Healthy");

        [MC2,chronicIDs2,sdLogC] = remove_rowwise_3sd( ...
            MC1,chronicIDs1,sdThreshold,"Chronic");
    else
        MH2 = MH1;
        MC2 = MC1;
        healthyIDs2 = healthyIDs1;
        chronicIDs2 = chronicIDs1;
        sdLogH = empty_sd_log();
        sdLogC = empty_sd_log();
    end

    sdLog = [sdLogH;sdLogC];

    nH = size(MH2,1);
    nC = size(MC2,1);

    if nH < 2 || nC < 2
        error('Too few participants after cleaning for %s. Healthy=%d, Chronic=%d', ...
            modelName,nH,nC);
    end

    fprintf('Participants retained: Healthy=%d, Chronic=%d\n',nH,nC);

    %% Build repeated-measures table
    TH = table( ...
        categorical(healthyIDs2), ...
        categorical(repmat("Healthy",nH,1),{'Healthy','Chronic'}), ...
        MH2(:,1),MH2(:,2),MH2(:,3),MH2(:,4), ...
        'VariableNames', { ...
            'SubjectID','Group', ...
            'S1_Accuracy','S1_Model','S2_Accuracy','S2_Model'});

    TC = table( ...
        categorical(chronicIDs2), ...
        categorical(repmat("Chronic",nC,1),{'Healthy','Chronic'}), ...
        MC2(:,1),MC2(:,2),MC2(:,3),MC2(:,4), ...
        'VariableNames', { ...
            'SubjectID','Group', ...
            'S1_Accuracy','S1_Model','S2_Accuracy','S2_Model'});

    Tall = [TH;TC];

    withinDesign = table( ...
        categorical({'Controllable';'Controllable'; ...
                     'Uncontrollable';'Uncontrollable'}, ...
                    {'Controllable','Uncontrollable'}), ...
        categorical({'Accuracy';'Model';'Accuracy';'Model'}, ...
                    {'Accuracy','Model'}), ...
        'VariableNames',{'Controllability','Predictor'});

    %% 2 x 2 x 2 mixed repeated-measures ANOVA
    rm = fitrm(Tall, ...
        'S1_Accuracy-S2_Model ~ Group', ...
        'WithinDesign',withinDesign);

    anovaWithin = ranova(rm, ...
        'WithinModel','Controllability*Predictor');

    anovaBetween = anova(rm);

    anovaWithinOut  = add_row_names(anovaWithin,'Effect');
    anovaBetweenOut = add_row_names(anovaBetween,'Effect');

    %% Post-hoc A: Healthy vs Chronic stress within each cell
    cellNames = [ ...
        "Controllable_Accuracy";
        "Controllable_Model";
        "Uncontrollable_Accuracy";
        "Uncontrollable_Model"];

    meanHealthy = nan(4,1);
    meanChronic = nan(4,1);
    meanDifference = nan(4,1);
    tA = nan(4,1);
    dfA = nan(4,1);
    pA = nan(4,1);
    ciLowerA = nan(4,1);
    ciUpperA = nan(4,1);

    for i = 1:4
        [~,p,ci,st] = ttest2(MH2(:,i),MC2(:,i),'Vartype','unequal');

        meanHealthy(i) = mean(MH2(:,i));
        meanChronic(i) = mean(MC2(:,i));
        meanDifference(i) = mean(MH2(:,i))-mean(MC2(:,i));

        tA(i) = st.tstat;
        dfA(i) = st.df;
        pA(i) = p;
        ciLowerA(i) = ci(1);
        ciUpperA(i) = ci(2);
    end

    pBonfA = min(pA*4,1);

    postBetween = table( ...
        cellNames,meanHealthy,meanChronic,meanDifference, ...
        tA,dfA,pA,pBonfA,ciLowerA,ciUpperA, ...
        'VariableNames', { ...
            'Cell','Mean_Healthy','Mean_Chronic','MeanDifference', ...
            't','df','p','p_Bonferroni','CI_Lower','CI_Upper'});

    %% Post-hoc B: Controllable vs Uncontrollable within each group/predictor
    GroupB = [ ...
        "Healthy";"Healthy"; ...
        "Chronic";"Chronic"];

    PredictorB = [ ...
        "Accuracy";"Model"; ...
        "Accuracy";"Model"];

    meanControllable = nan(4,1);
    meanUncontrollable = nan(4,1);
    meanDifferenceB = nan(4,1);
    tB = nan(4,1);
    dfB = nan(4,1);
    pB = nan(4,1);
    pBonfB = nan(4,1);
    ciLowerB = nan(4,1);
    ciUpperB = nan(4,1);

    % Healthy
    for k = 1:2
        [~,p,ci,st] = ttest(MH2(:,k),MH2(:,k+2));

        meanControllable(k) = mean(MH2(:,k));
        meanUncontrollable(k) = mean(MH2(:,k+2));
        meanDifferenceB(k) = mean(MH2(:,k)-MH2(:,k+2));

        tB(k) = st.tstat;
        dfB(k) = st.df;
        pB(k) = p;
        ciLowerB(k) = ci(1);
        ciUpperB(k) = ci(2);
    end
    pBonfB(1:2) = min(pB(1:2)*2,1);

    % Chronic stress
    for k = 1:2
        idx = 2+k;

        [~,p,ci,st] = ttest(MC2(:,k),MC2(:,k+2));

        meanControllable(idx) = mean(MC2(:,k));
        meanUncontrollable(idx) = mean(MC2(:,k+2));
        meanDifferenceB(idx) = mean(MC2(:,k)-MC2(:,k+2));

        tB(idx) = st.tstat;
        dfB(idx) = st.df;
        pB(idx) = p;
        ciLowerB(idx) = ci(1);
        ciUpperB(idx) = ci(2);
    end
    pBonfB(3:4) = min(pB(3:4)*2,1);

    postControl = table( ...
        GroupB,PredictorB,meanControllable,meanUncontrollable, ...
        meanDifferenceB,tB,dfB,pB,pBonfB,ciLowerB,ciUpperB, ...
        'VariableNames', { ...
            'Group','Predictor','Mean_Controllable','Mean_Uncontrollable', ...
            'MeanDifference','t','df','p','p_Bonferroni', ...
            'CI_Lower','CI_Upper'});

    %% Post-hoc C: Accuracy beta vs Model beta within group/condition
    GroupC = [ ...
        "Healthy";"Healthy"; ...
        "Chronic";"Chronic"];

    ControllabilityC = [ ...
        "Controllable";"Uncontrollable"; ...
        "Controllable";"Uncontrollable"];

    meanAccuracy = nan(4,1);
    meanModel = nan(4,1);
    meanDifferenceC = nan(4,1);
    tC = nan(4,1);
    dfC = nan(4,1);
    pC = nan(4,1);
    pBonfC = nan(4,1);
    ciLowerC = nan(4,1);
    ciUpperC = nan(4,1);

    % Healthy, controllable
    [~,p,ci,st] = ttest(MH2(:,1),MH2(:,2));
    meanAccuracy(1) = mean(MH2(:,1));
    meanModel(1) = mean(MH2(:,2));
    meanDifferenceC(1) = mean(MH2(:,1)-MH2(:,2));
    tC(1)=st.tstat; dfC(1)=st.df; pC(1)=p;
    ciLowerC(1)=ci(1); ciUpperC(1)=ci(2);

    % Healthy, uncontrollable
    [~,p,ci,st] = ttest(MH2(:,3),MH2(:,4));
    meanAccuracy(2) = mean(MH2(:,3));
    meanModel(2) = mean(MH2(:,4));
    meanDifferenceC(2) = mean(MH2(:,3)-MH2(:,4));
    tC(2)=st.tstat; dfC(2)=st.df; pC(2)=p;
    ciLowerC(2)=ci(1); ciUpperC(2)=ci(2);

    % Chronic, controllable
    [~,p,ci,st] = ttest(MC2(:,1),MC2(:,2));
    meanAccuracy(3) = mean(MC2(:,1));
    meanModel(3) = mean(MC2(:,2));
    meanDifferenceC(3) = mean(MC2(:,1)-MC2(:,2));
    tC(3)=st.tstat; dfC(3)=st.df; pC(3)=p;
    ciLowerC(3)=ci(1); ciUpperC(3)=ci(2);

    % Chronic, uncontrollable
    [~,p,ci,st] = ttest(MC2(:,3),MC2(:,4));
    meanAccuracy(4) = mean(MC2(:,3));
    meanModel(4) = mean(MC2(:,4));
    meanDifferenceC(4) = mean(MC2(:,3)-MC2(:,4));
    tC(4)=st.tstat; dfC(4)=st.df; pC(4)=p;
    ciLowerC(4)=ci(1); ciUpperC(4)=ci(2);

    % Two Accuracy-vs-Model comparisons per group.
    pBonfC(1:2) = min(pC(1:2)*2,1);
    pBonfC(3:4) = min(pC(3:4)*2,1);

    postAccuracyVsModel = table( ...
        GroupC,ControllabilityC,meanAccuracy,meanModel,meanDifferenceC, ...
        tC,dfC,pC,pBonfC,ciLowerC,ciUpperC, ...
        'VariableNames', { ...
            'Group','Controllability','Mean_Accuracy','Mean_Model', ...
            'MeanDifference','t','df','p','p_Bonferroni', ...
            'CI_Lower','CI_Upper'});

    %% Figure y-axis
    if useFixedYLim
        yLimits = fixedYLim;
        yTicks  = fixedYTicks;
        yTickFormat = fixedYTickFormat;
    else
        [yLimits,yTicks] = symmetric_axis_limits([MH2(:);MC2(:)],5);
        yTickFormat = '%.2f';
    end

    %% Plot positions
    xH = zeros(1,4);
    xC = zeros(1,4);
    sessionCenters = zeros(1,4);
    predictorCenters = zeros(1,2);

    xStart = 1;

    % Accuracy section
    xS1Accuracy = xStart;
    xS2Accuracy = xStart + gapS1S2;

    sessionCenters(1) = xS1Accuracy;
    sessionCenters(3) = xS2Accuracy;

    xH(1) = xS1Accuracy-gapHealthyChronic/2;
    xC(1) = xS1Accuracy+gapHealthyChronic/2;

    xH(3) = xS2Accuracy-gapHealthyChronic/2;
    xC(3) = xS2Accuracy+gapHealthyChronic/2;

    predictorCenters(1) = mean([xS1Accuracy,xS2Accuracy]);

    % Model-regressor section
    xS1Model = xStart + gapS1S2 + gapPredictor;
    xS2Model = xS1Model + gapS1S2;

    sessionCenters(2) = xS1Model;
    sessionCenters(4) = xS2Model;

    xH(2) = xS1Model-gapHealthyChronic/2;
    xC(2) = xS1Model+gapHealthyChronic/2;

    xH(4) = xS2Model-gapHealthyChronic/2;
    xC(4) = xS2Model+gapHealthyChronic/2;

    predictorCenters(2) = mean([xS1Model,xS2Model]);

    plotOrder = [1 3 2 4];
    xTickPositions = sessionCenters(plotOrder);
    xTickLabels = {'Controllable','Uncontrollable', ...
                   'Controllable','Uncontrollable'};

    %% Plot
    fig = figure( ...
        'Color','w', ...
        'Units','pixels', ...
        'Position',FIG_POS);

    ax = axes(fig);
    hold(ax,'on');

    for k = 1:4

        colIdx = plotOrder(k);

        yH = MH2(:,colIdx);
        yC = MC2(:,colIdx);

        if colIdx <= 2
            boxColor = colorBoxS1;
        else
            boxColor = colorBoxS2;
        end

        % Healthy controls
        boxchart(ax, ...
            xH(colIdx)*ones(size(yH)),yH, ...
            'BoxWidth',boxWidth, ...
            'BoxFaceColor',boxColor, ...
            'BoxFaceAlpha',boxAlpha, ...
            'WhiskerLineColor','k', ...
            'LineWidth',lineBox, ...
            'MarkerStyle','none');

        scatter(ax, ...
            xH(colIdx)+(rand(size(yH))-0.5)*2*xJitter, ...
            yH,dotSize,colorHealthy,'filled', ...
            'MarkerEdgeColor','k', ...
            'MarkerFaceAlpha',dotAlpha);

        mH = mean(yH);
        seH = std(yH)/sqrt(numel(yH));

        errorbar(ax,xH(colIdx),mH,seH,'k', ...
            'LineWidth',lineMean,'CapSize',0);

        scatter(ax,xH(colIdx),mH,meanSize,'k','filled');

        % Chronic stress
        boxchart(ax, ...
            xC(colIdx)*ones(size(yC)),yC, ...
            'BoxWidth',boxWidth, ...
            'BoxFaceColor',boxColor, ...
            'BoxFaceAlpha',boxAlpha, ...
            'WhiskerLineColor','k', ...
            'LineWidth',lineBox, ...
            'MarkerStyle','none');

        scatter(ax, ...
            xC(colIdx)+(rand(size(yC))-0.5)*2*xJitter, ...
            yC,dotSize,colorChronic,'filled', ...
            'MarkerEdgeColor','k', ...
            'MarkerFaceAlpha',dotAlpha);

        mC = mean(yC);
        seC = std(yC)/sqrt(numel(yC));

        errorbar(ax,xC(colIdx),mC,seC,'k', ...
            'LineWidth',lineMean,'CapSize',0);

        scatter(ax,xC(colIdx),mC,meanSize,'k','filled');
    end

    titleY = yLimits(2)+0.02*range(yLimits);

    text(ax,predictorCenters(1),titleY,'Accuracy', ...
        'HorizontalAlignment','center', ...
        'VerticalAlignment','bottom', ...
        'FontSize',fsTitle, ...
        'FontWeight','bold');

    text(ax,predictorCenters(2),titleY,modelName, ...
        'HorizontalAlignment','center', ...
        'VerticalAlignment','bottom', ...
        'FontSize',fsTitle, ...
        'FontWeight','bold');

    ylabel(ax,'\beta', ...
        'FontSize',fsLabel, ...
        'FontWeight','bold');

    ax.XTick = xTickPositions;
    ax.XTickLabel = xTickLabels;
    ax.XTickLabelRotation = 0;

    ax.FontSize = fsXTick;
    ax.LineWidth = lineAxes;
    ax.Box = 'off';
    ax.TickDir = 'out';

    ylim(ax,yLimits);
    yticks(ax,yTicks);
    ytickformat(ax,yTickFormat);

    xlim(ax,[min(xH)-0.55,max(xC)+0.85]);

    ax.YAxis.FontSize = fsYTick;
    ax.XAxis.FontSize = fsXTick;
    ax.XAxis.TickLength = [0 0];
    ax.YAxis.TickLength = [0.012 0.012];

    % Legend
    hBoxS1 = patch(ax,nan,nan,colorBoxS1, ...
        'EdgeColor','k','FaceAlpha',boxAlpha);

    hBoxS2 = patch(ax,nan,nan,colorBoxS2, ...
        'EdgeColor','k','FaceAlpha',boxAlpha);

    hHealthy = plot(ax,nan,nan,'o', ...
        'MarkerSize',9, ...
        'MarkerFaceColor',colorHealthy, ...
        'MarkerEdgeColor','k', ...
        'LineStyle','none');

    hChronic = plot(ax,nan,nan,'o', ...
        'MarkerSize',9, ...
        'MarkerFaceColor',colorChronic, ...
        'MarkerEdgeColor','k', ...
        'LineStyle','none');

    lgd = legend(ax, ...
        [hBoxS1,hBoxS2,hHealthy,hChronic], ...
        {'Controllable','Uncontrollable','Healthy controls','Chronic stress'}, ...
        'Location','northeast', ...
        'Box','off');

    lgd.FontSize = fsLegend;

    %% Export figure
    figureBase = fullfile(outDir, ...
        sprintf('RT_Betas_Healthy_vs_Chronic_%s',safeModel));

    exportgraphics(fig,[figureBase '.png'], ...
        'Resolution',PNG_DPI);

    exportgraphics(fig,[figureBase '.tiff'], ...
        'Resolution',PNG_DPI);

    exportgraphics(fig,[figureBase '.pdf'], ...
        'ContentType','vector');

    %% Save model-specific statistics
    statsExcel = fullfile(statsDir, ...
        sprintf('RT_Betas_%s_stats.xlsx',safeModel));

    statsText = fullfile(statsDir, ...
        sprintf('RT_Betas_%s_stats.txt',safeModel));

    statsMat = fullfile(statsDir, ...
        sprintf('RT_Betas_%s_stats.mat',safeModel));

    if isfile(statsExcel)
        delete(statsExcel);
    end

    writetable(TH,statsExcel,'Sheet','Healthy_Cleaned');
    writetable(TC,statsExcel,'Sheet','Chronic_Cleaned');

    writetable(manualLog,statsExcel,'Sheet','Removed_Manual');
    writetable(sdLog,statsExcel,'Sheet','Removed_3SD');

    writetable(anovaWithinOut,statsExcel,'Sheet','ANOVA_Within');
    writetable(anovaBetweenOut,statsExcel,'Sheet','ANOVA_Between');

    writetable(postBetween,statsExcel,'Sheet','PostHoc_Between');
    writetable(postControl,statsExcel,'Sheet','PostHoc_Control');
    writetable(postAccuracyVsModel,statsExcel,'Sheet','PostHoc_Accuracy_Model');

    analysisInfo = table( ...
        ["Computational model"; ...
         "Analysis"; ...
         "Between-participant factor"; ...
         "Within-participant factor 1"; ...
         "Within-participant factor 2"; ...
         "Beta_Cor"; ...
         "Beta_Unc"; ...
         "Manual exclusions"; ...
         "3-SD removal"; ...
         "SD threshold"; ...
         "Healthy N"; ...
         "Chronic-stress N"; ...
         "Group balancing/down-sampling"], ...
        [string(modelName); ...
         "2 x 2 x 2 mixed repeated-measures ANOVA"; ...
         "Group: Healthy vs Chronic stress"; ...
         "Controllability: Controllable vs Uncontrollable"; ...
         "Predictor: Accuracy beta vs Model beta"; ...
         "Prediction-accuracy coefficient"; ...
         "Computational-model coefficient"; ...
         "Recorded participant-level exclusions"; ...
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

    fprintf(fid,'RT BETA-COEFFICIENT ANALYSIS: CHRONIC STRESS STUDY\n');
    fprintf(fid,'===================================================\n\n');

    fprintf(fid,'Computational model: %s\n',modelName);
    fprintf(fid,'Beta_Cor = prediction-accuracy coefficient\n');
    fprintf(fid,'Beta_Unc = computational-model coefficient\n\n');

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

    fprintf(fid,'\nPOST-HOC B: CONTROLLABLE VS UNCONTROLLABLE WITHIN GROUP\n');
    fprintf(fid,'%s\n',evalc('disp(postControl)'));

    fprintf(fid,'\nPOST-HOC C: ACCURACY BETA VS MODEL BETA\n');
    fprintf(fid,'%s\n',evalc('disp(postAccuracyVsModel)'));

    fclose(fid);

    save(statsMat, ...
        'modelName','TH','TC','manualLog','sdLog', ...
        'rm','anovaWithin','anovaBetween', ...
        'postBetween','postControl','postAccuracyVsModel', ...
        'analysisInfo');

    fprintf('Saved figure and statistics for %s.\n',modelName);

    close(fig);
end

fprintf('\nAll RT beta-coefficient analyses completed.\n');
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

    for i = 1:numel(requiredColumns)
        vn = requiredColumns{i};
        T.(vn) = double(T.(vn));
    end
end


function [baseIDs,M] = pair_sessions(T1,T2,groupName)

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
                 'order. Verify that participant order is identical across sessions.'], ...
                 groupName);

        n = min(height(T1),height(T2));

        i1 = (1:n)';
        i2 = (1:n)';
        baseIDs = groupName + "_" + compose("%02d",(1:n)');
    end

    M = [ ...
        T1.Beta_Cor(i1), ...
        T1.Beta_Unc(i1), ...
        T2.Beta_Cor(i2), ...
        T2.Beta_Unc(i2)];
end


function id = normalize_subject_id(id)

    id = strtrim(id);

    % Remove common session suffixes.
    id = regexprep(id,'(?i)_S1_cleaned$','');
    id = regexprep(id,'(?i)_S2_cleaned$','');
    id = regexprep(id,'(?i)_S[12]$','');
    id = regexprep(id,'(?i)-S[12]$','');
    id = regexprep(id,'(?i)\s*S[12]$','');
end


function [Mclean,IDsClean,logTable] = apply_manual_row_exclusions( ...
    M,IDs,mr,groupName,tolerance)

    if groupName == "Healthy"
        fields = {'H_S1_Acc','H_S1_Model','H_S2_Acc','H_S2_Model'};
    else
        fields = {'C_S1_Acc','C_S1_Model','C_S2_Acc','C_S2_Model'};
    end

    removeRows = false(size(M,1),1);

    Group = strings(0,1);
    SubjectID = strings(0,1);
    Cell = strings(0,1);
    TargetValue = zeros(0,1);
    MatchedValue = zeros(0,1);
    AbsDifference = zeros(0,1);
    Removed = false(0,1);

    cellNames = ["S1_Accuracy","S1_Model","S2_Accuracy","S2_Model"];

    for col = 1:4

        targets = mr.(fields{col});
        targets = targets(isfinite(targets));

        for v = 1:numel(targets)

            target = targets(v);

            availableIdx = find(~removeRows & isfinite(M(:,col)));

            Group(end+1,1) = string(groupName);
            Cell(end+1,1) = cellNames(col);
            TargetValue(end+1,1) = target;

            if isempty(availableIdx)
                SubjectID(end+1,1) = "";
                MatchedValue(end+1,1) = NaN;
                AbsDifference(end+1,1) = NaN;
                Removed(end+1,1) = false;
                continue
            end

            [minDiff,localIdx] = min(abs(M(availableIdx,col)-target));
            rowIdx = availableIdx(localIdx);

            SubjectID(end+1,1) = string(IDs(rowIdx));
            MatchedValue(end+1,1) = M(rowIdx,col);
            AbsDifference(end+1,1) = minDiff;

            if minDiff <= tolerance
                removeRows(rowIdx) = true;
                Removed(end+1,1) = true;
            else
                Removed(end+1,1) = false;
            end
        end
    end

    Mclean = M(~removeRows,:);
    IDsClean = IDs(~removeRows);

    logTable = table( ...
        Group,SubjectID,Cell,TargetValue,MatchedValue, ...
        AbsDifference,Removed);
end


function [Mclean,IDsClean,logTable] = remove_rowwise_3sd( ...
    M,IDs,threshold,groupName)

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
        Group = repmat(string(groupName),numel(removedIdx),1);
        SubjectID = string(IDs(removedIdx));
        MaxAbsZ = max(Z(removedIdx,:),[],2);

        logTable = table(Group,SubjectID,MaxAbsZ);
    end

    Mclean = M(~removeRows,:);
    IDsClean = IDs(~removeRows);
end


function T = empty_sd_log()

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
