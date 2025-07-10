function stimuli = tslTemperatures(thresholds, slopes, TSLtype, baseline, warm_limit, cold_limit)
%% AG Mitchell 25.01.24
% This function takes 

% load optional inputs, if they do not exist
if isempty('warm_limit')
    warm_limit = 50;
end
if isempty('cold_limit')
    cold_limit = 0;
end

warm_limit=50;
%% fixed warm temperatures
% before starting, check that slope sigmas are < 1.5, if not, fix slope at
% .5
if slopes(2) <= 1.5
    slope_wdt = slopes(2);
else
    slope_wdt = 1.5;
end
if slopes(4) <= 1.5
    slope_hpt = slopes(4);
else
    slope_hpt = 1.5; 
end

% first get all temps
% condition 1 - detection threshold
tw1 = thresholds(2); %wdt
% condition 2 - detection threshold + 3*slope_o    
tw2 = thresholds(2)+(3*slope_wdt);
% condition 3 - pain threshold
tw3 = thresholds(4); %hpt
% condition 4 - pain threshold + 2*slope_o (3* is a little too much)
tw4 = thresholds(4)+(2*slope_hpt);

% checks to make sure temperatures are in a sensible range
% first - fix max temps to max
if tw4 > warm_limit
    tw4 = warm_limit-.1;
end
% then make sure tw3 is below the max temp - this could change when the
% warm limit is fixed
if tw3 >= tw4
    tw3 = tw4-(2*slope_hpt);
end
% next, check that detection temp is nowhere near pain threshold
% if it is, then reduce
if tw2 > thresholds(4)-(3*slope_hpt)
    tw2 = thresholds(4)-(3*slope_hpt);
end
% ensure that tw1 is above baseline and not in the pain range
if tw1 < baseline + 1
    tw1 = baseline + 1; %fixing tw1 to above baseline
elseif tw1 >= tw3 %if detection is pratically the same as pain threshold
    tw1 = baseline + 1; %lower to just above baseline
end
% finally, make sure that tw2 is above tw1
% and tw3 is above tw2 and tw4 is above tw3
if tw2 <= tw1 + .5
    tw2 = tw1 + (slope_wdt*3);
end
if tw3 <= tw2 + .5
    tw3 = tw2 + (slope_wdt*3);
end
if tw4 <= tw3 + .5
    if tw3 + (slope_hpt*2) < warm_limit
        tw4 = tw3 + slope_hpt;
    else
         tw4 = tw3 + slope_hpt + 1;
    end
end
% making sure tw4 is not above 50
if tw4 > warm_limit -.1
    tw4 = warm_limit -.1;
end
% making sure tw3 and tw4 are at least 1deg apart
if tw3 + 1 >= tw4
    tw3 = tw4 - 1;
end

%% fixed cold temperatures
      
%% save data
switch TSLtype
    case 1 %warm fixed
        max_temps = [tw1; tw2; tw3; tw4];
        pain_cond = ['innoc';'innoc';'noxio';'noxio'];
        temp_cond = [1; 2; 3; 4];
        stimuli = table(temp_cond,pain_cond,max_temps);
    case 2 %cold fixed
    case 3 %both fixed
    case 4 %thresholding phs in the warm range
        % just need max and minimum warm temperatures for modeling
        stimuli = [tw1; tw4];
        
end

end