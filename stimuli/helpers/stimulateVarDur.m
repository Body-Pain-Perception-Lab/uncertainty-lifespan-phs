function [stimTime, stimOn, stimOff, rampOff, tcsData] = stimulateVarDur(vars,keys,type,duration,varargin)
%function [stimTime,stimOn, stimOff, tcsData] = stimulateVarDur(vars,type,duration,varargin)

%Type: 0: cold, 1: warm, 2:TGI
%Question type: Array with ones or zeros stating which questions to ask. Refer to parameters' file.
%VARARGIN: If used 1-Tcold 2-Twarm

%% Set parameters
if length(varargin)<2 
    type=3;
%     warning('Cold or Warm specifications are missing. Stimulating with baseline temperature'); 
else
    Tcold = varargin{1};
    Twarm = varargin{2};
end

%TCS
% is set baseline needed
TcsSetBaseLine(vars.ser,vars.temp.Tbaseline); % skin temperature/baseline temperature
% TcsSetDurations(vars.control.ser,repmat(vars.stim.durationS,1,5)); % stimulation duration
TcsSetRampSpeed(vars.ser,repmat(vars.temp.speed_ramp,1,5)); % rate of temperature change to target
TcsSetReturnSpeed(vars.ser,repmat(vars.temp.return_ramp,1,5)); % rate of temperature change to baseline

% randomize stimulation bars
% Q: why do stimulation bars change? Can they not stay the same?
switch type
    case 0 % Cold. Select one within the 4 possibilities.
        possibilities = {[1 1 0 0 0],...
            [0 1 1 0 0],...
            [0 0 1 1 0],...
            [0 0 0 1 1]};
        possibilities_idx = randi(4);
        tcs_temperatures = single(possibilities{possibilities_idx});
        tcs_temperatures(tcs_temperatures==0)= vars.temp.Tbaseline;
        tcs_temperatures(tcs_temperatures==1)= Tcold;
        
    case 1 % Warm. Selct one within the 3 possibilities
        possibilities = {[1 1 1 0 0],...
            [0 1 1 1 0],...
            [0 0 1 1 1]};
        possibilities_idx = randi(3);
        tcs_temperatures = possibilities{possibilities_idx}*Twarm;
        tcs_temperatures(tcs_temperatures==0)= vars.temp.Tbaseline;
        
    case 2 % TGI. Only one possibility
        possibilities = [1 0 1 0 1];
        tcs_temperatures = possibilities*Twarm;
        tcs_temperatures(tcs_temperatures==0) = Tcold;
        
    case 3 %Baseline
        tcs_temperatures = single(ones(1,5)*vars.temp.Tbaseline);
end


TcsSetTemperatures(vars.ser,tcs_temperatures); % 5 stimulation temperatures

timepoint = 0;

%% STIMULATE
stimOn = GetSecs;

TcsFollowMode(vars.ser)
%% Get and save temperature data during stimulation
stimTime = tic; % timer for recording

% loop until RespT is reached
end_stim = 0;
end_counter = 0;
end_timer = Inf;
ramp_idx = 1;

while end_stim==0
    
% while toc(stimTime) <= duration % get tcs data for a predefined amount of time
    timepoint = timepoint + 1; % update counter
    time_sampled = toc(vars.time.trigger);   % timing with respect to when the experiment started (trigger)
    temperatures = TcsGetTemperatures(vars.ser); % get temperatures from USB port
    % are temperatures at stim value?
   % disp(num2str(temperatures)) % show current temperatures
    tcsData(timepoint,1) = vars.control.thisTrial; % trial number
    tcsData(timepoint,2) = time_sampled; % stimulation timing
    tcsData(timepoint,3:7) = temperatures; % temperatures of 5 zones
    tcsData(timepoint,8) = ramp_idx;
    
    % KbCheck for Esc key
    if keys.KeyCode(keys.Escape)== 1
        % Save, mark the run
        vars.RunSuccessfull = 0;
        vars.Aborted = 1;
        experimentEnd(keys, results, scr, vars);
        return
    end
    
    [~, ~, keys.KeyCode] = KbCheck;
    WaitSecs(0.001);
    
    if all(abs(temperatures-tcs_temperatures)<= vars.temp.Ttol*ones(size(tcs_temperatures))) && end_counter == 0 % if temperature reached, calculate ramp time
        t=timepoint;
        ramp_idx = 0;
        rampOff.t = tic; %marking for RT
        rampOff.sec = GetSecs(); %get indication of when ramping stops
        rampT = stimOn - rampOff.sec; % calculating ramp time
        end_counter = 1;
    elseif toc(stimTime) > 3 && end_counter == 0 %ramping for longer than three seconds, record this
        ramp_idx = 2; % 2 = fail
        rampOff.t = tic; %marking for RT
        rampOff.sec = GetSecs(); %get indication of when ramping stops
        end_counter = 1;
    end
    
    end_timer = GetSecs();
    
    % ends after total trial duration
    % (aka ramping is included in the stim. duration)
    if (end_timer - stimOn) > duration
        end_stim=1;
        %quit "follow mode"
        TcsAbortStimulation(vars.ser);
    end
end

stimOff = GetSecs;
% warning('on')
% if any((abs(tcsData(end,3:7)-tcs_temperatures) > vars.task.Ttol*ones(size(tcs_temperatures)))) && ~isequal(type,3)
%     warning('Target temperature not reached')
% end

%%
% clf
%     for ii=1:5
%         subplot(3,2,ii)
%         plot((tcsData(:,2)-tcsData(1,2)),tcsData(:,2+ii))
%         hold on
%         xline(tcsData(t,2)-tcsData(1,2))
%         xline(tcsData(end,2)-tcsData(1,2))
%         title(['Termode ' num2str(ii)])
%     end
% tcsData(end,2)-tcsData(t,2)
end