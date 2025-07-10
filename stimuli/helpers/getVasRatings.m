function [vasResp, vasOffset, vasAns] = getVasRatings(keys, scr, vars, instruction_n, responseTime)
%
% Get the participants confidence response - either keyboard or mouse
% Alexandra G Mitchell, Camila Sardeto Deolindo & Francesca Fardo 
% Last edit: 28/03/2022

    % The avaliable keys to press
    returnKey = keys.Up;

    %returnKey = returnKeys(1);
    leftKey = keys.Left;
    rightKey = keys.Right;

    % We set a time-out for conf rating, b/c otherwise it's Inf...
    [position, vasTimeStamp, RT, answer] = slideScale(scr.win, ...
        vars.display.VASquestion{instruction_n}, ...
        scr.winRect, ...
        vars.display.ConfEndPoints(instruction_n, :), ...
        'scalalength', 0.7,...
        'scalacolor',scr.TextColour,...
        'slidercolor', scr.TextColour,...
        'linelength', 15,...
        'width', 6,...
        'device', 'keyboard', ...
        'responseKeys', [returnKey leftKey rightKey], ...
        'stepsize', 10, ...
        'startposition', 'shuffle', ...
        'range', 2, ...
        'aborttime', responseTime);

    vasOffset = GetSecs();
    %update results and record position of marker           
    vasResp = position;
    vasAns = answer;

    % Show rating in command window
   if ~isnan(vasResp)
       disp(['Rating recorded: ', num2str(vasResp)]); 
   else
       disp(['No rating recorded.']);
   end
            
%             % Rate confidence: 1 Unsure, 2 Sure, 3 Very sure
%             
%             Screen('FillRect', scr.win, scr.BackgroundGray, scr.winRect);
%             DrawFormattedText(scr.win, [vars.instructions.Question{instruction_n}], ...
%                 'center', 'center', scr.TextColour);
%             [~, StartVas] = Screen('Flip', scr.win);
%             vars.StartVas = StartVas;
%             
%             % loop until valid key is pressed or ConfT is reached
%             while (GetSecs - StartVas) <= vars.task.RespT
%                 
%                 % KbCheck for response
%                 if keys.KeyCode(keys.One)==1
%                     % update results
%                     vars.ConfResp = 1;
%                     vars.ValidTrial(2) = 1;
%                 elseif keys.KeyCode(keys.Two)==1
%                     % update results
%                     vars.ConfResp = 2;
%                     vars.ValidTrial(2) = 1;
%                 elseif keys.KeyCode(keys.Three)==1
%                     % update results
%                     vars.ConfResp = 3;
%                     vars.ValidTrial(2) = 1;
%                 elseif keys.KeyCode(keys.Escape)==1
%                     vars.abortFlag = 1;
%                     
%                 else
%                     % DrawText: Please press a valid key...
%                     vars.ValidTrial(2) = 0;
%                 end
%                 
%                 [~, EndVas, keys.KeyCode] = KbCheck;
%                 WaitSecs(0.001);
%             
%                 if ~vars.control.fixedTiming
%                     % Stop waiting when a rating is made
%                     if(vars.ValidTrial(2)), WaitSecs(0.2); break; end
%                 end
%                 
%                 % Compute response time
%                 vars.ConfRatingT = (EndVas - StartVas);
%                 
%             end
%             
%             % show brief feedback
%             if ~isnan(vars.ConfResp)
%                 switch vars.ConfResp
%                     case 1
%                     feedbackXPos = ((scr.winRect(3)/2)-350);
%                     case 2
%                     feedbackXPos = ((scr.winRect(3)/2));
%                     case 3
%                     feedbackXPos = ((scr.winRect(3)/2)+350);
%                 end
%                 
%                 feedbackString = 'O';
%                 Screen('FillRect', scr.win, scr.BackgroundGray, scr.winRect);
%                 DrawFormattedText(scr.win, [vars.InstructionConf], 'center', 'center', scr.TextColour);
%                 DrawFormattedText(scr.win, feedbackString, feedbackXPos, ((scr.winRect(4)/2)+200), scr.AccentColour);
%                 [~, ~] = Screen('Flip', scr.win);
%                 WaitSecs(0.5);
%                 
%                 disp(['Rating ', num2str(instruction_n), ' recorded: ', num2str(vars.ConfResp)]);
%                 
%             else
%                 disp(['No rating ', num2str(instruction_n), ' recorded.']);
%             end
%             
  % Draw Fixation
    [~, ~] = Screen('Flip', scr.win);            % clear screen
    Screen('FillRect', scr.win, scr.Background, scr.winRect);
    scr = drawFixation(scr); % fixation point
    [~, ~] = Screen('Flip', scr.win);
    WaitSecs(0.2);
end