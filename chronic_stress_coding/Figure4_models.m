%% BMS winning-model plots: Chronic stress study
% Publication/repository version
%
% Compares Healthy controls and Chronic stress for subjective stress ratings
% in controllable (S1) and uncontrollable (S2) sessions.
%
% Candidate models:
%   1. Surprise
%   2. Belief uncertainty
%   3. Volatility
%
% Outputs:
%   - Winning-model summary workbook
%   - Separate model-frequency and exceedance-probability figures per session
%   - PNG (600 dpi), TIFF (600 dpi), and vector PDF
%
% Texture coding:
%   Surprise           = horizontal hatch
%   Belief uncertainty = vertical hatch
%   Volatility         = diagonal hatch
%
% Required folders beside this script:
%   data/BMS_Ratings/Healthy/
%   data/BMS_Ratings/Chronic/
%
% Daniyal Rajput
% Chronic stress / probabilistic aversive-learning study

clear; clc; close all;

%% Paths
scriptDir = fileparts(mfilename('fullpath'));
if isempty(scriptDir), scriptDir = pwd; end

dataDir    = fullfile(scriptDir,'data','BMS_Ratings');
healthyDir = fullfile(dataDir,'Healthy');
chronicDir = fullfile(dataDir,'Chronic');

outDir = fullfile(scriptDir,'results','BMS_Ratings_WinningModel');
if ~exist(outDir,'dir'), mkdir(outDir); end

summaryExcel = fullfile(outDir,'BMS_Ratings_winning_models.xlsx');

%% Input files
healthy_S1_file = "group_bms_summary_healthy_SRating_con.xlsx";
healthy_S2_file = "group_bms_summary_healthy_SRating_unc.xlsx";
chronic_S1_file = "group_bms_sum_chronic_SRating_con.xlsx";
chronic_S2_file = "group_bms_sum_chronic_SRating_unc.xlsx";

%% Model labels
modelLabels = {'Surprise','Belief uncertainty','Volatility'};

%% Figure style
pngDPI = 600;
fsXTick  = 22;
fsYTick  = 22;
fsLabel  = 22;
fsLegend = 20;

barWidth      = 0.30;
barLineWidth  = 1.6;
axisLineWidth = 1.0;
outlineColor  = [0.25 0.25 0.25];

healthyDark  = [0.22 0.38 0.72];
healthyLight = [0.72 0.86 1.00];
chronicDark  = [0.92 0.48 0.12];
chronicLight = [1.00 0.82 0.62];

hatchLineWidth = 1.6;
gapHorizontal  = 0.04;
gapVertical    = 0.04;
gapDiagonal    = 0.06;
hatchLightness = 0.20;
hatchColor = hatchLightness*[1 1 1] + (1-hatchLightness)*[0 0 0];

%% Resolve files
healthy_S1 = resolve_file(healthyDir,healthy_S1_file);
healthy_S2 = resolve_file(healthyDir,healthy_S2_file);
chronic_S1 = resolve_file(chronicDir,chronic_S1_file);
chronic_S2 = resolve_file(chronicDir,chronic_S2_file);

fprintf('\nFiles used:\n');
fprintf('Healthy, controllable:   %s\n',healthy_S1);
fprintf('Healthy, uncontrollable: %s\n',healthy_S2);
fprintf('Chronic, controllable:   %s\n',chronic_S1);
fprintf('Chronic, uncontrollable: %s\n\n',chronic_S2);

%% Read BMS summaries
H_S1 = read_bms_summary(healthy_S1,modelLabels);
H_S2 = read_bms_summary(healthy_S2,modelLabels);
C_S1 = read_bms_summary(chronic_S1,modelLabels);
C_S2 = read_bms_summary(chronic_S2,modelLabels);

%% Determine winners
[H_winFreq_S1,H_iFreq_S1] = max(H_S1.freq);
[C_winFreq_S1,C_iFreq_S1] = max(C_S1.freq);
[H_winExc_S1,H_iExc_S1]   = max(H_S1.exc);
[C_winExc_S1,C_iExc_S1]   = max(C_S1.exc);

[H_winFreq_S2,H_iFreq_S2] = max(H_S2.freq);
[C_winFreq_S2,C_iFreq_S2] = max(C_S2.freq);
[H_winExc_S2,H_iExc_S2]   = max(H_S2.exc);
[C_winExc_S2,C_iExc_S2]   = max(C_S2.exc);

H_labFreq_S1 = modelLabels{H_iFreq_S1};
C_labFreq_S1 = modelLabels{C_iFreq_S1};
H_labExc_S1  = modelLabels{H_iExc_S1};
C_labExc_S1  = modelLabels{C_iExc_S1};

