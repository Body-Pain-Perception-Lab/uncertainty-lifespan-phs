function phs_contrast_tutorial(vars)
%% Project: tgi-mri task code
% Part: MR main Task
%
% Alexandra G. Mitchell
% Adapted from code by Camila Sardeto, Francesca Fardo & Niia Nikolova

% Tests different design perameters and timing for the tgi-mri experiment
% Last edited 06/10/2023

% DESIGN: random interleaved

%% folder information
screenOn = 0; 

project = vars.control.project;
datatype = vars.control.datatype;
task_name = vars.control.taskname;

% path to save data to - should be changed depending on laptop (VAS_loadParams.m)
datPath = vars.control.path;
runPath = pwd;

% pp info
subject = ['sub-' sprintf('%04s', vars.control.ID)]; % Define subject 
session = ['ses-' sprintf('%02s', vars.control.ses_n)]; % Define session

vars.control.uFilename = fullfile(datPath, project, subject, session, datatype, task_name,...
        [subject '_' session '_' 'task-' task_name '_' datatype 'tutorial.mat']); % how it should be 
matfilename = vars.control.uFilename;

vars.control.startTrialN = 1;
vars.control.finalQ = 0;

% start trial information
thisTrial = vars.control.startTrialN;
endExp = 0;
if thisTrial ~= 1
    Restarted = 1;   % If experiment was aborted (e.g. TCS overheated), display restart screen
else
    Restarted = 0;
end

% Open a PTB window
scr.ViewDist = 56; 

% Get stimulator and open port
if vars.control.stimFlag
    if ~Restarted
        vars.ser = TcsCheckStimulator(vars);
    else
        % check stim hasn't been switched off
        % if so, reconnect
        stim_disconnected = input('Has the TCS been switched off and on again? (Yes - 1, No - 0): ');
        if stim_disconnected
            TcsCloseCom(vars.ser); %make sure com is cleared
            vars.ser = struct; %clear original
            vars.ser = TcsCheckStimulator(vars);
        end       
    end    
end

%% calculate temperatures to use for each condition
% for the tutorial, temperatures are fixed
max_temps = [36; 40];
pain_cond = ['innoc';'innoc'];
temp_cond = [1; 2];
stimuli = table(temp_cond,pain_cond,max_temps);

% how many trials to include in tutorial? 8 probably enough
%vars.task.stimArray = [stimuli; stimuli];
% order by temperatures
vars.task.stimArray = sortrows(stimuli, 'temp_cond', 'ascend');
% adding duration
vars.task.stimArray.duration = [vars.task.stimDur1; vars.task.stimDur1]; 
vars.task.stimArray.condition = [1:length(vars.task.stimArray.duration)]';
vars.task.stimArray.subject = repmat(subject, length(vars.task.stimArray.duration), 1);
vars.task.stimArray.session = repmat(session, length(vars.task.stimArray.duration), 1);
vars.task.stimArray.task = repmat(task_name, length(vars.task.stimArray.duration), 1);

% extend array to length of experiment (x by n trial reps)
vars.task.stimArray = repelem(vars.task.stimArray, vars.task.nTrialReps, 1); %3 trial reps

% randomly put two catch trial in
cRand_idx = randi(length(vars.task.stimArray.duration), 2, 1);
%cRand_idx = cRand' + 2 .*(0:length(cRand)-1);
% index them into the array
vars.task.stimArray.catch(cRand_idx) = 1;
% 
vars.task.stimArray.vas = ones(length(vars.task.stimArray.condition),1);
vars.task.stimArray.trial = [1:length(vars.task.stimArray.duration)]'; %add trial count

