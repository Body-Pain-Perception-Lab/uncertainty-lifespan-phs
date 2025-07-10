function [tempArray, vars] = getStimArray(vars, nrep, filename)
    %   getStimTemperatures.m searches for .csv file with temperature threshold
    %   information from previous behaviorual session (MultiDimThr)
    %   Warm, cold and TGI temperatures are then loaded to use in:
    %   tgimri_task.m
    
    %   nrep is the number of times the array is randomised
    
    %   Project: tgi-mri & MultiDim_Thr
    %   Author: Alexandra G. Mitchell, 11.01.2023

    %   Last edited: 21.07.2023
    
    %% Load data based on participant information
    if ~exist('vars.control.info')
        ID = '0011';    
        sess = '1';
    else
        ID = vars.control.info(1);
        sess = vars.control.info(3);
    end
    subject = ['sub-' sprintf('%04s', ID)]; % Define subject 
    session = ['ses-' sprintf('%02s', sess)]; % Define session
        
    % find temperature files derived from psi pain and detection thresholds
    
    % If no data - load defaults
    if ~exist('filename')
        temps = readtable('mri_exampleTemps.csv');
        
        new_line;
        disp('No mri temperatures found for this participant, using defaults');
        
        % add subject and session information
        temps.ID = repmat(ID, size(temps,1), 1);
        temps.Session = repmat(sess, size(temps,1), 1);
    else
        temps = readtable(filename, "FileType", "delimitedtext");
    end
    
    %% Pseudorandomise array 
    % So intensly painful trials are not followed by another non-painful
    % trial
    % do this for as many repetitions of the array that are needed
    
    % first create empty array
    tempArray = cell2table(cell(0,8), ...
        'VariableNames',{'coldT', 'warmT', 'trial_idx', 'pain', 'temp_idx', 'seq_idx', 'subject', 'session'});
    for r = 1:nrep
        
        array = temps(randperm(size(temps, 1)), :);  % shuffle array   
        idx = unique(find(diff(array.seq_idx)==0)); % find repeats for the pain trial index (=7)

        % also need to identify if the first cell = 7, if so then a pain
        % trial may follow a pain trial
        while ~isempty(idx) ||  array.seq_idx(1) == 6 %continue until no repeats
            array = temps(randperm(size(temps, 1)), :);  % shuffle array   
            idx = unique(find(diff(array.seq_idx)==0)); % find repeats
        end

    tempArray = [tempArray; array];
    
    end

  
end

