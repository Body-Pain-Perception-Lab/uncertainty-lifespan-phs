%function [keys] = keyConfig(vars)
function keys = keyConfig()

% Set-up keyboard
KbName('UnifyKeyNames')
keys.Escape = KbName('ESCAPE');
keys.Space = KbName('space');

% In scanner
%if ~vars.emulate %if scanning
%     keys.Trigger = KbName('5%');
%     keys.Left = KbName('3#');
%     keys.Right = KbName('4$');
    % to do: find out what these are!
    %keys.Up = KbName('UpArrow');
    %keys.Down = KbName('DownArrow');
%else
    keys.Left = KbName('LeftArrow');
    keys.Right = KbName('RightArrow');
    keys.Up = KbName('UpArrow');
    keys.Down = KbName('DownArrow');
%end

keys.One = KbName('1!');
keys.Two = KbName('2@');
keys.Three = KbName('3#');

keys.Warm = KbName('W');
keys.Cold = KbName('C');

keys.KeyCode = zeros(1,256);

end