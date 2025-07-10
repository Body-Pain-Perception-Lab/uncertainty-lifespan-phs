function bidsfolder(path, project, sub_n, ses_n, datatype, taskname)
% BIDSfolder check whether BIDS folders already exist, otherwise creates them

    subject = ['sub-' sprintf('%04s', sub_n)]; % Define subject 
    session = ['ses-' sprintf('%02s', ses_n)]; % Define session
    bids_subject_folder = fullfile(path,project,subject); % subject folder
    bids_session_folder = fullfile(bids_subject_folder, session); % session folder
    bids_datatype_folder = fullfile(bids_session_folder, datatype); % datatype folder 
    bids_tasktype_folder = fullfile(bids_datatype_folder, taskname); % datatype folder 
      
    % Check folders
    if ~exist(bids_subject_folder)
        mkdir(bids_subject_folder)
    end

    if ~exist(bids_session_folder)
         mkdir(bids_session_folder)
    end
            
    if ~exist(bids_datatype_folder)
         mkdir(bids_datatype_folder)
    end
    
    if ~exist(bids_tasktype_folder)
         mkdir(bids_tasktype_folder)
    end
    
    
end