H_labFreq_S2 = modelLabels{H_iFreq_S2};
C_labFreq_S2 = modelLabels{C_iFreq_S2};
H_labExc_S2  = modelLabels{H_iExc_S2};
C_labExc_S2  = modelLabels{C_iExc_S2};

%% Save winning-model summary
Session = ["Controllable";"Controllable";"Controllable";"Controllable"; ...
           "Uncontrollable";"Uncontrollable";"Uncontrollable";"Uncontrollable"];
Group = ["Healthy";"Chronic";"Healthy";"Chronic"; ...
         "Healthy";"Chronic";"Healthy";"Chronic"];
Metric = ["Model frequency";"Model frequency"; ...
          "Exceedance probability";"Exceedance probability"; ...
          "Model frequency";"Model frequency"; ...
          "Exceedance probability";"Exceedance probability"];
WinningModel = [string(H_labFreq_S1);string(C_labFreq_S1); ...
                string(H_labExc_S1);string(C_labExc_S1); ...
                string(H_labFreq_S2);string(C_labFreq_S2); ...
                string(H_labExc_S2);string(C_labExc_S2)];
WinningValue = [H_winFreq_S1;C_winFreq_S1;H_winExc_S1;C_winExc_S1; ...
                H_winFreq_S2;C_winFreq_S2;H_winExc_S2;C_winExc_S2];

winningSummary = table(Session,Group,Metric,WinningModel,WinningValue);
if isfile(summaryExcel), delete(summaryExcel); end
writetable(winningSummary,summaryExcel,'Sheet','Winning_Models');

write_model_values(summaryExcel,'Healthy_Controllable',H_S1,modelLabels);
write_model_values(summaryExcel,'Chronic_Controllable',C_S1,modelLabels);
write_model_values(summaryExcel,'Healthy_Uncontrollable',H_S2,modelLabels);
write_model_values(summaryExcel,'Chronic_Uncontrollable',C_S2,modelLabels);

%% Plot settings shared across figures
xPos = [0.75 1.50];

%% Controllable: model frequency
plot_winning_models(xPos,H_winFreq_S1,C_winFreq_S1, ...
    healthyDark,chronicDark,H_labFreq_S1,C_labFreq_S1, ...
    'Model Frequency','Controllable', ...
    fullfile(outDir,'BMS_Ratings_Controllable_ModelFrequency'), ...
    modelLabels,outlineColor,hatchColor,barWidth,barLineWidth,axisLineWidth, ...
    fsXTick,fsYTick,fsLabel,fsLegend,hatchLineWidth, ...
    gapHorizontal,gapVertical,gapDiagonal,pngDPI);

%% Controllable: exceedance probability
plot_winning_models(xPos,H_winExc_S1,C_winExc_S1, ...
    healthyDark,chronicDark,H_labExc_S1,C_labExc_S1, ...
    'Exceedance Probability','Controllable', ...
    fullfile(outDir,'BMS_Ratings_Controllable_ExceedanceProbability'), ...
    modelLabels,outlineColor,hatchColor,barWidth,barLineWidth,axisLineWidth, ...
    fsXTick,fsYTick,fsLabel,fsLegend,hatchLineWidth, ...
    gapHorizontal,gapVertical,gapDiagonal,pngDPI);

%% Uncontrollable: model frequency
plot_winning_models(xPos,H_winFreq_S2,C_winFreq_S2, ...
    healthyLight,chronicLight,H_labFreq_S2,C_labFreq_S2, ...
    'Model Frequency','Uncontrollable', ...
    fullfile(outDir,'BMS_Ratings_Uncontrollable_ModelFrequency'), ...
    modelLabels,outlineColor,hatchColor,barWidth,barLineWidth,axisLineWidth, ...
    fsXTick,fsYTick,fsLabel,fsLegend,hatchLineWidth, ...
    gapHorizontal,gapVertical,gapDiagonal,pngDPI);

%% Uncontrollable: exceedance probability
plot_winning_models(xPos,H_winExc_S2,C_winExc_S2, ...
    healthyLight,chronicLight,H_labExc_S2,C_labExc_S2, ...
    'Exceedance Probability','Uncontrollable', ...
    fullfile(outDir,'BMS_Ratings_Uncontrollable_ExceedanceProbability'), ...
    modelLabels,outlineColor,hatchColor,barWidth,barLineWidth,axisLineWidth, ...
    fsXTick,fsYTick,fsLabel,fsLegend,hatchLineWidth, ...
    gapHorizontal,gapVertical,gapDiagonal,pngDPI);

fprintf('\nBMS winning-model plots completed.\nOutputs saved to:\n%s\n\n',outDir);

%% ========================================================================
% Local functions
% ========================================================================

