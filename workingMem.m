function workingMem(subjectName,repetition,displayDuration,maxDifficulty,choiceDuration,seedStr)
% workingMem([subjectName] [,repetition][,displayDuration][,maxDifficulty][,choiceDuration][,seedStr])
% In default: subjectName:'test'   repetition:5   displayDuration:3
%               maxDifficulty:5    choiceDuration:10   seedStr:rand()*10^6
%
% Environment: windows10, matlab2015+, psychotoolbox
% 
% If you want to add new images, convert to .png then move in /sources folder.
% You can also remove images by simply delete them from /sources folder.
%
% The number in correctAnswer/chosenAnswer represent the order in imgFileName, that refer to the displayed pictures.
%
% coding for SH 9th people's hospital
% By BYC 12-2019

global TRIALINFO
difficultyCap = 5; % valid max difficulty

if nargin<1 || isempty(subjectName)
    subjectName = 'test';
    testMode = true;
else
    testMode = false;
end

if nargin<2 || isempty(repetition)
    TRIALINFO.repetition = 5;
else
    TRIALINFO.repetition = repetition;
end

if nargin<3 || isempty(displayDuration)
    TRIALINFO.displayDuration = 3; % second
else
    TRIALINFO.displayDuration = displayDuration;
end

if nargin<4 || isempty(maxDifficulty)
    TRIALINFO.maxDifficulty = 5; % maximum 5 pictures
else
    if maxDifficulty > difficultyCap
        warning(['Currently, max difficulty was capped by' num2str(difficultyCap) '!'])
        maxDifficulty = difficultyCap;
    end
    TRIALINFO.maxDifficulty = maxDifficulty;
end

if nargin<5 || isempty(choiceDuration)
    TRIALINFO.choiceDuration = 15; % second
else
    TRIALINFO.choiceDuration = choiceDuration;
end

% random seed
if nargin >= 6
    if strcmp(seedStr,'shuffle') || strcmp(seedStr,'default')
        TRIALINFO.seed = seedStr;
    elseif ischar(seedStr)
        TRIALINFO.seed = str2double(seedStr);
    elseif isempty(seedStr)
        TRIALINFO.seed = ceil(rand()*1000000);
    elseif isnumeric(seedStr)
        TRIALINFO.seed = seedStr;
    end
else
    TRIALINFO.seed = ceil(rand()*1000000);
end
rng(TRIALINFO.seed);

% path and file name
fileName = ['workingMemory_' subjectName '_' datestr(now,'yymmddHHMM')];
curDir = pwd;
saveDir = fullfile(pwd,'data');
mkdir(saveDir);

% key
KbName('UnifyKeyNames');
skipKey = KbName('Return'); % skip current trial
escape = KbName('ESCAPE'); % abort this block
repeatKey = KbName('backspace');

%% parameter
TRIALINFO.feedback = true; % true/1 to give feedback, false/0 not
TRIALINFO.feedbackDuration = TRIALINFO.displayDuration; % second
TRIALINFO.showExplanation = true;  % true/1 to give explanation, false/0 not
TRIALINFO.explanation = double('请记住出现过的图片，\n\n并按出现顺序依次选择以完成任务。');

% initial OpenGl
global SCREEN;
if testMode
    Screen('Preference', 'SkipSyncTests', 1); % for debug/test
else
    Screen('Preference', 'SkipSyncTests', 0); % for recording
end

AssertOpenGL;
InitializeMatlabOpenGL;

if max(Screen('Screens')) > 1
    SCREEN.screenId = max(Screen('Screens'))-1;
else
    SCREEN.screenId = max(Screen('Screens'));
end
PsychImaging('PrepareConfiguration');
PsychImaging('AddTask', 'General', 'FloatingPoint32BitIfPossible');
[win , winRect] = PsychImaging('OpenWindow', SCREEN.screenId);

Screen('ColorRange', win, 1, 0);

SCREEN.widthPix = winRect(3);
SCREEN.heightPix = winRect(4);
[SCREEN.center(1), SCREEN.center(2)] = RectCenter(winRect);

SCREEN.refreshRate = Screen('NominalFrameRate', SCREEN.screenId);
% SCREEN.backgroundColor = GrayIndex(win);
SCREEN.backgroundColor = [0.8 0.8 0.8];
SCREEN.redColor = [0.9 0.1 0.1];

Screen('FillRect', win, SCREEN.backgroundColor);

