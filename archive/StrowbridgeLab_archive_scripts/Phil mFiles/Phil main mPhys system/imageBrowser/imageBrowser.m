function imageBrowser(startingDir)
% can pass a starting directory, a file to open, or a zImage structure

if ~isappdata(0, 'imageBrowser')
    if ~isdeployed
        % determine what directory this file is in
            thisDir = which('imageBrowser');
            thisDir = thisDir(1:find(thisDir == filesep, 1, 'last'));

        %load extra color tables if not already present
            colorPath = strcat(fullfile(matlabroot,'toolbox','matlab','graph3d'), filesep);
            if ~exist(strcat(colorPath, 'bnw.m'), 'file')
                copyfile([thisDir 'red.m'], strcat(colorPath, 'red.m'), 'f');
                copyfile([thisDir 'blue.m'], strcat(colorPath, 'blue.m'), 'f');
                copyfile([thisDir 'green.m'], strcat(colorPath, 'green.m'), 'f');
                copyfile([thisDir 'purple.m'], strcat(colorPath, 'purple.m'), 'f');
                copyfile([thisDir 'yellow.m'], strcat(colorPath, 'yellow.m'), 'f');
                copyfile([thisDir 'cyan.m'], strcat(colorPath, 'cyan.m'), 'f');
                copyfile([thisDir 'purple2green.m'], strcat(colorPath, 'purple2green.m'), 'f');
                copyfile([thisDir 'yellow2blue.m'], strcat(colorPath, 'yellow2blue.m'), 'f');
                copyfile([thisDir 'cyan2red.m'], strcat(colorPath, 'cyan2red.m'), 'f');
                copyfile([thisDir 'redSat.m'], strcat(colorPath, 'redSat.m'), 'f');
                copyfile([thisDir 'bnw.m'], strcat(colorPath, 'bnw.m'), 'f');
            end

        % copy the monitors off program to the R drive
    %         copyfile([thisDir 'monitorsOff.exe'], 'R:\monitorsOff.exe');
    end
	
	if ~exist('startingDir', 'var')
        startingDir = pwd;
        if isappdata(0, 'currentExperiment')
            expData = getappdata(0, 'currentExperiment');
            if exist(expData.dataFolder, 'file')
                startingDir = expData.dataFolder;
            end
        end
		tempDir = startingDir;
    else
        tempDir = startingDir;
        if isstruct(startingDir)
            startingDir = startingDir.info.Filename;
        end
        if startingDir(end - 3)  == '.'
            if ~isempty(startingDir)
				startingDir = startingDir(1:find(startingDir == filesep, 1, 'last'));
            end		
            if ~exist(tempDir, 'file')     
                % if the original file doesn't exist then just key to the dir
                tempDir = startingDir;
            end            
        end
        if ~exist(startingDir, 'file')
            startingDir = pwd; 
        end
	end
	controlForm;
    imageDisplayForm;
    plotForm;
    plotROIForm;
    photometryPathForm;
    galvoTrajectoriesForm;
    rasterForm;
    locPlotForm;
	setappdata(getappdata(0, 'imageBrowser'), 'info', 0);

    % create some appdata that we'll use throughout
    fiducials = struct('set', 0);
    setappdata(getappdata(0, 'imageDisplay'), 'fiducials', fiducials);
    setappdata(getappdata(0, 'imageDisplay'), 'ROI', []);
    setappdata(getappdata(0, 'imageDisplay'), 'tempROI', []);
	
	if ~ispref('imageBrowser', 'exportSettings')
        setpref('imageBrowser', 'exportSettings', [1 1 1]);
	end    
	setMap;
	startingDir = tempDir;
else
% 	figure(getappdata(0, 'displayPlot'));
% 	figure(getappdata(0, 'imageDisplay'));
% 	figure(getappdata(0, 'imageBrowser'));
end

