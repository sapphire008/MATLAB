function [onset_index] = mapping_images_from_event_name(SPM,event)
%[onset_index] = mapping_images_from_event_name(SPM,event,series_length)
% onset_index = the index of the onset locations for a given event
%
% SPM = the SPM data structure
% event = a string that matches an event name in the SPM design
%

offset = 0;
for n = 1:size(SPM.Sess,2),  % loop through each block
    timeline = SPM.xY.RT * (0:SPM.nscan(n));  % TR * number of scans gives the timeing for the block
    j = 1;
    % loop through each modeled event to locate the matching condition
    for k = 1:size(SPM.Sess(n).U,2),
        
        name=SPM.Sess(n).U(k).name{1};
        % compare strings based on the length of the longest string
        if length(name)>length(event)
            cutoff_length=length(name);
        else
            cutoff_length=length(event);
        end
        
        if strncmp(name, event, cutoff_length) % compare strings
            if length(SPM.Sess(n).U(k).ons) == 1,   % if only a single onset value
                onset_index(n).onset(j) = round(SPM.Sess(n).U(k).ons);
                j = j + 1;
            else %                                    if several onset values
                onset_index(n).onset(j:length(SPM.Sess(n).U(k).ons)) = round(SPM.Sess(n).U(k).ons);%onset_index(n).onset(j:j+length(SPM.Sess(n).U(k).ons)) = round(SPM.Sess(n).U(k).ons);
                j = j + length(SPM.Sess(n).U(k).ons);
            end
        end
    end
    %if onset_index does not exit in the first block skip this section
    if exist('onset_index')
        % catch the case of an event not occuring within a block
        if size(onset_index,2) < n,
            onset_index(n).index = [];
            onset_index(n).onset = [];
        else
            for k = 1:length(onset_index(n).onset),
                [foo onset_index(n).index(k)]= min(abs(timeline - onset_index(n).onset(k)));  % find the volume index closest to the onset time
                onset_index(n).index(k) = onset_index(n).index(k) + offset;  % increase index by the number of scans by number of scans so far (offset)
            end
        end
        offset = offset + SPM.nscan(n); % increment offset by number of scans in block
    else
        error('event name does not exist');
    end
end

% strip out any empty blocks (empty because event did not occur)
onset_index = onset_index(~cellfun('isempty',{onset_index.index}));