function filePath = resolve_file(folderPath,requestedName)
    assert(isfolder(folderPath),'Input folder not found: %s',folderPath);
    filePath = fullfile(folderPath,requestedName);
    if ~isfile(filePath)
        files = dir(fullfile(folderPath,'*.xlsx'));
        if isempty(files)
            error('No .xlsx files found in: %s',folderPath);
        end
        names = string({files.name});
        error('Requested file not found:\n%s\n\nAvailable files:\n%s', ...
            filePath,strjoin(names,newline));
    end
end

function S = read_bms_summary(filePath,modelLabels)
    T = readtable(filePath,'VariableNamingRule','preserve');
    if height(T) < 3
        error('BMS summary must contain at least three model rows: %s',filePath);
    end

    originalNames = string(T.Properties.VariableNames);
    names = normalize_names(originalNames);

    freqIdx = find_name_match(names,["frequency","modelfrequency","freq","expectedfrequency"]);
    excIdx  = find_name_match(names,["exceedanceprobability","exceedanceprob","exceedance","exc","xp"]);

    if isempty(freqIdx)
        error('Could not identify frequency column in %s. Columns: %s', ...
            filePath,strjoin(originalNames,', '));
    end
    if isempty(excIdx)
        error('Could not identify exceedance-probability column in %s. Columns: %s', ...
            filePath,strjoin(originalNames,', '));
    end

    freq = double(T{:,freqIdx});
    exc  = double(T{:,excIdx});

    modelIdx = find_name_match(names,["model","modelname","name","models"]);

    if isempty(modelIdx)
        freq = freq(1:3);
        exc  = exc(1:3);
    else
        modelText = string(T{:,modelIdx});
        [freq,exc] = reorder_by_model_name(modelText,freq,exc,modelLabels,filePath);
    end

    if numel(freq) ~= 3 || numel(exc) ~= 3
        error('Expected exactly three candidate models in: %s',filePath);
    end
    if any(~isfinite(freq)) || any(~isfinite(exc))
        error('Non-finite BMS values found in: %s',filePath);
    end

    S.freq = freq(:);
    S.exc  = exc(:);
end

function normalized = normalize_names(names)
    normalized = lower(string(names));
    normalized = regexprep(normalized,'[^a-z0-9]','');
end

function idx = find_name_match(normalizedNames,candidates)
    idx = [];
    for c = 1:numel(candidates)
        candidate = regexprep(lower(candidates(c)),'[^a-z0-9]','');
        hit = find(normalizedNames == candidate,1);
        if ~isempty(hit), idx = hit; return; end
    end
    for c = 1:numel(candidates)
        candidate = regexprep(lower(candidates(c)),'[^a-z0-9]','');
        hit = find(contains(normalizedNames,candidate),1);
        if ~isempty(hit), idx = hit; return; end
    end
end

function [freqOrdered,excOrdered] = reorder_by_model_name(modelText,freq,exc,modelLabels,filePath)
    modelNorm = normalize_names(modelText);
    canonical = normalize_names(string(modelLabels));

    freqOrdered = nan(3,1);
    excOrdered  = nan(3,1);

    aliases = { ...
        ["surprise","surprisal"], ...
        ["beliefuncertainty","uncertainty"], ...
        ["volatility","environmentalvolatility"]};

    for m = 1:3
        hit = find(modelNorm == canonical(m),1);
        if isempty(hit)
            for a = 1:numel(aliases{m})
                hit = find(contains(modelNorm,aliases{m}(a)),1);
                if ~isempty(hit), break; end
            end
        end
        if isempty(hit)
            error('Could not identify model "%s" in %s.',modelLabels{m},filePath);
        end
        freqOrdered(m) = freq(hit);
        excOrdered(m)  = exc(hit);
    end
end

function write_model_values(excelFile,sheetName,S,modelLabels)
    Model = string(modelLabels(:));
    ModelFrequency = S.freq(:);
    ExceedanceProbability = S.exc(:);
    T = table(Model,ModelFrequency,ExceedanceProbability);
    writetable(T,excelFile,'Sheet',sheetName);
end