TRIALINFO.imgRate = 4;
imgSize1 = ceil(min(SCREEN.widthPix/(1+(1+TRIALINFO.imgRate)*ceil((TRIALINFO.maxDifficulty+1)/2)),SCREEN.heightPix/(1+(1+TRIALINFO.imgRate)*2))*TRIALINFO.imgRate);
imgSize2 = ceil(min(SCREEN.widthPix/(1+(1+TRIALINFO.imgRate)*ceil((TRIALINFO.maxDifficulty+1)/3)),SCREEN.heightPix/(1+(1+TRIALINFO.imgRate)*3))*TRIALINFO.imgRate);
if imgSize1>imgSize2
    TRIALINFO.layOutType = 1; % in 1 or 2 row, reserved for 7-8 pictures
    TRIALINFO.imgSize = ceil(imgSize1/2)*2;
else
    TRIALINFO.layOutType = 2; % in 1-3 row, reserved for 7-8 pictures
    TRIALINFO.imgSize = ceil(imgSize2/2)*2;
end

% read img source
sourceIndex = dir(fullfile(curDir,'sources','*.png'));
imgFileName = {};
for i = 1:length(sourceIndex)
    if ~contains(sourceIndex(i).name,'exp1') && ~contains(sourceIndex(i).name,'exp2') && ~contains(sourceIndex(i).name,'expblank')
        imgFileName = cat(2,imgFileName,sourceIndex(i).name);
    end
end
img = cell(size(imgFileName));
imgT = cell(size(imgFileName));
for i = 1:length(imgFileName)
    [img{i},~,imgT{i}] = imread(fullfile(pwd,'sources',imgFileName{i}),'png');
    img{i} = imresize(img{i},[TRIALINFO.imgSize,TRIALINFO.imgSize],'nearest'); imgT{i} = imresize(imgT{i},[TRIALINFO.imgSize,TRIALINFO.imgSize],'nearest');
    img{i}(:,:,1) = SCREEN.backgroundColor(1).*(max(max(imgT{i}))-imgT{i})+img{i}(:,:,1).*(imgT{i}./max(max(imgT{i})));
    img{i}(:,:,2) = SCREEN.backgroundColor(2).*(max(max(imgT{i}))-imgT{i})+img{i}(:,:,2).*(imgT{i}./max(max(imgT{i})));
    img{i}(:,:,3) = SCREEN.backgroundColor(3).*(max(max(imgT{i}))-imgT{i})+img{i}(:,:,3).*(imgT{i}./max(max(imgT{i})));
end

ShowCursor('Hand');

% set default text font, style and size,etc
% Screen('TextFont',win, 'Tahoma');
Screen('TextFont',win,'楷体');
Screen('TextStyle',win, 1); % 0=normal,1=bold,2=italic,4=underline,8=outline,32=condense,64=extend.

Screen('Flip',win);

%% show explanation
while 1
    repeatTextBounds=showExp(win);
    textBoundsx = [repeatTextBounds(1) repeatTextBounds(3) repeatTextBounds(3) repeatTextBounds(1)];
    textBoundsy = [repeatTextBounds(2) repeatTextBounds(2) repeatTextBounds(4) repeatTextBounds(4)];
    
    % check for mouse release
    while 1
        [~,~,buttons] = GetMouse(win);
        if ~sum(buttons)
            break
        end
    end
    
    [~,x,y,~] = GetClicks(win);
    if inpolygon(x,y,textBoundsx,textBoundsy)
        % repeat the explanation
        
        % check for mouse release
        while 1
            [~,~,buttons] = GetMouse(win);
            if ~sum(buttons)
                break
            end
        end
        TRIALINFO.showExplanation = true;
        continue;
    else
        % going to the task
        
        % check for mouse release
        while 1
            [~,~,buttons] = GetMouse(win);
            if ~sum(buttons)
                break
            end
        end
        
        break;
    end
end
    

%% formally start
trialIndex = 2:TRIALINFO.maxDifficulty;
trialOrder = sort(repmat(trialIndex,1,TRIALINFO.repetition));
breakFlag = 0;
correctAnswer = cell(size(trialOrder));
chosenAnswer = cell(size(trialOrder));
reactionTime = cell(size(trialOrder));

% calculate for location of picture center, order from left to right, top to bottom
picLocations = calculatePicLocation();

