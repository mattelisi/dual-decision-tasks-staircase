% Clear the workspace
close all;
clear;
sca;

% add custom functions 
addpath('functions');

% Seed the random number generator. Here we use the an older way to be
% compatible with older systems. Newer syntax would be rng('shuffle'). Look
% at the help function of rand "help rand" for more information
rand('seed', sum(100 * clock));

%----------------------------------------------------------------------
%                       Collect information
%----------------------------------------------------------------------
subjectID=input('participantID: ','s');
subjectAge=input('participant age: ','s');
subjectGender=input('participant gender: ','s');

%----------------------------------------------------------------------
%                 Prepare for saving data
%----------------------------------------------------------------------

% Make a directory for the results
if IsWin
    resultsDir = [pwd '\data\'];
    if exist(resultsDir, 'dir') < 1
        mkdir(resultsDir);
    end
else
    resultsDir = [pwd '/data/'];
    if exist(resultsDir, 'dir') < 1
        mkdir(resultsDir);
    end
end

% prep data header
datFid = fopen([resultsDir subjectID], 'w');
fprintf(datFid, 'id\tage\tgender\ttrial\tdecision\tn_left\tn_right\tside\tresponse\taccuracy\tRT\tconf\tconf_RT\tvoid\n');
    
%----------------------------------------------------------------------
%                       Display settings
%----------------------------------------------------------------------

scr.subDist = 65;   % subject distance (cm)
scr.width   = 310;  % monitor width (mm)

%----------------------------------------------------------------------
%                       Task settings
%----------------------------------------------------------------------

soa_range = [0.4, 0.6];
iti = 1; % inter trial interval
n_trials = 250; % it should be divisible by 5
n_trials_practice = 10;

% if you want also self-report ratings after each decision [1, 2]
collect_confidence = [0, 0]; 

%----------------------------------------------------------------------
%                       Initialize PTB
%----------------------------------------------------------------------

% Setup PTB with some default values
PsychDefaultSetup(2);

% Skip sync tests for demo purposes only
Screen('Preference', 'SkipSyncTests', 2);

% Set the screen number to the external secondary monitor if there is one
% connected
screenNumber = max(Screen('Screens'));

% Define black, white and grey
visual.white =255;%WhiteIndex(screenNumber);
visual.grey = floor(255/2);%visual.white / 2;
visual.black = 0; %BlackIndex(screenNumber);
visual.bgColor = visual.grey;
visual.fixColor = 170/255;

% Open the screen
%[scr.window, scr.windowRect] = PsychImaging('OpenWindow', screenNumber, visual.grey/255, [0 0 1920 1200], 32, 2); % debug
%[scr.window, scr.windowRect] = PsychImaging('OpenWindow', screenNumber, visual.grey/255, [1920 0 3840 1080], 32, 2); % debug
[scr.window, scr.windowRect] = PsychImaging('OpenWindow', screenNumber, visual.grey/255, [], 32, 2);

% Flip to clear
Screen('Flip', scr.window);

% Query the frame duration
ifi = Screen('GetFlipInterval', scr.window);
scr.ifi = ifi;

% Set the text size
Screen('TextSize', scr.window, 60);

% Query the maximum priority level
topPriorityLevel = MaxPriority(scr.window);

% Get the centre coordinate of the scr.window
[scr.xCenter, scr.yCenter] = RectCenter(scr.windowRect);

% Get the heigth and width of screen [pix]
[scr.xres, scr.yres] = Screen('WindowSize', scr.window); 

% Set the blend funciton for the screen
Screen('BlendFunction', scr.window, 'GL_SRC_ALPHA', 'GL_ONE_MINUS_SRC_ALPHA');

%----------------------------------------------------------------------
%                       Stimuli
%----------------------------------------------------------------------
ppd = va2pix(1,scr); % pixel per degree
visual.ppd  = ppd;

visual.textSize = round(0.5*ppd);

% fixation
visual.fix_size = 0.1*ppd;

% stimulus size and ececntricity
visual.stim_size = 4*ppd;
visual.stim_ecc = 4*ppd; %2.25*ppd;
visual.stim_rects = [CenterRectOnPoint([0,0, visual.stim_size, visual.stim_size], scr.xCenter-visual.stim_ecc, scr.yCenter)', ...
    CenterRectOnPoint([0,0, visual.stim_size, visual.stim_size], scr.xCenter+visual.stim_ecc, scr.yCenter)'];

% stimulus duration
visual.stim_dur = 0.5;

% placeholder locations
visual.dots_dy = (visual.stim_size/2)*1.5;
visual.dots_xy = [scr.xCenter-visual.stim_ecc, scr.xCenter+visual.stim_ecc; ...
    scr.yCenter-visual.dots_dy, scr.yCenter-visual.dots_dy];

visual.dots_col_1 =(visual.white/255)/3;
visual.dots_col_2 = ([246, 14,0; 0 160 0]'/255);
visual.dots_size = 20;

% stim dots parameters

visual.stim_pen_width = 1;
visual.inner_circle = round(visual.stim_size * 0.95);
visual.stim_dotsize = 0.08;
visual.stim_dotcolor = [visual.black, visual.black, visual.black, 0.65];
visual.stim_centers = [scr.xCenter-visual.stim_ecc, scr.yCenter;...
    scr.xCenter+visual.stim_ecc, scr.yCenter];

visual.ndots_ref = 50;
visual.ndots_dif_range = [1, 50];

% visual.ndots_range = [];
%
% visual.ndots_LR_range = [0.05, 2];
% visual.ndots_LR_step = 0.04;
% % diff((25:75) ./ (75:-1:25))


% p.stim.inner_circle % Diameter of the circle relative to the screen
% p.stim.dotsize      % circle size
% p.fov % min(p.frame.size) size of diaply?
% p.stim.centers
% 
% p.frame.ptr % window pointer
% p.white % white index for dots - but we'll make them black I think
% p.stim.rectL % boundiong bozes of left and right circles 
% p.stim.rectR 
% p.stim.pen_width %
% p.stim.dotsize      % circle size
% p.stim.inner_circle % Diameter of the circle relative to the screen
% p.fov % min(p.frame.size) size of diaply?
% p.stim.centers % [p.stim.rect(:,3)+p.stim.rect(:,1) p.stim.rect(:,4)+p.stim.rect(:,2)]/2;
% % % Points' number reference
% p.stim.REF = 50;
% % Size of the dots:
% p.stim.dotsize = 0.03;

%----------------------------------------------------------------------
%                       Keyboard information
%----------------------------------------------------------------------

% Define the keyboard keys that are listened for. We will be using the left
% and right arrow keys as response keys for the task and the escape key as
% a exit/reset key
KbName('UnifyKeyNames')
escapeKey = KbName('ESCAPE');
leftKey = KbName('LeftArrow');
rightKey = KbName('RightArrow');


%----------------------------------------------------------------------
%                       Practice trials
%----------------------------------------------------------------------

DrawFormattedText(scr.window, 'Welcome to our experiment \n\n \n\n Press any key to start the practice',...
    'center', 'center', visual.black);
Screen('Flip', scr.window);
WaitSecs(0.2);
KbStrokeWait;

HideCursor; % hide mouse cursor


for t = 1:n_trials_practice
    
    % run trials
    d_i = randi([10, 50],1,1);
    [~, ~, first_correct, second_correct] = runSingleTrial(scr, visual, leftKey, rightKey, soa_range, d_i , collect_confidence);
    
    Screen('Flip', scr.window);
    
    % feedback
    if first_correct==1 && second_correct==1
        DrawFormattedText(scr.window, 'Well done! both answers were correct. \n Press a key to continue',...
            'center', 'center', visual.black);
        Screen('Flip', scr.window);
        KbStrokeWait;
        
    elseif first_correct==1 && second_correct==0
        
        DrawFormattedText(scr.window, 'The 1st answer was correct, but you made an error in the 2nd. \n Press a key to continue',...
            'center', 'center', visual.black);
        Screen('Flip', scr.window);
        KbStrokeWait;
        
    elseif first_correct==0 && second_correct==1
        
        DrawFormattedText(scr.window, 'The 2nd answer was correct, but you made an error in the 1st. \n Press a key to continue',...
            'center', 'center', visual.black);
        Screen('Flip', scr.window);
        KbStrokeWait;
    
    elseif first_correct==0 && second_correct==0
        
        DrawFormattedText(scr.window, 'Both answers were wrong... \n Press a key to continue',...
            'center', 'center', visual.black);
        Screen('Flip', scr.window);
        KbStrokeWait;
        
    end
        
end

%----------------------------------------------------------------------
%                       Experimental loop
%----------------------------------------------------------------------

DrawFormattedText(scr.window, 'Practice finished! \n\n Press any key to begin the experiment \n\n From now on giving correct answers will increase your chance of winning the prize.',...
    'center', 'center', visual.black);
Screen('Flip', scr.window);
KbStrokeWait;

HideCursor; % hide mouse cursor
ACC = [];

% Staircase settings
d_i = 20;
d_step = 2;

% Animation loop: we loop for the total number of trials
for t = 1:n_trials
    
    [dataline1, dataline2, first_correct, second_correct] = runSingleTrial(scr, visual, leftKey, rightKey, soa_range, d_i, collect_confidence);
    ACC = [ACC, first_correct, second_correct];
    
    % UPDATE STAIRCASE SETTING %-------------------------------------
    if  first_correct==1
        d_i = d_i-d_step;
        if d_i<visual.ndots_dif_range(1)
            d_i=visual.ndots_dif_range(1);
        end
    elseif first_correct==0
        d_i = d_i+3*d_step;
        if d_i > visual.ndots_dif_range(2)
            d_i = visual.ndots_dif_range(2);
        end
    end
    
    % adjust step
    if(d_step==2 && t>=20)
        d_step = 1;
    end
    
    % save data
    dataline1 = sprintf('%s\t%s\t%s\t%i\t%s\t%i\n', subjectID, subjectAge, subjectGender, t, dataline1, 0);
    fprintf(datFid, dataline1);
    
    dataline2 = sprintf('%s\t%s\t%s\t%i\t%s\t%i\n', subjectID, subjectAge, subjectGender, t, dataline2, 0);
    fprintf(datFid, dataline2);
    
    %Screen('FillOval', scr.window, visual.black, CenterRectOnPoint([0,0, round(visual.fix_size), round(visual.fix_size)], scr.xCenter, scr.yCenter));
    %Screen('DrawDots', scr.window, visual.dots_xy, visual.dots_size, visual.dots_col_1, [], 2);
    %Screen('Flip', scr.window);
    %WaitSecs(iti);
    
    if mod(t,50)==0
        
        break_message = sprintf('Need a break? \n\n\n You have completed %i out of %i total trials. \n\n\n\n\n Press any key to continue.', t, n_trials);
        
        DrawFormattedText(scr.window, break_message,'center', 'center', visual.black);
        Screen('Flip', scr.window);
        KbStrokeWait;
    else
        Screen('FillOval', scr.window, visual.fixColor, CenterRectOnPoint([0,0, round(visual.fix_size), round(visual.fix_size)], scr.xCenter, scr.yCenter));
        Screen('Flip', scr.window);
        WaitSecs(iti);
    end
        
end

% close data file
fclose(datFid);


% End of experiment screen. We clear the screen once they have made their
% response
message_string = ['Experiment Finished! \n\n Your score for this part is ', num2str(sum(ACC )), ' out of ', num2str(length(ACC )), '. \n\n Press Any Key To Exit'];
DrawFormattedText(scr.window, message_string,...
    'center', 'center', visual.black);
Screen('Flip', scr.window);

% -------------------------------------------------------------------------
% goodbye
KbStrokeWait;
sca;

% print score on command window
fprintf('%s\n',message_string);

% save also into a text file
total_score = sum(ACC);
file_name = sprintf('%s_score.txt', subjectID);
file_id = fopen(file_name, 'w');
fprintf(file_id, '%i\n', total_score);
fclose(file_id);
