function workingMem(subjectName,repetition,displayDuration,maxDifficulty,seedStr)
% coding for SH 9th people's hospital
% 
% By BYC 12-2019

difficultyCap = 5; % valid max difficulty

if nargin<1
    subjectName = 'test';
    testMode = 1;
else
    testMode = 0;
end
if nargin<2
    TRIALINFO.repetition = 5;
else
    TRIALINFO.repetition = repetition;
end
if nargin<3
    TRIALINFO.displayDuration = 3; % second
else
    TRIALINFO.displayDuration = displayDuration;
end
if nargin<4
    TRIALINFO.maxDifficulty = 5; % maximum 5 pictures
else
    if maxDifficulty > difficultyCap
        warning(['Currently, max difficulty was capped by' num2str(difficultyCap) '!'])
        maxDifficulty = difficultyCap;
    end
    TRIALINFO.maxDifficulty = maxDifficulty;
end

% random seed
if nargin >= 5
    if strcmp(seedStr,'shuffle') || strcmp(seedStr,'default')
        seed = seedStr;
    elseif ischar(seedStr)
        seed = str2double(seedStr);
    elseif isnumeric(seedStr)
        seed = seedStr;
    end
else
    seed = ceil(rand()*1000000);
end
rng(seed);

% path and file name
fileName = ['workingMemory_' subjectName '_' datestr(now,'yymmddHHMM')];
curdir = pwd;
saveDir = fullfile(pwd,'data');
mkdir(saveDir);

% key
KbName('UnifyKeyNames');
skipKey = KbName('Return'); % skip current trial
escape = KbName('ESCAPE'); % abort this block

% parameter
feedback = 1; % 1 to give feedback
feedbackDuration = 1; % second
showExplanation = 1;  % 1 to give explanation
explanation = '���ס���ֹ���ͼƬ����������˳������ѡ�����������';

% initial OpenGl
global GL;
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

PsychImaging('PrepareConfiguration');
PsychImaging('AddTask', 'General', 'FloatingPoint32BitIfPossible');
[win , winRect] = PsychImaging('OpenWindow', SCREEN.screenId);

Screen('ColorRange', win, 1, 0);

SCREEN.widthPix = winRect(3);
SCREEN.heightPix = winRect(4);
[SCREEN.center(1), SCREEN.center(2)] = RectCenter(winRect);

SCREEN.refreshRate = Screen('NominalFrameRate', SCREEN.screenId);
grayColor = GrayIndex(win);
redColor = [0.9 0.1 0.1];

Screen('FillRect', win, grayColor);

imgRate = 4;
imgSize1 = ceil(min(SCREEN.widthPix/(1+(1+imgRate)*ceil(TRIALINFO.maxDifficulty/2)),SCREEN.heightPix/(1+(1+imgRate)*2))*imgRate);
imgSize2 = ceil(min(SCREEN.widthPix/(1+(1+imgRate)*ceil(TRIALINFO.maxDifficulty/3)),SCREEN.heightPix/(1+(1+imgRate)*3))*imgRate);
if imgSize1>imgSize2
    layOutType = 1; % in one or two row
    imgSize = ceil(imgSize1/2)*2;
else
    layOutType = 2; % in 1-3 row
    imgSize = ceil(imgSize2/2)*2;
end

% read img source
imgFileName = {'bag.png','cake.png','chair.png','earphone.png', 'HDD.png', 'lipstick.png', 'microwave.png', 'pingpang.png', 'shoes.png', 'wine.png'};
img = cell(size(imgFileName));
imgT = cell(size(imgFileName));
for i = 1:length(imgFileName)
    [img{i},~,imgT{i}] = imread(fullfile(pwd,'sources',imgFileName{i}),'png');
    img{i} = imresize(img{i},[imgSize,imgSize],'nearest'); imgT{i} = ~imresize(imgT{i},[imgSize,imgSize],'nearest');
    Tindex(:,:,1) = imgT{i};Tindex(:,:,2) = imgT{i};Tindex(:,:,3) = imgT{i};
    img{i}(Tindex) = 255/2;
end
            
ShowCursor;

% set default text font, style and size,etc
Screen('TextFont',win, 'Tahoma');
Screen('TextStyle',win, 1); % 0=normal,1=bold,2=italic,4=underline,8=outline,32=condense,64=extend.

Screen('Flip',win);