for triali = 1:length(trialOrder)
    picRemNum = trialOrder(triali);
    picDisNum = trialOrder(triali)+1;
    picIndex = randperm(length(img),picDisNum);
    picRemOrder = randperm(picDisNum,picRemNum);
    picDisOrder = randperm(picDisNum);
    
    correctAnswer{triali} = picRemOrder;
    
    dispImg = cell(picDisNum,1);
    for i = 1:picDisNum
        dispImg{i} = Screen('MakeTexture', win, img{picIndex(i)});
    end
    
    % show pictures to remember
    for remi = 1:picRemNum
        Screen('DrawTexture', win, dispImg{picRemOrder(remi)}, [], [picLocations{1}(1,1)-TRIALINFO.imgSize/2,picLocations{1}(1,2)-TRIALINFO.imgSize/2,picLocations{1}(1,1)+TRIALINFO.imgSize/2,picLocations{1}(1,2)+TRIALINFO.imgSize/2],[],[],[]);
        Screen('DrawingFinished',win);
        Screen('Flip',win,0,0);
        tic
        while toc<TRIALINFO.displayDuration
            [~, ~, keycode] = KbCheck;
            if keycode(escape)
                breakFlag = 1;
                break;
            elseif keycode(skipKey)
                break;
            end
        end
        if breakFlag
            break;
        end
    end
    
    if breakFlag
        break;
    end
    
    % start choice
    for disi = 1:picDisNum
        Screen('DrawTexture', win, dispImg{picDisOrder(disi)}, [], [picLocations{picDisNum}(disi,1)-TRIALINFO.imgSize/2,picLocations{picDisNum}(disi,2)-TRIALINFO.imgSize/2,picLocations{picDisNum}(disi,1)+TRIALINFO.imgSize/2,picLocations{picDisNum}(disi,2)+TRIALINFO.imgSize/2],[],[],[]);
    end
    Screen('DrawingFinished',win);
    Screen('Flip',win,0,0);
    
    choiceT = tic;
    choicei = 1;
    chosenPic = [];
    while toc(choiceT) < TRIALINFO.choiceDuration && choicei <= picRemNum
        [mx,my,mouseDown] = GetMouse(win);
        if mouseDown(1)
            for mouseChecki = 1:picDisNum
                vx = [picLocations{picDisNum}(mouseChecki,1)-TRIALINFO.imgSize/2,picLocations{picDisNum}(mouseChecki,1)+TRIALINFO.imgSize/2,picLocations{picDisNum}(mouseChecki,1)+TRIALINFO.imgSize/2,picLocations{picDisNum}(mouseChecki,1)-TRIALINFO.imgSize/2,picLocations{picDisNum}(mouseChecki,1)-TRIALINFO.imgSize/2];
                vy = [picLocations{picDisNum}(mouseChecki,2)-TRIALINFO.imgSize/2,picLocations{picDisNum}(mouseChecki,2)-TRIALINFO.imgSize/2,picLocations{picDisNum}(mouseChecki,2)+TRIALINFO.imgSize/2,picLocations{picDisNum}(mouseChecki,2)+TRIALINFO.imgSize/2,picLocations{picDisNum}(mouseChecki,2)-TRIALINFO.imgSize/2];
                if inpolygon(mx,my,vx,vy) && ~ismember(picDisOrder(mouseChecki),chosenAnswer{triali})
                    chosenAnswer{triali}(choicei) = picDisOrder(mouseChecki);
                    chosenPic = cat(1,chosenPic,mouseChecki);
                    reactionTime{triali}(choicei) = toc(choiceT);
                    choicei = choicei+1;
                    for disi = 1:picDisNum
                        Screen('DrawTexture', win, dispImg{picDisOrder(disi)}, [], [picLocations{picDisNum}(disi,1)-TRIALINFO.imgSize/2,picLocations{picDisNum}(disi,2)-TRIALINFO.imgSize/2,picLocations{picDisNum}(disi,1)+TRIALINFO.imgSize/2,picLocations{picDisNum}(disi,2)+TRIALINFO.imgSize/2],[],[],[]);
                    end
                    for squarei = 1:length(chosenPic)
                        x1 = picLocations{picDisNum}(chosenPic(squarei),1)-TRIALINFO.imgSize/2;
                        y1 = picLocations{picDisNum}(chosenPic(squarei),2)-TRIALINFO.imgSize/2;
                        x2 = picLocations{picDisNum}(chosenPic(squarei),1)+TRIALINFO.imgSize/2;
                        y2 = picLocations{picDisNum}(chosenPic(squarei),2)-TRIALINFO.imgSize/2;
                        x3 = picLocations{picDisNum}(chosenPic(squarei),1)+TRIALINFO.imgSize/2;
                        y3 = picLocations{picDisNum}(chosenPic(squarei),2)+TRIALINFO.imgSize/2;
                        x4 = picLocations{picDisNum}(chosenPic(squarei),1)-TRIALINFO.imgSize/2;
                        y4 = picLocations{picDisNum}(chosenPic(squarei),2)+TRIALINFO.imgSize/2;
                        lineMetrix = [x1,x2,x2,x3,x3,x4,x4,x1;y1,y2,y2,y3,y3,y4,y4,y1];
                        Screen('DrawLines', win, lineMetrix,8,SCREEN.redColor);
                    end
                    Screen('DrawingFinished',win);
                    Screen('Flip',win,0,0);
                end
            end
            while mouseDown(1)
                % until realease
                [~,~,mouseDown] = GetMouse(win);
            end
        end
    end
    
    % for feedback
    if TRIALINFO.feedback
        if isequal(chosenAnswer{triali}, correctAnswer{triali})
            Screen('TextSize',win,ceil(80/1280*SCREEN.widthPix));
            [~, ~, ~] = DrawFormattedText(win, double('恭喜你回答正确！'),'center','center',[0.2 0.8 0.2]);
            Screen('TextBackgroundColor',win, SCREEN.backgroundColor);
            Screen('DrawingFinished',win);
            Screen('Flip',win,0,0);
        else
            Screen('TextSize',win,ceil(80/1280*SCREEN.widthPix));
            [~, ~, ~] = DrawFormattedText(win, double('请再尝试一下'),'center','center',[0.8 0.2 0.2]);
            Screen('TextBackgroundColor',win, SCREEN.backgroundColor);
            Screen('DrawingFinished',win);
            Screen('Flip',win,0,0);
        end
        tic;
        while toc<TRIALINFO.feedbackDuration
            [~, ~, keycode] = KbCheck;
            if keycode(escape)
                breakFlag = 1;
                break;
            elseif keycode(skipKey)
                break;
            end
        end
    end
    
    if breakFlag
        break;
    end
