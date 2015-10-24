function print_vectors(vect_path,pause_dur)
% print the vectors to help user manually check vectors
%
% Inputs: All inputs are optional.
%       vect_path: path to the vector. If not specified or left as empty
%                  argument, the function will use the workspace variables
%       pause_dir: duration to pause. Set to 0 to prevent pause; set to Inf
%                  to pause indefinitely. Default Inf.



% if specified the path of the vector, 
if nargin>0 && ischar(vect_path)
    load(vect_path);
else
    %otherwise, use the workspace variables
    durations = evalin('base','durations');
    names = evalin('base','names');
    onsets = evalin('base','onsets');
end
if nargin<2 || isempty(pause_dur) || ~isnumeric(pause_dur)
    pause_dur = Inf;% pause duration
end

% sanity check to see if each variable of the vector has the same length
LENG = [length(durations),length(names),length(onsets)];
if range(LENG)>0
    error('Variables'' lengths are not the same\ndurations:%d\nnames:%d\nonsets:%d\n',...
        LENG(1),LENG(2),LENG(3));
end

% print each condition names
for n = 1:length(names)
    fprintf('name:%s\n',names{n});
    fprintf('onsets:\n')
    fprintf('%0.3f\n',onsets{n});
    fprintf('duration:%d\n',durations{n});

    % pause printing for the user
switch pause_dur
    case 0
        % do nothing
    case Inf
        pause on;
        pause;% pause indefinitely until subject press the key
        pause off;
        clc;% clear the screen
    otherwise
        pause on;
        pause(pause_dur);
        pause off;
end

end
end