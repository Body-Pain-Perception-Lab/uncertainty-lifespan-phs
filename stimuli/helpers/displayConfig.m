function [scr] = displayConfig(scr)
%function [scr] = displayConfig(scr)
%
    % Called by main.m
    % Input: 
    %   scr         struct with screen / display settings
    % 
    % Niia Nikolova
    % Last edit: 16/06/2020


    %% Set-up screen
    if length(Screen('Screens')) > 1
        scr.ExternalMonitor = 1;% set to 1 for secondary monitor
        % N.B. It's not optimal to use external monitor for newer Win systems
        % (Windows 7+) due to timing issues
    else
        scr.ExternalMonitor = 0;
    end

    if scr.ExternalMonitor
    %     scr.screenID = max(Screen('Screens')); 
        scr.screenID = 1;
        if ~isfield(scr,'MonitorHeight') || isempty(scr.MonitorHeight)
            scr.MonitorHeight = 23; end     % in cm 
        if ~isfield(scr,'MonitorWidth') || isempty(scr.MonitorWidth)
            scr.MonitorWidth = 38; end
        if ~isfield(scr,'ViewDist') || isempty(scr.ViewDist)
            scr.ViewDist = 56; end
        scr.GammaGuess = 2.3;

    else % Laptop
        scr.screenID = min(Screen('Screens')); 
        if ~isfield(scr,'MonitorHeight') || isempty(scr.MonitorHeight)
            scr.MonitorHeight = 16.5; end
        if ~isfield(scr,'MonitorWidth') || isempty(scr.MonitorWidth)
            scr.MonitorWidth = 23.5; end
        if ~isfield(scr,'ViewDist') || isempty(scr.ViewDist)
            scr.ViewDist = 40; end
        scr.GammaGuess = 2.6;
    end

    % Colour correction
    PsychImaging('PrepareConfiguration');
    PsychImaging('AddTask', 'FinalFormatting', 'DisplayColorCorrection', 'SimpleGamma');


    %% Colours and text params
    scr.Background = ([.4 .4 .4])*255;
    scr.TextColour = ([.01 .01 .01])*255;
    scr.FbColour = ([.9 .9 .9])*255;
    %scr.BackgroundGray = 90;        %   GrayIndex(scr.screenID, 0.3);

end