end
save(fullfile(saveDir,fileName),'TRIALINFO','SCREEN','correctAnswer','chosenAnswer','reactionTime','breakFlag','imgFileName');
Screen('CloseAll');
cd(curDir);
clear TRIALINFO SCREEN subjectName repetition displayDuration maxDifficulty choiceDuration seedStr
end

function drawExplanation(win)
global SCREEN
global TRIALINFO
Screen('TextSize',win,ceil(20/1280*SCREEN.widthPix));
[~, ~, ~] = DrawFormattedText(win, double('点击鼠标跳过说明'),'right',SCREEN.heightPix - ceil(15/1280*SCREEN.widthPix),[0.2 0.2 0.2]);
Screen('TextSize',win,ceil(50/1280*SCREEN.widthPix));
[~, ~, ~] = DrawFormattedText(win, TRIALINFO.explanation,'center',SCREEN.heightPix/4,[0.2 0.6 0.7]);
Screen('TextBackgroundColor',win, SCREEN.backgroundColor);
end

function repeatTextBounds=showExp(win)
% check for mouse release
while 1
    [~,~,buttons] = GetMouse(win);
    if ~sum(buttons)
        break
    end
end

global TRIALINFO
global SCREEN

if TRIALINFO.showExplanation
    explainImgName = {'exp1.png','exp2.png','expblank.png'};
    explainImg = cell(size(explainImgName));
    for i = 1:length(explainImgName)
        [explainImg{i},~,~] = imread(fullfile(pwd,'sources',explainImgName{i}),'png');
        explainImg{i} = imresize(explainImg{i},[TRIALINFO.imgSize,TRIALINFO.imgSize],'nearest');
    end
    
    x1 = SCREEN.widthPix/2-TRIALINFO.imgSize/TRIALINFO.imgRate*(1+TRIALINFO.imgRate)-TRIALINFO.imgSize/2; x2 = SCREEN.widthPix/2-TRIALINFO.imgSize/TRIALINFO.imgRate*(1+TRIALINFO.imgRate)+TRIALINFO.imgSize/2; x3 = SCREEN.widthPix/2-TRIALINFO.imgSize/TRIALINFO.imgRate*(1+TRIALINFO.imgRate)+TRIALINFO.imgSize/2;x4 = SCREEN.widthPix/2-TRIALINFO.imgSize/TRIALINFO.imgRate*(1+TRIALINFO.imgRate)-TRIALINFO.imgSize/2;
    y1 = SCREEN.heightPix/4*3-TRIALINFO.imgSize/2; y2 = SCREEN.heightPix/4*3-TRIALINFO.imgSize/2; y3 = SCREEN.heightPix/4*3+TRIALINFO.imgSize/2; y4 = SCREEN.heightPix/4*3+TRIALINFO.imgSize/2;
    xyMetrix{1} = [x1,x2,x2,x3,x3,x4,x4,x1;y1,y2,y2,y3,y3,y4,y4,y1];
    expImgH{1} = Screen('MakeTexture', win, explainImg{1});
    
    x1 = SCREEN.widthPix/2-TRIALINFO.imgSize/2; x2 = SCREEN.widthPix/2+TRIALINFO.imgSize/2; x3 = SCREEN.widthPix/2+TRIALINFO.imgSize/2;x4 = SCREEN.widthPix/2-TRIALINFO.imgSize/2;
    y1 = SCREEN.heightPix/4*3-TRIALINFO.imgSize/2; y2 = SCREEN.heightPix/4*3-TRIALINFO.imgSize/2; y3 = SCREEN.heightPix/4*3+TRIALINFO.imgSize/2; y4 = SCREEN.heightPix/4*3+TRIALINFO.imgSize/2;
    xyMetrix{2} = [x1,x2,x2,x3,x3,x4,x4,x1;y1,y2,y2,y3,y3,y4,y4,y1];
    expImgH{2} = Screen('MakeTexture', win, explainImg{2});
    
    x1 = SCREEN.widthPix/2+TRIALINFO.imgSize/TRIALINFO.imgRate*(1+TRIALINFO.imgRate)-TRIALINFO.imgSize/2; x2 = SCREEN.widthPix/2+TRIALINFO.imgSize/TRIALINFO.imgRate*(1+TRIALINFO.imgRate)+TRIALINFO.imgSize/2; x3 = SCREEN.widthPix/2+TRIALINFO.imgSize/TRIALINFO.imgRate*(1+TRIALINFO.imgRate)+TRIALINFO.imgSize/2;x4 = SCREEN.widthPix/2+TRIALINFO.imgSize/TRIALINFO.imgRate*(1+TRIALINFO.imgRate)-TRIALINFO.imgSize/2;
    y1 = SCREEN.heightPix/4*3-TRIALINFO.imgSize/2; y2 = SCREEN.heightPix/4*3-TRIALINFO.imgSize/2; y3 = SCREEN.heightPix/4*3+TRIALINFO.imgSize/2; y4 = SCREEN.heightPix/4*3+TRIALINFO.imgSize/2;
    xyMetrix{3} = [x1,x2,x2,x3,x3,x4,x4,x1;y1,y2,y2,y3,y3,y4,y4,y1];
    expImgH{3} = Screen('MakeTexture', win, explainImg{3});
    
    explanationStep = 1;
    while 1
        [~,~,buttons] = GetMouse(win);
        if sum(buttons)
            break;
        end
        
        if explanationStep<3
            drawExplanation(win);
            
            Screen('DrawTexture', win, expImgH{explanationStep}, [], [SCREEN.widthPix/2-TRIALINFO.imgSize/2,SCREEN.heightPix/4*3-TRIALINFO.imgSize/2,SCREEN.widthPix/2+TRIALINFO.imgSize/2,SCREEN.heightPix/4*3+TRIALINFO.imgSize/2],[],[],[]);
            Screen('DrawingFinished',win);
            Screen('Flip',win,0,0);
            t = tic;
            while toc(t)<TRIALINFO.displayDuration
                [~,~,buttons] = GetMouse(win);
                if sum(buttons)
                    break;
                end
            end
        elseif explanationStep == 3
            expImgOrder = randperm(3);
            drawExplanation(win);
            
            Screen('DrawTexture', win, expImgH{expImgOrder(1)}, [], [SCREEN.widthPix/2-TRIALINFO.imgSize/TRIALINFO.imgRate*(1+TRIALINFO.imgRate)-TRIALINFO.imgSize/2,SCREEN.heightPix/4*3-TRIALINFO.imgSize/2,SCREEN.widthPix/2-TRIALINFO.imgSize/TRIALINFO.imgRate*(1+TRIALINFO.imgRate)+TRIALINFO.imgSize/2,SCREEN.heightPix/4*3+TRIALINFO.imgSize/2],[],[],[]);
            Screen('DrawTexture', win, expImgH{expImgOrder(2)}, [], [SCREEN.widthPix/2-TRIALINFO.imgSize/2,SCREEN.heightPix/4*3-TRIALINFO.imgSize/2,SCREEN.widthPix/2+TRIALINFO.imgSize/2,SCREEN.heightPix/4*3+TRIALINFO.imgSize/2],[],[],[]);
            Screen('DrawTexture', win, expImgH{expImgOrder(3)}, [], [SCREEN.widthPix/2+TRIALINFO.imgSize/TRIALINFO.imgRate*(1+TRIALINFO.imgRate)-TRIALINFO.imgSize/2,SCREEN.heightPix/4*3-TRIALINFO.imgSize/2,SCREEN.widthPix/2+TRIALINFO.imgSize/TRIALINFO.imgRate*(1+TRIALINFO.imgRate)+TRIALINFO.imgSize/2,SCREEN.heightPix/4*3+TRIALINFO.imgSize/2],[],[],[]);
            Screen('DrawingFinished',win);
            Screen('Flip',win,0,0);
            t = tic;
            while toc(t)<TRIALINFO.displayDuration
                [~,~,buttons] = GetMouse(win);
                if sum(buttons)
                    break;
                end
            end
        elseif explanationStep == 4
            step4 = tic;
            showSquare = true;
            while toc(step4)<TRIALINFO.displayDuration
                drawExplanation(win);
                
                Screen('DrawTexture', win, expImgH{expImgOrder(1)}, [], [SCREEN.widthPix/2-TRIALINFO.imgSize/TRIALINFO.imgRate*(1+TRIALINFO.imgRate)-TRIALINFO.imgSize/2,SCREEN.heightPix/4*3-TRIALINFO.imgSize/2,SCREEN.widthPix/2-TRIALINFO.imgSize/TRIALINFO.imgRate*(1+TRIALINFO.imgRate)+TRIALINFO.imgSize/2,SCREEN.heightPix/4*3+TRIALINFO.imgSize/2],[],[],[]);
                Screen('DrawTexture', win, expImgH{expImgOrder(2)}, [], [SCREEN.widthPix/2-TRIALINFO.imgSize/2,SCREEN.heightPix/4*3-TRIALINFO.imgSize/2,SCREEN.widthPix/2+TRIALINFO.imgSize/2,SCREEN.heightPix/4*3+TRIALINFO.imgSize/2],[],[],[]);
                Screen('DrawTexture', win, expImgH{expImgOrder(3)}, [], [SCREEN.widthPix/2+TRIALINFO.imgSize/TRIALINFO.imgRate*(1+TRIALINFO.imgRate)-TRIALINFO.imgSize/2,SCREEN.heightPix/4*3-TRIALINFO.imgSize/2,SCREEN.widthPix/2+TRIALINFO.imgSize/TRIALINFO.imgRate*(1+TRIALINFO.imgRate)+TRIALINFO.imgSize/2,SCREEN.heightPix/4*3+TRIALINFO.imgSize/2],[],[],[]);
                
                if showSquare
                    exp1stImg = find(expImgOrder == 1);
                    Screen('DrawLines', win, xyMetrix{exp1stImg},8,SCREEN.redColor);
                end
                Screen('DrawingFinished',win);
                Screen('Flip',win,0,0);
                t = tic;
                while toc(t)<0.4
                    [~,~,buttons] = GetMouse(win);
                    if sum(buttons)
                        break;
                    end
                end
                [~,~,buttons] = GetMouse(win);
                if sum(buttons)
                    break;
                end
                showSquare = ~showSquare;
            end
        elseif explanationStep == 5
            step5 = tic;
            showSquare = true;
            while toc(step5)<TRIALINFO.displayDuration
                drawExplanation(win);
                
                Screen('DrawTexture', win, expImgH{expImgOrder(1)}, [], [SCREEN.widthPix/2-TRIALINFO.imgSize/TRIALINFO.imgRate*(1+TRIALINFO.imgRate)-TRIALINFO.imgSize/2,SCREEN.heightPix/4*3-TRIALINFO.imgSize/2,SCREEN.widthPix/2-TRIALINFO.imgSize/TRIALINFO.imgRate*(1+TRIALINFO.imgRate)+TRIALINFO.imgSize/2,SCREEN.heightPix/4*3+TRIALINFO.imgSize/2],[],[],[]);
                Screen('DrawTexture', win, expImgH{expImgOrder(2)}, [], [SCREEN.widthPix/2-TRIALINFO.imgSize/2,SCREEN.heightPix/4*3-TRIALINFO.imgSize/2,SCREEN.widthPix/2+TRIALINFO.imgSize/2,SCREEN.heightPix/4*3+TRIALINFO.imgSize/2],[],[],[]);
                Screen('DrawTexture', win, expImgH{expImgOrder(3)}, [], [SCREEN.widthPix/2+TRIALINFO.imgSize/TRIALINFO.imgRate*(1+TRIALINFO.imgRate)-TRIALINFO.imgSize/2,SCREEN.heightPix/4*3-TRIALINFO.imgSize/2,SCREEN.widthPix/2+TRIALINFO.imgSize/TRIALINFO.imgRate*(1+TRIALINFO.imgRate)+TRIALINFO.imgSize/2,SCREEN.heightPix/4*3+TRIALINFO.imgSize/2],[],[],[]);
                Screen('DrawLines', win, xyMetrix{exp1stImg},8,SCREEN.redColor);
                
                if showSquare
                    exp2ndImg = find(expImgOrder == 2);
                    Screen('DrawLines', win, xyMetrix{exp2ndImg},8,SCREEN.redColor);
                end
                Screen('DrawingFinished',win);
                Screen('Flip',win,0,0);
                t = tic;
                while toc(t)<0.4
                    [~,~,buttons] = GetMouse(win);
                    if sum(buttons)
                        break;
                    end
                end
                [~,~,buttons] = GetMouse(win);
                if sum(buttons)
                    break;
                end
                showSquare = ~showSquare;
            end
        else
            drawExplanation(win);
            
            Screen('TextSize',win,ceil(60/1280*SCREEN.widthPix));
            [~, ~, ~] = DrawFormattedText(win, double('回答正确！'),'center',SCREEN.heightPix/4*3,[0.2 0.8 0.2]);
            Screen('TextBackgroundColor',win, SCREEN.backgroundColor);
            Screen('DrawingFinished',win);
            Screen('Flip',win,0,0);
            t = tic;
            while toc(t)<TRIALINFO.displayDuration
                [~,~,buttons] = GetMouse(win);
                if sum(buttons)
                    break;
                end
            end
        end
        [~,~,buttons] = GetMouse(win);
        if sum(buttons)
            break;
        end
        explanationStep = explanationStep+1;
        if explanationStep > 6
            explanationStep = 1;
        end
    end
