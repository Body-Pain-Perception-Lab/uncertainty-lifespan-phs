function tempArray = createArray(ID,session,order,c1,c2,w1,w2)
%   Creates a stimulus array of temperatures to use for the tgi-mri project
%   order - the counterbalance procedure, to decide on order of array
%   c1, c2, w1, w2 indexes temperature input
%   c for cold, w for warm
%   first temperatures are painful, second are innocuous

% different array options
a1 = {ID, session, 0, 'ctg', 3, c2, 30, 0; ... %cold TGI stim
    ID, session, 1, 'wpt', 2, 30, w1, 1; ... %warm pain stim
    ID, session, 1, 'wtg', 4, 30, w2, 0; ... %warm TGI stim
    %ID, session, 2, 'tgi', 5, c2, w2, 1; %TGI
    ID, session, 0, 'cpt', 1, c1, 30, 1; ...  %warm pain stim
    ID, session, 3, 'bln', 6, 30, 30, 1}; ... %baseline
a2 = {ID, session, 0, 'ctg', 3, c2, 30, 0;... 
    ID, session, 0, 'cpt', 1, c1, 30, 1; ... 
   % ID, session, 2, 'tgi', 5, c2, w2, 1;... 
    ID, session, 1, 'wtg', 4, 30, w2, 0; ... 
    ID, session, 1, 'wpt', 2, 30, w1, 1; ...
    ID, session, 3, 'bln', 6, 30, 30, 1}; ... %baseline};   
a3 = {ID, session, 1, 'wtg', 4, 30, w2, 0; ...
    ID, session, 0, 'cpt', 1, c1, 30, 1; ...
    ID, session, 0, 'ctg', 3, c2, 30, 0; ... %cold TGI stim
    %ID, session, 2, 'tgi', 5, c2, w2, 1; ...
    ID, session, 1, 'wpt', 2, 30, w1, 1; ...
    ID, session, 3, 'bln', 6, 30, 30, 1}; ... %baseline}; 
a4 = {ID, session, 1, 'wtg', 4, 30, w2, 0;... 
    ID, session, 1, 'wpt', 2, 30, w1, 1; ...    
    %ID, session, 2, 'tgi', 5, c2, w2, 1; ... 
    ID, session, 0, 'ctg', 3, c2, 30, 0; ... 
    ID, session, 0, 'cpt', 1, c1, 30, 1; ...
    ID, session, 3, 'bln', 6, 30, 30, 1}; ... %baseline}; 

% generate arrays for entire run based on order
switch order
    case 1
        tempC = [a1; a2; a3; a4; a1];
    case 2
        tempC = [a1; a3; a2; a4; a2];
    case 3     
        tempC = [a3; a4; a1; a2; a3];
    case 4
        tempC = [a2; a4; a1; a3; a4];
end

% remove the last baseline trial
tempC = tempC(1:end-1, :);

% compile array into a table
tempArray = cell2table(tempC);
tempArray = renamevars(tempArray, {'tempC1','tempC2','tempC3','tempC4','tempC5','tempC6','tempC7','tempC8'},...
    {'subject','session','type','stimuli','trial_index','coldt','warmt','pain'});


