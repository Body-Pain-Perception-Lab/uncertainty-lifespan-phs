function [t, stimOn, stimOff, stimEnd, startRampT, sin_peakT, dm_temps]...
    = stimulateSinW(vars, type, p, np, r, sw, varargin)
% TCS code to simulate a sinwav function
% For the project: MINDLAB2022_MR-SensCogThermPercep

% varargins:
    % t1 = first temperature
    % t2 = second temperature (if TGI)
    % tb = baseline temperature
% p = period duration (s)
% np = number of periods to iterate over
% r = option to enter ramp speed
% sw = stimulus wait time (s), if you want stim to paus at t1 for a duration, default = 0

%% Set temperatures
if length(varargin) < 2
    t1 = varargin{1}; %warm or cold temperature
    t2 = vars.temp.Tbaseline; %setting to baseline
else
    t1 = varargin{1};
    t2 = varargin{2};
end
% baseline
tb = vars.temp.Tbaseline; 

%% Set ramp speed & timing 
first_rampT = p/2; % end of first ramp from t1 to t2 (1/2 the sinusoid), from start
%second_rampT = 24; % timepoint of end of second ramp (t1 - t2) from start
sin_dur = p; %total length of sinusoid

if ~exist('r') % if no rampspeed input, calculate based on delta and duration
    if type < 3 % if not TGI
        delta = abs(tb - t1);
        % also, divide by slightly shorter ramp (~15s) incase speed needs to be
        % rounded down - better to be faster than slower (imo)
        rate = round(delta/(sin_dur/2.1), 1);
    else 
        % calculate delta seperately for cold and warm, then get maxmimum
        dC = abs(tb - t1);
        dw = abs(tb - t2);
        delta = max(dC, dW);
        % then calculate rate from max delta
        rate = round(delta/(sin_dur/2.1), 1);
    end
else
    rate = r; 
end

% stimulus wait time, setting to 0 if it does not exist
if ~exist('sw')
    sw = 0;
end

% jitter time
jitter = vars.task.jitterT;

% figure out timing of stimuli
% switch type
%     case 0 %cold
%         d = t2 - t1;
%         predStimP = (d/rate)+(sw/2); %predicted stimulus peak
%         delayTime = (p/2) - predStimP; 
%     case 1 %warm
%         d = t1 - t2;
%         predStimP = (d/rate)+(sw/2); %predicted stimulus peak
%         delayTime = (p/2) - predStimP; 
%     case 2 %tgi
%         dC = tb - t1;
%         dW = t2 - tb;
%         % calculate stim peak time for each temperature
%         predStimP_c = (dC/rate)+(sw/2);
%         predStimP_w = (dW/rate)+(sw/2);
%         % then delay for each temperature
%         delayTime_c = (p/2) - predStimP_c;
%         delayTime_w = (p/2) - predStimP_w;
%         % which time is longer?
%         if delayTime_c < delayTime_w
%             cold_first = 1;
%         else
%             cold_first = 0;
%         end
%         % then calculate difference
%         %delayTime = (p/2) - predStimP_c;
%     case 3
%         d = 0.3; %minimum difference
%         predStimP = (d/rate)+(sw/2); %predicted stimulus peak
%         delayTime = (p/2) - predStimP; 
% end

delayTime = 0.05; %set delay