end
Screen('TextSize',win,ceil(90/1280*SCREEN.widthPix));
[~, ~, ~] = DrawFormattedText(win, double('点击鼠标开始测试'),'center','center',[0.2 0.8 0.2]);
Screen('TextSize',win,ceil(20/1280*SCREEN.widthPix));
[~, ~, repeatTextBounds] = DrawFormattedText(win, double('点击此处重放说明'),'right',SCREEN.heightPix - ceil(15/1280*SCREEN.widthPix),[0.2 0.2 0.2]);
Screen('TextBackgroundColor',win, SCREEN.backgroundColor);
Screen('DrawingFinished',win);
Screen('Flip',win,0,0);
end

function picLocations = calculatePicLocation()
global TRIALINFO
global SCREEN
picLocations{1} = [SCREEN.widthPix/2 SCREEN.heightPix/2];

picLocations{2} = [SCREEN.widthPix/2-TRIALINFO.imgSize/TRIALINFO.imgRate*(1+TRIALINFO.imgRate/2), SCREEN.heightPix/2;
    SCREEN.widthPix/2+TRIALINFO.imgSize/TRIALINFO.imgRate*(1+TRIALINFO.imgRate/2), SCREEN.heightPix/2];

picLocations{3} = [SCREEN.widthPix/2-TRIALINFO.imgSize/TRIALINFO.imgRate*(1+TRIALINFO.imgRate), SCREEN.heightPix/2;
    SCREEN.widthPix/2, SCREEN.heightPix/2;
    SCREEN.widthPix/2+TRIALINFO.imgSize/TRIALINFO.imgRate*(1+TRIALINFO.imgRate), SCREEN.heightPix/2];

