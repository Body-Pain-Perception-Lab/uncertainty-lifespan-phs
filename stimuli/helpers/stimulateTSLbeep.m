function [t, stimOn, stimEnd, tmaxT, tminT, resp] = stimulateTSLbeep(vars, tslType, tb, np, r, tone, sd, catchT, varargin)
%% TCS code to simulate a single TSL trial
% For the project: 

% tb = starting temperature (baseline)
% np = number of periods to iterate over
% r = ramp speed. This is set only for phases that require no response.
% Ramp speed of response phases set to 1deg/s
% tslType. 0 = standard (response always), 1 = response only on cold ramp,
% 2 = response only on hot ramp

% tone = presence of an auditory tone. If 0 = no tone, 1 = tone only on down ramp, 2 =
% tone only on up ramp, 3 = tone on both ramps

% sd - the amount of time the temperature is held at before falling/rising
% in seconds
% if not defined, default is 0

% catchT
% if this trial is a catch trial, then heat up after baseline

% varargins - options for setting maximum and minimum temperatures (ºC), if
% two, tmin should always be first
    % tmin
    % tmax
    
%% Plan
% start at baseline
% ramp up to tmax OR to button press
% then ramp down
% auditory tone at 32º on down ramp
% ramp down to tmin OR to button press

%% Set ramp speed & timing 
% if rate is empty, set as 1deg/s
if ~exist('r')
    r = 1;
end
rate = r;

% if duration is empty, set at 0
if ~exist('sd')
    sd = 0.001;
end

% if catch not defined, then 0
if ~exist('catchT')
    catchT = 0;
end

delayTime = 0.05; %set delay

% define keys
keys = keyConfig();

%% Set temperatures
% if tmax and tmin not defined then set 50º for max and 0º for min
% then don't forget to code in button press :)
if length(varargin) < 1
    tmax = 50;
    tmin = 0;
elseif length(varargin) < 2
    if varargin{1} < tb
        tmin = varargin{1};
        tmax = 50;
    else
        tmax = varargin{1};
        tmin = 0;
    end
else 
    tmin = varargin{1};
    tmax = varargin{2};
end

%% Set TCS
tcs = vars.ser;
%get into "follow mode":
TcsSetBaseLine(tcs, tb); %set baseline
TcsSetRampSpeed(tcs, repmat(rate, 1, 5)); % setting speed to this
% set stimulation zones on T11
% Select one within the 4 possibilities.
% this should remain the same for the whole 6 trials
possibilities = {[1 1 0 0 0],...
    [0 1 1 0 0],...
    [0 0 1 1 0],...
    [0 0 0 1 1]};
possibilities_idx = randi(4);
zones = possibilities{possibilities_idx};

nReps = 0; %rep counter

%% begin stimulation
trial = vars.control.thisTrial;
cpt = 0;
tic; %set start time

% set peak tcs temperatures
tcsTemperatures1(zones==0)= tb;
tcsTemperatures1(zones==1)= tmax;
%return temperatures
tcsTemperatures2 = repmat(tb,1,5);

% set trough temperatures
tcsTemperatures3(zones==0)= tb;
tcsTemperatures3(zones==1)= tmin;

% define initial target temperatures (peak)
targetT = tcsTemperatures1; %target temperatures for setting limits
tDist = targetT; %setting first tDist

% ramp rate - set depending on tsl type
if tslType == 0
    TcsSetRampSpeed(tcs, ones(1, 5)); %set to one deg/s anyway
else
    TcsSetRampSpeed(tcs, repmat(rate,1,5)); %set to predefined ramp speed
end

% set temperatures to initial
TcsSetTemperatures(tcs, targetT); 
% follow mode
TcsFollowMode(tcs);
stimOn = GetSecs();