%%
try %try loop to catch errors
    % checck if ptb open, if not open ptb screen
    [scr] = openScreen(scr, vars);

    % Dummy calls to prevent delays
    keys = keyConfig();
    [~, ~, keys.KeyCode] = KbCheck;
    %Response = NaN(length(vars.task.TcoldArray),1); %adapt so this is matched to question
    % open PTB audio
    vars.audio.pah = PsychPortAudio('Open', [], 1, 1, vars.audio.sampRate, vars.audio.nrchannels);

   
    %% Start screen
    DrawFormattedText(scr.win, uint8([vars.display.actStart]), 'center', 'center', scr.TextColour, 60);
    [~, ~] = Screen('Flip', scr.win);
    [~, ~] = KbWait(); %wait for keypress

    % Starting...
    vars.control.startTask = tic;
    vars.task.startTime = GetSecs(); %time stamp
    
    %% Display fixation before start
    %Screen('FillRect', scr.win, scr.Background, scr.winRect);
    scr = drawFixation(scr); % fixation point
    [~, ~] = Screen('Flip', scr.win);
    screenOn = 1;
    
    % Wait a short time to start
    WaitSecs(.5);

    ListenChar(2);
    HideCursor;
    nReps = 0;

    while endExp ~= 1
        %% Trial starts: Configure temperatures
        vars.control.thisTrial = thisTrial;
        results.trial(thisTrial) = thisTrial; %also recording trial N in results
        startTrial = tic; %timestamp for starting the trial
        vars.time.startTrial(thisTrial) = GetSecs;
         
        % add rep count
        nReps = nReps+1;
        % clear tmax and tmin for next round
        clear('tmax', 'tmin')
    
        % Draw fix
        Screen('FillRect', scr.win, scr.Background, scr.winRect);
        scr = drawFixation(scr); % fixation point
        [~, ~] = Screen('Flip', scr.win);
        
       
        %% Start stimulation - TSL task       
        % switching between conditions - this will change the peak points
        cond = vars.task.stimArray.condition(thisTrial);
        if cond == 9 %if condition is the standard TSL, there is no need to set tmax or min
            toneIdx = 3;
            vars.task.tsl = 0;
        else %all other conditions
            toneIdx = 1;
            vars.task.tsl = 1;      
        end
        
        stimDur = vars.task.stimArray.duration(thisTrial);
        tmax = round(vars.task.stimArray.max_temps(thisTrial), 1); %condition-1 to get appropriate temps
        catchT = vars.task.stimArray.catch(thisTrial);
        
        % RUN TSL
        % tmax, tmin, rate, baseline, stimulus wait time, number of
        % iterations, tone code
        if vars.control.stimFlag
            if vars.task.tsl > 0
                DrawFormattedText(scr.win, uint8([vars.display.pressButtonText]), 'center', 'center', scr.TextColour, 60);
                [~, ~] = Screen('Flip', scr.win);
                %stimulate
                [t, stimOn, stimEnd, tmaxT, tminT, timing] = ...
                            stimulateTSLbeep(vars, vars.task.tsl, vars.temp.Tbaseline, vars.task.TSLrep,...
                            vars.temp.rate, toneIdx, stimDur, catchT, tmax);
            else %condition 9 is a standard TSL
                [t, stimOn, stimEnd, tmaxT, tminT, timing] = ...
                            stimulateTSLtrial(vars, vars.task.tsl, vars.temp.Tbaseline, vars.task.TSLrep, vars.temp.rate,...
                            catchT, toneIdx);
            end
            
             % find minimum temp but only if it does not exist
            if ~exist('tmin')
                tmin = min(min(t(:,3:7)));
            end
            % find maximum temp - but only if tmax does not already exist
            if ~exist('tmax')
                tmax = max(max(t(:,3:7)));
            end
            
                
            % calculate response time
            results.responseData{thisTrial} = timing;
            results.respDown(thisTrial) = timing.tMin - timing.toneDown;
           % save tcs data    
            results.tcsData{thisTrial} = t;

            results.startTrial(thisTrial) = vars.time.startTrial(thisTrial);
            results.stimOn(thisTrial) = stimOn; %trial start
            results.tmaxT(thisTrial) = tmaxT; %time of peak temperature
            results.tminT(thisTrial) = tminT; %time of minimum temperature
            results.stimEnd(thisTrial) = stimEnd; %time trial over
            
            results.tmax(thisTrial) = tmax;
            results.tmin(thisTrial) = tmin;

            % plot tcs data