picLocations{4} = [SCREEN.widthPix/2-TRIALINFO.imgSize/TRIALINFO.imgRate*(1+TRIALINFO.imgRate/2), SCREEN.heightPix/2-TRIALINFO.imgSize/TRIALINFO.imgRate*(1+TRIALINFO.imgRate/2);
    SCREEN.widthPix/2+TRIALINFO.imgSize/TRIALINFO.imgRate*(1+TRIALINFO.imgRate/2), SCREEN.heightPix/2-TRIALINFO.imgSize/TRIALINFO.imgRate*(1+TRIALINFO.imgRate/2);
    SCREEN.widthPix/2-TRIALINFO.imgSize/TRIALINFO.imgRate*(1+TRIALINFO.imgRate/2), SCREEN.heightPix/2+TRIALINFO.imgSize/TRIALINFO.imgRate*(1+TRIALINFO.imgRate/2);
    SCREEN.widthPix/2+TRIALINFO.imgSize/TRIALINFO.imgRate*(1+TRIALINFO.imgRate/2), SCREEN.heightPix/2+TRIALINFO.imgSize/TRIALINFO.imgRate*(1+TRIALINFO.imgRate/2)];

picLocations{5} = [SCREEN.widthPix/2-TRIALINFO.imgSize/TRIALINFO.imgRate*(1+TRIALINFO.imgRate/2), SCREEN.heightPix/2-TRIALINFO.imgSize/TRIALINFO.imgRate*(1+TRIALINFO.imgRate/2);
    SCREEN.widthPix/2+TRIALINFO.imgSize/TRIALINFO.imgRate*(1+TRIALINFO.imgRate/2), SCREEN.heightPix/2-TRIALINFO.imgSize/TRIALINFO.imgRate*(1+TRIALINFO.imgRate/2);
    SCREEN.widthPix/2-TRIALINFO.imgSize/TRIALINFO.imgRate*(1+TRIALINFO.imgRate), SCREEN.heightPix/2+TRIALINFO.imgSize/TRIALINFO.imgRate*(1+TRIALINFO.imgRate/2);
    SCREEN.widthPix/2, SCREEN.heightPix/2+TRIALINFO.imgSize/TRIALINFO.imgRate*(1+TRIALINFO.imgRate/2);
    SCREEN.widthPix/2+TRIALINFO.imgSize/TRIALINFO.imgRate*(1+TRIALINFO.imgRate), SCREEN.heightPix/2+TRIALINFO.imgSize/TRIALINFO.imgRate*(1+TRIALINFO.imgRate/2)];

