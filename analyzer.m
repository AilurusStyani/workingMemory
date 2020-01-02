% to briefly analyze the data

dataPath = fullfile(pwd,'data');
files = dir(fullfile(dataPath,'*.mat'));
data = cell(size(files));

set(figure(1),'pos',[27 63 1849 892],'Name','Correct Rate');clf;
subplot1 = tight_subplot(1,length(files),[0.3 0.05]);
suptitle('Correction rate');

set(figure(2),'pos',[27 63 1849 892],'Name','Response Time');clf;
subplot2 = tight_subplot(length(files),2,[0.3 0.05]);
suptitle('Response Time');

for filei = 1:length(files)
    axes(subplot1(filei));
    hold on

    data{filei} = load(fullfile(dataPath,files(filei).name));
    if data{filei}.breakFlag
        % check if the block is broked
        continue
    end
    
    trialNum = length(data{filei}.chosenAnswer);
    correct = 0;
    correct_sep = zeros(data{filei}.TRIALINFO.maxDifficulty,1);
    trialNum_sep = zeros(data{filei}.TRIALINFO.maxDifficulty,1);
    for i = 1:length(data{filei}.chosenAnswer)
        for j = 1:length(data{filei}.chosenAnswer{i})
            if data{filei}.chosenAnswer{i}(j) == data{filei}.correctAnswer{i}(j)
                correct_sep(j) = correct_sep(j)+1; % calculate for every choice
            end
            trialNum_sep(j) = trialNum_sep(j)+1;
        end
        if isequal(data{filei}.chosenAnswer{i},data{filei}.correctAnswer{i})
            correct = correct+1; % calculate for trial
        end
    end
    correctRate = correct./trialNum;
    correctRate_sep = correct_sep./trialNum_sep;
    
    bar(1:length(correctRate_sep),correctRate_sep,'b');
    bar(length(correctRate_sep)+1,correctRate,'k')
    xlabel('Order of graphs');
    ylabel('Correct rate');
    set(subplot1(filei),'YTickLabelMode','auto');
    xticks(1:length(correctRate_sep)+1);
    xticklabels({1:length(correctRate_sep),'overall'})
    
    axes(subplot2(filei*2-1));
    hold on
    responseT = cell(data{filei}.TRIALINFO.maxDifficulty,1);
    for i = 1:length(data{filei}.reactionTime)
        for j = 1:length(data{filei}.reactionTime{i})
            if j == 1
                responseT{j} = cat(1,responseT{j},data{filei}.reactionTime{i}(j));
            else
                responseT{j} = cat(1,responseT{j},data{filei}.reactionTime{i}(j)-data{filei}.reactionTime{i}(j-1));
            end
        end
    end
    
    reaponseTErrorBar = zeros(size(responseT));
    responseTMean = zeros(size(responseT));
    for i = 1:length(responseT)
        responseTMean(i) = mean(responseT{i});
        reaponseTErrorBar(i) = std(responseT{i})./sqrt(length(responseT{i}));
    end
    bar(responseTMean);
    er = errorbar(1:length(responseT),responseTMean,reaponseTErrorBar,reaponseTErrorBar);
    er.Color = 'k';
    er.LineStyle = 'none';
    xlabel('Order of graphs');
    ylabel('Reaction time (second)');
    set(subplot2(filei*2-1),'YTickLabelMode','auto');
    xticks(1:TRIALINFO.maxDifficulty);
    xticklabels(1:TRIALINFO.maxDifficulty)
    
    axes(subplot2(filei*2));
    hold on
    responseT_level = cell(data{filei}.TRIALINFO.maxDifficulty-1,1);
    level = 2;
    for i = 1:length(data{filei}.correctAnswer)
        if ~isequal(data{filei}.correctAnswer{i},data{filei}.chosenAnswer{i})
            continue
        end
        if length(data{filei}.correctAnswer{i}) > level
            level = level+1;
        end
        responseT_level{level-1} = cat(1,responseT_level{level-1},data{filei}.reactionTime{i});
    end
    
    meanResT_lev = cell(data{filei}.TRIALINFO.maxDifficulty-1,1);
    errorbarResT_lev = cell(data{filei}.TRIALINFO.maxDifficulty-1,1);
    for i = 1:length(responseT_level)
        meanResT_lev{i} = mean(responseT_level{i},1);
        if size(responseT_level{i},1)>1
            errorbarResT_lev{i} = std(responseT_level{i},1)./size(responseT_level{i},1);
        else
            errorbarResT_lev{i} = zeros(size(responseT_level{i}));
        end
    end
    for i = 1:length(meanResT_lev)
        errorbar(1:length(meanResT_lev{i}),meanResT_lev{i},errorbarResT_lev{i});
    end
    xlabel('Order of graphs');
    ylabel('Reaction time (second)');
    set(subplot2(filei*2),'YTickLabelMode','auto');
    xticks(1:TRIALINFO.maxDifficulty);
    xticklabels(1:TRIALINFO.maxDifficulty)
end


function [ha, pos] = tight_subplot(Nh, Nw, gap, marg_h, marg_w)

% tight_subplot creates "subplot" axes with adjustable gaps and margins
%
% [ha, pos] = tight_subplot(Nh, Nw, gap, marg_h, marg_w)
%
%   in:  Nh      number of axes in hight (vertical direction)
%        Nw      number of axes in width (horizontaldirection)
%        gap     gaps between the axes in normalized units (0...1)
%                   or [gap_h gap_w] for different gaps in height and width 
%        marg_h  margins in height in normalized units (0...1)
%                   or [lower upper] for different lower and upper margins 
%        marg_w  margins in width in normalized units (0...1)
%                   or [left right] for different left and right margins 
%
%  out:  ha     array of handles of the axes objects
%                   starting from upper left corner, going row-wise as in
%                   subplot
%        pos    positions of the axes objects
%
%  Example: ha = tight_subplot(3,2,[.01 .03],[.1 .01],[.01 .01])
%           for ii = 1:6; axes(ha(ii)); plot(randn(10,ii)); end
%           set(ha(1:4),'XTickLabel',''); set(ha,'YTickLabel','')

% Pekka Kumpulainen 21.5.2012   @tut.fi
% Tampere University of Technology / Automation Science and Engineering


if nargin<3; gap = .02; end
if nargin<4 || isempty(marg_h); marg_h = .05; end
if nargin<5; marg_w = .05; end

if numel(gap)==1
    gap = [gap gap];
end
if numel(marg_w)==1
    marg_w = [marg_w marg_w];
end
if numel(marg_h)==1
    marg_h = [marg_h marg_h];
end

axh = (1-sum(marg_h)-(Nh-1)*gap(1))/Nh; 
axw = (1-sum(marg_w)-(Nw-1)*gap(2))/Nw;

py = 1-marg_h(2)-axh; 

% ha = zeros(Nh*Nw,1);
ii = 0;
for ih = 1:Nh
    px = marg_w(1);
    
    for ix = 1:Nw
        ii = ii+1;
        ha(ii) = axes('Units','normalized', ...
            'Position',[px py axw axh], ...
            'XTickLabel','', ...
            'YTickLabel','');
        px = px+axw+gap(2);
    end
    py = py-axh-gap(1);
end
if nargout > 1
    pos = get(ha,'Position');
end
ha = ha(:);
end
