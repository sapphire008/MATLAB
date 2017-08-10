function outText = autoCorrelate(varargin)
% show an autocorrelogram
persistent correlationBounds

if nargin == 0
    outText = 'Autocorrelate';
else
	if isempty(correlationBounds)
		correlationBounds = [-100 100];
	end
    
	tempData = inputdlg({'Autocorrelation start (ms)', 'Stop'},'Autocorr...',1, {num2str(correlationBounds(1)), num2str(correlationBounds(2))});      
	if numel(tempData) == 0
        return
	end
	correlationBounds = [str2double(tempData(1)) str2double(tempData(2))];
	
    events = getappdata(gca, 'events');
    crossCorr(events(varargin{5}).data', correlationBounds);
end