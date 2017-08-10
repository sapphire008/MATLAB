function checkAcquisitionRate

if ~isappdata(0, 'experiment')
	% not acquiring so no worries
	return
end
% verify that the rate chosen is possible

handles = get(getappdata(0, 'runningProtocol'), 'userData');
whichRate = find(strcmp(get(handles.acquisitionRate, 'string'), num2str(1e3/str2double(get(handles.timePerPoint, 'string')))));
if ~isempty(whichRate)
    set(handles.acquisitionRate, 'value', whichRate);
else
    set(handles.acquisitionRate, 'value', numel(get(handles.acquisitionRate, 'string')));    
end
hwNames = get(handles.source, 'string');
switch hwNames{get(handles.source, 'value')}
    case 'ITC-18'
		experimentData = getappdata(0, 'currentExperiment');
		protocolData = getappdata(0, 'currentProtocol');
        currentTime = str2double(get(handles.timePerPoint, 'string'));
		digitalOuts = sum(cell2mat(experimentData.ttlEnable));
		if isfield(experimentData, 'ampEnable')
			analogOuts = sum(cell2mat(experimentData.ampEnable) & (cell2mat(protocolData.ampTpEnable) | cell2mat(protocolData.ampMonitorRin) | (cell2mat(protocolData.ampStimEnable) & (cell2mat(protocolData.ampStepEnable) | cell2mat(protocolData.ampPspEnable) | cell2mat(protocolData.ampSineEnable) | cell2mat(protocolData.ampRampEnable) | cell2mat(protocolData.ampTrainEnable) | cell2mat(protocolData.ampPulseEnable) | ~cellfun('isempty', protocolData.ampMatlabStim))) | ~cellfun('isempty', protocolData.ampMatlabCommand)));
		else
			analogOuts = 0;
		end		
		tempData = cellfun(@(x) ~isempty(x) && (isa(x, 'function_handle') | (isa(x, 'double') && ~isnan(x))), getappdata(0, 'adScaleFactors'));
		numInstructions = max([sum(tempData(:,1)) digitalOuts + analogOuts]);
        if ~any((currentTime ./ (numInstructions + (0:3)) ./ 1.25) == round(currentTime ./ (numInstructions + (0:3)) ./ 1.25))
            [whichRate whichRate] = min([currentTime - round(currentTime ./ (numInstructions + (1:3)) ./ 1.25) .* 1.25 .* (numInstructions + (1:3))]);
			currentTime = 1.25 * (numInstructions + whichRate - 1) * round(currentTime / (numInstructions + whichRate - 1) / 1.25);
			msgbox(['Sampling rate for the ITC-18 must be a multiple of 1.25 us times the number of channels read and written.  The rate will be set at ' num2str(currentTime)]);
            set(handles.timePerPoint, 'string', num2str(1.25 * round(currentTime / 1.25)));
        end
    otherwise
        adBoard = getappdata(0, 'adBoard');
        timePerPoint = str2double(get(handles.timePerPoint, 'string'));
        if timePerPoint < 1e6 / adBoard.maxSampleRate
            set(handles.timePerPoint, 'string', num2str(1e6 / adBoard.maxSampleRate));
        end
        if timePerPoint > 1e6 / adBoard.minSampleRate
            set(handles.timePerPoint, 'string', num2str(1e6 / adBoard.minSampleRate));
        end        
end