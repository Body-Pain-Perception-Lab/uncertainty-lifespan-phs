function phs_contrast_main(vars)
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
        [subject '_' session '_' 'task-' task_name '_' datatype '.mat']); % how it should be 
matfilename = vars.control.uFilename;

%% Check restart - commented out for debugging
% if the filename already exists
% if exist(matfilename, "file")
%     vars.control.confirmedSubjN = input('Subject already exists. Do you want to continue anyway (yes = 1, no = 0)?    ');
%     if vars.control.confirmedSubjN
%         %com = vars.ser;
%         load(matfilename,'results','vars')       
%         %vars.ser = com; clear com;
%         vars.control.startTrialN = input('Define the trial number to restart from?   ');
%     else
%         return
%     end
% else
%     vars.control.startTrialN = 1;
% end

vars.control.startTrialN = 1;
vars.control.finalQ = 0; %only turn on when end is reached

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
stimuli = tslTemperatures(vars.tempArray.thresholds, vars.tempArray.slope_o, 1, ...
    vars.temp.Tbaseline, [], []);

% now create array
vars.task.stimArray = [stimuli; stimuli];
% order by temperatures
vars.task.stimArray = sortrows(vars.task.stimArray, 'temp_cond', 'ascend');
% adding duration
vars.task.stimArray.duration = [repmat([vars.task.stimDur1; vars.task.stimDur2],4,1)]; 
vars.task.stimArray.condition = [1:length(vars.task.stimArray.duration)]';
vars.task.stimArray.subject = repmat(subject, length(vars.task.stimArray.duration), 1);
vars.task.stimArray.session = repmat(session, length(vars.task.stimArray.duration), 1);
vars.task.stimArray.task = repmat(task_name, length(vars.task.stimArray.duration), 1);

% extend array to length of experiment (x by n trial reps)
vars.task.stimArray = repelem(vars.task.stimArray, vars.task.nTrialReps, 1); %7 trial reps because one is a catch trial

% code catch trials where probe actually heats up
vars.task.stimArray.catch = zeros(length(vars.task.stimArray.condition),1); %first add column of zeros
%then randomly identify locations within each condition for catch trials
cRand = randi(vars.task.nTrialReps, vars.task.nCond, 1);
cRand_idx = cRand' + vars.task.nTrialReps .*(0:length(cRand)-1);
% index them into the array
vars.task.stimArray.catch(cRand_idx) = 1;

% finally, add trials where a VAS will be, importantly cannot be a catch
vars.task.stimArray.vas = ones(length(vars.task.stimArray.condition),1);
% % loop through conditions
% allIdx = [];
% for c = 1:vars.task.nCond
%     % identify specific condition
%     vIdx1 = find(vars.task.stimArray.condition == c & vars.task.stimArray.catch == 0);
%     % randomly assign three trials with VAS ratings
%     vIdx = vIdx1(randperm(numel(vIdx1),(length(vIdx1)/2)));
%     
%     allIdx = [allIdx; vIdx]; %make large data-frame
% end
% 
% vars.task.stimArray.vas(allIdx) = 1; %identifying trials with vas
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
    if Restarted == 0
        %Screen('FillRect', scr.win, scr.Background, scr.winRect);
        DrawFormattedText(scr.win, uint8([vars.display.mainExperiment]), 'center', 'center', scr.TextColour, 60);
        [~, ~] = Screen('Flip', scr.win);
    else
        %Screen('FillRect', scr.win, scr.Background, scr.winRect);
        DrawFormattedText(scr.win, uint8([vars.display.restart]), 'center', 'center', scr.TextColour, 60);
        [~, ~] = Screen('Flip', scr.win);
    end

    [sT, ~] = KbWait(); %wait for keypress

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
            DrawFormattedText(scr.win, uint8([vars.display.pressButtonText]), 'center', 'center', scr.TextColour, 60);
            [~, ~] = Screen('Flip', scr.win);
        
            if vars.task.tsl > 0
                [t, stimOn, stimEnd, tmaxT, tminT, timing] = ...
                            stimulateTSLbeep(vars, vars.task.tsl, vars.temp.Tbaseline, vars.task.TSLrep, vars.temp.rate,...
                            toneIdx, stimDur, catchT, tmax);
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

                vars.time.respTime(thisTrial,q) = vars.time.respEnd(thisTrial,q) - ...
                     vars.time.respStart(thisTrial,q);
                %remT = round(vars.task.respTime - vars.time.respTime(thisTrial,q), 2); %calculate time remaining
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

        %% save data at every trial
        %save(strcat(vars.OutputFolder, vars.UniqueFileName), 'Results', 'vars', 'scr', 'keys' );
        save(matfilename, 'results', 'vars', 'scr', 'keys', '-regexp', ['^(?!', 'vars.ser' , '$).'] );
        
        %% display pause screen after N repetitions of each condition
        % unless it is the end of the experiment
        if nReps == vars.task.NTrialsTotal/2
            nReps = 0; %set count back to 0
            if thisTrial ~= vars.task.NTrialsTotal
                % display pause screen
                Screen('FillRect', scr.win, scr.Background, scr.winRect);
                DrawFormattedText(scr.win, uint8([vars.display.pause]), 'center', 'center', scr.TextColour, 60);
                [~, ~] = Screen('Flip', scr.win);
                KbWait();
                
                % Starting screen
                Screen('FillRect', scr.win, scr.Background, scr.winRect);
                DrawFormattedText(scr.win, uint8([vars.display.starting]), 'center', 'center', scr.TextColour, 60);
                [~, ~] = Screen('Flip', scr.win);
                WaitSecs(1);
               
            end
        end

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
        [subject '_' session '_' 'task-' task_name '_' datatype '_' task_name '_results.tsv']); 
        writetable(results.allDat, tsvfilename2, 'FileType','text','Delimiter','\t');
    end
    
    %% Last thing - ask participants how they did the task
    % first, ask them which response they were more likely to make
    vars.control.finalQ = 1;
    
    DrawFormattedText(scr.win, uint8([vars.display.perfCheckinstr]), 'center', 'center', scr.TextColour, 60);
                [~, ~] = Screen('Flip', scr.win);

    [results.taskCheck.response(1), results.taskCheck.RT(1), vars] =...
                         getResponse(scr, vars, 3);
                     
    question_idx = [2 3];
    % change vas time to a long time
    
    results.taskCheck.onset = GetSecs();
    for q = 1:length(question_idx)
        % present vas
        [results.taskCheck.response(question_idx(q)), results.taskCheck.RT(question_idx(q))] = ...
            getVasRatings(keys, scr, vars, question_idx(q), vars.task.checkRespTime);
        results.taskCheck.offset = GetSecs();
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