%             figure(thisTrial)
%             plot(t(:,2), t(:, 3:7), 'LineWidth', 1.2)
%             hold on
%             %plot(tcsData(:,2), (rampOff_code*max(tcsData(end, 3:7))), '.', 'markersize', 4) 
%             title(sprintf('Stimulation data trial-%d', thisTrial))
%             xlabel('Time (s)')
%             ylabel('Temperature (°C)')
%             %legend('z1','z2','z3','z4','z5')
%             ylim([0 50])
%             grid on; zoom on;
            
            disp(['Trial #' num2str(thisTrial) ', Tmax = ' num2str(tmax) ', Tmin = ' num2str(tmin)])
            %saveas(figure(thisTrial), sprintf('Trial-%d.png', thisTrial))
        end
        
        %% Response 
        % 1. what temperature did you feel? (warm/cold)
        % 2. did the temperature burn? (yes/no)

        for q = 1:length(vars.display.questionCode) %loop through questions
            if vars.display.whichQuestion(q)
                [results.resp(thisTrial,q), results.respRT(thisTrial,q), vars] =...
                         getResponse(scr, vars, q);

                 % make sure response is always 2s
                vars.time.respTime(thisTrial,q) = vars.time.respEnd(thisTrial,q) - ...
                     vars.time.respStart(thisTrial,q);
                remT = round(vars.task.respTime - vars.time.respTime(thisTrial,q), 2); %calculate time remaining
            end
             
            %WaitSecs(remT);
        end
         
        %% After response, present confidence VAS
        % 
        if vars.task.stimArray.vas(thisTrial) == 1 % some way of recording whether task is VAS
            % randomise question, although this step not needed here
            question_idx = 1;       
            for q = 1:length(question_idx)                
                results.vasOnset(thisTrial,question_idx(q)) = GetSecs();
                % present vas
                [results.vasResponse(thisTrial,question_idx(q)), results.vasRT(thisTrial,question_idx(q))] = ...
                    getVasRatings(keys, scr, vars, question_idx(q), vars.task.vasTime);
                results.vasOffset(thisTrial,question_idx(q)) = GetSecs();
            end
            
            vasTime = results.vasOffset(thisTrial,question_idx(q)) - results.vasOnset(thisTrial,question_idx(q));
            remT2 = round(vars.task.vasTime - vasTime, 2);
            
            %WaitSecs(remT2)
        end
         
        vars.time.endTrial(thisTrial) = GetSecs(); %time stamp

        % save data at every trial
        %save(strcat(vars.OutputFolder, vars.UniqueFileName), 'Results', 'vars', 'scr', 'keys' );
        save(matfilename, 'results', 'vars', 'scr', 'keys', '-regexp', ['^(?!', 'vars.ser' , '$).'] );
        

        %% Continue to next trial or time to stop? (max # trials reached)
        if (thisTrial == vars.task.NTrialsTotal)
            endExp = 1;
        else
            thisTrial = thisTrial + 1;
        end % next Trial 
        
    end % experiment loop

    %% End
    vars.task.endTime = GetSecs();
    vars.task.timeLength = vars.task.endTime - vars.task.startTime;

    fprintf('Run duration: %d', vars.task.timeLength)

    %% Results
    % % make results table and create .tsv
    % to include: temperatures for each trial, response time, stimulus
    % times, condition, subject, session, task
    if vars.control.stimFlag == 1
        resultsTab = table(results.trial', results.stimOn', results.tmaxT', results.tminT', results.stimEnd',...
            results.tmax', results.tmin',...
            results.resp(:,1), results.respRT(:,1), ...
            results.vasOnset(:,1), results.vasOffset(:,1), results.vasResponse(:,1), results.vasRT(:,1), ...
                'VariableNames', {'trial','stimOn_time','tmax_time','tmin_time','stimEnd_time',...
                'tmax_temp','tmin_temp','tempResp','tempRT','vasOnset','vasOffset','vasRating','vasRT'});
        % merge with trial data
        results.allDat = join(vars.task.stimArray, resultsTab);

        % save file
        tsvfilename2 = fullfile(datPath, project, subject, session, datatype, task_name,...
        [subject '_' session '_' 'task-' task_name '_' datatype '_' task_name '_results_tutorial.tsv']); 
        writetable(results.allDat, tsvfilename2, 'FileType','text','Delimiter','\t');
    end
    
    % finally save data
    % saving -need to transport into 'experiment end' function
    save(matfilename, 'results', 'vars', 'scr', 'keys', '-regexp', ['^(?!', 'vars.ser' , '$).'] );

catch ME
    if vars.control.stimFlag
        TcsCloseCom(vars.ser) %close stim port
    end
    rethrow(ME)
    
    if screenOn
        % show aborted screen
        Screen('FillRect', scr.win, scr.BackgroundGray, scr.winRect);
        DrawFormattedText(scr.win, 'Run aborted', 'center', 'center', scr.TextColour, 60);
        [~, ~] = Screen('Flip', scr.win);
        WaitSecs(2)

        sca
    end

    ShowCursor;
    fclose('all'); %Not working Screen('CloseAll')
    Priority(0);
    ListenChar(0);          % turn on keypresses -> command window    
end

if vars.control.stimFlag
    TcsCloseCom(vars.ser) %close stim port
end
sca
ShowCursor;
fclose('all'); %Not working Screen('CloseAll')
Priority(0);
ListenChar(0);          % turn on keypresses -> command window