while nReps < np %whilst the number of reps is less than np
    % other important things
    nReps = nReps + 1; %increase reps 
    % number of TSL steps to complete (starting at 1)
    nTSLsteps = 4; 
    peak_reached = 0;
    
    %% first we ramp up
    stim_idx = 1; %setting indicator for ramp direction (1 = up, 0 = down)
    
    % if necessary play auditory tone prior to ramping (so participants
    % know they can respond)
    
    % set up jitter
    % this varies the time between the button press and the point at
    % which the probe starts to change temperature
    if vars.control.jitterOn
       jitter = vars.task.jitterT(vars.control.thisTrial);          
    else
       vars.task.jitterTime = 0; %setting to 0, needed for sinW
    end
        
    switch tone
        case 2
            myBeep = MakeBeep(300, vars.audio.beepLength, vars.audio.sampRate);
            playAudio(vars,myBeep);
            resp.toneUp = GetSecs();
            WaitSecs(jitter);
        case 3
            myBeep = MakeBeep(300, vars.audio.beepLength, vars.audio.sampRate);
            playAudio(vars,myBeep);
            resp.toneUp = GetSecs();
            WaitSecs(jitter);
    end

    % stimulate until either tmax/min OR button press
    while stim_idx < nTSLsteps %keep looping until 4 steps of TSL are complete
        
        buttonPress = 0;
        cpt = cpt+1; %record count
        %  get TCS temperatures
        currentTemperatures = []; %create empty variable to reload

        currentTemperatures = TcsGetTemperatures(tcs); %get current temperature
        currentTime = toc; %get current time
        %time_sampled = toc(vars.control.startTask); %get time with respect to trigger
    
        if length(currentTemperatures) ~= 5
            currentTemperatures = repmat(NaN,1,5);
        end
    
        tDist = abs(currentTemperatures - targetT); %distance from probe temperature to targetT
        %disp(currentTemperatures); %disp current temperature
    
        if any(isnan(tDist))
            tDist = repmat(0.6,1,5);
        end

        % code in button press if tmax or tmin not set
        % can only read button press if this is the case
        if stim_idx == 1 %to tmax
            if isempty(varargin) || varargin{1} < tb
                % Check for button press
                [~, ~, keys.KeyCode] = KbCheck;
                WaitSecs(0.001);
    
                if keys.KeyCode(keys.Up) == 1 %if key
                    buttonPress = 1; %end ramp
                    resp.tMax = GetSecs();
                end
            end
            
        elseif stim_idx == 3 %to tmin
            if isempty(varargin) || varargin{1} >= tb
                % Check for button press
                [~, ~, keys.KeyCode] = KbCheck;
                WaitSecs(0.001);
    
                if keys.KeyCode(keys.Up) == 1 %if key
                    tMinTime = GetSecs();
                    buttonPress = 1; %end ramp
                end

            end
            
        end
        
        % record
        t(cpt, 1) = trial; %count trials    
        t(cpt, 2) = currentTime; %record current time
        t(cpt, 3:7) = currentTemperatures; %record temperatures in t
        %t(cpt, 8) = time_sampled; %time from trigger - to match MR data
        t(cpt, 8) = stim_idx; %code for whether probe has started to ramp up or down
        t(cpt, 9) = buttonPress; %get whether or not button was pressed at that timepoint

        % change ramp direction if
        if all(tDist <= vars.temp.Ttol) && peak_reached == 0 %if temperatures reached
            % set clock
            peak_reached = 1; %set to 1
            peakT = toc;
        end
        
        %alternating ramps
        switch stim_idx %depending on stage in tsl, make a different choice
            case 1 %end of up ramp
                if (peak_reached == 1 && sd <= currentTime - peakT) || buttonPress == 1
                    peak_reached = 0; %resetting
                    stim_idx = stim_idx + 1;
                    % set temperatures to baseline
                    tmaxT = GetSecs(); %get seconds of maximum temp
                    targetT = tcsTemperatures2;
                    % if tmax = baseline, then wait 2s
                    % this is to even out trial duration
                    if tmax == tb
                        WaitSecs(2);
                    end
                    if tslType == 2 %if response required at heat ramp
                        TcsSetRampSpeed(tcs, ones(1, 5)); % setting speed 1deg/s for response
                    end
                    TcsSetTemperatures(tcs, targetT);
                end
            case 2 %baseline before down ramp
                if peak_reached == 1 
                    peak_reached = 0; %resetting
                    %play auditory tone if coded
                    switch tone
                        case 1
                            myBeep = MakeBeep(500, vars.audio.beepLength, vars.audio.sampRate);
                            playAudio(vars,myBeep);
                            resp.toneDown = GetSecs();
                        case 3
                            myBeep = MakeBeep(500, vars.audio.beepLength, vars.audio.sampRate);
                            playAudio(vars,myBeep);
                            resp.toneDown = GetSecs();
                    end
                    % wait jitterd time
                    WaitSecs(jitter); %so tone is not associated with temperature drop
                    
                    % set tcs temperatures
                    %tcsTemperatures1(zones==0)= tb;
                    
                    if catchT == 0 %if this is not a catch trial, decrease as normal
                        tcsTemperatures3(zones==1)= tmin; % this also mean probe ramps up again if 0 reached
                        if tslType == 1 %if response required at cold ramp
                            TcsSetRampSpeed(tcs, ones(1, 5)); % setting speed 1deg/s for response
                        end
                    else % if it is a catch trial, increase
                        tcsTemperatures3(zones==1)= 50; %set limit to 50, in the hope that pp press the button before then!
                        if tslType == 1 %if response required at cold ramp
                            TcsSetRampSpeed(tcs, repmat(1.5,1,5)); % speed slightly higher for catch trials to be able to distinguish them less
                        end
                    end
                    
                    targetT = tcsTemperatures3;
                    
                    
                    TcsSetTemperatures(tcs, targetT);
                    
                    stim_idx = stim_idx + 1; 
                end
            case 3 %end of down ramp              
                if (peak_reached == 1 && sd <= currentTime - peakT) || buttonPress == 1
                    if ~exist('tMinTime')
                        resp.tMin = GetSecs();
                    else
                        resp.tMin = tMinTime;
                    end
                    
                    peak_reached = 0; %resetting
                    stim_idx = stim_idx + 1; 
                    
                    tminT = GetSecs(); %get seconds of minimum temp
                    targetT = tcsTemperatures2; %back to baseline
                    TcsSetTemperatures(tcs, targetT);
                end
                
        end %switch loop
    end %tsl loop
 
end

%quit "follow mode"
TcsSetBaseLine(tcs,tb) %setting everything back to baseline
stimEnd = GetSecs(); %stim off stamp
TcsAbortStimulation(tcs);