picLocations{6} = [SCREEN.widthPix/2-TRIALINFO.imgSize/TRIALINFO.imgRate*(1+TRIALINFO.imgRate), SCREEN.heightPix/2-TRIALINFO.imgSize/TRIALINFO.imgRate*(1+TRIALINFO.imgRate/2);
    SCREEN.widthPix/2, SCREEN.heightPix/2-TRIALINFO.imgSize/TRIALINFO.imgRate*(1+TRIALINFO.imgRate/2);
    SCREEN.widthPix/2+TRIALINFO.imgSize/TRIALINFO.imgRate*(1+TRIALINFO.imgRate), SCREEN.heightPix/2-TRIALINFO.imgSize/TRIALINFO.imgRate*(1+TRIALINFO.imgRate/2);
    SCREEN.widthPix/2-TRIALINFO.imgSize/TRIALINFO.imgRate*(1+TRIALINFO.imgRate), SCREEN.heightPix/2+TRIALINFO.imgSize/TRIALINFO.imgRate*(1+TRIALINFO.imgRate/2);
    SCREEN.widthPix/2, SCREEN.heightPix/2+TRIALINFO.imgSize/TRIALINFO.imgRate*(1+TRIALINFO.imgRate/2);
    SCREEN.widthPix/2+TRIALINFO.imgSize/TRIALINFO.imgRate*(1+TRIALINFO.imgRate), SCREEN.heightPix/2+TRIALINFO.imgSize/TRIALINFO.imgRate*(1+TRIALINFO.imgRate/2)];

% if TRIALINFO.layOutType == 1
%     picLocations{7} = [];
%     picLocations{8} = [];
% elseif TRIALINFO.layOutType == 2
%     picLocations{7} = [];
%     picLocations{8} = [];
% end
end