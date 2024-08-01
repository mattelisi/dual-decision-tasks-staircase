% Clear the workspace
close all;
clear;
sca;

% add custom functions 
addpath('functions');

%----------------------------------------------------------------------
%                       Collect information
%----------------------------------------------------------------------
sj.subjectID=input('participantID: ','s');
sj.subjectAge=input('participant age: ','s');
sj.subjectGender=input('participant gender: ','s');

%----------------------------------------------------------------------
%                       Display settings
%----------------------------------------------------------------------

scr.subDist = 65;   % subject distance (cm)
scr.width   = 310;  % monitor width (mm)

%----------------------------------------------------------------------
%                       Task settings
%----------------------------------------------------------------------

iti = 1; % inter trial interval
n_trials = 250;
n_trials_practice = 5;
collect_confidence = [0, 0]; % if you want also self-report ratings after each decision [1, 2]

% do you want grount truth based on calories on plate (less stimuli)
% or based on the calories per 100g serving?
total_plate = 1;

%----------------------------------------------------------------------
%                       Initialize PTB
%----------------------------------------------------------------------

% Setup PTB with some default values
PsychDefaultSetup(2);

% Skip sync tests for demo purposes only
Screen('Preference', 'SkipSyncTests', 2);

% Seed the random number generator. Here we use the an older way to be
% compatible with older systems. Newer syntax would be rng('shuffle'). Look
% at the help function of rand "help rand" for more information
rand('seed', sum(100 * clock));

% Set the screen number to the external secondary monitor if there is one
% connected
scr.screenNumber = max(Screen('Screens'));

% Define black, white and grey
visual.white =255; % WhiteIndex(screenNumber);
visual.grey = floor(255/2);% visual.white / 2;
visual.black = 0;  % BlackIndex(screenNumber);
visual.bgColor = visual.grey;

% Open the screen
%[scr.window,  scr.windowRect] = PsychImaging('OpenWindow', scr.screenNumber, visual.grey/255, [0 0 1920 1200], 32, 2); % debug
[scr.window, scr.windowRect] = PsychImaging('OpenWindow', scr.screenNumber, visual.grey/255, [], 32, 2);

% Flip to clear
Screen('Flip',  scr.window);

% Query the frame duration
ifi = Screen('GetFlipInterval',  scr.window);

% Set the text size
Screen('TextSize', scr.window, 60);

% Query the maximum priority level
topPriorityLevel = MaxPriority( scr.window);

% Get the centre coordinate of the window
[scr.xCenter, scr.yCenter] = RectCenter(scr.windowRect);

% Get the heigth and width of screen [pix]
[scr.xres, scr.yres] = Screen('WindowSize',  scr.window); 

% Set the blend funciton for the screen
Screen('BlendFunction',  scr.window, 'GL_SRC_ALPHA', 'GL_ONE_MINUS_SRC_ALPHA');

%----------------------------------------------------------------------
%                       Stimuli
%----------------------------------------------------------------------
ppd = va2pix(1,scr); % pixel per degree
visual.ppd  = ppd;

visual.textSize = round(0.5*ppd);