if nargin > 0
	if isstruct(startingDir)
		assignin('base', 'zImage', startingDir);

		setappdata(getappdata(0, 'imageBrowser'), 'info', startingDir.info);
		updateAverage;
		displayImage;
		set(findobj('tag', 'imageAxis'),...
			'units', 'normal',...
			'Ylim', [0.5 startingDir.info.Height + 0.5],...
			'Xlim', [0.5 startingDir.info.Width + 0.5],...
			'position', [0 0 1 1],...
			'UserData', 1,...
			'units', 'pixel');
		set(findobj('tag', 'hScroll'), 'value', 0.5, 'userData', 0.5, 'sliderStep', [.1, inf]);
		set(findobj('tag', 'vScroll'), 'value', 0.5, 'userData', 0.5, 'sliderStep', [.1, inf]);	
		resizeImage;		
	else
		if ~isempty(startingDir) && numel(startingDir) > 3 && startingDir(end - 3) == '.'
			% display the image
			zImage = readImage(startingDir);
			assignin('base', 'zImage', zImage);

			setappdata(getappdata(0, 'imageBrowser'), 'info', zImage.info);
			updateAverage;
			displayImage;
			set(findobj('tag', 'imageAxis'),...
				'units', 'normal',...
				'Ylim', [0.5 zImage.info.Height + 0.5],...
				'Xlim', [0.5 zImage.info.Width + 0.5],...
				'position', [0 0 1 1],...
				'UserData', 1,...
				'units', 'pixel');
			set(findobj('tag', 'hScroll'), 'value', 0.5, 'userData', 0.5, 'sliderStep', [.1, inf]);
			set(findobj('tag', 'vScroll'), 'value', 0.5, 'userData', 0.5, 'sliderStep', [.1, inf]);	
			set(findobj('label', 'Open...'), 'userData', startingDir(1:find(startingDir == '\', 1, 'last')));
			set(findobj('label', 'Open Z Stack...'), 'userData', startingDir(1:find(startingDir == '\', 1, 'last')));
			set(findobj('label', 'Combine Z-Stacks...'), 'userData', startingDir(1:find(startingDir == '\', 1, 'last')));            
			resizeImage;
		else
			% set the open directory to be that passed
			set(findobj('label', 'Open...'), 'userData', startingDir);
			set(findobj('label', 'Open Z Stack...'), 'userData', startingDir);
			set(findobj('label', 'Combine Z-Stacks...'), 'userData', startingDir);
		end
	end
end


	function controlForm
		% generate the imageBrowser form
		propStruct.userData = startingDir;
		handles = guihandles(hgload('imageBrowser.fig', propStruct));
		
		% set its location
		if ~ispref('locations', 'imageBrowser')
			setpref('locations', 'imageBrowser', [1 75 150.83 11.93]);
		end	        
		set(handles.frmImageBrowser, 'closeRequestFcn', @closeMain, 'position', getpref('locations', 'imageBrowser'));
        onScreen(handles.frmImageBrowser);
        
		set(handles.mnuDisplayScaleBar, 'callback', @displayScaleBar);
        set(handles.mnuExportSettings, 'callback', @exportSettings);
        set(handles.mnuScanCurrentRoi, 'callback', {@scanRoi, 0, 0});
        set(handles.mnuScanAllRoi, 'callback', {@scanRoi, 1, 0});
        set(handles.mnuTestCurrentRoi, 'callback', {@scanRoi, 0, 1});
        set(handles.mnuTestAllRoi, 'callback', {@scanRoi, 1, 1});  
        set(handles.mnuClearTestLine, 'callback', {@scanRoi, -1, -1});
        set(handles.mnuRasterCurrentRoi, 'callback', @rasterRoi);
		set(handles.cmdZoomDirect, 'callback', @zoomDirect);
		set(handles.cmdZoomIn, 'callback', @zoomIn);
		set(handles.cmdZoomOut, 'callback', @zoomOut);
		set(handles.hScroll, 'callback', @hScroll, 'sliderStep', [1 inf]);
		set(handles.vScroll, 'callback', @vScroll, 'sliderStep', [1 inf]);
		set(handles.cboPalette, 'callback', @setMap);
		set(handles.chkInvertPalette, 'callback', @setMap);
		set(handles.cmdSetAsBaseline, 'callback', @setBaseline);
		set(handles.cmdZoomType, 'callback', @setZoomType);
		set(handles.cmdPanType, 'callback', @setPanType);
		set(handles.chkAutoscalePalette, 'callback', @setPaletteScale);
        set(handles.cboROIShape, 'callback', @setRoiShape);
        set(handles.cboRoiNumber, 'callback', @setRoiNumber);
        set(handles.txtRotations, 'callback', @setRotations);
        set(handles.txtPointsPerRotation, 'callback', @setPointsPerRotation);
        set(handles.txtNucleusCenterX, 'callback', @setNucleusCenterX);
        set(handles.txtNucleusCenterY, 'callback', @setNucleusCenterY);
        set(handles.txtLissajousX, 'callback', @setLissajousX);
        set(handles.txtLissajousY, 'callback', @setLissajousY);
        set(handles.txtRoiSegments, 'callback', @setRoiSegments);
        imageCommands = loadMatlabText('imageBrowserCommands.txt');
        set(handles.txtCommand,'userData', {size(imageCommands, 2) + 1, imageCommands},'keyPressFcn', @commandKeyPress);
        setappdata(handles.txtCommand, 'callback', 'displayImage');
        
		setappdata(0, 'imageBrowser', handles.frmImageBrowser);
		set(handles.frmImageBrowser, 'userData', handles);
		setMap;

		function closeMain(varargin)
            % save the locations
            set(getappdata(0, 'imageDisplay'), 'units', 'pixels');
            setpref('locations', 'imageDisplay', get(getappdata(0, 'imageDisplay'), 'position'));	
            set(getappdata(0, 'displayPlot'), 'units', 'pixels');
            setpref('locations', 'displayPlot', get(getappdata(0, 'displayPlot'), 'position'));	
            set(getappdata(0, 'roiPlot'), 'units', 'pixels');
            setpref('locations', 'roiPlot', get(getappdata(0, 'roiPlot'), 'position'));	
            set(getappdata(0, 'rasterPlot'), 'units', 'pixels');
            setpref('locations', 'rasterPlot', get(getappdata(0, 'rasterPlot'), 'position'));	
            set(getappdata(0, 'photometryPath'), 'units', 'pixels');
            setpref('locations', 'photometryPath', get(getappdata(0, 'photometryPath'), 'position'));	
            set(getappdata(0, 'locPlot'), 'units', 'pixels');
            setpref('locations', 'locPlot', get(getappdata(0, 'locPlot'), 'position'));	
            set(getappdata(0, 'galvoTrajectories'), 'units', 'pixels');
            setpref('locations', 'galvoTrajectories', get(getappdata(0, 'galvoTrajectories'), 'position'));	
            set(getappdata(0, 'imageBrowser'), 'units', 'characters');
            setpref('locations', 'imageBrowser', get(getappdata(0, 'imageBrowser'), 'position'));	
            
			% delete the figures
			delete(getappdata(0, 'imageDisplay'));
			delete(getappdata(0, 'displayPlot'));
			delete(getappdata(0, 'roiPlot'));
			delete(getappdata(0, 'rasterPlot'));
            delete(getappdata(0, 'photometryPath'));
			delete(getappdata(0, 'locPlot'));
            delete(getappdata(0, 'galvoTrajectories'));
			delete(getappdata(0, 'imageBrowser'));  
			if isappdata(0, 'scaleBar')
				delete(getappdata(0, 'scaleBar'));
				rmappdata(0, 'scaleBar');
			end
			% remove the app data
			rmappdata(0, 'imageDisplay');
			rmappdata(0, 'displayPlot');
			rmappdata(0, 'roiPlot');
            rmappdata(0, 'photometryPath');
			rmappdata(0, 'rasterPlot');
			rmappdata(0, 'locPlot');
            rmappdata(0, 'galvoTrajectories');
			rmappdata(0, 'imageBrowser');
        end
		
        function displayScaleBar(varargin)
            if strcmp(get(varargin{1}, 'checked'), 'on')
                set(varargin{1}, 'checked', 'off');
                delete(findobj(findobj('tag', 'imageAxis'), 'tag', 'scaleBar'));
            else
                set(varargin{1}, 'checked', 'on');
                scaleBar(findobj('tag', 'imageAxis'), evalin('base', 'zImage.info'));
            end            
        end
        
		function zoomDirect(varargin)
		% set zoom of imageDisplayForm to 1

			info = getappdata(handles.frmImageBrowser, 'info');

			set(findobj('tag', 'imageAxis'),...
				'units', 'normal',...
				'Ylim', [0.5 info.Height + 0.5],...
				'Xlim', [0.5 info.Width + 0.5],...
				'position', [0 0 1 1],...
				'UserData', 1,...
				'units', 'pixel');

			% set scrollers to 0
			set(handles.hScroll, 'value', 0.5, 'userData', 0.5, 'sliderStep', [.1 inf]);
			set(handles.vScroll, 'value', 0.5, 'userData', 0.5, 'sliderStep', [.1 inf]);
		end
		
		function zoomIn(varargin)
		% set the zoom of the imageDisplayForm to twice the current

			imageAxis = findobj('tag', 'imageAxis');

			%reset dims
			set(imageAxis,...
				'Ylim', get(imageAxis, 'ylim') + [1/4 -1/4] .* diff(get(imageAxis, 'ylim')),...
				'Xlim', get(imageAxis, 'xlim') + [1/4 -1/4] .* diff(get(imageAxis, 'xlim')));
			setScroll;
		end
		
		function zoomOut(varargin)
		% set the zoom of the imageDisplayForm to half the current

			imageAxis = findobj('tag', 'imageAxis');	
			info = getappdata(getappdata(0, 'imageBrowser'), 'info');
			if diff(get(imageAxis, 'xlim')) * 2 > info.Width
				zoomDirect;
				return
			end
			%reset dims
			set(imageAxis,...
				'Ylim', get(imageAxis, 'ylim') + [-1/2 1/2] .* diff(get(imageAxis, 'ylim')),...
				'Xlim', get(imageAxis, 'xlim') + [-1/2 1/2] .* diff(get(imageAxis, 'xlim')));
			setScroll;
		end
		
		function hScroll(varargin)
		%scroll in the horizontal direction

			imageAxis = findobj('tag', 'imageAxis');
			info = getappdata(handles.frmImageBrowser, 'info');
			% if a large increment was sent then move by one frame width			
			% if a small increment was sent then move by a fifth of a frame
			newLim = (info.Width - diff(get(imageAxis, 'xlim'))) * get(gcbo, 'value');
			newLim(2) = newLim + diff(get(imageAxis, 'xlim'));
			
			% limit to the image
			if newLim(1) < 0.5
				newLim = [0.5 0.5 + diff(newLim)];
			end
			if newLim(2) > info.Width - 0.5
				newLim = info.Width - 0.5 - [diff(newLim) 0];
			end
			set(gcbo, 'value', newLim(1) / (info.Width - diff(get(imageAxis, 'xlim'))));
			set(imageAxis, 'xlim', newLim);
		end

		function vScroll(varargin)
		%scroll in the vertical direction
			imageAxis = findobj('tag', 'imageAxis');
			info = getappdata(handles.frmImageBrowser, 'info');
			% if a large increment was sent then move by one frame width			
			% if a small increment was sent then move by a fifth of a frame
			newLim = (info.Height - diff(get(imageAxis, 'ylim'))) * get(gcbo, 'value');
			newLim(2) = newLim + diff(get(imageAxis, 'ylim'));
            
			% limit to the image
			if newLim(1) < 0.5
				newLim = [0.5 0.5 + diff(newLim)];
			end
			if newLim(2) > info.Height - 0.5
				newLim = info.Height - 0.5 - [diff(newLim) 0];
			end
			set(gcbo, 'value', newLim(1) / (info.Height - diff(get(imageAxis, 'ylim'))));
			set(imageAxis, 'ylim', newLim);
		end
		
		function setZoomType(varargin)
			if strcmp(get(gcbo, 'string'), 'Mouse')
				set(gcbo, 'string', 'Standard');
				h = zoom(getappdata(0, 'imageDisplay'));
				set(h, 'actionPostCallback', @setScroll);
				set(h, 'enable', 'on');
				set(findobj('tag', 'cmdPanType'), 'string', 'Free Pan');
			else
				set(gcbo, 'string', 'Mouse');
				zoom(getappdata(0, 'imageDisplay'), 'off');
			end
		end
		
		function setPanType(varargin)
			if strcmp(get(gcbo, 'string'), 'Free Pan')
				set(gcbo, 'string', 'Scrollers');
				h = pan(getappdata(0, 'imageDisplay'));
				set(h, 'actionPostCallback', @setScroll);
				set(h, 'enable', 'on');
				set(findobj('tag','cmdZoomType'), 'string', 'Mouse');
			else
				set(gcbo, 'string', 'Free Pan');
				pan(getappdata(0, 'imageDisplay'), 'off');
			end
		end
		
		function setPaletteScale(varargin)
			if get(handles.chkAutoscalePalette, 'value')
				set([handles.txtPaletteMin handles.lblPalette handles.txtPaletteMax], 'visible', 'off');
				set(handles.cmdAdjustColor, 'visible', 'on');
				set(findobj('tag', 'imageAxis'), 'climMode', 'auto');
			else
				set([handles.txtPaletteMin handles.lblPalette handles.txtPaletteMax], 'visible', 'on');
				set(handles.cmdAdjustColor, 'visible', 'off');
				set(findobj('tag', 'imageAxis'), 'climMode', 'manual');
				set(handles.txtPaletteMin, 'string', sprintf('%1.3f', min(get(findobj('tag', 'imageAxis'), 'clim'))));
				set(handles.txtPaletteMax, 'string', sprintf('%1.3f', max(get(findobj('tag', 'imageAxis'), 'clim'))));				
			end
		end
		
		function setScroll(varargin)
			% set the scroll bars to be where mouse zoom/pan set them
			imageAxis = findobj('tag', 'imageAxis');
			info = getappdata(handles.frmImageBrowser, 'info');
			zoomFactor = info.Width / diff(get(imageAxis, 'xlim'));
			newStep = 1 / zoomFactor / (1- 1 / zoomFactor);
			set(handles.hScroll, 'value', min(get(imageAxis, 'xlim')) / (info.Width - diff(get(imageAxis, 'xlim'))), 'sliderStep', [newStep / 10 newStep]);
			set(handles.vScroll, 'value', min(get(imageAxis, 'ylim')) / (info.Height - diff(get(imageAxis, 'ylim'))), 'sliderStep', [newStep / 10 newStep]);
		end
		
		function setBaseline(varargin)
			%set baseline to current image
			if strcmp(get(handles.cmdSetAsBaseline, 'string'), 'Remove Baseline')
				set(handles.cmdSetAsBaseline, 'String', 'Set as Baseline');
				set(findobj('tag', 'baseline'), 'CData', zeros(size(get(findobj('tag', 'baseline'), 'CData'))));        
			else
				set(handles.cmdSetAsBaseline, 'String', 'Remove Baseline');
				set(findobj('tag', 'baseline'), 'CData', get(findobj('tag', 'image'), 'Cdata'));   
			end

			displayImage;
        end
        
        function setRoiShape(varargin)
            if get(handles.cboROIType, 'value') < 4
                if get(varargin{1}, 'value') > 3
                    set(varargin{1}, 'value', 1);
                end
            elseif ~ismember(get(varargin{1}, 'value'), [1 4 5 6])
                set(varargin{1}, 'value', 4);
            end
            ROI = getappdata(getappdata(0, 'imageDisplay'), 'ROI');
            if ~isempty(ROI)
                whichROI = get(handles.cboRoiNumber, 'value');
                ROI(whichROI).Shape = get(varargin{1}, 'value');
                ROI(whichROI).points = [];
                ROI(whichROI).data = [];
                ROI(whichROI).ExtendToEdge = false;
                info = getappdata(getappdata(0, 'imageBrowser'), 'info');									
                ROI(whichROI) = shapeRaster(ROI(whichROI));  
                if ROI(whichROI).Type == 1 % Integrative
                    ROI(whichROI) = calcROI(ROI(whichROI));
                    ROI(whichROI).Frames = 1:info.NumImages;										
                else
                    ROI(whichROI).data = nan(info.NumImages,1);
                    if ROI(whichROI).Type == 2 % Clearing
                        switch get(handles.cboAverageType, 'value')
                            case {1 3} % right, left
                                ROI(whichROI).Frames = get(handles.cboFrame, 'value'):get(handles.cboFrame, 'value') + get(handles.cboAverageNumber, 'value') - 1;
                            case 2 % center
                                ROI(whichROI).Frames = get(handles.cboAverageNumber, 'value') - 2 + get(handles.cboFrame, 'value'):get(handles.cboFrame, 'value') + get(handles.cboAverageNumber, 'value');
                        end
                    else
                        ROI(whichROI).Frames = 1:info.NumImages;
                        if ROI(whichROI).Type == 4
                            ROI(whichROI).Rotations = str2double(get(handles.txtRotations, 'string'));
                            ROI(whichROI).PointsPerRotation = str2double(get(handles.txtPointsPerRotation, 'string'));
                            switch ROI(whichROI).Shape
                                case 4 % Lissajous
                                    ROI(whichROI).Lissajous = [str2double(get(handles.txtLissajousX, 'string')) ...
                                                          str2double(get(handles.txtLissajousY, 'string'))];
                                case 5 % spiral
                                    ROI(whichROI).NucleusCenter = [str2double(get(handles.txtNucleusCenterX, 'string')) ...
                                                              str2double(get(handles.txtNucleusCenterY, 'string'))];
                                    ROI(whichROI).NucleusSize = [str2double(get(handles.txtLissajousX, 'string')) ...
                                                            str2double(get(handles.txtLissajousY, 'string'))];
                            end
                        end
                    end
                end
                
                ROI = drawROI(whichROI);
                setappdata(getappdata(0, 'imageDisplay'), 'ROI', ROI);
            end
        end
        
        function setRotations(varargin)
            ROI = getappdata(getappdata(0, 'imageDisplay'), 'ROI');
            if ~isempty(ROI)
                ROI(get(handles.cboRoiNumber, 'value')).Rotations = str2double(get(varargin{1}, 'string'));
                setappdata(getappdata(0, 'imageDisplay'), 'ROI', ROI);
                drawROI(get(handles.cboRoiNumber, 'value'));
            end
        end
        
        function setPointsPerRotation(varargin)
            data = str2double(get(varargin{1}, 'string'));
            data = round(data * sign(data));
            set(varargin{1}, 'string', num2str(data));
            ROI = getappdata(getappdata(0, 'imageDisplay'), 'ROI');
            if ~isempty(ROI)
                ROI(get(handles.cboRoiNumber, 'value')).PointsPerRotation = data;
                setappdata(getappdata(0, 'imageDisplay'), 'ROI', ROI);
                drawROI(get(handles.cboRoiNumber, 'value'));
            end
        end
        
        function setNucleusCenterX(varargin)
            data = str2double(get(varargin{1}, 'string'));
            data = max([min([data 100]) 0]);
            set(varargin{1}, 'string', num2str(data));
            ROI = getappdata(getappdata(0, 'imageDisplay'), 'ROI');
            if ~isempty(ROI)
                ROI(get(handles.cboRoiNumber, 'value')).NucleusCenter(1) = data;
                setappdata(getappdata(0, 'imageDisplay'), 'ROI', ROI);
                drawROI(get(handles.cboRoiNumber, 'value'));
            end
        end
        
        function setNucleusCenterY(varargin)
            data = str2double(get(varargin{1}, 'string'));
            data = max([min([data 100]) 0]);
            set(varargin{1}, 'string', num2str(data));
            ROI = getappdata(getappdata(0, 'imageDisplay'), 'ROI');
            if ~isempty(ROI)
                ROI(get(handles.cboRoiNumber, 'value')).NucleusCenter(2) = data;
                setappdata(getappdata(0, 'imageDisplay'), 'ROI', ROI);
                drawROI(get(handles.cboRoiNumber, 'value'));
            end
        end
        
        function setLissajousX(varargin)
            data = str2double(get(varargin{1}, 'string'));
            data = max([min([data 100]) 0]);
            set(varargin{1}, 'string', num2str(data));
            ROI = getappdata(getappdata(0, 'imageDisplay'), 'ROI');
            if ~isempty(ROI)
                if ROI(get(handles.cboRoiNumber, 'value')).Shape == 4
                    ROI(get(handles.cboRoiNumber, 'value')).Lissajous(1) = data;
                else
                    ROI(get(handles.cboRoiNumber, 'value')).NucleusSize(1) = data;
                end
                setappdata(getappdata(0, 'imageDisplay'), 'ROI', ROI);
                drawROI(get(handles.cboRoiNumber, 'value'));
            end
        end
        
        function setLissajousY(varargin)
            data = str2double(get(varargin{1}, 'string'));
            data = max([min([data 100]) 0]);
            set(varargin{1}, 'string', num2str(data));
            ROI = getappdata(getappdata(0, 'imageDisplay'), 'ROI');
            if ~isempty(ROI)
                if ROI(get(handles.cboRoiNumber, 'value')).Shape == 4
                    ROI(get(handles.cboRoiNumber, 'value')).Lissajous(2) = data;
                else
                    ROI(get(handles.cboRoiNumber, 'value')).NucleusSize(2) = data;
                end
                setappdata(getappdata(0, 'imageDisplay'), 'ROI', ROI);
                drawROI(get(handles.cboRoiNumber, 'value'));
            end
        end
        
        function setRoiSegments(varargin)
            data = str2num(get(varargin{1}, 'string'));
            if ~isempty(data) && (~isvector(data) || any(data > 1 | data < 0))
                msgbox('Segments must be a normalized vector of break points such as [.3 .5].');
                data = data(data > 0 & data <= 1);
                set(varargin{1}, 'string', num2str(data));                
            else
                ROI = getappdata(getappdata(0, 'imageDisplay'), 'ROI');
                if ~isempty(ROI)
                    ROI(get(handles.cboRoiNumber, 'value')).segments = data;
                    setappdata(getappdata(0, 'imageDisplay'), 'ROI', ROI);
                    ROI = drawROI(get(handles.cboRoiNumber, 'value'));
                    setappdata(getappdata(0, 'imageDisplay'), 'ROI', ROI);
                    
                    resavePhotometry = get(getappdata(0, 'photometryPath'), 'userData');
                    resavePhotometry(get(handles.cboRoiNumber, 'value'));
                end
            end
        end
        
        function scanRoi(varargin)
            persistent dataHandle
            
            if varargin{3} == -1
                delete(dataHandle);
                dataHandle = [];
                return
            end
            
            if isempty(dataHandle) || ~ishandle(dataHandle)
                dataHandle = line(1, 1,...
                    'lineWidth', 2,...
                    'color', [0 0 1],...
                    'parent', findobj('tag', 'imageAxis'));
            end
            ROI = getappdata(getappdata(0, 'imageDisplay'), 'ROI');
            pixelUs = str2double(get(handles.txtPixelUs, 'string'));            
            if varargin{3} == 0
                % scan only the current ROI
                scanPoints = sequenceScan(get(handles.cboRoiNumber, 'value'));
            else
                scanPoints = sequenceScan;                
            end
            numPoints = size(scanPoints, 1);
%             scanPoints = scanPoints([ones(1, 149) 1:end], :);
            if varargin{4}
                scanPoints = repmat(scanPoints, 10, 1);
            end
            
            zImage = takeTwoPhotonNI([], scanPoints, [], pixelUs, varargin{4});
            
            info = getappdata(getappdata(0, 'imageBrowser'), 'info');
            voltSize = sscanf(info.SizeOnSource, 'Size = %g by %g mV'); 
            centerLoc = sscanf(info.Comment, 'Center = %g x %g mV');
                
            imageAxis = findobj('tag', 'imageAxis');
            if varargin{4}
                % scanner positions were returned
                set(dataHandle,...
                    'xData', (zImage.photometry(:,1) - centerLoc(1)) ./ voltSize(1) .* info.Width + info.Width / 2,...
                    'yData', (zImage.photometry(:,2) - centerLoc(2)) ./ voltSize(2) .* info.Height + info.Height / 2);            
                % bring this data to the front
                kids = get(get(dataHandle, 'parent'), 'children');
                set(get(dataHandle, 'parent'), 'children', [dataHandle; kids(kids ~= dataHandle)]);
                if numPoints * pixelUs > 1000
                    set(getappdata(0, 'imageBrowser'), 'name', [sprintf('%1.2f', numPoints * pixelUs / 1000) ' ms per circuit']);
                else
                    set(getappdata(0, 'imageBrowser'), 'name', [sprintf('%1.1f', numPoints * pixelUs) ' ' char(181) 's per circuit']);
                end
                
                set(0, 'currentFigure', getappdata(0, 'galvoTrajectories'));
                delete(get(subplot(2,1,1), 'children'));
                subplot(2,1,1);
                plot(zImage.photometry(:,1), 'color', 'red');
                hold on
                plot(scanPoints(:,1), 'color', 'black');
                delete(get(subplot(2,1,2), 'children'));
                subplot(2,1,2);
                plot(zImage.photometry(:,2), 'color', 'red');
                hold on
                plot(scanPoints(:,2), 'color', 'black');
                linkaxes(get(gcf, 'children'), 'x');
                zoom xon
            else
                % photometry data was returned
                % parse the data out of the ROI and into the data section
                % of the ROI structure then call showROI.
                
                % in the meanwhile plot the values as scaled versions of
                % the roi colors
%                 currentValue = get(findobj('tag', 'txtPixelUs'), 'string');
%                 set(findobj('tag', 'txtPixelUs'), 'string', '100');
%                 if varargin{3} == 0
%                     % scan only the current ROI
%                     scanPoints = sequenceScan(get(handles.cboRoiNumber, 'value'));
%                 else
%                     scanPoints = sequenceScan;                
%                 end
%                 set(findobj('tag', 'txtPixelUs'), 'string', currentValue);
%                 scanPoints(:, 1) = (scanPoints(:, 1) - centerLoc(1)) ./ voltSize(1) .* info.Width + info.Width / 2;
%                 scanPoints(:, 2) = (scanPoints(:, 2) - centerLoc(2)) ./ voltSize(2) .* info.Height + info.Height / 2;                
                zImage.photometry(:,1) = (zImage.photometry(:,1) - min(zImage.photometry(:,1))) ./ range(zImage.photometry(:,1));
%                 numPoints = round(length(zImage.photometry) / ROI.Rotations);
%                 for i = 1:ROI.Rotations - 1
%                     zImage.photometry(1,1:numPoints) = zImage.photometry(1,1:numPoints) + zImage.photometry(1, i * numPoints + 1:(i + 1) * numPoints);
%                 end
%                 zImage.photometry = zImage.photometry(1:numPoints, 1) ./ ROI.Rotations;
                
                colorData = get(get(imageAxis, 'parent'), 'colormap');
%                 set(ROI.handle, 'visible', 'off');
%                 for i = 1:size(zImage.photometry, 1)
%                     dataHandle(i) = line('parent', imageAxis, 'xdata', scanPoints(i, 1), 'ydata', scanPoints(i, 2), 'marker', '.', 'markerSize', 6, 'color', colorData(round(zImage.photometry(i,1) * (size(colorData, 1) - 1) + 0.5),:));% 'color', hsv2rgb(zImage.photometry(i,1), 1, 1),);
%                 end
                if varargin{3} == 0
                    % scan only the current ROI
                    figHandle = getappdata(0, 'photometryPath');
                    set(0, 'currentFigure', figHandle);
                    set(figHandle, 'colormap', colorData);
                    imagesc(reshape(zImage.photometry(2:end,1), [], ROI(get(handles.cboRoiNumber, 'value')).Rotations)')
                    ylabel('Rotation #');
                    xlabel('Point');                    
                else

                end                

            end
        end
        
        function rasterRoi(varargin)
            % do a raster scan of the current ROI
            if ~isappdata(0, 'rasterScan')
                rasterScan; % generate the figure if it wasn't there already
            end
            
            % set the values from the current ROI
            ROI = getappdata(getappdata(0, 'imageDisplay'), 'ROI');
            if ~isempty(ROI)
                info = getappdata(getappdata(0, 'imageBrowser'), 'info');
                voltSize = sscanf(info.SizeOnSource, 'Size = %g by %g mV');
                centerLoc = sscanf(info.Comment, 'Center = %g x %g mV');                   
                ROI = ROI(get(handles.cboRoiNumber, 'value'));
                set(findobj('tag', 'centerX'), 'string', sprintf('%1.2f', centerLoc(1) + (ROI.Centroid(1) - info.Width / 2) / info.Width * voltSize(1)));
                set(findobj('tag', 'centerY'), 'string', sprintf('%1.2f', centerLoc(2) + (ROI.Centroid(2) - info.Height / 2) / info.Height * voltSize(2)));
                set(findobj('tag', 'voltsX'), 'string', sprintf('%1.2f', ROI.MajorAxisLength / info.Width * voltSize(1)));
                set(findobj('tag', 'voltsY'), 'string', sprintf('%1.2f', ROI.MinorAxisLength / info.Height * voltSize(2)));
                set(findobj('tag', 'rotation'), 'string', sprintf('%1.4f', ROI.Orientation / pi * 180));
            end
                
            % request the scan
%             rasterScan('R:\TempImage.img');
        end
	end

	function imageDisplayForm
		% set its location
		if ~ispref('locations', 'imageDisplay')
			setpref('locations', 'imageDisplay', [1 1 754 784]);
		end	        
        
		% create main image form
		figHandle = onScreen(figure('NumberTitle','off',...
			'Menubar', 'none',...
			'Name', 'Image Display',...
			'Units', 'pixels',...
			'Position', getpref('locations', 'imageDisplay'),...
            'PaperPositionMode', 'auto',...
			'ResizeFcn', 'resizeImage',...
			'Pointer', 'crosshair',...
			'windowButtonDownFcn', @mouseDownImage,...
			'windowButtonMotionFcn', @mouseMoveImage,...
			'windowButtonUpFcn', @mouseUpImage,...
			'keyPressFcn', @keyPressImage,...
			'CloseRequestFcn', 'set(gcf, ''visible'', ''off'');',...
			'tag', 'frmDisplayImage'));
        

		imageAxis = axes('Units','pixels',...
			'Parent', figHandle,...
			'Position', [0 0 756 800],...
			'TickDir', 'out',...
			'XGrid', 'off',...
			'YGrid', 'off',...
			'dataaspectratio', [1 1 1],...
			'plotboxaspectratio', [1 1 1],...
			'Xtick', [],...
			'Ytick', [], ...
			'Visible', 'off',...
			'ALimMode', 'manual',...
			'layer', 'top',...
			'CLimMode', 'auto',...
			'DrawMode', 'fast',...
			'nextplot', 'add',...
			'Interruptible', 'off',...
			'tag', 'imageAxis');

		mainImage = image([1 1], [1 1], 1,...
			'BusyAction', 'cancel', ...
			'Parent', imageAxis,...
			'CDataMapping', 'Scaled', ...
			'Interruptible', 'off',...
			'xdata', 1,...
			'ydata', 1,...
			'tag', 'image');

		background = image([1 1], [1 1], 1,...
			'BusyAction', 'cancel', ...
			'Parent', imageAxis,...
			'CDataMapping', 'Scaled', ...
			'Interruptible', 'off',...
			'xdata', 1,...
			'ydata', 1,...
			'tag', 'background');

		baseline = image([1 1], [1 1], 1,...
			'BusyAction', 'cancel', ...
			'Parent', imageAxis,...
			'CDataMapping', 'Scaled', ...
			'Interruptible', 'off',...
			'xdata', 1,...
			'ydata', 1,...
			'tag', 'baseline');
		
		codeByDepth = image([1 1], [1 1], 1,...
			'BusyAction', 'cancel', ...
			'Parent', imageAxis,...
			'CDataMapping', 'Scaled', ...
			'Interruptible', 'off',...
			'xdata', 1,...
			'ydata', 1,...
			'tag', 'codeByDepth');
		
		codeByTime = image([1 1], [1 1], 1,...
			'BusyAction', 'cancel', ...
			'Parent', imageAxis,...
			'CDataMapping', 'Scaled', ...
			'Interruptible', 'off',...
			'xdata', 1,...
			'ydata', 1,...
			'tag', 'codeByTime');
		
		fiducials = image([1 1], [1 1], 1,...
			'BusyAction', 'cancel', ...
			'Parent', imageAxis,...
			'CDataMapping', 'Scaled', ...
			'Interruptible', 'off',...
			'xdata', 1,...
			'ydata', 1,...
			'tag', 'fiducials');

		set(figHandle, 'userData', guihandles(figHandle));
		setappdata(0, 'imageDisplay', figHandle);
		setappdata(0, 'doGraph', @mouseMoveImage);
		
		function mouseDownImage(varargin)
			if evalin('base', '~exist(''zImage'', ''var'')')
				return;
			end			
			pointerLoc = get(figHandle, 'CurrentPoint');
			imageLoc = get(imageAxis, 'Position');
			tempROI = getappdata(figHandle, 'tempROI');
			if any(strcmp(get(figHandle, 'selectionType'), {'normal', 'alt'})) && isempty(tempROI) && pointerLoc(1) > imageLoc(1) && pointerLoc(1) < imageLoc(1) + imageLoc(3) && pointerLoc(2) > imageLoc(2) && pointerLoc(2) < imageLoc(2) + imageLoc(4)
				%transfer to image coordinates           
				imageCoord = round([pointerLoc(1) / imageLoc(3) * diff(get(imageAxis, 'xlim')) + min(get(imageAxis, 'xlim')) ...
									pointerLoc(2) / imageLoc(4) * diff(get(imageAxis, 'ylim')) + min(get(imageAxis, 'ylim'))]); 
				if get(findobj('tag', 'chkFlipLrImage'), 'value')
					imageCoord(1) = sum(get(imageAxis, 'xlim')) - imageCoord(1);
				end
                if get(findobj('tag', 'chkFlipUdImage'), 'value')
					imageCoord(2) = sum(get(imageAxis, 'ylim')) - imageCoord(2);
                end
				if strcmp(get(figHandle, 'selectionType'), 'normal')
					% first click sets the start points for drawing a line
					tempROI.xStart = imageCoord(1);
					tempROI.yStart = imageCoord(2); 
					tempROI.lineHandle = line(imageCoord(1), imageCoord(2), 'color', [0 1 0], 'linewidth', 2);
				else
				   % determine whether we are in any ROI
				   ROI = getappdata(figHandle, 'ROI');
				   tempROI.Centroid = [inf inf];

				   for i = 1:numel(ROI)
					  if ~isempty(strmatch('on', get(ROI(i).handle, 'visible'), 'exact')) && ~isempty(find(ROI(i).points(:,1) == imageCoord(1) & ROI(i).points(:,2) == imageCoord(2), 1)) && sum((ROI(i).Centroid - imageCoord).^2) < sum((tempROI.Centroid - imageCoord).^2)
						  tempROI.Centroid = ROI(i).Centroid;
						  tempROI.Offset = ROI(i).Centroid - imageCoord;
						  tempROI.ROInum = i;
                          set(ROI(i).handle(2:end), 'visible', 'off');
					  end
				   end          
				end
				setappdata(figHandle, 'tempROI', tempROI);
			end
		end
		
		function mouseMoveImage(varargin)
			if evalin('base', '~exist(''zImage'', ''var'')')
				return;
			end
			pointerLoc = get(figHandle, 'CurrentPoint');
			imageLoc = get(imageAxis, 'Position');
            if pointerLoc(1) > imageLoc(1) && pointerLoc(1) < imageLoc(1) + imageLoc(3) && pointerLoc(2) > imageLoc(2) && pointerLoc(2) < imageLoc(2) + imageLoc(4)
				%transfer to image coordinates				
				imageCoord = [pointerLoc(1) / imageLoc(3) * diff(get(imageAxis, 'xlim')) + min(get(imageAxis, 'xlim')) ...
									pointerLoc(2) / imageLoc(4) * diff(get(imageAxis, 'ylim')) + min(get(imageAxis, 'ylim'))]; 
				if get(findobj('tag', 'chkFlipLrImage'), 'value')
					imageCoord(1) = sum(get(imageAxis, 'xlim')) - imageCoord(1);
				end
                if get(findobj('tag', 'chkFlipUdImage'), 'value')
					imageCoord(2) = sum(get(imageAxis, 'ylim')) - imageCoord(2);
                end	
                imageCoord = round(imageCoord);
				tempROI = getappdata(figHandle, 'tempROI');
				switch get(figHandle, 'selectionType')
					case 'normal'
						if isfield(tempROI, 'xStart') && imageCoord(1) ~= tempROI.xStart && imageCoord(2) ~= tempROI.yStart
							if ~isfield(tempROI, 'lineSlope')
								tempROI.MajorAxisLength = sign(imageCoord(1) - tempROI.xStart) * sqrt((tempROI.xStart - imageCoord(1)) ^ 2 + (tempROI.yStart - imageCoord(2)) ^ 2) / 2;
								set(tempROI.lineHandle, 'xData', [tempROI.xStart imageCoord(1)], 'yData', [tempROI.yStart, imageCoord(2)])
							else
								% determine slope and intercept of line
								lineSlope2 = -1 / tempROI.lineSlope;
								lineIntercept2 = -lineSlope2 * imageCoord(1) + imageCoord(2);
								xPoint = (tempROI.lineIntercept - lineIntercept2) / (lineSlope2 - tempROI.lineSlope);
								yPoint = lineSlope2 * xPoint + lineIntercept2;

								switch get(findobj('tag', 'cboROIShape'), 'value')
% 									x' = cos(theta)*x - sin(theta)*y 
% 									y' = sin(theta)*x + cos(theta)*y
									case {1, 5} % ellipse, spiral
										% set ROI params
										tempROI.Centroid = (imageCoord + [tempROI.xStart tempROI.yStart]) ./ 2;
										tempROI.MinorAxisLength = sqrt((imageCoord(1) - xPoint) ^ 2 + (imageCoord(2) - yPoint) ^ 2) / 2;										
										tempROI.MajorAxisLength = sqrt((tempROI.xStart - xPoint) ^ 2 + (tempROI.yStart - yPoint) ^ 2) / 2;
										t = 0:pi/20:2*pi;
										set(tempROI.lineHandle, 'xData', tempROI.Centroid(1) + tempROI.MajorAxisLength * cos(t) * cos(tempROI.Orientation) - tempROI.MinorAxisLength * sin(t) * sin(tempROI.Orientation), 'ydata', tempROI.Centroid(2) + tempROI.MajorAxisLength * cos(t) * sin(tempROI.Orientation) + tempROI.MinorAxisLength * sin(t) * cos(tempROI.Orientation));
									case {2, 4} % rectangle, Lissajous
										% set ROI params
										tempROI.Centroid = (imageCoord + [tempROI.xStart tempROI.yStart]) ./ 2;
										tempROI.MinorAxisLength = sqrt((imageCoord(1) - xPoint) ^ 2 + (imageCoord(2) - yPoint) ^ 2) / 2;																				
										tempROI.MajorAxisLength = sqrt((tempROI.xStart - xPoint) ^ 2 + (tempROI.yStart - yPoint) ^ 2) / 2;
										xy = [-tempROI.MajorAxisLength -tempROI.MinorAxisLength;...
											tempROI.MajorAxisLength -tempROI.MinorAxisLength;...
											tempROI.MajorAxisLength tempROI.MinorAxisLength;...
											-tempROI.MajorAxisLength tempROI.MinorAxisLength;...
											-tempROI.MajorAxisLength -tempROI.MinorAxisLength];
										set(tempROI.lineHandle, 'xData', tempROI.Centroid(1) + cos(tempROI.Orientation) .* xy(:,1) - sin(tempROI.Orientation) .* xy(:,2), 'ydata', tempROI.Centroid(2) + sin(tempROI.Orientation) .* xy(:,1) + cos(tempROI.Orientation) .* xy(:,2));										
									case 3 % wedge
										% set ROI params
										tempROI.Centroid = [tempROI.xStart tempROI.yStart];
										tempROI.MinorAxisLength = sign(imageCoord(2) - yPoint) * sqrt((imageCoord(1) - xPoint) ^ 2 + (imageCoord(2) - yPoint) ^ 2) / 2;																														
										tempROI.MinorAxisLength2 = sign(imageCoord(2) - yPoint) * sqrt((tempROI.xStart - xPoint) ^ 2 + (tempROI.yStart - yPoint) ^ 2) / 2;
										xy = [2 * tempROI.MajorAxisLength 0;...
											0 0;...
											0 tempROI.MinorAxisLength;...
											2 * tempROI.MajorAxisLength tempROI.MinorAxisLength2];	
										set(tempROI.lineHandle, 'xData', tempROI.Centroid(1) + cos(tempROI.Orientation) .* xy(:,1) - sin(tempROI.Orientation) .* xy(:,2), 'ydata', tempROI.Centroid(2) + sin(tempROI.Orientation) .* xy(:,1) + cos(tempROI.Orientation) .* xy(:,2));										
								end
							end
							setappdata(figHandle, 'tempROI', tempROI);							
						end
					case 'alt'
						% redraw ROI around current point
						ROI = getappdata(figHandle, 'ROI');
                        if isfield(tempROI, 'Offset')
                            ROI(tempROI.ROInum).Centroid = imageCoord + tempROI.Offset;

                            switch ROI(tempROI.ROInum).Shape
                                case {1, 5} % ellipse, spiral
                                    t = 0:pi/20:2*pi;
                                    set(ROI(tempROI.ROInum).handle(1), 'xData', ROI(tempROI.ROInum).Centroid(1) + ROI(tempROI.ROInum).MajorAxisLength * cos(t) * cos(ROI(tempROI.ROInum).Orientation) - ROI(tempROI.ROInum).MinorAxisLength * sin(t) * sin(ROI(tempROI.ROInum).Orientation), 'ydata', ROI(tempROI.ROInum).Centroid(2) + ROI(tempROI.ROInum).MajorAxisLength * cos(t) * sin(ROI(tempROI.ROInum).Orientation) + ROI(tempROI.ROInum).MinorAxisLength * sin(t) * cos(ROI(tempROI.ROInum).Orientation));
                                case {2, 4} % rectangle, Lissajous
                                    xy = [-ROI(tempROI.ROInum).MajorAxisLength -ROI(tempROI.ROInum).MinorAxisLength;...
                                        ROI(tempROI.ROInum).MajorAxisLength -ROI(tempROI.ROInum).MinorAxisLength;...
                                        ROI(tempROI.ROInum).MajorAxisLength ROI(tempROI.ROInum).MinorAxisLength;...
                                        -ROI(tempROI.ROInum).MajorAxisLength ROI(tempROI.ROInum).MinorAxisLength;...
                                        -ROI(tempROI.ROInum).MajorAxisLength -ROI(tempROI.ROInum).MinorAxisLength];
                                    set(ROI(tempROI.ROInum).handle(1), 'xData', ROI(tempROI.ROInum).Centroid(1) + cos(ROI(tempROI.ROInum).Orientation) .* xy(:,1) - sin(ROI(tempROI.ROInum).Orientation) .* xy(:,2), 'ydata', ROI(tempROI.ROInum).Centroid(2) + sin(ROI(tempROI.ROInum).Orientation) .* xy(:,1) + cos(ROI(tempROI.ROInum).Orientation) .* xy(:,2));										
                                case 3 % wedge
                                    xy = [2 * ROI(tempROI.ROInum).MajorAxisLength 0;...
                                        0 0;...
                                        0 ROI(tempROI.ROInum).MinorAxisLength;...
                                        2 * ROI(tempROI.ROInum).MajorAxisLength ROI(tempROI.ROInum).MinorAxisLength2];								
                                    set(ROI(tempROI.ROInum).handle, 'xData', ROI(tempROI.ROInum).Centroid(1) + cos(ROI(tempROI.ROInum).Orientation) .* xy(:,1) - sin(ROI(tempROI.ROInum).Orientation) .* xy(:,2), 'ydata', ROI(tempROI.ROInum).Centroid(2) + sin(ROI(tempROI.ROInum).Orientation) .* xy(:,1) + cos(ROI(tempROI.ROInum).Orientation) .* xy(:,2));										
                            end
                            setappdata(figHandle, 'ROI', ROI);
                        end
				end

				% plot the graph
				zImage = evalin('base', 'zImage');
				shiftVal = (get(findobj('tag', 'cboCursorSize'), 'value') - 1);

                if imageCoord(1) - shiftVal < 1 || imageCoord(2) - shiftVal < 1 || imageCoord(1) + shiftVal > zImage.info.Width || imageCoord(2) + shiftVal > zImage.info.Height
					return
                end
                
                frameLength = str2double(get(findobj('tag', 'txtFrameDuration'), 'string'));
				if size(zImage.stack, 3) > 2
					slimData = squeeze(mean(mean(zImage.stack(imageCoord(1) + (-shiftVal:shiftVal), imageCoord(2) + (-shiftVal:shiftVal), :), 1), 2));
					slimData([1 end]) = [];
                    if frameLength > 0
    					xData = (2:zImage.info.NumImages - 1) * frameLength;
                    else
    					xData = 2:zImage.info.NumImages - 1;
                    end
				else
					slimData = mean(mean(zImage.stack(imageCoord(1) + (-shiftVal:shiftVal), imageCoord(2) + (-shiftVal:shiftVal), :), 1), 2);
                    if frameLength > 0
    					xData = (1:zImage.info.NumImages) * frameLength;
                    else
                        xData = 1:zImage.info.NumImages;
                    end
				end

                switch get(findobj('tag', 'cboPlotType'), 'value')
					case 1
						%plot F data
						set(findobj('tag', 'displayPlotLine'), 'YData', slimData, 'XData', xData);
					case 2
						%plot dF data
						set(findobj('tag', 'displayPlotLine'), 'YData', slimData - slimData(1), 'XData', xData);  
					case 3
						%plot df/F data
						set(findobj('tag', 'displayPlotLine'), 'Ydata', (1 - slimData(1) .\ slimData) * 100, 'XData', xData);
					case 4
						%plot histogram
                        if strcmp(get(mainImage, 'visible'), 'on')
							currentImage = get(mainImage, 'Cdata');
						elseif strcmp(get(background, 'visible'), 'on')
							currentImage = get(background, 'Cdata');
						elseif strcmp(get(baseline, 'visible'), 'on')
							currentImage = get(baseline, 'Cdata');
						elseif strcmp(get(codeByDepth, 'visible'), 'on')
							currentImage = get(codeByDepth, 'Cdata');
						elseif strcmp(get(codeByTime, 'visible'), 'on')
							currentImage = get(codeByTime, 'Cdata');
						elseif strcmp(get(fiducials, 'visible'), 'on')
							currentImage = get(fiducials, 'Cdata');
                        end
%                         [yData xData] = imhist(currentImage);
% 						set(findobj('tag', 'displayPlotLine'), 'Ydata', yData, 'xdata', xData);                        
						set(findobj('tag', 'displayPlotLine'), 'Ydata', hist(currentImage(:), min(min(currentImage)) + 0.5:1:max(max(currentImage)) - 0.5), 'XData', min(min(currentImage)) + 0.5:1:max(max(currentImage)) - 0.5);                    
                end

                if frameLength > 0 && get(findobj('tag', 'cboPlotType'), 'value') ~= 4
                    setAxisLabels(get(findobj('tag', 'displayPlotLine'), 'parent'));
                else
                    set(get(findobj('tag', 'displayPlotLine'), 'parent'), 'xtickmode', 'auto', 'xticklabelmode', 'auto');
                end
                if numel(xData) > 1
                    set(get(findobj('tag', 'displayPlotLine'), 'parent'), 'xlim', [xData(1) xData(end)]);
                end
				frameNumber = get(findobj('tag', 'cboFrame'), 'string');
				frameNumber = str2double(frameNumber(get(findobj('tag', 'cboFrame'), 'value')));
				set(getappdata(0, 'displayPlot'), 'Name', ['Plot at (' num2str(double(imageCoord(1))) ', ' num2str(double(imageCoord(2))) ') = ' num2str(mean(mean(zImage.stack(imageCoord(1) + (-shiftVal:shiftVal), imageCoord(2) + (-shiftVal:shiftVal), frameNumber), 1), 2))]);
            end
		end
		
		function mouseUpImage(varargin)
			if get(0, 'currentFigure') == getappdata(0, 'imageDisplay') && evalin('base', 'exist(''zImage'', ''var'')')
                clear doSingle % to make sure that any roi boundaries are lost
				pointerLoc = get(figHandle, 'CurrentPoint');
				imageLoc = get(imageAxis, 'Position');
				if pointerLoc(1) > imageLoc(1) && pointerLoc(1) < imageLoc(1) + imageLoc(3) && pointerLoc(2) > imageLoc(2) && pointerLoc(2) < imageLoc(2) + imageLoc(4)
					%transfer to image coordinates                   
					imageCoord = round([pointerLoc(1) / imageLoc(3) * diff(get(imageAxis, 'xlim')) + min(get(imageAxis, 'xlim')) ...
										pointerLoc(2) / imageLoc(4) * diff(get(imageAxis, 'ylim')) + min(get(imageAxis, 'ylim'))]); 
                    if get(findobj('tag', 'chkFlipLrImage'), 'value')
                        imageCoord(1) = sum(get(imageAxis, 'xlim')) - imageCoord(1);
                    end
                    if get(findobj('tag', 'chkFlipUdImage'), 'value')
                        imageCoord(2) = sum(get(imageAxis, 'ylim')) - imageCoord(2);
                    end
					ROI = getappdata(figHandle, 'ROI');
					tempROI = getappdata(figHandle, 'tempROI'); 

                    switch get(figHandle, 'selectionType')
						case 'normal'
							if imageCoord(1) ~= tempROI.xStart && imageCoord(2) ~= tempROI.yStart
								if ~isfield(tempROI, 'lineSlope')
                                    tempROI.lineSlope = (imageCoord(2) - tempROI.yStart) / (imageCoord(1) - tempROI.xStart);
                                    tempROI.lineIntercept = -tempROI.lineSlope * imageCoord(1) + imageCoord(2);                                    
                                    tempROI.Orientation = atan(tempROI.lineSlope);                                    
                                    if get(findobj('tag', 'cboROIShape'), 'value') == 6
                                        % this is a line scan so we are done
                                        ROI(end + 1).Centroid = round((imageCoord + [tempROI.xStart tempROI.yStart]) ./ 2);
                                        ROI(end).MajorAxisLength = tempROI.MajorAxisLength;
                                        ROI(end).MinorAxisLength = 0;
                                        ROI(end).Shape = 6;
                                        ROI(end).Orientation = tempROI.Orientation;
                                        ROI(end).points = [];
                                        ROI(end).data = [];
                                        ROI(end).Lissajous = [];
                                        ROI(end).NucleusCenter = [];
                                        ROI(end).NucleusSize = [];
                                        ROI(end).segments = [];
                                        ROI(end).ExtendToEdge = false;
                                        ROI(end).Type = 4;                            
                                        ROI(end).handle = tempROI.lineHandle;
                                        ROI(end).Frames = 1;
                                        ROI(end).Rotations = str2double(get(findobj('tag', 'txtRotations'), 'string'));                                        
                                        ROI(end).PointsPerRotation = str2double(get(findobj('tag', 'txtPointsPerRotation'), 'string'));
                                        setappdata(figHandle, 'ROI', ROI);                                        
                                        tempROI = [];
                                        drawROI;      
                                        set(findobj('tag', 'cboRoiNumber'), 'string', num2str((1:length(ROI))'), 'value', length(ROI));                                                                              
                                    end
                                    setappdata(figHandle, 'tempROI', tempROI);  
								else
									ROI(end + 1).Centroid = round(tempROI.Centroid);
									ROI(end).MajorAxisLength = round(tempROI.MajorAxisLength);
									ROI(end).MinorAxisLength = round(tempROI.MinorAxisLength);
									ROI(end).Shape = get(findobj('tag', 'cboROIShape'), 'value');																		
									if ROI(end).Shape == 3
										ROI(end).MinorAxisLength2 = round(tempROI.MinorAxisLength2);
									end
									ROI(end).Orientation = tempROI.Orientation;
									ROI(end).points = [];
									ROI(end).data = [];
                                    ROI(end).Lissajous = [];
                                    ROI(end).NucleusCenter = [];
                                    ROI(end).NucleusSize = [];
                                    ROI(end).segments = [];
									ROI(end).ExtendToEdge = false;
									ROI(end).Type = get(findobj('tag', 'cboROIType'), 'value');
									info = getappdata(getappdata(0, 'imageBrowser'), 'info');									
									ROI(end).handle = tempROI.lineHandle;		
                                    ROI(end) = shapeRaster(ROI(end));  
                                    ROI(end).PointsPerRotation = str2double(get(findobj('tag', 'txtPointsPerRotation'), 'string'));
                                    ROI(end).Rotations = str2double(get(findobj('tag', 'txtRotations'), 'string'));                                    
									if ROI(end).Type == 1 % Integrative
										ROI(end) = calcROI(ROI(end));
										ROI(end).Frames = 1:info.NumImages;										
                                    else
										ROI(end).data = nan(info.NumImages,1);
										if ROI(end).Type == 2 % Clearing
											switch get(findobj('tag', 'cboAverageType'), 'value')
												case {1 3} % right, left
													ROI(end).Frames = get(findobj('tag', 'cboFrame'), 'value'):get(findobj('tag', 'cboFrame'), 'value') + get(findobj('tag', 'cboAverageNumber'), 'value') - 1;
												case 2 % center
													ROI(end).Frames = get(findobj('tag', 'cboAverageNumber'), 'value') - 2 + get(findobj('tag', 'cboFrame'), 'value'):get(findobj('tag', 'cboFrame'), 'value') + get(findobj('tag', 'cboAverageNumber'), 'value');
											end
										else
											ROI(end).Frames = 1:info.NumImages;
                                            if ROI(end).Type == 4
                                                ROI(end).segments = str2num(get(findobj('tag', 'txtRoiSegments'), 'string'));
                                                switch ROI(end).Shape
                                                    case 4 % Lissajous
                                                        ROI(end).Lissajous = [str2double(get(findobj('tag', 'txtLissajousX'), 'string')) ...
                                                                              str2double(get(findobj('tag', 'txtLissajousY'), 'string'))];
                                                    case 5 % spiral
                                                        ROI(end).NucleusCenter = [str2double(get(findobj('tag', 'txtNucleusCenterX'), 'string')) ...
                                                                                  str2double(get(findobj('tag', 'txtNucleusCenterY'), 'string'))];
                                                        ROI(end).NucleusSize = [str2double(get(findobj('tag', 'txtLissajousX'), 'string')) ...
                                                                                str2double(get(findobj('tag', 'txtLissajousY'), 'string'))];
                                                end
                                                setappdata(figHandle, 'ROI', ROI);                                                
                                                ROI = drawROI(numel(ROI));
                                            end
										end
									end
									setappdata(figHandle, 'tempROI', []);

									set(findobj('tag', 'cboRoiNumber'), 'string', num2str((1:length(ROI))'), 'value', length(ROI));  
									roiColors = colorSpread(numel([ROI.segments]) + numel(ROI));
									roiIndex = 1;
                                    for i = 1:numel(ROI)
										if ROI(i).Type == 1
											set(ROI(i).handle, 'color',  roiColors(roiIndex,:));
											roiIndex = roiIndex + 1;
										end
                                    end
                                    setappdata(figHandle, 'ROI', ROI);
                                    setappdata(getappdata(0, 'roiPlot'), 'roiData', [ROI.data]);
                                    if numel([ROI.data]) > numel(ROI)
                                        feval(getappdata(findobj(getappdata(0, 'roiPlot'), 'tag', 'roiCommand'), 'callback'));
                                    end
                                    highlightROI(numel(ROI));
                                    if ROI(end).Type == 2 % Clearing
                                        displayImage;
                                    end
								end
							end
						case 'extend'
							% center click in a ROI to delete it

							% determine which ROI we are inside
							needsRefresh = false;
							numDeleted = 0;
							for i = 1:numel(ROI)
								if ~isempty(strmatch('on', get(ROI(i - numDeleted).handle, 'visible'), 'exact')) && ~isempty(find(ROI(i - numDeleted).points(:,1) == imageCoord(1) & ROI(i - numDeleted).points(:,2) == imageCoord(2), 1))
									if ROI(i - numDeleted).Type == 2
										needsRefresh = true;
									end
									delete(ROI(i - numDeleted).handle);
									ROI(i - numDeleted) = [];
									numDeleted = numDeleted + 1;
								end
							end  
							set(findobj('tag', 'cboRoiNumber'), 'string', num2str((1:numel(ROI))'));
							if get(findobj('tag', 'cboRoiNumber'), 'value') > numel(ROI)
								set(findobj('tag', 'cboRoiNumber'), 'value', 1);
							end
							if numel(ROI) < 1
								set(findobj('tag', 'cboRoiNumber'), 'string', 'None');
							end    
                            if needsRefresh
								setappdata(figHandle, 'ROI', ROI);
								displayImage;
                            end
                            setappdata(figHandle, 'ROI', ROI);
                            setappdata(getappdata(0, 'roiPlot'), 'roiData', [ROI.data]);
                            feval(getappdata(findobj(getappdata(0, 'roiPlot'), 'tag', 'roiCommand'), 'callback'));
						case 'alt'
							set(figHandle, 'selectionType', 'normal');
							setappdata(figHandle, 'tempROI', []);
                            if isfinite(tempROI.Centroid(1))
								ROI(tempROI.ROInum) = shapeRaster(ROI(tempROI.ROInum));
                                drawROI(tempROI.ROInum);
                                set(findobj('tag', 'cboRoiNumber'), 'value', tempROI.ROInum);
                                setRoiNumber;
                            end
                            setappdata(figHandle, 'ROI', ROI);
                            setappdata(getappdata(0, 'roiPlot'), 'roiData', [ROI.data]);
                            if numel([ROI.data]) > numel(ROI)
                                feval(getappdata(findobj(getappdata(0, 'roiPlot'), 'tag', 'roiCommand'), 'callback'));
                            end
                    end
				end
			end
		end
	end

	function keyPressImage(varargin)
		if strcmp(varargin{2}.Key, 'downarrow')
			frameList = findobj('tag', 'cboFrame');
			averageList = findobj('tag', 'cboAverageNumber');
			if ~isempty(varargin{2}.Modifier) && strcmp(varargin{2}.Modifier{:},'control')
				if numel(get(frameList, 'string')) - get(frameList, 'value') >= get(averageList, 'value')
					set(frameList, 'value', get(frameList, 'value') + get(averageList, 'value'));
					displayImage;
				end
			else
				if numel(get(frameList, 'string')) - get(frameList, 'value') > 0
					set(frameList, 'value', get(frameList, 'value') + 1);
					displayImage;
				end
			end
		elseif strcmp(varargin{2}.Key, 'uparrow')
			frameList = findobj('tag', 'cboFrame');
			averageList = findobj('tag', 'cboAverageNumber');
            if ~isempty(varargin{2}.Modifier) && strcmp(varargin{2}.Modifier{:},'control')
				if get(frameList, 'value') >= get(averageList, 'value')
					set(frameList, 'value', get(frameList, 'value') - get(averageList, 'value'));
					displayImage;
				end
			else
				if get(frameList, 'value') > 1
					set(frameList, 'value', get(frameList, 'value') - 1);
					displayImage;
				end
            end
        elseif (strcmp(varargin{2}.Key, 'r') || strcmp(varargin{2}.Key, 'R')) && any(strcmp(varargin{2}.Modifier, 'control'))
            data = get(findobj('tag', 'mnuScanCurrentRoi'), 'callback');
            data{1}([], [], 0, 0);
        elseif (strcmp(varargin{2}.Key, 't') || strcmp(varargin{2}.Key, 'T')) && any(strcmp(varargin{2}.Modifier, 'control'))
            data = get(findobj('tag', 'mnuTestCurrentRoi'), 'callback');
            data{1}([], [], 0, 1);
		end
	end

	function exportSettings(varargin)
		settings = getpref('imageBrowser', 'exportSettings');

		if ~isappdata(0, 'imageBrowserExportSettings')
			h1 = figure('numbertitle', 'off',...
				'name', 'Export',...
				'menu', 'none',...
				'color', [.8 .8 .8],...
				'position', [400 400 155 70],...
				'closeRequestFcn', 'rmappdata(0, ''imageBrowserExportSettings''); delete(gcf)',...
				'resize', 'off');

			uicontrol(...
				'background', [.8 .8 .8],...
				'Parent',h1,...
				'Units','norm',...
				'Position',[.1 .7 .8 .2],...
				'String','Show Image Path',...
				'Style','checkbox',...
				'callback', 'tempPref = getpref(''imageBrowser'',''exportSettings''); setpref(''imageBrowser'',''exportSettings'',[get(gcbo, ''value'') tempPref(2:end)]);',...
				'Value',settings(1));

			uicontrol(...
				'background', [.8 .8 .8],...
				'Parent',h1,...
				'Units','norm',...
				'Position',[.1 .4 .8 .2],...
				'String','Show Scale Bar',...
				'Style','checkbox',...
				'callback', 'tempPref = getpref(''imageBrowser'',''exportSettings''); setpref(''imageBrowser'',''exportSettings'',[tempPref(1) get(gcbo, ''value'') tempPref(3:end)]);',...        
				'Value', settings(2));

			uicontrol(...
				'background', [.8 .8 .8],...
				'Parent',h1,...
				'Units','norm',...
				'Position',[.1 .1 .8 .2],...
				'String','Show Color Bar',...
				'Style','checkbox',...
				'callback', 'tempPref = getpref(''imageBrowser'',''exportSettings''); setpref(''imageBrowser'',''exportSettings'',[tempPref(1:2) get(gcbo, ''value'') tempPref(4:end)]);',...        
				'Value', settings(3));

			setappdata(0, 'imageBrowserExportSettings', h1);
		else
			figure(getappdata(0, 'imageBrowserExportSettings'));
		end
	end
	
	function plotForm
		if ~ispref('locations', 'displayPlot')
			setpref('locations', 'displayPlot', [765 976 600 176]);
		end	        
		%initialize plotting window
		figHandle = onScreen(figure('NumberTitle', 'off',...
			'Menubar', 'none',...
			'Name', 'Plots',...
			'Units', 'pixels',...
			'Position', getpref('locations', 'displayPlot'),...
			'tag', 'displayPlot',...
			'CloseRequestFcn', 'set(gcf, ''visible'', ''off'');',...
			'units', 'norm'));

		axisHandle = axes('Units','normal',...
			'Position', [.05 .1 .9 .9],...
			'TickDir', 'out',...
			'XGrid', 'off',...
			'YGrid', 'off',...
			'DataAspectRatio', [1 1 1],...
			'DrawMode', 'fast',...
			'parent', figHandle,...
			'tag', 'displayPlotAxis');

		plot(1,...
			'parent', axisHandle,...
			'tag', 'displayPlotLine');
		
		set(figHandle, 'userData', guihandles(figHandle));
		setappdata(0, 'displayPlot', figHandle);
	end

	function plotROIForm
		if ~ispref('locations', 'roiPlot')
			setpref('locations', 'roiPlot', [765 401 600 600]);
		end	        
		% create region of interest plotting form
		figHandle = onScreen(figure('NumberTitle', 'off',...
			'Menubar', 'none',...
			'Name', 'ROI Plots',...
			'Units', 'pixels',...
			'Position', getpref('locations', 'roiPlot'),...
			'Visible', 'off',...
			'windowbuttonmotionfcn', @whichROI,...
			'closeRequestFcn', 'set(gcf, ''visible'', ''off'');',...
			'tag', 'roiPlot',...
			'units', 'norm'));

		axisHandle = axes('Units','normal',...
			'Position',[.05 .1 .9 .9],...
			'TickDir', 'out',...
			'XGrid', 'off',...
			'YGrid', 'off',...
			'DrawMode', 'fast',...
			'nextplot', 'replacechildren',...
			'parent', figHandle,...
			'tag', 'roiPlotAxis');

		plot(1,...
			'tag', 'roiPlotLine',...
			'parent', axisHandle);
        
        matlabText = loadMatlabText('D:\matlabImageTraceCommands.txt');
        setappdata(uicontrol('style', 'edit',...
            'position', [0 0 500 20],...
            'keyPressFcn', @commandKeyPress,...
            'tag', 'roiCommand',...
            'userData', {size(matlabText, 2) + 1, matlabText}), 'callback', @plotRoi);
		
		set(figHandle, 'userData', guihandles(figHandle));
		setappdata(0, 'roiPlot', figHandle);
        cMenu = uicontextmenu('parent', figHandle);
        set(axisHandle, 'uicontextmenu', cMenu);
        uimenu(cMenu, 'Label', 'Print...', 'callback', {@exportFigure, figHandle, 1});
        uimenu(cMenu, 'Label', 'Copy', 'callback', {@exportFigure, figHandle, 0});
        uimenu(cMenu, 'Label', 'Save as Image...', 'callback', {@exportFigure, figHandle, 2});
        uimenu(cMenu, 'Label', 'Save as Other...', 'callback', {@exportFigure, figHandle, 3});
        uimenu(cMenu, 'sep', 'on', 'Label', 'To Scope', 'callback', @toScope);
        uimenu(cMenu, 'Label', 'To Multiscope', 'callback', @toMultiScope);
        
		function whichROI(varargin)
            kids = get(axisHandle, 'children');
			yData = get(kids, 'yData');   

			pointerLoc = get(figHandle, 'CurrentPoint');
			imageLoc = get(axisHandle, 'Position');
			if ~isempty(yData) && (pointerLoc(1) > imageLoc(1) && pointerLoc(1) < imageLoc(1) + imageLoc(3) && pointerLoc(2) > imageLoc(2) && pointerLoc(2) < imageLoc(2) + imageLoc(4))
                
                if ~iscell(yData)
                    yData = {yData};
                end
                xData = get(kids(end), 'xData');
                
				%transfer to image coordinates
				imageCoord = [round((pointerLoc(1) - imageLoc(1)) / (1 - imageLoc(1)) * diff(get(axisHandle, 'xlim')) + min(get(axisHandle, 'xlim'))) ...
									(pointerLoc(2) - imageLoc(2)) / (1 - imageLoc(2)) * diff(get(axisHandle, 'ylim')) + min(get(axisHandle, 'ylim'))];

                imageCoord(1) = find(xData > imageCoord(1), 1, 'first');                
                if imageCoord(1) < 1
                    imageCoord(1) = 1;
                elseif imageCoord(1) > size(yData{1}, 2)
                    imageCoord(1) = size(yData{1}, 2);
                end
                
				smallGap = inf;
				whichTrace = nan;
                for i = 1:numel(yData)
					if ~isnan(yData{i}(1)) && abs(yData{i}(imageCoord(1)) - imageCoord(2)) < smallGap
						whichTrace = i;
						smallGap = abs(yData{i}(imageCoord(1)) - imageCoord(2));
					end
                end
                if ~isnan(whichTrace)
                    set(findobj('tag', 'cboRoiNumber'), 'value', highlightROI(whichTrace));                    
                end
			end
        end		
        
        function plotRoi(varargin)
            delete(get(axisHandle, 'children'));
            roiData = double(getappdata(figHandle, 'roiData'));
            
            %generate color scheme
            roiColors = colorSpread(size(roiData, 2));
            roiCommandText = get(findobj('tag', 'roiCommand'), 'string');
            if get(findobj('tag', 'cmdOffset'), 'value') == 1
                offset = str2double(get(findobj('tag', 'txtOffset'), 'string'));
                if ~isnumeric(offset)
                    offset = 0;
                end
            else
                offset = 0;
            end
            frameLength = str2double(get(findobj('tag', 'txtFrameDuration'), 'string'));            
            for i = size(roiData, 2):-1:1
                data = roiData(:,i);
                if ~isempty(roiCommandText)
                    eval(roiCommandText);
                end
                if numel(data) > 1
                    if ~isnan(frameLength)
                        line('xData', (1:length(data)) * frameLength, 'yData', data + (i - 1) * offset, 'color', roiColors(i,:), 'parent', axisHandle);
                        xlabel(axisHandle, 'Time (ms)');
                        setAxisLabels(axisHandle);
                        set(axisHandle, 'xlim', [frameLength length(data) * frameLength]);
                    else
                        line('xData', 1:length(data), 'yData', data + (i - 1) * offset, 'color', roiColors(i,:), 'parent', axisHandle);
                        xlabel(axisHandle, 'Frame Number');
                        set(axisHandle, 'xtickmode', 'auto', 'xlim', [1 length(data)]);
                    end
                end
            end
        end
        
        function toScope(varargin)
            roiData = double(getappdata(figHandle, 'roiData'));
            
            %generate color scheme
            roiColors = colorSpread(size(roiData, 2));
            roiCommandText = get(findobj('tag', 'roiCommand'), 'string');

            for i = size(roiData, 2):-1:1
                data = roiData(:,i);
                if ~isempty(roiCommandText)
                    eval(roiCommandText);
                end
                roiData(:, i) = data;
            end
            frameLength = str2double(get(findobj('tag', 'txtFrameDuration'), 'string'));            
            if ~isnan(frameLength)
                scopeHandles = newScope(roiData, (1:size(roiData, 1)) * frameLength, 'ROI Data');
            else
                scopeHandles = newScope(roiData, 1:size(roiData, 1), 'ROI Data');
            end
            kids = get(scopeHandles.axes, 'children');
            for i = 1:numel(kids) - 2
                set(kids(i), 'color', roiColors(end - i + 1, :));
            end
        end
        
        function toMultiScope(varargin)
            roiData = double(getappdata(figHandle, 'roiData'));
            
            %generate color scheme
            roiColors = colorSpread(size(roiData, 2));
            roiCommandText = get(findobj('tag', 'roiCommand'), 'string');

            for i = size(roiData, 2):-1:1
                data = roiData(:,i);
                if ~isempty(roiCommandText)
                    eval(roiCommandText);
                end
                scopeData{i} = data;
                scopeNames{i} = ['ROI ' sprintf('%0.0f', i)];
            end
            frameLength = str2double(get(findobj('tag', 'txtFrameDuration'), 'string'));            
            if ~isnan(frameLength)
                scopeHandles = newScope(scopeData, (1:size(roiData, 1)) * frameLength, scopeNames);
            else
                scopeHandles = newScope(scopeData, 1:size(roiData, 1), scopeNames);
            end
            for i = 1:scopeHandles.axesCount
                kids = get(scopeHandles.axes(i), 'children');
                set(kids(1), 'color', roiColors(i, :));
            end
        end        
    end

    function photometryPathForm
        if ~ispref('locations', 'photometryPath')
			setpref('locations', 'photometryPath', [520 680 560 420]);
        end	
        setappdata(0, 'photometryPath', onScreen(figure('numberTitle', 'off',...
            'name', 'Photometry Path (unwrapped)',...
            'Visible', 'off',...
            'units', 'pixels',...
            'position', getpref('locations', 'photometryPath'),...
			'closeRequestFcn', 'set(gcf, ''visible'', ''off'');',...
			'tag', 'photometryPath')));
    end

    function galvoTrajectoriesForm
        if ~ispref('locations', 'galvoTrajectories')
			setpref('locations', 'galvoTrajectories', [520 680 560 420]);
        end	   
        setappdata(0, 'galvoTrajectories', onScreen(figure('numberTitle', 'off',...
            'name', 'Trajectories',...
            'Visible', 'off',...
            'units', 'pixels',...
            'position', getpref('locations', 'galvoTrajectories'),...            
			'closeRequestFcn', 'set(gcf, ''visible'', ''off'');',...
			'tag', 'galvoTrajectories')));
    end

    function rasterForm
		% create the form for displaying AP rasters
        if ~ispref('locations', 'rasterPlot')
			setpref('locations', 'rasterPlot', [6 26 150 175]);
        end	          
		figHandle = onScreen(figure('NumberTitle', 'off',...
			'Menubar', 'none',...
			'Name', 'Raster',...
			'Units', 'pixels',...
			'Position', getpref('locations', 'rasterPlot'),...
			'Visible', 'off',...
			'tag', 'rasterPlot',...
			'CloseRequestFcn', 'set(gcf, ''visible'', ''off'');',...
			'units', 'norm'));

		axes('Units','normal',...
			'Position', [.05 .05 .95 .95],...
			'TickDir', 'in',...
			'TickLength', [.1 0],...
			'XTickMode', 'manual',...
			'YTickMode', 'manual',...
			'XGrid', 'off',...
			'YGrid', 'off',...
			'DataAspectRatio', [1 1 1],...
			'DrawMode', 'fast',...
			'tag', 'rasterPlotAxis',...
			'parent', figHandle);
		
		set(figHandle, 'userData', guihandles(figHandle));
		setappdata(0, 'rasterPlot', figHandle);		
	end

	function handleList = locPlotForm(handleList)
		% create raster locationplotting window
        if ~ispref('locations', 'locPlot')
			setpref('locations', 'locPlot', [6 26 150 175]);
        end	               
		figHandle = onScreen(figure('NumberTitle','off',...
			'Menubar', 'none',...
			'Name', 'Spike Location',...
			'Units', 'pixels',...
			'Position', getpref('locations', 'locPlot'),...
			'ResizeFcn', 'resizeRaster',...
			'Visible', 'off',...
			'tag', 'locPlot',...
			'units', 'norm',...
			'CloseRequestFcn', 'set(gcf, ''visible'', ''off'');'));

		handleList.locPlot = axes('Units', 'pixels',...
			'Position', [20 20 130 155],...
			'TickDir', 'in',...
			'TickLength', [.1 0],...
			'XTickMode', 'manual',...
			'YTickMode', 'manual',...
			'XGrid', 'off',...
			'YGrid', 'off',...
			'DataAspectRatio', [1 1 1],...
			'DrawMode', 'fast',...
			'tag', 'locPlotAxis',...
			'parent', figHandle);
		
		set(figHandle, 'userData', guihandles(figHandle));
		setappdata(0, 'locPlot', figHandle);			
	end

	function setMap(varargin)
		% set the colormap for the display form based on the drop-down box on
		% the control form

		switch get(findobj('tag', 'cboPalette'),'Value')
			case 1
				set(getappdata(0, 'imageDisplay'), 'Colormap', autumn(256))
			case 2
				set(getappdata(0, 'imageDisplay'), 'Colormap', bone(256))
			case  3
				set(getappdata(0, 'imageDisplay'), 'Colormap', colorcube(256))
			case 4
				set(getappdata(0, 'imageDisplay'), 'Colormap', cool(256))
			case 5
				set(getappdata(0, 'imageDisplay'), 'Colormap', copper(256))
			case 6
				set(getappdata(0, 'imageDisplay'), 'Colormap', flag(256))
			case 7
				set(getappdata(0, 'imageDisplay'), 'Colormap', gray(256))
			case 8
				set(getappdata(0, 'imageDisplay'), 'Colormap', hot(256))
			case 9
				set(getappdata(0, 'imageDisplay'), 'Colormap', hsv(256))
			case 10
				set(getappdata(0, 'imageDisplay'), 'Colormap', jet(256))
			case 11
				set(getappdata(0, 'imageDisplay'), 'Colormap', lines(256))
			case 12
				set(getappdata(0, 'imageDisplay'), 'Colormap', pink(256))
			case 13
				set(getappdata(0, 'imageDisplay'), 'Colormap', prism(256))
			case 14
				set(getappdata(0, 'imageDisplay'), 'Colormap', spring(256))
			case 15
				set(getappdata(0, 'imageDisplay'), 'Colormap', summer(256))
			case 16
				set(getappdata(0, 'imageDisplay'), 'Colormap', white(256))    
			case 17
				set(getappdata(0, 'imageDisplay'), 'Colormap', winter(256))
			case 18
				set(getappdata(0, 'imageDisplay'), 'Colormap', bnw(256))
			case 19
				set(getappdata(0, 'imageDisplay'), 'Colormap', redSat(256))        
			case 20
				set(getappdata(0, 'imageDisplay'), 'Colormap', red(256))    
			case 21
				set(getappdata(0, 'imageDisplay'), 'Colormap', green(256))    
			case 22
				set(getappdata(0, 'imageDisplay'), 'Colormap', blue(256))
			case 23
				set(getappdata(0, 'imageDisplay'), 'Colormap', cyan(256))
			case 24
				set(getappdata(0, 'imageDisplay'), 'Colormap', purple(256))
			case 25
				set(getappdata(0, 'imageDisplay'), 'Colormap', yellow(256))     
			case 26
				set(getappdata(0, 'imageDisplay'), 'Colormap', cyan2red(256))
			case 27
				set(getappdata(0, 'imageDisplay'), 'Colormap', purple2green(256))
			case 28
				set(getappdata(0, 'imageDisplay'), 'Colormap', yellow2blue(256))               
		end

		if get(findobj('tag', 'chkInvertPalette'), 'Value') == 1
			% flip the color map top to bottom
			set(getappdata(0, 'imageDisplay'), 'Colormap', flipud(get(getappdata(0, 'imageDisplay'), 'Colormap')));
		end
    end

    function setRoiNumber(varargin)
        handles = get(getappdata(0, 'imageBrowser'), 'userData');
        stringData = get(handles.cboRoiNumber, 'string');
        if ~(numel(stringData) == 1 && strcmp(stringData, 'None'))
            ROI = getappdata(getappdata(0, 'imageDisplay'), 'ROI');
            whichROI = get(handles.cboRoiNumber, 'value');
            ROI = ROI(whichROI);
            set(handles.cboROIType, 'value', ROI.Type);
            set(handles.cboROIShape, 'value', ROI.Shape);
            if ~isempty(ROI.Rotations)
                set(handles.txtRotations, 'string', num2str(ROI.Rotations));
                set(handles.txtPointsPerRotation, 'string', num2str(ROI.PointsPerRotation));
            end
            if ~isempty(ROI.NucleusCenter)
                set(handles.txtNucleusCenterX, 'string', num2str(ROI.NucleusCenter(1)));
                set(handles.txtNucleusCenterY, 'string', num2str(ROI.NucleusCenter(2)));
                set(handles.txtLissajousX, 'string', num2str(ROI.NucleusSize(1)));
                set(handles.txtLissajousY, 'string', num2str(ROI.NucleusSize(2)));                    
            elseif ~isempty(ROI.Lissajous)
                set(handles.txtLissajousX, 'string', num2str(ROI.Lissajous(1)));
                set(handles.txtLissajousY, 'string', num2str(ROI.Lissajous(2)));                    
            end
            if isempty(ROI.segments)
                set(handles.txtRoiSegments, 'string', '');
            else
                set(handles.txtRoiSegments, 'string', ['[' num2str(ROI.segments, '% g') ']']);
            end
            highlightROI(whichROI);
        end
    end

    function commandText = loadMatlabText(fileName)
        fid = fopen(fileName);
        whichCommand = 1;
        if fid > 0
            while 1
                tline = fgetl(fid);
                if ~ischar(tline)
                    break
                end
                commandText{whichCommand} = tline;
                whichCommand = whichCommand + 1;
            end
            fclose(fid);
        else
            commandText = '';
        end
    end

    function addText(src, eventInfo)
        userData = get(src, 'userData');
        commandText = userData{2};
        newCommand = cell2mat(get(src, 'string'));
        if find(strcmp(commandText, newCommand))
            commandText(find(strcmp(commandText, newCommand)):length(commandText) - 1) = commandText(find(strcmp(commandText, newCommand)) + 1:length(commandText));
            commandText{length(commandText)} = newCommand;
            set(src, 'userData', {length(commandText), commandText});
        else
            commandText{end + 1} = newCommand;
            set(src, 'userData', {length(commandText), commandText});		
        end
    end

    function commandKeyPress(src, eventInfo)
        userData = get(src, 'userData');
        commandText = userData{2};
        whichCommand = userData{1};

        if whichCommand <= length(commandText) + 1 && whichCommand > -1
            if strcmp(eventInfo.Key, 'downarrow')  % down arrow
                if whichCommand < length(commandText)
                    whichCommand = whichCommand + 1;
                    set(src, 'string', commandText(whichCommand));
                elseif whichCommand == length(commandText)
                    whichCommand = whichCommand + 1;
                    set(src, 'string', '');
                end
            end

            if strcmp(eventInfo.Key, 'uparrow') && whichCommand > 1 % up arrow
                whichCommand = whichCommand - 1;
                set(src, 'string', commandText(whichCommand));
            end
        end

        set(src, 'userData', {whichCommand, commandText})

        if strcmp(eventInfo.Key, 'return')
            handles = get(gcf, 'userdata');
            pause(.05);
            addText(src, eventInfo);
            feval(getappdata(src, 'callback'));
        end    
    end
end