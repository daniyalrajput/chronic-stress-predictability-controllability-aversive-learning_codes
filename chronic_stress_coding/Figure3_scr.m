%% SCR analysis: Chronic stress study
% Publication/repository version
%
% Design
%   Group: Healthy control vs Chronic stress (between participants)
%   Controllability: Controllable vs Uncontrollable (within participants)
%   Predictability: HP vs MP vs UP (within participants)
%
% Primary analysis
%   2 x 2 x 3 mixed repeated-measures ANOVA on participant-level SCR.
%
% Processing
%   Raw SCR -> square-root transform -> recorded exclusions -> optional 3-SD
%   exclusion. Excluded cells remain NaN so participant correspondence is
%   preserved. Complete cases are used for the repeated-measures ANOVA.
%
%
% Required files (relative to this script)
%   data/healthy_SCR_peaks/SCR_data_peaks_s1.mat
%   data/healthy_SCR_peaks/SCR_data_peaks_s2.mat
%   data/results_chronic/chronic_scr_peaks_s1_erly.mat
%   data/results_chronic/chronic_scr_peaks_s2_erly.mat
%
% S1 = Controllable; S2 = Uncontrollable
%
% Author: Daniyal Rajput
% Study: Chronic stress, predictability, controllability and aversive learning

clear; clc; close all;
rng(1,'twister');

%% Paths
scriptDir = fileparts(mfilename('fullpath'));
if isempty(scriptDir), scriptDir = pwd; end

dataDir = fullfile(scriptDir,'data');
healthyDir = fullfile(dataDir,'healthy_SCR_peaks');
chronicDir = fullfile(dataDir,'results_chronic');
outDir = fullfile(scriptDir,'results','SCR');
if ~exist(outDir,'dir'), mkdir(outDir); end

healthyS1File = fullfile(healthyDir,'SCR_data_peaks_s1.mat');
healthyS2File = fullfile(healthyDir,'SCR_data_peaks_s2.mat');
chronicS1File = fullfile(chronicDir,'chronic_scr_peaks_s1.mat');
chronicS2File = fullfile(chronicDir,'chronic_scr_peaks_s2.mat');

assert(isfile(healthyS1File),'Missing file: %s',healthyS1File);
assert(isfile(healthyS2File),'Missing file: %s',healthyS2File);
assert(isfile(chronicS1File),'Missing file: %s',chronicS1File);
assert(isfile(chronicS2File),'Missing file: %s',chronicS2File);

excelFile = fullfile(outDir,'SCR_analysis_results.xlsx');
textFile  = fullfile(outDir,'SCR_analysis_results.txt');
matFile   = fullfile(outDir,'SCR_cleaned_data.mat');

%% Cleaning settings
manualTolerance = 0.02;
use3SD = true;
sdThreshold = 3;
useIQR = false;
iqrMultiplier = 1.5;

%% Recorded exclusions from the original analysis
% Target values are on the square-root transformed SCR scale.
manualExclusions = table( ...
    ["Healthy";"Healthy";"Healthy";"Healthy";"Healthy";"Healthy"; ...
     "Chronic";"Chronic";"Chronic";"Chronic";"Chronic";"Chronic"], ...
    ["HP_S1";"MP_S1";"UP_S1";"HP_S2";"MP_S2";"UP_S2"; ...
     "HP_S1";"MP_S1";"UP_S1";"HP_S2";"MP_S2";"UP_S2"], ...
    'VariableNames',{'Group','Variable','TargetValue'});

%% Load participant-level data
HS1 = load(healthyS1File);
HS2 = load(healthyS2File);
CS1 = load(chronicS1File);
CS2 = load(chronicS2File);

assert(isfield(HS1,'peak_HP') && isfield(HS1,'peak_MP') && isfield(HS1,'peak_UP'), ...
    'Healthy S1 file does not contain the expected variables.');
