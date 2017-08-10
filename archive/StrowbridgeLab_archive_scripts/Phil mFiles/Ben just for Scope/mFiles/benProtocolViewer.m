function benProtocolViewer(fileName)

if nargin < 1
	error('No file name passed to benProtocolViewer')
end

if length(fileName) > 4 && strcmp(fileName(end - 3:end), '.mat')
	% we have the wrong kind of file here
% 	loadProtocol(fileName);
	return
end

if ~isempty(strfind(fileName, ','))
%     msgbox('Doesn''t work with multiple episodes')
    return
end

if ~isappdata(0, 'benProtocolViewer')
    setappdata(0, 'benProtocolViewer', figure('numbertitle', 'off', 'position', [0 0 530 400], 'menu', 'none', 'closerequestfcn', @closeFigure));
    try
        set(gcf, 'userData', actxcontrol('phil.viewProtocol', [2 0 530 400]));
    catch
        % probably not registered so needs to be
        thisPath = mfilename('fullpath');
        system(['regsvr32 "' thisPath(1:find(thisPath == '\', 1, 'last')) 'phil.ocx"']);
        msgbox('Protocol viewer has just been installed and you need to restart Matlab before it is functional');
    end
end

if nargin > 0
    set(get(getappdata(0, 'benProtocolViewer'), 'userData'), 'showProtocol', fileName);
    set(getappdata(0, 'benProtocolViewer'), 'name', fileName(find(fileName == '\', 1, 'last') + 1:end));
end

function closeFigure(src, eventInfo)
    % removes the handle from the appdata construct
    rmappdata(0, 'benProtocolViewer');
    delete(src)