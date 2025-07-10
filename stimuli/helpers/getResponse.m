function [Resp, RT, vars] = getResponse(scr, vars, question_type_idx)
    %% Project: tgi-mri
    % Get button press response for tgimri_task.m

    % Developed by A.G. Mitchell from code by Camila Sardeto Deolindo on
    % 23.01.2023
    
    thisTrial = vars.control.thisTrial; %getting trial index for later
    RT = [];
    vars.time.respStart(thisTrial,question_type_idx) = GetSecs();
    
    % if end question, then make sure resptime is long
    if vars.control.finalQ
        responseTime = vars.task.checkRespTime;
    else
        responseTime = vars.task.respTime;
    end
    
    % get response and update button press results
    switch vars.control.inputDevice
        case 1 % keyboard
            [keys] = keyConfig();

            switch vars.display.whichKey{1}%Which buttons to use? Left Right or Up Down?
                case 'LR'
                    key_1 = keys.Left;
                    key_0 = keys.Right;
                    feedbackXPosOffset = 300;
                    feedbackYPosOffset = 150;
                case 'UD'
                    key_1 = keys.Up;
                    key_0 = keys.Down;
                    feedbackXPosOffset = 0;
                    feedbackYPosOffset = 250;
            end
    end


    %% Present question
    qN = size(vars.display.feedback, 1); %get total number of question options
    % screen positions
    YesXPos = ((scr.winRect(3)/2)-feedbackXPosOffset);
    NoXPos = ((scr.winRect(3)/2)+feedbackXPosOffset);
    YPos = ((scr.winRect(4)/2)+feedbackYPosOffset);

    %Screen('FillRect', scr.win, scr.Background, scr.winRect);

    DrawFormattedText(scr.win, uint8(vars.display.question{question_type_idx}), 'center', 'center', scr.TextColour);
    DrawFormattedText(scr.win, uint8(vars.display.feedback{question_type_idx}), YesXPos, YPos,  scr.TextColour);
    DrawFormattedText(scr.win, uint8(vars.display.feedback{question_type_idx+qN}), NoXPos, YPos, scr.TextColour);
    
    [~, answerTimeOn] = Screen('Flip', scr.win);
    questionOn = tic; %question timestamp
    switch vars.control.inputDevice
        case 1 % keyboard
            % kb check
            while ((GetSecs - answerTimeOn) <=  responseTime) && (keys.KeyCode(keys.Left) == 0 ...
                    && keys.KeyCode(keys.Right) == 0)
                %(~any(keys.KeyCode)) && ((GetSecs - answerTimeOn) <=  vars.task.respTime)% wait for press & response time
                    [~, ~, keys.KeyCode] = KbCheck;
                    WaitSecs(0.001);
            end
            
            % KbCheck for response
            if keys.KeyCode(key_1)==1         % Left key
                if mod(str2double(vars.control.ID),2) == 0
                    Resp = 0; %even ID = warm
                else
                    Resp = 1; %odd ID = cold
                end
                RT = toc(questionOn); %RT of response
    %             vars.control.ValidTrial(1) = 1;
            elseif keys.KeyCode(key_0)==1    % Right key
                if mod(str2double(vars.control.ID),2) == 0
                    Resp = 1; %even ID = cold
                else
                    Resp = 0; %odd ID = warm
                end
                RT = toc(questionOn);
    %           vars.control.ValidTrial(1) = 1;
            elseif keys.KeyCode(keys.Escape)==1
                vars.control.Aborted = 1;
                vars.control.RunSuccessful = 0;
                return
            else
                Resp = NaN;
                RT = NaN;
                
    %             vars.control.ValidTrial(1) = 0;
            end
    end

    

    %% Brief feedback
    %Screen
    %feedbackColour = [255 255 255];

    Screen('FillRect', scr.win, scr.Background, scr.winRect);
    if keys.KeyCode(key_1)==1 %if left key pressed
        DrawFormattedText(scr.win, uint8(vars.display.question{question_type_idx}), 'center', 'center', scr.TextColour); %Instruction does not disappear 
        DrawFormattedText(scr.win, uint8(vars.display.feedback{question_type_idx}), YesXPos, YPos, scr.FbColour);
        DrawFormattedText(scr.win, uint8(vars.display.feedback{question_type_idx+qN}), NoXPos, YPos, scr.TextColour);
        
        %feedbackString = 'O';

        %DrawFormattedText(scr.win, feedbackString, feedbackXPos, feedbackYPos, feedbackColour); 
        [~, ~] = Screen('Flip', scr.win);
        WaitSecs(vars.task.feedbackTime);
    elseif keys.KeyCode(key_0)==1 %if right key pressed
        DrawFormattedText(scr.win, uint8(vars.display.question{question_type_idx}), 'center', 'center', scr.TextColour); %Instruction does not disappear 
        DrawFormattedText(scr.win, uint8(vars.display.feedback{question_type_idx}), YesXPos, YPos, scr.TextColour);
        DrawFormattedText(scr.win, uint8(vars.display.feedback{question_type_idx+qN}), NoXPos, YPos, scr.FbColour);

        %DrawFormattedText(scr.win, feedbackString, YesXPos, feedbackYPos, feedbackColour); 
        [~, ~] = Screen('Flip', scr.win);
        WaitSecs(vars.task.feedbackTime);
    else
        DrawFormattedText(scr.win, 'Too slow', 'center', 'center', scr.TextColour);%Instruction does not disappear
        [~, ~] = Screen('Flip', scr.win);
        WaitSecs(vars.task.feedbackTime);
    end


%     % Draw Fixation
%     [~, ~] = Screen('Flip', scr.win);            % clear screen
%     Screen('FillRect', scr.win, scr.BackgroundGray, scr.winRect);
%     scr = drawFixation(scr); % fixation point
%     [~, ~] = Screen('Flip', scr.win);

    %% Brief feedback to experimenter
    if Resp == 1
        disp('Cold') % 
    elseif Resp == 0
        disp('Warm')
    else
        disp('No response recorded.')
    end

    vars.time.respEnd(thisTrial,question_type_idx) = GetSecs();

end