%% Parameters file
% For the phs-contrast experimental task
% Project: ageing-and-neuropathy/phs

% where vars are defined
% Project: Implementation of Multidimensional TGI Threshold estimation
%
% Alexandra G. Mitchell
% Last edit: 22/01/24

%% folder information
project = vars.control.project;
datatype = 'beh';
task_name = 'phs_con';

% path to save data to - should be changed depending on laptop (VAS_loadParams.m)
datPath = vars.control.path;

if vars.control.tutorial
    vars.task.nTrialReps = 4; %for practise
else
    vars.task.nTrialReps = 8; %number of repetitions per condition (including catch trials)
end
    
%% select temperatures
if ~vars.control.tutorial %only during main task
    % based on thresholding! :)
    % find temperature thresholds
    temp_filename = fullfile(datPath, project, subject, session, datatype,...
        [subject '_' session '_' 'saved_thresholds.tsv']); % temperature file name

    % make array
    % if it does not, end
     if ~isfile(temp_filename)
         disp('No threshold temperatures found for this participant, will use default');
         ex_filename = fullfile(datPath, project, filesep, 'stimuli', ['example_saved_thresholds.csv']);
         vars.tempArray = readtable(ex_filename, "FileType","delimitedtext");
     else 
         %load the full stimulus array
         vars.tempArray = readtable(temp_filename, "FileType","delimitedtext");
     end
end
      
%% Length & Timing´
vars.task.toneIdx = 1; %indicate where tone should appear in TSL task
vars.task.nCond = 8; % number of conditions, change when determined
vars.task.TSLrep = 1;

if vars.control.tutorial
    vars.task.NTrialsTotal = 8; %short tutorial
else
    vars.task.NTrialsTotal = vars.task.nTrialReps*vars.task.nCond; % total trial number
end
%vars.task.NTrialsTotal = 5; % total trial number
vars.task.NTrialsChangeP = vars.task.NTrialsTotal;

% timing
vars.task.jitterT   = randInRange(0.01,0.5,[1,vars.task.NTrialsTotal]); % jitter the time between tone at 32 and temperature change
vars.task.feedbackTime       = 0.500; % this determines how long the feedbacks "button press detected" is shown on the screen
%vars.task.ITI                = 5 - (vars.task.jitter + vars.task.feedbackTime*2);
vars.task.longJittT = randInRange(1,3,[1,vars.task.NTrialsTotal]); %add a long jitter at the end of the trial

vars.task.vasType = [1 2 3 4]; 

% Response
if vars.control.tutorial
    vars.task.respTime = 30; %for practise
    vars.task.vasTime = 30;
else
    vars.task.respTime = 10; %N seconds participants have to respond, for binary questions
    vars.task.vasTime = 10; %short VAS
    vars.task.checkRespTime = 300; %they have five minutes for the end questions
end

vars.task.feedbackTime = 0.5;


%calculate total length of paradigm
vars.task.totTrialT = vars.task.TSLrep+(vars.task.respTime*2)+vars.task.vasTime;
%vars.task.duration = sum(vars.task.longJittT)+(vars.task.totTrialT)*(vars.nTrialReps*15);

%% Temperatures & stim
vars.temp.rate = 2.5;   % rate of temperature change, up here because I might change it
vars.temp.Tbaseline = 32;   % baseline temperature
%vars.temp.wait = 2.5; %how long to hold stimulation temperature constant for (currently 120s)
vars.temp.Ttol = .25;  % Temperature temperature reached if within range of this

%vars.temp.randTidx           = randperm(length(vars.temp.TwarmArray));
% change variables depending on design choice, to be fixed later

%vars.temp.TrampTol = 1; % temperature tolerance to flag ramp end (stimulation should vary less than tol every 100ms)
vars.temp.Tcheck = .100; %check temperatures every 200ms

vars.temp.coldLim = 0;
vars.temp.warmLim = 50;

vars.task.stimDur1 = .0001;
vars.task.stimDur2 = 1.5; %variable durations of peak stimulus

%% Psychtoolbox Display and Audio
vars.display.textSize = 20;
% Instructions
vars.display.instVas = []; % When to show VAS instructions - atm every trial
%vars.display.instProbe = 1:vars.task.NTrialsChangeP:vars.task.NTrialsTotal; % When to ask participant to change thermode position
%vars.intstructions

% define language - for testing always 1
if vars.control.language == 1
    English_instructions;
elseif vars.control.language == 2
    Danish_instructions;
end

% Audio
vars.audio.beepLength = .5; %250ms
vars.audio.beepPause = .05; %%50ms
vars.audio.nrchannels = 2;
vars.audio.sampRate = 48000;
vars.audio.repetitions = 1; % number of repetitions of the tone
vars.audio.start = 0; % start delay in secs, start immediately = 0
% Should we wait for the device to really start (1 = yes)
vars.audio.waitForDevice = 1;