%% set zones
% switch between warm, cold and TGI stim
% change location of the stimulation
% switch between warm, cold and TGI stim
switch type
    case 1 % Cold. Select one within the 4 possibilities.
        possibilities = {[1 1 0 0 0],...
            [0 1 1 0 0],...
            [0 0 1 1 0],...
            [0 0 0 1 1]};
        possibilities_idx = randi(4);
        zones = possibilities{possibilities_idx};
        tcsTemperatures1 = single(zones);
        tcsTemperatures1(tcsTemperatures1==0)= t2;
        tcsTemperatures1(tcsTemperatures1==1)= t1;
        
    case 2 % Warm. Selct one within the 3 possibilities
        possibilities = {[1 1 0 0 0],...
            [0 1 1 0 0],...
            [0 0 1 1 0],...
            [0 0 0 1 1]};
        possibilities_idx = randi(4);
        zones = possibilities{possibilities_idx};
        tcsTemperatures1 = single(zones);
        tcsTemperatures1(tcsTemperatures1==0)= t2;
        tcsTemperatures1(tcsTemperatures1==1)= t1;
        
    case 3 % TGI. Only one possibility
       %NEEDS TO BE CHANGED
       % possibilities = {[1 0 1 0 0],...
       %     [0 1 0 1 0]
        zones = possibilities;
        tcsTemperatures1 = possibilities*t2;
        tcsTemperatures1(tcsTemperatures1==0) = t1;
        
        % setting TCS temperatures to jitter start of ramp
        % cold start first
        tcsTemperatures1_c = zones*tb; %set warm zones to baseline
        tcsTemperatures1_c(tcsTemperatures1_c==0) = t1; 
        % warm start first
        tcsTemperatures1_w = zones*t2;
        tcsTemperatures1_w(tcsTemperatures1_w==0) = tb; %set cold zones to baseline
        
    case 4 % baseline
        zones = [1 0 1 0 1];
        tcsTemperatures1 = repmat(tb,1,5);
end
%return temperatures
tcsTemperatures2 = repmat(tb,1,5);

%% Set tcs
tcs = vars.ser;
%get into "follow mode":
% probe goes to setpoint @ramp speed
TcsSetBaseLine(tcs, tb); %set baseline
TcsSetRampSpeed(tcs, repmat(rate, 1, 5)); % setting speed to this

%% Stimulate sine wave
%loop to record stimulation temperatures
tic; %set start time
cpt = 0;
r_idx = 0; %setting ramp index
n_idx = 1; % setting loop index
ramp_started = 0;
targetT = tcsTemperatures1; %identifying the target temperatures
tDist = zeros(1,5); %creating tDist to induce first temp change
tgiStart_idx = 0;

% defining output
sin_peakT = NaN;
startRampT = NaN;
dm.temps = struct;

trial = vars.control.thisTrial;
 
if type < 3
    cond = vars.stim.cond;
else
    cond = 6;
end
% coding probe I incase it does not work
probeI.start = NaN;
probeI.delay = NaN;

%% start trial

TcsSetTemperatures(tcs, tcsTemperatures2); % run baseline first if stim designs are 5&6

% follow mode
TcsFollowMode(tcs);

% stimulus time-stamp
stimOn = GetSecs;
stimTime = tic; % timer for recording
if type < 3
    stim_idx = 0; %stimulus still at baseline
else
    stim_idx= 1; %always 'on' for baseline
end
        
currentTime = toc; %get current time
prevCurrentTime = currentTime; %init previous current time


while currentTime < (np*p)-jitter % trial length = length of sinwave, minus any task-related jitter

    % get and record current temperatures and time
    sin_startT(n_idx) = GetSecs();
    cpt = cpt + 1;
    currentTime = toc; %get current time
    time_sampled = toc(vars.time.trigger); %get time with respect to trigger
    currentTemperatures = [];
    
    % get TCS temperatures
    currentTemperatures = TcsGetTemperatures(tcs); %get current temperature

    if length(currentTemperatures) ~= 5
        currentTemperatures = repmat(NaN,1,5);
    end

    tDist = abs(currentTemperatures - targetT); %distance from probe temperature to targetT
    %disp(currentTemperatures); %disp current temperature

    if any(isnan(tDist))
        tDist = repmat(0.6,1,5);
    end
    
    % record
    t(cpt, 1) = trial; %count trials    
    t(cpt, 2) = currentTime; %reccord current time
    t(cpt, 3:7) = currentTemperatures; %record temperatures in t
    t(cpt, 8) = time_sampled; %time from trigger - to match MR data
    t(cpt, 9) = stim_idx; %code for whether probe has started to ramp up or down
    
    % calculate volumes and temperature at the beginning of each volume
    % for design matrix purposes
    tr_time = (t(:,8)./vars.MR.TR)+1; %calculate volume N based on time
    t(:,10) = floor(tr_time*1)/1; %rounding to volume N
    % extract tcs at the beginning of each volume
    vol_idx = [1; find(diff(t(:,10)) > 0) + 1]; %indexing when vol changes
    tcs_vol = t(vol_idx, :); % extracting temperatures
    tcs_vol(:,11) = cond; %adding condition to array
    % extract temp change for zones of probe that actually change
    col_idx = [1, 3, 4, 5, 6, 7, 8, 9, 10, 11];
    t1_idx = [1, zones, 1, 1, 1, 1];
    t2_idx = [0, zones, 0, 0, 0, 0];
    col1_idx = nonzeros(col_idx.*t1_idx)';
    col2_idx = col_idx(t2_idx == 0);
    % get warm and cold temperatures based on type
    switch type
        case 1
            cold_all = tcs_vol(:, col1_idx);
            warm_all = tcs_vol(:, col2_idx);
            % get average
            cold_all(:,end+1) = round(mean(cold_all(:,2:3), 2), 1);
            warm_all(:,end+1) = round(mean(warm_all(:,2:4), 2), 1);
        case 2
            cold_all = tcs_vol(:, col2_idx);
            warm_all = tcs_vol(:, col1_idx);
            % get average
            cold_all(:,end+1) = round(mean(cold_all(:,2:3), 2), 1);
            warm_all(:,end+1) = round(mean(warm_all(:,2:4), 2), 1);
        case 3      
            cold_all = tcs_vol(:, col2_idx);
            warm_all = tcs_vol(:, col1_idx);
            % get average
            cold_all(:,end+1) = round(mean(cold_all(:,2:3), 2), 1);
            warm_all(:,end+1) = round(mean(warm_all(:,2:4), 2), 1);
        case 4
            cold_all = tcs_vol(:, col2_idx);
            warm_all = tcs_vol(:, col1_idx);
            % get average
            cold_all(:,end+1) = round(mean(cold_all(:,2:3), 2), 1);
            warm_all(:,end+1) = round(mean(warm_all(:,2:4), 2), 1);
    end

    dm_temps.cold = cold_all;
    dm_temps.warm = warm_all;
    
    % switch between ramp types (temperature to ramp up and down to)
    switch r_idx
        case 0
            if type == 3 %if TGI, delay time differs for warm and cold
                if cold_first == 1 % if cold delay is longer than warm delay
                    if (currentTime - prevCurrentTime)/n_idx > delayTime_c && tgiStart_idx == 0 %start cold temp ramp first
                        TcsSetTemperatures(tcs, tcsTemperatures1_c); %set temperatures
                        r_idx = 0; %ramp to one
                        startRampT = GetSecs();
                        stim_idx = 1;
                        tgiStart_idx = 1;
                    end
                    if (currentTime - prevCurrentTime)/n_idx > delayTime_w && tgiStart_idx == 1 %start warm temp ramp second
                        TcsSetTemperatures(tcs, tcsTemperatures1); %set temperatures
                        targetT = tcsTemperatures1;
                        r_idx = 1; %ramp to one
                        %tgiStart_idx = 0;
                    end
                elseif cold_first == 0
                    if (currentTime - prevCurrentTime)/n_idx > delayTime_w && tgiStart_idx == 0 %start cold temp ramp first
                        TcsSetTemperatures(tcs, tcsTemperatures1_w); %set temperatures
                        r_idx = 0; %ramp to one
                        startRampT = GetSecs();
                        stim_idx = 1;
                        tgiStart_idx = 1;
                    end
                    if (currentTime - prevCurrentTime)/n_idx > delayTime_c && tgiStart_idx == 1 %start warm temp ramp second
                        TcsSetTemperatures(tcs, tcsTemperatures1); %set temperatures
                        targetT = tcsTemperatures1;
                        r_idx = 1; %ramp to one
                        %tgiStart_idx = 0;
                    end
                end
            else
                if (currentTime - prevCurrentTime)/n_idx > delayTime
                    TcsSetTemperatures(tcs, tcsTemperatures1); %set temperatures
                    r_idx = 1; %ramp to one
                    targetT = tcsTemperatures1;
                    startRampT = GetSecs();
                    stim_idx = 1;
               end
            end
        case 1
            if all(tDist <= vars.temp.Ttol)
                sin_peakT(n_idx) = GetSecs();
                WaitSecs(sw);
                TcsSetTemperatures(tcs, tcsTemperatures2); %temperature to baseline
                r_idx = 2; %ramp to two
                targetT = tcsTemperatures2;
                stimOff = GetSecs();
            elseif (currentTime - prevCurrentTime)/n_idx > (first_rampT+sw)
                sin_peakT(n_idx) = GetSecs();
                TcsSetTemperatures(tcs, tcsTemperatures2); %temperature to baseline
                r_idx = 2; %ramp to two
                targetT = tcsTemperatures2;
                stimOff = GetSecs();
            end
        case 2
            % if temperatures are reached, start ramping
            % but only after one iteration of p
            if all(tDist <= vars.temp.Ttol) && stim_idx == 1
                %stimOff(n_idx) = GetSecs();
                stim_idx = 0;
            end
            if all(tDist <= vars.temp.Ttol) && (currentTime - prevCurrentTime)/n_idx > p 
                TcsSetTemperatures(tcs, tcsTemperatures1);
                r_idx = 0; %ramp to 0
                targetT = tcsTemperatures1; %changing target temperature                
                n_idx = n_idx+1;
            end

    end

end

if ~exist('stimOff')
    stimOff = NaN;
end

%quit "follow mode"
stimEnd = GetSecs(); %stim off stamp
TcsAbortStimulation( tcs );

% %display 5x temp curves
% plot( t(:,2), t(:,3) ); hold on;
% plot( t(:,2), t(:,4) );
% plot( t(:,2), t(:,5) );
% plot( t(:,2), t(:,6) );
% plot( t(:,2), t(:,7) );
% xlabel('Time (s)'); ylabel('Temperature (C)');
% title('Stimulation sequence');
% legend('z1','z2','z3','z4','z5')
% grid on; zoom on;
% hold off;