function plot_winning_models(xPos,healthyValue,chronicValue,healthyColor,chronicColor, ...
    healthyModel,chronicModel,yLabelText,sessionLabel,outputBase,modelLabels, ...
    outlineColor,hatchColor,barWidth,barLineWidth,axisLineWidth, ...
    fsXTick,fsYTick,fsLabel,fsLegend,hatchLineWidth,gapH,gapV,gapD,pngDPI)

    fig = figure('Color','w','Position',[200 200 900 650]);
    ax = axes(fig); hold(ax,'on');

    values = [healthyValue chronicValue];
    colors = [healthyColor; chronicColor];
    winningModels = {healthyModel,chronicModel};
    barHandles = gobjects(1,2);

    for i = 1:2
        barHandles(i) = bar(ax,xPos(i),values(i),barWidth, ...
            'FaceColor',colors(i,:),'EdgeColor',outlineColor, ...
            'LineWidth',barLineWidth);
        add_model_texture(ax,xPos(i),values(i),barWidth,winningModels{i}, ...
            modelLabels,hatchColor,hatchLineWidth,gapH,gapV,gapD);
    end

    ylim(ax,[0 1]);
    xlim(ax,[0.35 1.90]);
    yticks(ax,0:0.2:1.0);
    xticks(ax,xPos);
    xticklabels(ax,{healthyModel,chronicModel});

    ax.Box = 'off';
    ax.LineWidth = axisLineWidth;
    ax.TickDir = 'out';
    ax.FontSize = fsYTick;
    ax.Layer = 'top';
    ax.YGrid = 'off';
    ax.XGrid = 'off';
    ax.XAxis.FontSize = fsXTick;

    ylabel(ax,yLabelText,'FontSize',fsLabel,'FontWeight','bold');
    xlabel(ax,'Winning model','FontSize',fsLabel,'FontWeight','bold');

    sessionHandle = plot(ax,nan,nan,'LineStyle','none','Marker','none','Color','none');
    legend(ax,[barHandles(1),barHandles(2),sessionHandle], ...
        {'Healthy controls','Chronic stress',sessionLabel}, ...
        'Box','off','FontSize',fsLegend,'Location','northeast');

    exportgraphics(fig,[outputBase '.png'],'Resolution',pngDPI);
    exportgraphics(fig,[outputBase '.tiff'],'Resolution',pngDPI);
    exportgraphics(fig,[outputBase '.pdf'],'ContentType','vector');
    close(fig);
end

function add_model_texture(ax,xCenter,barHeight,barWidth,modelName,modelLabels, ...
    hatchColor,hatchLineWidth,gapH,gapV,gapD)

    if barHeight <= 0, return; end

    xLeft = xCenter-barWidth/2;
    xRight = xCenter+barWidth/2;
    yBottom = 0;
    yTop = barHeight;

    modelIndex = find(strcmpi(modelLabels,modelName),1);
    if isempty(modelIndex), return; end

    switch modelIndex
        case 1  % Surprise: horizontal
            yVals = yBottom+gapH:gapH:yTop-gapH/2;
            for y = yVals
                line(ax,[xLeft xRight],[y y],'Color',hatchColor, ...
                    'LineWidth',hatchLineWidth,'Clipping','on');
            end

        case 2  % Belief uncertainty: vertical
            xVals = xLeft+gapV:gapV:xRight-gapV/2;
            for x = xVals
                line(ax,[x x],[yBottom yTop],'Color',hatchColor, ...
                    'LineWidth',hatchLineWidth,'Clipping','on');
            end

        case 3  % Volatility: diagonal
            m = max(yTop-yBottom,0.01)/(xRight-xLeft);
            bMin = yBottom-m*xRight;
            bMax = yTop-m*xLeft;
            for b = bMin:max(gapD,0.01):bMax
                [x1,y1,x2,y2,ok] = clip_diagonal_to_rect( ...
                    m,b,xLeft,xRight,yBottom,yTop);
                if ok
                    line(ax,[x1 x2],[y1 y2],'Color',hatchColor, ...
                        'LineWidth',hatchLineWidth,'Clipping','on');
                end
            end
    end
end

function [x1,y1,x2,y2,ok] = clip_diagonal_to_rect(m,b,xLeft,xRight,yBottom,yTop)
    pts = zeros(0,2);

    y = m*xLeft+b;
    if y >= yBottom && y <= yTop, pts(end+1,:) = [xLeft y]; end 

    y = m*xRight+b;
    if y >= yBottom && y <= yTop, pts(end+1,:) = [xRight y]; end 

    if abs(m) > eps
        x = (yBottom-b)/m;
        if x >= xLeft && x <= xRight, pts(end+1,:) = [x yBottom]; end 

        x = (yTop-b)/m;
        if x >= xLeft && x <= xRight, pts(end+1,:) = [x yTop]; end 
    end

    if size(pts,1) < 2
        x1=NaN; y1=NaN; x2=NaN; y2=NaN; ok=false; return
    end

    pts = unique(round(pts,12),'rows','stable');
    if size(pts,1) < 2
        x1=NaN; y1=NaN; x2=NaN; y2=NaN; ok=false; return
    end

    x1=pts(1,1); y1=pts(1,2);
    x2=pts(2,1); y2=pts(2,2);
    ok=true;
end
