function captureGUI

if ~isappdata(0, 'imageCapture')
	if ~ispref('locations', 'imageCapture')
		setpref('locations', 'imageCapture', [100 100 640 480]);
	end
	
	figHandle = figure('resize', 'off', 'menu', 'none', 'Name', 'Capture', 'numbertitle', 'off', 'units', 'pixels', 'position', getpref('locations', 'imageCapture'), 'closerequestfcn', @closeMe);
    try
        imageHandle = actxcontrol('vbVidC60.ezVidCap', [0 0 640 480]);
    catch
        delete(gcf)
        
        if ~isdeployed
            thisPath = mfilename('fullpath');
            system(['regsvr32 "' thisPath(1:find(thisPath == '\', 1, 'last')) 'ezVidC60.ocx"']);
            msgbox('DIC capture has just been installed and you need to restart Matlab before it is functional');       
        end
        return
    end
	set(imageHandle, 'stretchPreview', 1, 'captureFile', 'C:\Capture.avi');
	set(figHandle, 'userData', imageHandle);
	
	% set up menus
	captureMenu = uimenu('label', 'Capture');
	uimenu(captureMenu, 'label', 'Preview', 'accelerator', 'P', 'checked', 'on', 'callback', @setPreview);
	uimenu(captureMenu, 'label', 'Single Frame', 'accelerator', 'S', 'callback', @captureSingle);
	uimenu(captureMenu, 'label', 'Reference Frame', 'accelerator', 'R', 'callback', @captureReference);
	setupMenu = uimenu('label', 'Setup');
	uimenu(setupMenu, 'label', 'Format...', 'callback', 'invoke(get(getappdata(0, ''imageCapture''), ''userData''), ''ShowDlgVideoFormat'');');
	uimenu(setupMenu, 'label', 'Source...', 'callback', 'invoke(get(getappdata(0, ''imageCapture''), ''userData''), ''ShowDlgVideoSource'');');
	uimenu(setupMenu, 'label', 'Display...', 'callback', 'invoke(get(getappdata(0, ''imageCapture''), ''userData''), ''ShowDlgVideoDisplay'');');
	uimenu(setupMenu, 'label', 'Compression...', 'callback', 'invoke(get(getappdata(0, ''imageCapture''), ''userData''), ''ShowDlgCompressionOptions'');');
	
	% set as appdata
	setappdata(0, 'imageCapture', figHandle);
	
	if ~ispref('objectives', 'nominalMagnification')
		error('No objectives calibrated for this setup');
	else
		objectives = getpref('objectives', 'nominalMagnification');
		uimenu(setupMenu, 'label', objectives{1}, 'sep', 'on', 'checked', 'on', 'callback', @setObjective);	
		setappdata(imageHandle, 'objective', 1);
		for i = 2:numel(objectives)
			uimenu(setupMenu, 'label', objectives{i}, 'callback', @setObjective);
		end
	end
else
	figHandle = figure(getappdata(0, 'imageCapture'));
end

onScreen(getappdata(0, 'imageCapture'));

	function closeMe(varargin)
		setpref('locations', 'imageCapture', get(figHandle, 'position'));
		rmappdata(0, 'imageCapture');
		delete(figHandle);
	end

	function setPreview(varargin)
		if strcmp(get(varargin{1}, 'checked'), 'on')
			set(varargin{1}, 'checked', 'off');
			set(imageHandle, 'Preview', 0)
		else
			set(varargin{1}, 'checked', 'on');
			set(imageHandle, 'Preview', 1)		
		end
	end

	function captureSingle(varargin)

		invoke(imageHandle, 'CapSingleFrame');
		% matlab's clipboard handling can't do images so we write this to a
		% file and then read it from there
		if isappdata(0, 'experiment')
			experimentInfo = getappdata(0, 'currentExperiment');
			tempHandles = guihandles(getappdata(0, 'experiment'));
			fileName = [get(tempHandles.mnuSetDataFolder, 'userData') filesep experimentInfo.cellName '.' datestr(clock, 'ddmmmyy') '.1.pic'];	
		else
			fileName = ['R:\' datestr(now, 'ddmmmyy HH.MM.SS') '.pic'];
		end
		invoke(imageHandle, 'SaveDIB', 'C:\tempFile.bmp');
		set(imageHandle, 'Preview', strcmp(get(findobj('label', 'Preview', 'type', 'uimenu'), 'checked'), 'on'));
		fileName = writeBiorad(fileName, 'C:\tempFile.bmp', getappdata(imageHandle, 'objective'));	
		imageBrowser(fileName);
	end

	function captureReference(varargin)

		invoke(imageHandle, 'CapSingleFrame');
		% matlab's clipboard handling can't do images so we write this to a
		% file and then read it from there
		if isappdata(0, 'experiment')
			experimentInfo = getappdata(0, 'currentExperiment');
			tempHandles = guihandles(getappdata(0, 'experiment'));
			fileName = [get(tempHandles.mnuSetDataFolder, 'userData') filesep experimentInfo.cellName '.' datestr(clock, 'ddmmmyy') '.' experimentInfo.nextEpisode '.pic'];	
		else
			fileName = ['R:\' datestr(now, 'ddmmmyy HH.MM.SS') '.pic'];
		end
		invoke(imageHandle, 'SaveDIB', 'C:\tempFile.bmp');
		fileName = writeBiorad(fileName, 'C:\tempFile.bmp', getappdata(imageHandle, 'objective'));	
		setReference(fileName);
		set(imageHandle, 'Preview', strcmp(get(findobj('label', 'Preview', 'type', 'uimenu'), 'checked'), 'on'));
	end

	function setObjective(varargin)
		kids = get(get(varargin{1}, 'parent'), 'children');
		set(kids(kids ~= varargin{1}), 'checked', 'off');
		set(varargin{1}, 'checked', 'on');
		objectives = getpref('objectives', 'nominalMagnification');
		setappdata(imageHandle, 'objective', find(strcmp(objectives, get(varargin{1}, 'label'))));
	end
end