% stimulus size and ececntricity
% img origina lsize 3872 x 2592 (food)
% height is 0.6694 times width
visual.stim_size = 4*ppd;
visual.stim_ecc = 4*ppd;
visual.stim_rects = [CenterRectOnPoint([0,0, visual.stim_size, round(0.6694*visual.stim_size)], scr.xCenter-visual.stim_ecc, scr.yCenter)', ...
    CenterRectOnPoint([0,0, visual.stim_size, round(0.6694*visual.stim_size)], scr.xCenter+visual.stim_ecc, scr.yCenter)'];

% placeholder locations
visual.dots_dy = (visual.stim_size/2)*1.05;
visual.dots_xy = [scr.xCenter-visual.stim_ecc, scr.xCenter+visual.stim_ecc; ...
    scr.yCenter-visual.dots_dy, scr.yCenter-visual.dots_dy];

visual.dots_col_1 =(visual.white/255)/3;
visual.dots_col_2 = ([246, 14,0; 0 160 0]'/255);
visual.dots_size = 20;

visual.names_locations = [scr.xCenter-visual.stim_ecc, scr.yCenter+round(visual.stim_size/2);...
    scr.xCenter+visual.stim_ecc, scr.yCenter+round(visual.stim_size/2)];

% load list of countries
parent_dir = pwd;
if IsWin 
    if total_plate
        data_food = readtable([parent_dir '\food_data/all_onplate_food.csv']);
    else
        data_food = readtable([parent_dir '\food_data/all_food.csv']);
    end
    flags_path = [parent_dir '\food_data\F4H_Collection_Food_Images_n377\'];
else
    if total_plate
        data_food = readtable([parent_dir '/food_data/all_onplate_food.csv']);
    else
        data_food = readtable([parent_dir '/food_data/all_food.csv']);
    end
    flags_path = [parent_dir '/food_data/F4H_Collection_Food_Images_n377/'];
end

nFood = size(data_food,1);
% Preallocate memory for food_pairs
% Total pairs = n*(n-1)/2 (since we are avoiding duplicate pairs)
totalPairs = nFood * (nFood - 1) / 2;
food_pairs = cell(totalPairs, 7);

pairCounter = 1;
for i = 1:nFood
    for j = i+1:nFood  % Start j from i+1 to avoid duplicates
        food1 = data_food.Name{i};
        img1 = data_food.image{i};
        if total_plate
            nrg1 = data_food.Total_energy_on_plate(i);
        else
            nrg1 = data_food.Energy_per_100g(i);
        end

        food2 = data_food.Name{j};
        img2 = data_food.image{j};
        if total_plate
            nrg2 = data_food.Total_energy_on_plate(j);
        else
            nrg2 = data_food.Energy_per_100g(j);
        end

        % Store the details in the preallocated array
        if nrg1>nrg2
            food_pairs{pairCounter, 1} = food1;
            food_pairs{pairCounter, 2} = img1;
            food_pairs{pairCounter, 3} = log(nrg1);
            food_pairs{pairCounter, 4} = food2;
            food_pairs{pairCounter, 5} = img2;
            food_pairs{pairCounter, 6} = log(nrg2);
            food_pairs{pairCounter, 7} = abs(log(nrg1) - log(nrg2));
        else
            food_pairs{pairCounter, 1} = food2;
            food_pairs{pairCounter, 2} = img2;
            food_pairs{pairCounter, 3} = log(nrg2);
            food_pairs{pairCounter, 4} = food1;
            food_pairs{pairCounter, 5} = img1;
            food_pairs{pairCounter, 6} = log(nrg1);
            food_pairs{pairCounter, 7} = abs(log(nrg2) - log(nrg1));
        end
        
        pairCounter = pairCounter + 1;
    end
end

% histogram(([food_pairs{:,7}]))
% scatter([food_pairs{:,3}], [food_pairs{:,6}])
% hold on
% plot([1 10],[1 10],'-b')
% hold off

% all([food_pairs{:,3}]>[food_pairs{:,6}])% OK

% Sort the food_pairs array based on the 7th column (absolute log difference)
% in ascending order
food_pairs = sortrows(food_pairs, 7);

% staircase settings
lfc_step = 0.5; % initial stepsize, get halved twice after 10 trials
lfc_diff = 1 + randn(1)*0.125; % randomized initial value

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
datFid = fopen([resultsDir sj.subjectID], 'w');
fprintf(datFid, 'date\tid\tage\tgender\ttrial\tdecision\tfood_1\tlog_cal_1\tfood_2\tlog_cal_2\trr\taccuracy\tRT\tconf\tconf_RT\n');

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
    
    % -----
    % select stimuli
    [pair1, ~] = selectByDifficulty(food_pairs, 4 + randn(1)*0.1);
    [pair2, ~] = selectByDifficulty(food_pairs, 4 + randn(1)*0.1);
    
    % run trials
    [~, ~, first_correct, second_correct] = runSingleTrial(scr, visual, pair1, pair2, flags_path, leftKey, rightKey, collect_confidence);
    
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

all_answers = [];

% Animation loop: we loop for the total number of trials
for t = 1:n_trials
    
    % -----
    % select stimuli
    [pair1, food_pairs] = selectByDifficulty(food_pairs, lfc_diff);
    [pair2, food_pairs] = selectByDifficulty(food_pairs, lfc_diff);
    
    % run trials
    [dataline1, dataline2, first_correct, second_correct] = runSingleTrial(scr, visual, pair1, pair2, flags_path, leftKey, rightKey, collect_confidence);
    
    % UPDATE STAIRCASE SETTING %-------------------------------------
    lfc_range = [min([food_pairs{:,7}]), max([food_pairs{:,7}])];
    if  first_correct==1
        lfc_diff = lfc_diff-lfc_step;
        if lfc_diff < lfc_range(1)
            lfc_diff=lfc_range(1);
        end
    elseif first_correct==0
        lfc_diff = lfc_diff+3*lfc_step;
        if lfc_diff > lfc_range(2)
            lfc_diff=lfc_range(2);
        end
    end
    
    % adjust step
    if(lfc_step==0.5 && t>=10)
        lfc_step = lfc_step/2;
    elseif(lfc_step==0.5/2 && t>=20)
        lfc_step = lfc_step/2;
    end
    
    % write data to file
    dataline1 = sprintf('%s\t%s\t%s\t%s\t%i\t%s', date, sj.subjectID, sj.subjectAge, sj.subjectGender, t, dataline1);
    fprintf(datFid, dataline1);
    
    dataline2 = sprintf('%s\t%s\t%s\t%s\t%i\t%s', date, sj.subjectID, sj.subjectAge, sj.subjectGender, t, dataline2);
    fprintf(datFid, dataline2);
    
    % keep track of accuracy for final feedback
    all_answers = [all_answers, first_correct, second_correct];
    
    if mod(t,50)==0
        
        break_message = sprintf('Need a break? \n\n\n You have completed %i out of %i total trials. \n\n\n\n\n Press any key to continue.', t, n_trials);
        
        DrawFormattedText(scr.window, break_message,'center', 'center', visual.black);
        Screen('Flip', scr.window);
        KbStrokeWait
    else
        Screen('Flip', scr.window);
        WaitSecs(iti);
    end
        
end

% close data file
fclose(datFid);

% End of experiment screen. We clear the screen once they have made their
% response
message_string = ['Experiment Finished! \n\n Your final score is ', num2str(sum(all_answers)), ' out of ', num2str(length(all_answers)), '. \n\n Press Any Key To Exit'];
DrawFormattedText(scr.window, message_string,...
    'center', 'center', visual.black);
Screen('Flip', scr.window);
KbStrokeWait;
sca;
fprintf('%s\n',message_string);

% save also into a text file
total_score = sum(all_answers);
file_name = sprintf('%s_score.txt', sj.subjectID);
file_id = fopen(file_name, 'w');
fprintf(file_id, '%i\n', total_score);
fclose(file_id);
