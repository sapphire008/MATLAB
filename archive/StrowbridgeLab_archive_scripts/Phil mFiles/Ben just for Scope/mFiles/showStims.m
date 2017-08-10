function showStims(figHandle, showLegend)
% show TTL stimuli if they are blanked
% modified by BWS on 12/8/08
if ischar(figHandle) && strcmp(figHandle, 'all')
    scopeHandles = getappdata(0, 'scopes');
    for i = scopeHandles
        showStims(i);
    end
    return
end

ttlColors = lines(4);
handles = get(figHandle, 'userData');
for axisHandle = handles.axes
    ylims = get(axisHandle, 'ylim');
    kids = get(axisHandle, 'children');
    delete(kids(strcmp(get(kids, 'userData'), 'stims')));
    possibles = findobj('Label', 'Blank Artifacts');
    for i = 1:numel(possibles)
        if cell2mat(ancestor(possibles(i), 'figure')) == ancestor(axisHandle, 'figure')
            menuHandle = possibles(i);
            break
        end
    end

    kids = get(axisHandle, 'children');
    whichData = find(strcmp(get(kids, 'userData'), 'data'));
    finalKids = [];
    text = cell(4,1);
    if strcmp(get(menuHandle, 'checked'), 'on')
        for traceIndex = 1:numel(whichData)
            try
                protocol = evalin('base', ['zData.protocol(' sprintf('%1.0f', traceIndex) ')']);
            catch
                % there are some traces left that are about to be
                % deleted by a call from fileBrowser
            end
            stimTimes = findStims(protocol, 1);
            % line below changed to start at 2 by BWS on 12/8/08
            for ttlIndex = 2:numel(protocol.ttlEnable)
                if ~isempty(stimTimes{ttlIndex}) && ((protocol.ttlStepEnable{ttlIndex} && protocol.ttlStepDuration{ttlIndex} > 1) || (protocol.ttlPulseEnable{ttlIndex} && protocol.ttlPulseDuration{ttlIndex} > 1000))
                    digOut = zeros(protocol.sweepWindow * 1000 / protocol.timePerPoint, 1);         
                    pointsPerMsec = 1000 / protocol.timePerPoint;
                    
                    % step
                    if protocol.ttlStepEnable{ttlIndex}
                        digOut(protocol.ttlStepLatency{ttlIndex} * pointsPerMsec:(protocol.ttlStepLatency{ttlIndex} + protocol.ttlStepDuration{ttlIndex}) * pointsPerMsec) = 1;
                    end

                    % pulses
                    if protocol.ttlPulseEnable{ttlIndex}
                        pulsePoints = round(protocol.ttlPulseDuration{ttlIndex} / protocol.timePerPoint);           

                        % arbitrary
                        if protocol.ttlArbitraryEnable{ttlIndex}
                            whichPoints = eval(protocol.ttlArbitrary{ttlIndex}) * pointsPerMsec;
                            digOut(whichPoints:whichPoints + pulsePoints) = 1;
                        end

                        % train
                        if protocol.ttlTrainEnable{ttlIndex}
                            for trainIndex = 0:protocol.ttlTrainNumber{ttlIndex} - 1
                                if protocol.ttlBurstEnable{ttlIndex}
                                    % train of bursts
                                    for burstIndex = 0:protocol.ttlBurstNumber{ttlIndex} - 1
                                        digOut((protocol.ttlTrainLatency{ttlIndex} + trainIndex * protocol.ttlTrainInterval{ttlIndex} + burstIndex * protocol.ttlBurstInterval{ttlIndex}) * pointsPerMsec + (1:pulsePoints)) = 1;                    
                                    end
                                else
                                    digOut((protocol.ttlTrainLatency{ttlIndex} + trainIndex * protocol.ttlTrainInterval{ttlIndex}) * pointsPerMsec + (1:pulsePoints)) = 1;                    
                                end
                            end
                        end
                    end                      
                    lineHandle = line((0:length(digOut) - 1) .* (protocol.timePerPoint / 1000), (ylims(1) + .002 * diff(ylims)) + digOut .* .03 * diff(ylims), 'parent', axisHandle, 'color', ttlColors(ttlIndex,:));
                    set(lineHandle, 'userData', 'stims');
                    finalKids = [finalKids lineHandle];
                else
                    for stimIndex = 1:size(stimTimes{ttlIndex}, 1)  
                        if stimTimes{ttlIndex}(stimIndex, 1) <= protocol.sweepWindow
                            % BWS added this line to correct SIU delays
                            % with VB6 ITC Aquire program
                            stimTimes{ttlIndex}(stimIndex,1)=stimTimes{ttlIndex}(stimIndex,1)+1;
                            lineHandle = line(stimTimes{ttlIndex}(stimIndex,1), (ylims(1) + .007 * diff(ylims)), 'parent', axisHandle, 'linestyle', 'none', 'marker', '^', 'markeredgecolor', ttlColors(ttlIndex,:), 'markerfacecolor', ttlColors(ttlIndex,:), 'markersize', 10);
                            set(lineHandle, 'userData', 'stims');
                            finalKids = [finalKids lineHandle];
                        end
                    end
                end
                if ~isempty(stimTimes{ttlIndex}) && (numel(text{ttlIndex}) < numel(protocol.ttlTypeName{ttlIndex}) || ~strcmp(text{ttlIndex}(1:end - numel(protocol.ttlTypeName{ttlIndex}) + 1), protocol.ttlTypeName{ttlIndex}))
                    if numel(text{ttlIndex}) > numel(protocol.ttlTypeName{ttlIndex})
                        text{ttlIndex} = [text{ttlIndex} ' or '];
                    end
                    if strcmp(protocol.ttlTypeName{ttlIndex}, 'Unknown')
                        text{ttlIndex} = [text{ttlIndex} '\color[rgb]{' num2str(ttlColors(ttlIndex, :)) '}TTL' num2str(ttlIndex)];
                    else
                        text{ttlIndex} = [text{ttlIndex} '\color[rgb]{' num2str(ttlColors(ttlIndex, :)) '}' protocol.ttlTypeName{ttlIndex}];
                    end
                end
            end
            finalKids = [finalKids kids(whichData(traceIndex))];
        end
        set(axisHandle, 'children', [finalKids kids(~strcmp(get(kids, 'userData'), 'data'))']);
    end
end
if nargin > 1
    msgbox(text(cellfun(@(x) ~isempty(x), text)), struct('Interpreter', 'tex', 'WindowStyle', 'non-modal'))
end