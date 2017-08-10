function clearROI(varargin)
%clears current set of ROI

if nargin == 0 || (ischar(varargin{1}) && strcmp(varargin{1}, 'current') && numel(get(findobj('tag', 'cboRoiNumber'), 'string')) == 1)
    % clear them all
    delete(get(findobj('tag', 'roiPlotAxis'), 'children'));
%     set(handleList.frmDisplayROIPlot, 'userData', handleList.chkROIType);
    ROI = get(findobj('tag', 'imageAxis'), 'children');
    delete(ROI(1:end - 6));
    set(findobj('tag', 'cboRoiNumber'), 'string', 'None', 'value', 1);
    setappdata(getappdata(0, 'imageDisplay'), 'ROI', []);
elseif isnumeric(varargin{1})
    % clear the requested ROI
    
elseif ischar(varargin{1}) && strcmp(varargin{1}, 'current')
    % clear the current ROI
   ROI = getappdata(getappdata(0, 'imageDisplay'), 'ROI');
   if ~isempty(ROI)
       currentROI = get(findobj('tag', 'cboRoiNumber'), 'value');
       delete(ROI(currentROI).handle);
       ROI(currentROI) = [];
       set(findobj('tag', 'cboRoiNumber'), 'string', num2str((1:numel(ROI))'), 'value', 1);
       setappdata(getappdata(0, 'imageDisplay'), 'ROI', ROI);
   end
end