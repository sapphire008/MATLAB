function setReference(fileName)
% sets the current image as a location reference for future images

	if ~ispref('locations', 'referenceImage')
		setpref('locations', 'referenceImage', [1235 678 560 420]);
	end
	
    if ~isappdata(0, 'referenceImage')
        figHandle = figure('tag', 'frmReferenceImage',...
			'numbertitle', 'off',...
			'menu', 'none',...
			'name', 'Reference Image',...
			'resizeFcn', @resizeMe,...
			'closerequestfcn', @closeMe,...
			'units', 'pixels',...
			'position', getpref('locations', 'referenceImage'));
		imageAxis = axes('Units','pixels',...
			'Parent', figHandle,...
			'units', 'normal',...
			'Position', [0 0 1 1],...
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
			'tag', 'referenceImageAxis',...
			'units', 'pixel');
		setappdata(0, 'referenceImage', figHandle);
	else
		figHandle = getappdata(0, 'referenceImage');
		delete(get(findobj('tag', 'referenceImageAxis'), 'children'));
    end
    
	if nargin < 1
        % got here from the imageBrowser
		imageHandle = copyobj(findobj('parent', findobj('tag', 'imageAxis'), 'visible', 'on'), findobj('tag', 'referenceImageAxis'));
		set(figHandle, 'colormap', get(getappdata(0, 'imageDisplay'), 'colormap'));
        set(imageHandle, 'tag', '');
		setappdata(figHandle, 'info', getappdata(getappdata(0, 'imageBrowser'), 'info'));
    else
        % got here from the command line
        zImage = readImage(fileName);
        imageHandle = imagesc(zImage.stack(:,:,1)', 'parent', findobj('tag', 'referenceImageAxis'));
        set(figHandle, 'colormap', gray);
        setappdata(figHandle, 'info', zImage.info);		
	end
	
	locationTimer = timer('name', 'locationTimer', 'Period', 1, 'executionMode', 'fixedDelay', 'busyMode', 'drop', 'timerFcn', @locationTimerCallback);
	
    g = uicontextmenu('parent', figHandle);
        uimenu(g,'Label','Mark Position as ROI','callback',@markROI);
        uimenu(g,'Label','Print Frame','Callback', 'printFrame(getappdata(0, ''referenceImage''), findobj(''tag'', ''referenceImageAxis''))');
        uimenu(g,'Label','Export Frame','Callback', 'exportFrame(getappdata(0, ''referenceImage''), findobj(''tag'', ''referenceImageAxis''))');
        uimenu(g,'Label','Clear Annotations','Callback',@clearROI);
		uimenu(g,'Label','Show Current Location','Separator','on','Callback', @showLocation);
    set(imageHandle, 'buttonDownFcn', @figureClicked, 'uicontextmenu', g);
    
    onScreen(figHandle);
    
	function closeMe(varargin)
		setpref('locations', 'referenceImage', get(varargin{1}, 'position'));
        stop(timerfind('name', 'locationTimer'));
        delete(timerfind('name', 'locationTimer'));
		rmappdata(0, 'referenceImage');

		delete(varargin{1});
	end

	function resizeMe(varargin)
        info = getappdata(varargin{1}, 'info');
        frmPosition = get(varargin{1}, 'Position');
        savedPoint = frmPosition(4);

		%determine which dimension is too big and shrink it
		if frmPosition(3)/info.Width > frmPosition(4)/info.Height
			frmPosition(3) = frmPosition(4)/info.Height*info.Width;
		else
			frmPosition(4) = frmPosition(3)/info.Width*info.Height;
		end

		set(findobj('tag', 'referenceImageAxis'), 'xlim', [0.5 info.Width + 0.5], 'ylim', [0.5 info.Height + 0.5], 'position', [0 0 frmPosition(3) frmPosition(4)]);
        set(varargin{1}, 'Position', [frmPosition(1) frmPosition(2) + savedPoint - frmPosition(4) frmPosition(3) frmPosition(4)]);
	end

	function figureClicked(varargin)
		switch get(gcf, 'selectiontype')
			case 'open'
				info = getappdata(gcf, 'info');
				imageBrowser(info.Filename);
		end
    end

    function markROI(varargin)
        if ~isappdata(0, 'imageBrowser')
            warning('No image is currently loaded in the image browser')
        else
            refInfo = getappdata(get(findobj('tag', 'referenceImageAxis'), 'parent'), 'info');    
            kids = get(findobj('tag', 'referenceImageAxis'), 'children');    
            extent = transferPoints([get(kids(1), 'xdata'); get(kids(1), 'ydata')]', refInfo, getappdata(getappdata(0, 'imageBrowser'), 'info'));

            currentROI = getappdata(getappdata(0, 'imageDisplay'), 'ROI');
            currentROI(end + 1).Centroid = round(mean(extent([1 3], :)));
            currentROI(end).MajorAxisLength = round((extent(3,1) - extent(1,1))/2);
            currentROI(end).MinorAxisLength = round((extent(3,2) - extent(1,2))/2);            
            currentROI(end).Shape = 2;
            currentROI(end).Orientation = 0;
            currentROI(end).Lissajous = [];
            currentROI(end).NucleusCenter = [];
            currentROI(end).NucleusSize = [];
            currentROI(end).segments = [];
            currentROI(end).ExtendToEdge = 0;
            currentROI(end).Type = 1;
            currentROI(end).handle = line('parent', findobj('tag', 'imageAxis'));
            currentROI(end).PointsPerRotation = 100;
            currentROI(end).Rotations = 1;
            currentROI(end).points = [];
            currentROI(end).data = [];
            currentROI(end) = shapeRaster(currentROI(end));  
            currentROI(end) = calcROI(currentROI(end));
            currentROI(end).Frames = 1;
            setappdata(getappdata(0, 'imageDisplay'), 'ROI', currentROI);
            drawROI;
        end
    end

	function clearROI(varargin)
		kids = get(imageAxis, 'children');
		delete(kids(1:end - 1));
	end

	function showLocation(varargin)
		if strcmp(get(varargin{1}, 'checked'), 'on')
			stop(locationTimer);
            set(varargin{1}, 'checked', 'off');
		else
			start(locationTimer);
            set(varargin{1}, 'checked', 'on');            
		end
	end

	function locationTimerCallback(varargin)
		if isappdata(0, 'asiGui') || isappdata(0, 'mitutoyoGui')
			setCrossHairs(sscanf('X = %d\nY = %d', get(findobj('tag', lblLocation), 'string')));
		elseif ispref('mitutoyo', 'xComm')
            objectiveOrigins = getpref('objectives', 'origins');
            objectiveDeltas = getpref('objectives', 'deltas');
			currentPosition = readMitutoyo .* getpref('objectives', 'micronPerMit') + objectiveOrigins(getappdata(get(getappdata(0, 'imageCapture'), 'userData'), 'objective'), :) + [-1.05 -0.62] .* objectiveDeltas(getappdata(get(getappdata(0, 'imageCapture'), 'userData'), 'objective'));
			setCrossHairs(currentPosition(1), currentPosition(2));
		elseif ispref('ASI', 'commPort')
			currentPosition = readASI;
			setCrossHairs(currentPosition(1), currentPosition(2));			
		else
			setCrossHairs(nan, nan);
		end
	end
end