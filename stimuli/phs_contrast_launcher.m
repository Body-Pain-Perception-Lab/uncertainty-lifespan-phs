%% phs_contrast launcher code
% launches phs_contrast_main(vars).m from the ageing and neuropathy project

%% Variables and set-up
clear all
close all

% add helpers to the path
vars.control.language = 1; %1 - english, 2 - danish (test mode always 1)
vars.control.inputDevice = 1; %1 for keyboard or response box
vars.control.jitterOn = 1; %jitter stim? added to test design

vars.control.devFlag = 0; %development mode?
vars.control.stimFlag = 1; %stimulator on and connected?

vars.control.os = 3; %operating for storage system, 1 = mac, 2 = windows, 3 = hyades

%% Paths
% path depends on operating system
switch vars.control.os
    case 1 %mac
        vars.control.path = '/Users/au706616/Documents/Experiments/';
        vars.control.project = 'ageing-and-neuropathy';
        vars.control.git = '/Users/au706616/Documents/Git/ageing-and-neuropathy/PHS/';
    case 2 %windows
        vars.control.path = 'C:\Users\stimuser\Documents\';
        vars.control.project = 'ageing-and-neuropathy';
        vars.control.git = fullfile(vars.control.path, 'Git\ageing-and-neuropathy\PHS');
    case 3 %hyades
        vars.control.path = 'C:\Users\stimuser\Documents\';
        vars.control.project = 'ageing-and-neuropathy'; %define project for path
        vars.control.git = fullfile(vars.control.path, vars.control.project, filesep, 'stimuli', filesep, 'PHS');
end

% add helper files
addpath(genpath(fullfile(vars.control.git, filesep, 'helpers')));
addpath(genpath(fullfile(vars.control.path, filesep, vars.control.project,...
    filesep, 'stimuli', filesep, 'LibTcsMatlab2021a')));

% Participant information
if ~vars.control.devFlag
   %  input participant number (and any other info)
    vars.control.info = string(inputdlg({'Participant ID:','Session:','Language:'},...
            'Session information', [1 30; 1 10;1 10]));
    vars.control.ID = vars.control.info(1); %get participant ID
    vars.control.ses_n = vars.control.info(2); %session N
    vars.control.language = str2double(vars.control.info(3));

    vars.control.pp = 1;
    % make a folder with participant ID
else %debug mode
     vars.control.ID = '8888';
     vars.control.ses_n = '1';
     vars.control.pp = 0;
end

% for saving
subject = ['sub-' sprintf('%04s', vars.control.ID)]; % Define subject 
session = ['ses-' sprintf('%02s', vars.control.ses_n)]; % Define session

vars.control.taskname = 'phs_con';    
vars.control.datatype = 'beh';

% participant folder
% Create BIDs folder for subject
bidsfolder(vars.control.path, vars.control.project, ...
    vars.control.ID, vars.control.ses_n, vars.control.datatype, vars.control.taskname) % check/make BIDS folders

% Reseed the random-number generator
SetupRand;

%% Run practise session
% first, ask if tutorial should be run
% only ask this for the first run
tutQ = input('Do you want to run a practise? 1-yes, 0-no ');
if tutQ
    vars.control.tutorial = 1;
else
    vars.control.tutorial = 0;
end
% load parameters - some are specific to tutorial
task_loadParams;

% Define task specific vars
if vars.control.tutorial
    % run practice, no need to save
    phs_contrast_tutorial(vars)
    mainT = input('Tutorial over, do you want to continue to the main task? 1-yes, 0-no ');
    if mainT == 0
        return
    end
end

%% Run experiment
% task
vars.control.tutorial = 0; %set back to 0
% load parameters - some are specific to tutorial
task_loadParams;

vars.control.startTask = tic;           % task start time
phs_contrast_main(vars);            % task script
endTask = toc(vars.control.startTask);  % task end time
disp(['Task duration: ', num2str(round(endTask/60,1)), ' minutes']) % task duration

% Restore path
cd(vars.control.git)
