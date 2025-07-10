%% Extracting all necessary data requried for phs-ageing analyses
% A.G.Mitchell 24.03.2025

clear all
system = 2; %local (1), cluster (2)

%% Folders
switch system
    case 1 %mac
    case 2 %cybertron
        env = '/mnt/slow_scratch/';
        project = 'ageing-and-neuropathy';
        out = 'data';
        gitPath = '/home/alexm/Git/phs-ageing/';
end

cd(gitPath);
datPath = fullfile(env, project, filesep, out);

% Identify subjects in directory
subjDirs = dir(datPath);
subjects = {subjDirs.name};
% remove first two rows
subjects = subjects(3:end);

%% Loop through subjects
% get data, extract all critical components
% recreate .tsv

for s = 1:length(subjects)
    f = s+2; %folder index
    % get subject specific folder
    sFolder = fullfile(subjDirs(f).folder, subjDirs(f).name);
    phsFolder = fullfile(sFolder, filesep, 'ses-01', filesep, 'beh', filesep, 'phs_con', filesep);
    
    if exist(phsFolder,'dir')
        % load .mat
        fileName = sprintf('%s_ses-01_task-phs_con_beh.mat', subjects{s});
        load(fullfile(phsFolder, fileName));

        % extract button response time
        buttonRT = results.respDown - vars.task.jitterT;
        % load this into existing table
        buttonRT_tab = table(results.allDat.trial, buttonRT', 'VariableNames', {'trial','buttonRT'});
        results.allDat_new = join(results.allDat, buttonRT_tab);

        % save new data-frame, override old .tsv
        tsvfilename2 = fullfile(phsFolder,...
        [subjects{s} '_ses-01_task-phs_con_beh_results.tsv']); 
        writetable(results.allDat_new, tsvfilename2, 'FileType','text','Delimiter','\t');

        % next get data from end of experiment questions
        endResp = results.taskCheck.response;
        subNr = str2double(subject(end));
        % check if even
        if mod(subNr, 2) == 0 %is even
            endResp(1) = endResp(1);
        else
            endResp(1) = (endResp(1)-1)*-1; %reversing the coding for odd
        end

        % make table with subject number and responses
        % 0 = press when not sure, 1 = wait until sure
        endResp(4) = str2double(subject(5:end));
        allResp(s,:) = endResp;
        
    else
        fprintf('No data for %s, moving on to next', subjects{s}); 
    end
end % subjects

datPath = fullfile(env, project, filesep, out);
responsesTable = table(allResp(:,1), allResp(:,2), allResp(:,3), allResp(:,4), ...
    'VariableNames', {'response','unsure_VAS','sure_VAS','subject'});
writetable(responsesTable, fullfile(datPath, 'EOT_data.tsv'), ...
            'FileType', 'text', 'Delimiter', '\t');

% done