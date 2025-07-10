function [scr]=openScreen(scr, vars)
% open screen window
%if ~exist('scr')
    if ~isfield(scr, 'win')
        % Diplay configuration
        [scr] = displayConfig(scr);
        %Screen('Preference', 'SkipSyncTests', 1);
        
        scr.bkColor = scr.Background;
        AssertOpenGL;
        Screen('Preference', 'SkipSyncTests', 1);
        
        if vars.control.devFlag % open smaller screen when in dev mode
          [scr.win, scr.winRect] = PsychImaging('OpenWindow', scr.screenID, scr.Background, [0 0 1000 1000]); %,[0 0 1920 1080] mr screen dim
        else
          [scr.win, scr.winRect] = PsychImaging('OpenWindow', scr.screenID, scr.Background); %,[0 0 1920 1080] mr screen dim
        end
        PsychColorCorrection('SetEncodingGamma', scr.win, 1/scr.GammaGuess);
        
        
        % Set text size, dependent on screen resolution
        if any(logical(scr.winRect(:)>3000))       % 4K resolution
            scr.TextSize =  20;
        else
            scr.TextSize = vars.display.textSize;
        end
        Screen('TextSize', scr.win, scr.TextSize);
        
        % Set priority for script execution to realtime priority:
        scr.priorityLevel = MaxPriority(scr.win);
        Priority(scr.priorityLevel);
        
        % Determine stim size in pixels
        scr.dist = scr.ViewDist;
        scr.width  = scr.MonitorWidth;
        scr.resolutionX = scr.winRect(3); % number of pixels of display in horizontal direction
        scr.resolutionY = scr.winRect(4); % number of pixels in vertical direction
        scr.resolution = [scr.resolutionX scr.resolutionY];
    end
%Send
end
