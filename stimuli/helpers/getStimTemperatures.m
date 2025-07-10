function [temps, vars] = getStimTemperatures(vars)
    %   getTemperatures.m searches for .csv file with temperature threshold
    %   information from previous behaviorual session (MultiDimThr)
    %   Warm, cold and TGI temperatures are then loaded to use in:
    %   tgimri_task.m

    %   Project: tgi-mri
    %   Author: Alexandra G. Mitchell, 11.01.2023

    %   Last edited: 20.01.2023

    %% Load thresholds based on ID
    % THIS CODE NEEDS EDITING BASED ON OUTPUT OF thresholdExtract.m code
    datatype = 'beh'; %change to beh - extracting from behavioural data folder
    task = 'task-mri';
    
    if vars.control.pp == 1 %if subject information has been entered
        ID = vars.control.info(1);
        session = 'ses-01';
        subject = sprintf('sub-%s', ID); %converting to string

        % paths
        path = vars.control.path;
        project = vars.control.project;
        
        dataSpec = fullfile(path,project,subject,session,datatype); %search for specific folder
        files = dir(dataSpec); % loading files within that folder
    else
        ID = 'test';
        subject = 'sub-test';
        session = 'ses-01';
    end

    if exist('files') && ~isempty(files) %if file exists and is not empty
    % loading threshold files
    %if subject folder exists & has something in it..
        % find and load the file of interest
        dffilename = sprintf('%s_%s_%s_temps_%s.tsv',subject,session,task,datatype);
        matfilename = sprintf('%s_%s_%s_thresh_%s.mat',subject,session,task,datatype);
        
        temps_file = fullfile(dataSpec, dffilename); %this might need to change
        % getting just threshold values
        load(fullfile(dataSpec, matfilename));
               
        % reading in temperatures from file
        temps.df = struct2table(tdfread(temps_file));
        % remove prob column
        temps.df = removevars(temps.df,{'prob'});
    else 
        disp('No thresholding files found/in debugging mode. Using default temperatures')
        % generate default temperature arrays
        temps.warmT = 46; 
        temps.coldT = 5;
        temps.tgiLowC = 21;
        temps.tgiLowW = 39;
        temps.tgiHighC = 14.5;
        temps.tgiHighW = 41.5;
        
%         % as tables 
%         cold = table(ID, session, 0, 'cold', cold_thresh, 30,...
%             'VariableNames', {'subject','session','type','stimuli','coldt','warmt'});
%         warm = table(ID, session, 1, 'warm', 30, warm_thresh,...
%             'VariableNames', {'subject','session','type','stimuli','coldt','warmt'});
%         %tgi table
%         tgi = table(ID, session, 2, 'ttgi', tgi_cold, tgi_warm,...
%             'VariableNames', {'subject','session','type','stimuli','coldt','warmt'});
%         
%         % join all tables
%         temps.df = vertcat(cold, warm, tgi);
    end
    
  % permutate array so conditions are pseudorandomised equally among trial
  % number
end