assert(isfield(HS2,'peaks') && isfield(HS2.peaks,'HP') && ...
    isfield(HS2.peaks,'MP') && isfield(HS2.peaks,'UP'), ...
    'Healthy S2 file does not contain the expected variables.');
assert(isfield(CS1,'peak_HP') && isfield(CS1,'peak_MP') && isfield(CS1,'peak_UP'), ...
    'Chronic S1 file does not contain the expected variables.');
assert(isfield(CS2,'peak_HP') && isfield(CS2,'peak_MP') && isfield(CS2,'peak_UP'), ...
    'Chronic S2 file does not contain the expected variables.');

v = @(x) double(x(:));

healthyRaw = table(v(HS1.peak_HP),v(HS1.peak_MP),v(HS1.peak_UP), ...
                   v(HS2.peaks.HP),v(HS2.peaks.MP),v(HS2.peaks.UP), ...
    'VariableNames',{'HP_S1','MP_S1','UP_S1','HP_S2','MP_S2','UP_S2'});

chronicRaw = table(v(CS1.peak_HP),v(CS1.peak_MP),v(CS1.peak_UP), ...
                   v(CS2.peak_HP),v(CS2.peak_MP),v(CS2.peak_UP), ...
    'VariableNames',{'HP_S1','MP_S1','UP_S1','HP_S2','MP_S2','UP_S2'});