% show explanation
if showExplanation
    explainImgName = {'1.png','2.png','blank.png'};
    explainImg = cell(size(explainImgName));
    for i = 1:length(explainImgName)
        [explainImg{i},~,~] = imread(fullfile(pwd,'sources',explainImgName{i}),'png');
        explainImg{i} = imresize(explainImg{i},[imgSize,imgSize],'nearest');
    end
    
    x1 = SCREEN.widthPix/2-imgSize/imgRate*(1+imgRate)-imgSize/2; x2 = SCREEN.widthPix/2-imgSize/imgRate*(1+imgRate)+imgSize/2; x3 = SCREEN.widthPix/2-imgSize/imgRate*(1+imgRate)+imgSize/2;x4 = SCREEN.widthPix/2-imgSize/imgRate*(1+imgRate)-imgSize/2;
    y1 = SCREEN.heightPix/4*3-imgSize/2; y2 = SCREEN.heightPix/4*3-imgSize/2; y3 = SCREEN.heightPix/4*3+imgSize/2; y4 = SCREEN.heightPix/4*3+imgSize/2;
    xyMetrix{1} = [x1,x2,x2,x3,x3,x4,x4,x1;y1,y2,y2,y3,y3,y4,y4,y1];
    expImgH{1} = Screen('MakeTexture', win, explainImg{1});
    
    x1 = SCREEN.widthPix/2-imgSize/2; x2 = SCREEN.widthPix/2+imgSize/2; x3 = SCREEN.widthPix/2+imgSize/2;x4 = SCREEN.widthPix/2-imgSize/2;
    y1 = SCREEN.heightPix/4*3-imgSize/2; y2 = SCREEN.heightPix/4*3-imgSize/2; y3 = SCREEN.heightPix/4*3+imgSize/2; y4 = SCREEN.heightPix/4*3+imgSize/2;
    xyMetrix{2} = [x1,x2,x2,x3,x3,x4,x4,x1;y1,y2,y2,y3,y3,y4,y4,y1];
    expImgH{2} = Screen('MakeTexture', win, explainImg{2});
    
    x1 = SCREEN.widthPix/2+imgSize/imgRate*(1+imgRate)-imgSize/2; x2 = SCREEN.widthPix/2+imgSize/imgRate*(1+imgRate)+imgSize/2; x3 = SCREEN.widthPix/2+imgSize/imgRate*(1+imgRate)+imgSize/2;x4 = SCREEN.widthPix/2+imgSize/imgRate*(1+imgRate)-imgSize/2;
    y1 = SCREEN.heightPix/4*3-imgSize/2; y2 = SCREEN.heightPix/4*3-imgSize/2; y3 = SCREEN.heightPix/4*3+imgSize/2; y4 = SCREEN.heightPix/4*3+imgSize/2;
    xyMetrix{3} = [x1,x2,x2,x3,x3,x4,x4,x1;y1,y2,y2,y3,y3,y4,y4,y1];
    expImgH{3} = Screen('MakeTexture', win, explainImg{3});

    explanationStep = 1;
    while 1
        [~, ~, keycode] = KbCheck;
        if keycode(skipKey)
            break;
        end
        
        if explanationStep<3
            Screen('TextSize',win,ceil(20/1280*SCREEN.widthPix));
            [~, ~, ~] = DrawFormattedText(win, explanation,'center',SCREEN.heightPix/4,[0.2 0.6 0.7]);
            Screen('TextBackgroundColor',win, grayColor);
            Screen('DrawTexture', win, expImgH{explanationStep}, [], [SCREEN.widthPix/2-imgSize/2,SCREEN.heightPix/4*3-imgSize/2,SCREEN.widthPix/2+imgSize/2,SCREEN.heightPix/4*3+imgSize/2],[],[],[]);
            Screen('DrawingFinished',win);
            Screen('Flip',win,0,0);
            WaitSecs(TRIALINFO.displayDuration);
        elseif explanationStep == 3
            expImgOrder = randperm(3);
            Screen('TextSize',win,ceil(20/1280*SCREEN.widthPix));
            [~, ~, ~] = DrawFormattedText(win, explanation,'center',SCREEN.heightPix/4,[0.2 0.6 0.7]);
            Screen('TextBackgroundColor',win, grayColor);
            Screen('DrawTexture', win, expImgH{expImgOrder(1)}, [], [SCREEN.widthPix/2-imgSize/imgRate*(1+imgRate)-imgSize/2,SCREEN.heightPix/4*3-imgSize/2,SCREEN.widthPix/2-imgSize/imgRate*(1+imgRate)+imgSize/2,SCREEN.heightPix/4*3+imgSize/2],[],[],[]);
            Screen('DrawTexture', win, expImgH{expImgOrder(2)}, [], [SCREEN.widthPix/2-imgSize/2,SCREEN.heightPix/4*3-imgSize/2,SCREEN.widthPix/2+imgSize/2,SCREEN.heightPix/4*3+imgSize/2],[],[],[]);
            Screen('DrawTexture', win, expImgH{expImgOrder(3)}, [], [SCREEN.widthPix/2+imgSize/imgRate*(1+imgRate)-imgSize/2,SCREEN.heightPix/4*3-imgSize/2,SCREEN.widthPix/2+imgSize/imgRate*(1+imgRate)+imgSize/2,SCREEN.heightPix/4*3+imgSize/2],[],[],[]);
            Screen('DrawingFinished',win);
            Screen('Flip',win,0,0);
            WaitSecs(TRIALINFO.displayDuration);
        elseif explanationStep == 4
            step4 = tic;
            showSquare = true;
            while toc(step4)<TRIALINFO.displayDuration
                Screen('TextSize',win,ceil(20/1280*SCREEN.widthPix));
                [~, ~, ~] = DrawFormattedText(win, explanation,'center',SCREEN.heightPix/4,[0.2 0.6 0.7]);
                Screen('TextBackgroundColor',win, grayColor);
                Screen('DrawTexture', win, expImgH{expImgOrder(1)}, [], [SCREEN.widthPix/2-imgSize/imgRate*(1+imgRate)-imgSize/2,SCREEN.heightPix/4*3-imgSize/2,SCREEN.widthPix/2-imgSize/imgRate*(1+imgRate)+imgSize/2,SCREEN.heightPix/4*3+imgSize/2],[],[],[]);
                Screen('DrawTexture', win, expImgH{expImgOrder(2)}, [], [SCREEN.widthPix/2-imgSize/2,SCREEN.heightPix/4*3-imgSize/2,SCREEN.widthPix/2+imgSize/2,SCREEN.heightPix/4*3+imgSize/2],[],[],[]);
                Screen('DrawTexture', win, expImgH{expImgOrder(3)}, [], [SCREEN.widthPix/2+imgSize/imgRate*(1+imgRate)-imgSize/2,SCREEN.heightPix/4*3-imgSize/2,SCREEN.widthPix/2+imgSize/imgRate*(1+imgRate)+imgSize/2,SCREEN.heightPix/4*3+imgSize/2],[],[],[]);
                
                if showSquare
                    exp1stImg = find(expImgOrder == 1);
                    Screen('DrawLines', win, xyMetrix{exp1stImg},8,redColor);
                end
                Screen('DrawingFinished',win);
                Screen('Flip',win,0,0);
                WaitSecs(0.5);
                showSquare = ~showSquare;
            end
        elseif explanationStep == 5
            step5 = tic;
            showSquare = true;
            while toc(step5)<TRIALINFO.displayDuration
                Screen('TextSize',win,ceil(20/1280*SCREEN.widthPix));
                [~, ~, ~] = DrawFormattedText(win, explanation,'center',SCREEN.heightPix/4,[0.2 0.6 0.7]);
                Screen('TextBackgroundColor',win, grayColor);
                Screen('DrawTexture', win, expImgH{expImgOrder(1)}, [], [SCREEN.widthPix/2-imgSize/imgRate*(1+imgRate)-imgSize/2,SCREEN.heightPix/4*3-imgSize/2,SCREEN.widthPix/2-imgSize/imgRate*(1+imgRate)+imgSize/2,SCREEN.heightPix/4*3+imgSize/2],[],[],[]);
                Screen('DrawTexture', win, expImgH{expImgOrder(2)}, [], [SCREEN.widthPix/2-imgSize/2,SCREEN.heightPix/4*3-imgSize/2,SCREEN.widthPix/2+imgSize/2,SCREEN.heightPix/4*3+imgSize/2],[],[],[]);
                Screen('DrawTexture', win, expImgH{expImgOrder(3)}, [], [SCREEN.widthPix/2+imgSize/imgRate*(1+imgRate)-imgSize/2,SCREEN.heightPix/4*3-imgSize/2,SCREEN.widthPix/2+imgSize/imgRate*(1+imgRate)+imgSize/2,SCREEN.heightPix/4*3+imgSize/2],[],[],[]);
                Screen('DrawLines', win, xyMetrix{exp1stImg},8,redColor);
                
                if showSquare
                    exp2ndImg = find(expImgOrder == 2);
                    Screen('DrawLines', win, xyMetrix{exp2ndImg},8,redColor);
                end
                Screen('DrawingFinished',win);
                Screen('Flip',win,0,0);
                WaitSecs(0.5);
                showSquare = ~showSquare;
            end
        else
            Screen('TextSize',win,ceil(20/1280*SCREEN.widthPix));
            [~, ~, ~] = DrawFormattedText(win, explanation,'center',SCREEN.heightPix/4,[0.2 0.6 0.7]);
            Screen('TextBackgroundColor',win, grayColor);
            
            Screen('TextSize',win,ceil(40/1280*SCREEN.widthPix));
            [~, ~, ~] = DrawFormattedText(win, '�ش���ȷ��','center',SCREEN.heightPix/4*3,[0.2 0.8 0.2]);
            Screen('TextBackgroundColor',win, grayColor);
            Screen('DrawingFinished',win);
            Screen('Flip',win,0,0);
            WaitSecs(TRIALINFO.displayDuration);
        end
        explanationStep = explanationStep+1;
        if explanationStep > 6
            explanationStep = 1;
        end
    end
end

trialIndex = 1:TRIALINFO.maxDifficulty;
trialOrder = sort(repmat(trialIndex,1,TRIALINFO.repetition));
breakFlag = 0;
correctOrder = cell(TRIALINFO.repetition*TRIALINFO.maxDifficulty,1);

for triali = 1:length(trialOrder)
    
end