measureVars = {'HP_S1','MP_S1','UP_S1','HP_S2','MP_S2','UP_S2'};
healthyRaw.SubjectID = compose("H%02d",(1:height(healthyRaw))');
chronicRaw.SubjectID = compose("C%02d",(1:height(chronicRaw))');
healthyRaw = movevars(healthyRaw,'SubjectID','Before',1);
chronicRaw = movevars(chronicRaw,'SubjectID','Before',1);

%% Square-root transform
healthy = healthyRaw;
chronic = chronicRaw;
for i = 1:numel(measureVars)
    vn = measureVars{i};
    assert(all(healthy.(vn)(~isnan(healthy.(vn))) >= 0),'Negative Healthy SCR values in %s',vn);
    assert(all(chronic.(vn)(~isnan(chronic.(vn))) >= 0),'Negative Chronic SCR values in %s',vn);
    healthy.(vn) = sqrt(healthy.(vn));
    chronic.(vn) = sqrt(chronic.(vn));
end
healthySqrt = healthy;
chronicSqrt = chronic;

%% Recorded cell-specific exclusions
[healthy,chronic,manualLog] = apply_manual_exclusions( ...
    healthy,chronic,manualExclusions,manualTolerance);

%% Optional automatic outlier exclusion
[healthy,chronic,automaticLog] = apply_automatic_exclusions( ...
    healthy,chronic,measureVars,use3SD,sdThreshold,useIQR,iqrMultiplier);

%% Complete cases for repeated-measures ANOVA
healthy.CompleteCase = all(~ismissing(healthy(:,measureVars)),2);
chronic.CompleteCase = all(~ismissing(chronic(:,measureVars)),2);
healthyRM = healthy(healthy.CompleteCase,:);
chronicRM = chronic(chronic.CompleteCase,:);

fprintf('Healthy complete-case N: %d / %d\n',height(healthyRM),height(healthy));
fprintf('Chronic complete-case N: %d / %d\n',height(chronicRM),height(chronic));

%% Descriptives
Descriptives = make_descriptives(healthy,chronic,measureVars);

%% 2 x 2 x 3 mixed repeated-measures ANOVA
nH = height(healthyRM);
nC = height(chronicRM);

Group = categorical([repmat("Healthy",nH,1);repmat("Chronic",nC,1)], ...
    {'Healthy','Chronic'});
SubjectID = categorical([healthyRM.SubjectID;chronicRM.SubjectID]);

HP_S1 = [healthyRM.HP_S1;chronicRM.HP_S1];
MP_S1 = [healthyRM.MP_S1;chronicRM.MP_S1];
UP_S1 = [healthyRM.UP_S1;chronicRM.UP_S1];
HP_S2 = [healthyRM.HP_S2;chronicRM.HP_S2];
MP_S2 = [healthyRM.MP_S2;chronicRM.MP_S2];
UP_S2 = [healthyRM.UP_S2;chronicRM.UP_S2];

anovaData = table(SubjectID,Group,HP_S1,MP_S1,UP_S1,HP_S2,MP_S2,UP_S2);

withinDesign = table( ...
    categorical({'Controllable';'Controllable';'Controllable'; ...
                 'Uncontrollable';'Uncontrollable';'Uncontrollable'}), ...
    categorical({'HP';'MP';'UP';'HP';'MP';'UP'}), ...
    'VariableNames',{'Controllability','Predictability'});

rm = fitrm(anovaData,'HP_S1-UP_S2 ~ Group','WithinDesign',withinDesign);
anovaWithin = ranova(rm,'WithinModel','Controllability*Predictability');
anovaBetween = anova(rm);

anovaWithinOut = add_row_names(anovaWithin,'Effect');
anovaBetweenOut = add_row_names(anovaBetween,'Effect');

%% Follow-up tests
PostHoc_Between = between_group_posthocs(healthy,chronic);
PostHoc_Control = controllability_posthocs(healthy,chronic);
PostHoc_Predict = predictability_posthocs(healthy,chronic);
CellMeans = make_cell_means(healthy,chronic);

%% Export tables
if isfile(excelFile), delete(excelFile); end
writetable(healthyRaw,excelFile,'Sheet','Healthy_Raw');
writetable(chronicRaw,excelFile,'Sheet','Chronic_Raw');
writetable(healthySqrt,excelFile,'Sheet','Healthy_Sqrt');
writetable(chronicSqrt,excelFile,'Sheet','Chronic_Sqrt');
writetable(healthy,excelFile,'Sheet','Healthy_Cleaned');
writetable(chronic,excelFile,'Sheet','Chronic_Cleaned');
writetable(manualLog,excelFile,'Sheet','Manual_Removal_Log');
writetable(automaticLog,excelFile,'Sheet','Automatic_Removal_Log');
writetable(Descriptives,excelFile,'Sheet','Descriptives');
writetable(anovaData,excelFile,'Sheet','ANOVA_Data');
writetable(anovaWithinOut,excelFile,'Sheet','ANOVA_Within');
writetable(anovaBetweenOut,excelFile,'Sheet','ANOVA_Between');
writetable(PostHoc_Between,excelFile,'Sheet','PostHoc_Between');
writetable(PostHoc_Control,excelFile,'Sheet','PostHoc_Control');
writetable(PostHoc_Predict,excelFile,'Sheet','PostHoc_Predict');
writetable(CellMeans,excelFile,'Sheet','Cell_Means');

Summary = table( ...
    ["Analysis";"Between-participant factor";"Within-participant factor 1"; ...
     "Within-participant factor 2";"Transformation";"3-SD removal"; ...
     "SD threshold";"IQR removal";"Healthy raw N";"Chronic raw N"; ...
     "Healthy complete-case N";"Chronic complete-case N"], ...
    ["2 x 2 x 3 mixed repeated-measures ANOVA";"Group";"Controllability"; ...
     "Predictability";"Square root";string(use3SD);string(sdThreshold); ...
     string(useIQR);string(height(healthyRaw));string(height(chronicRaw)); ...
     string(nH);string(nC)], ...
    'VariableNames',{'Item','Value'});
writetable(Summary,excelFile,'Sheet','Summary');

save(matFile,'healthyRaw','chronicRaw','healthySqrt','chronicSqrt', ...
    'healthy','chronic','healthyRM','chronicRM','manualExclusions', ...
    'manualLog','automaticLog','anovaData','withinDesign','rm', ...
    'anovaWithin','anovaBetween','PostHoc_Between','PostHoc_Control', ...
    'PostHoc_Predict','CellMeans','Summary');

%% Text report
fid = fopen(textFile,'w');
assert(fid ~= -1,'Could not create text report.');
fprintf(fid,'SCR ANALYSIS: CHRONIC STRESS STUDY\n');
fprintf(fid,'==================================\n\n');
fprintf(fid,'Healthy complete-case N: %d / %d\n',nH,height(healthyRaw));
fprintf(fid,'Chronic complete-case N: %d / %d\n\n',nC,height(chronicRaw));
fprintf(fid,'WITHIN-SUBJECT ANOVA\n%s\n',evalc('disp(anovaWithinOut)'));
fprintf(fid,'BETWEEN-SUBJECT ANOVA\n%s\n',evalc('disp(anovaBetweenOut)'));
fprintf(fid,'BETWEEN-GROUP FOLLOW-UPS\n%s\n',evalc('disp(PostHoc_Between)'));
fprintf(fid,'CONTROLLABILITY FOLLOW-UPS\n%s\n',evalc('disp(PostHoc_Control)'));
fprintf(fid,'PREDICTABILITY FOLLOW-UPS\n%s\n',evalc('disp(PostHoc_Predict)'));
fclose(fid);

%% Publication figure
make_scr_figure(healthy,chronic,outDir);

fprintf('\nSCR analysis complete.\nOutputs saved to: %s\n',outDir);

%% ========================================================================
% Local functions
% ========================================================================

function [H,C,logT] = apply_manual_exclusions(H,C,E,tol)
Group = strings(0,1); SubjectID = strings(0,1); Variable = strings(0,1);
TargetValue = []; RemovedValue = []; AbsDifference = []; Removed = false(0,1);

for i = 1:height(E)
    grp = E.Group(i); vn = E.Variable(i); target = E.TargetValue(i);
    if grp == "Healthy", T = H; else, T = C; end
    x = T.(char(vn)); valid = find(~isnan(x));

    Group(end+1,1) = grp; Variable(end+1,1) = vn; TargetValue(end+1,1) = target;
    if isempty(valid)
        SubjectID(end+1,1) = ""; RemovedValue(end+1,1) = NaN;
        AbsDifference(end+1,1) = NaN; Removed(end+1,1) = false; continue
    end

    [d,loc] = min(abs(x(valid)-target)); idx = valid(loc);
    if d <= tol
        SubjectID(end+1,1) = string(T.SubjectID(idx));
        RemovedValue(end+1,1) = x(idx); AbsDifference(end+1,1) = d;
        Removed(end+1,1) = true; x(idx) = NaN; T.(char(vn)) = x;
        if grp == "Healthy", H = T; else, C = T; end
    else
        SubjectID(end+1,1) = ""; RemovedValue(end+1,1) = NaN;
        AbsDifference(end+1,1) = d; Removed(end+1,1) = false;
    end
end
logT = table(Group,SubjectID,Variable,TargetValue,RemovedValue,AbsDifference,Removed);
end

function [H,C,logT] = apply_automatic_exclusions(H,C,vars,use3SD,sdThr,useIQR,iqrMult)
Group = strings(0,1); SubjectID = strings(0,1); Variable = strings(0,1);
Method = strings(0,1); RemovedValue = []; LowerThreshold = []; UpperThreshold = [];
Ts = {H,C}; names = ["Healthy","Chronic"];

for g = 1:2
    T = Ts{g};
    for v = 1:numel(vars)
        vn = vars{v}; x = T.(vn);
        if use3SD
            mu = mean(x,'omitnan'); sd = std(x,'omitnan');
            if ~isnan(sd) && sd > 0
                lo = mu-sdThr*sd; hi = mu+sdThr*sd;
                idx = find(~isnan(x) & (x<lo | x>hi));
                for j = 1:numel(idx)
                    Group(end+1,1)=names(g); SubjectID(end+1,1)=string(T.SubjectID(idx(j)));
                    Variable(end+1,1)=string(vn); Method(end+1,1)="3SD";
                    RemovedValue(end+1,1)=x(idx(j)); LowerThreshold(end+1,1)=lo; UpperThreshold(end+1,1)=hi;
                end
                x(idx)=NaN;
            end
        end
        if useIQR
            valid=x(~isnan(x));
            if ~isempty(valid)
                q1=prctile(valid,25); q3=prctile(valid,75); iq=q3-q1;
                lo=q1-iqrMult*iq; hi=q3+iqrMult*iq;
                idx=find(~isnan(x) & (x<lo | x>hi));
                for j=1:numel(idx)
                    Group(end+1,1)=names(g); SubjectID(end+1,1)=string(T.SubjectID(idx(j)));
                    Variable(end+1,1)=string(vn); Method(end+1,1)="IQR";
                    RemovedValue(end+1,1)=x(idx(j)); LowerThreshold(end+1,1)=lo; UpperThreshold(end+1,1)=hi;
                end
                x(idx)=NaN;
            end
        end
        T.(vn)=x;
    end
    Ts{g}=T;
end
H=Ts{1}; C=Ts{2};
logT=table(Group,SubjectID,Variable,Method,RemovedValue,LowerThreshold,UpperThreshold);
end

function D = make_descriptives(H,C,vars)
Group=strings(0,1); Cell=strings(0,1); N=[]; Mean=[]; SD=[]; SEM=[]; Median=[]; Minimum=[]; Maximum=[];
Ts={H,C}; names=["Healthy","Chronic"];
for g=1:2
    T=Ts{g};
    for i=1:numel(vars)
        x=T.(vars{i}); x=x(~isnan(x));
        Group(end+1,1)=names(g); Cell(end+1,1)=string(vars{i}); N(end+1,1)=numel(x);
        Mean(end+1,1)=mean(x); SD(end+1,1)=std(x); SEM(end+1,1)=std(x)/sqrt(numel(x));
        Median(end+1,1)=median(x); Minimum(end+1,1)=min(x); Maximum(end+1,1)=max(x);
    end
end
D=table(Group,Cell,N,Mean,SD,SEM,Median,Minimum,Maximum);
end

function T = add_row_names(T,newName)
rn=string(T.Properties.RowNames);
if isempty(rn), rn="Row_"+string((1:height(T))'); end
T.(newName)=rn; T=movevars(T,newName,'Before',1); T.Properties.RowNames={};
end

function O = between_group_posthocs(H,C)
cells={'Controllable','HP','HP_S1';'Controllable','MP','MP_S1';'Controllable','UP','UP_S1'; ...
       'Uncontrollable','HP','HP_S2';'Uncontrollable','MP','MP_S2';'Uncontrollable','UP','UP_S2'};
Controllability=strings(6,1); Predictability=strings(6,1); N_Healthy=zeros(6,1); N_Chronic=zeros(6,1);
Mean_Healthy=zeros(6,1); Mean_Chronic=zeros(6,1); t=zeros(6,1); df=zeros(6,1); p=zeros(6,1);
for i=1:6
    x=H.(cells{i,3}); y=C.(cells{i,3}); x=x(~isnan(x)); y=y(~isnan(y));
    [~,p(i),~,st]=ttest2(x,y);
    Controllability(i)=string(cells{i,1}); Predictability(i)=string(cells{i,2});
    N_Healthy(i)=numel(x); N_Chronic(i)=numel(y); Mean_Healthy(i)=mean(x); Mean_Chronic(i)=mean(y);
    t(i)=st.tstat; df(i)=st.df;
end
p_Bonferroni=min(p*6,1);
O=table(Controllability,Predictability,N_Healthy,N_Chronic,Mean_Healthy,Mean_Chronic,t,df,p,p_Bonferroni);
end

function O = controllability_posthocs(H,C)
Ts={H,C}; names=["Healthy","Chronic"]; preds={'HP','MP','UP'};
Group=strings(0,1); Predictability=strings(0,1); N=[]; Mean_Controllable=[]; Mean_Uncontrollable=[]; t=[]; df=[]; p=[]; p_Bonferroni=[];
for g=1:2
    T=Ts{g}; first=numel(p)+1;
    for j=1:3
        x=T.([preds{j} '_S1']); y=T.([preds{j} '_S2']); valid=~isnan(x)&~isnan(y); x=x(valid); y=y(valid);
        [~,pv,~,st]=ttest(x,y);
        Group(end+1,1)=names(g); Predictability(end+1,1)=string(preds{j}); N(end+1,1)=numel(x);
        Mean_Controllable(end+1,1)=mean(x); Mean_Uncontrollable(end+1,1)=mean(y); t(end+1,1)=st.tstat; df(end+1,1)=st.df; p(end+1,1)=pv; p_Bonferroni(end+1,1)=NaN;
    end
    last=numel(p); p_Bonferroni(first:last)=min(p(first:last)*3,1);
end
O=table(Group,Predictability,N,Mean_Controllable,Mean_Uncontrollable,t,df,p,p_Bonferroni);
end

function O = predictability_posthocs(H,C)
Ts={H,C}; names=["Healthy","Chronic"]; sessions={'Controllable','S1';'Uncontrollable','S2'};
comps={'HP_vs_MP','HP','MP';'HP_vs_UP','HP','UP';'MP_vs_UP','MP','UP'};
Group=strings(0,1); Controllability=strings(0,1); Comparison=strings(0,1); N=[]; t=[]; df=[]; p=[]; p_Bonferroni=[];
for g=1:2
    T=Ts{g};
    for s=1:2
        first=numel(p)+1; suffix=sessions{s,2};
        for k=1:3
            x=T.([comps{k,2} '_' suffix]); y=T.([comps{k,3} '_' suffix]); valid=~isnan(x)&~isnan(y); x=x(valid); y=y(valid);
            [~,pv,~,st]=ttest(x,y);
            Group(end+1,1)=names(g); Controllability(end+1,1)=string(sessions{s,1}); Comparison(end+1,1)=string(comps{k,1});
            N(end+1,1)=numel(x); t(end+1,1)=st.tstat; df(end+1,1)=st.df; p(end+1,1)=pv; p_Bonferroni(end+1,1)=NaN;
        end
        last=numel(p); p_Bonferroni(first:last)=min(p(first:last)*3,1);
    end
end
O=table(Group,Controllability,Comparison,N,t,df,p,p_Bonferroni);
end

function O = make_cell_means(H,C)
Ts={H,C}; names=["Healthy","Chronic"];
cells={'Controllable','HP','HP_S1';'Controllable','MP','MP_S1';'Controllable','UP','UP_S1'; ...
       'Uncontrollable','HP','HP_S2';'Uncontrollable','MP','MP_S2';'Uncontrollable','UP','UP_S2'};
Group=strings(0,1); Controllability=strings(0,1); Predictability=strings(0,1); N=[]; Mean=[]; SEM=[];
for g=1:2
    T=Ts{g};
    for i=1:6
        x=T.(cells{i,3}); x=x(~isnan(x));
        Group(end+1,1)=names(g); Controllability(end+1,1)=string(cells{i,1}); Predictability(end+1,1)=string(cells{i,2});
        N(end+1,1)=numel(x); Mean(end+1,1)=mean(x); SEM(end+1,1)=std(x)/sqrt(numel(x));
    end
end
O=table(Group,Controllability,Predictability,N,Mean,SEM);
end

function make_scr_figure(H,C,outDir)
cols={[0.00 0.25 0.85],[0.90 0.40 0.05],[0.60 0.80 1.00],[1.00 0.78 0.50]};
data={H.HP_S1(~isnan(H.HP_S1)),C.HP_S1(~isnan(C.HP_S1)),H.HP_S2(~isnan(H.HP_S2)),C.HP_S2(~isnan(C.HP_S2)); ...
      H.MP_S1(~isnan(H.MP_S1)),C.MP_S1(~isnan(C.MP_S1)),H.MP_S2(~isnan(H.MP_S2)),C.MP_S2(~isnan(C.MP_S2)); ...
      H.UP_S1(~isnan(H.UP_S1)),C.UP_S1(~isnan(C.UP_S1)),H.UP_S2(~isnan(H.UP_S2)),C.UP_S2(~isnan(C.UP_S2))};
titles={'Highly predictable','Moderately predictable','Unpredictable'};
fig=figure('Color','w','Position',[120 180 1800 620]); ax=axes(fig); hold(ax,'on');
base=[1 1.5 2.4 2.9]; blockWidth=1.9; gap=1.1; yMin=0.2; yMax=1.0;
ctrlCenters=zeros(1,3); unctrlCenters=zeros(1,3);
for p=1:3
    pos=base+(p-1)*(blockWidth+gap); ctrlCenters(p)=mean(pos(1:2)); unctrlCenters(p)=mean(pos(3:4));
    yAll=[]; gAll=[];
    for j=1:4, y=data{p,j}; yAll=[yAll;y(:)]; gAll=[gAll;repmat(j,numel(y),1)]; end %#ok<AGROW>
    boxplot(ax,yAll,gAll,'Positions',pos,'Widths',0.30,'Labels',{'','','',''},'Symbol','','Whisker',1.5,'Colors','k');
    delete(findobj(ax,'Tag','Outliers')); boxes=findobj(ax,'Tag','Box'); boxes=flipud(boxes(1:4));
    for j=1:4
        patch(get(boxes(j),'XData'),get(boxes(j),'YData'),cols{j},'FaceAlpha',0.45,'EdgeColor','k','LineWidth',1);
        y=data{p,j}; x=pos(j)+(rand(size(y))-0.5)*0.15;
        scatter(ax,x,y,42,'MarkerFaceColor',cols{j},'MarkerEdgeColor','k','MarkerFaceAlpha',0.80,'LineWidth',0.6);
        if ~isempty(y), m=mean(y); se=std(y)/sqrt(numel(y)); plot(ax,pos(j),m,'ko','MarkerFaceColor','k','MarkerSize',5); line(ax,[pos(j) pos(j)],[m-se m+se],'Color','k','LineWidth',1); end
    end
    text(ax,mean(pos([1 4])),yMax+0.024,titles{p},'HorizontalAlignment','center','FontSize',18,'FontWeight','bold');
end
ax.Box='off'; ax.LineWidth=0.8; ax.FontSize=16; ax.TickDir='out'; ax.XTick=[]; ax.YGrid='off'; ax.XGrid='off'; ax.Layer='top';
xlim(ax,[0.4 base(end)+2*(blockWidth+gap)+0.8]); ylim(ax,[yMin yMax]); yticks(ax,linspace(yMin,yMax,5)); yticklabels(ax,compose('%.1f',linspace(yMin,yMax,5)));
ylabel(ax,'SQRT (Range-corrected SCR)','FontSize',20,'FontWeight','bold');
for p=1:3
    text(ax,ctrlCenters(p),yMin-0.008,'Controllable','HorizontalAlignment','center','VerticalAlignment','top','FontSize',16);
    text(ax,unctrlCenters(p),yMin-0.008,'Uncontrollable','HorizontalAlignment','center','VerticalAlignment','top','FontSize',16);
end
p1=patch(ax,nan,nan,cols{1},'FaceAlpha',0.45,'EdgeColor','k'); p2=patch(ax,nan,nan,cols{2},'FaceAlpha',0.45,'EdgeColor','k');
legend(ax,[p1 p2],{'Healthy controls','Chronic stress'},'Box','off','FontSize',16,'Location','northeastoutside');
exportgraphics(fig,fullfile(outDir,'SCR_figure.png'),'Resolution',600);
exportgraphics(fig,fullfile(outDir,'SCR_figure.tiff'),'Resolution',600);
exportgraphics(fig,fullfile(outDir,'SCR_figure.pdf'),'ContentType','vector');
end
