function zImage = takeTwoPhotonImage(fileName, scanPoints, beamOnPoints, pixelUs, returnScanPosition, triggeredAcquisition)

if nargin < 5
    returnScanPosition = false;
end

if nargin < 6
    triggeredAcquisition = false;
end

% tells raster to take a 2p image

if ~isappdata(0, 'interProcess')
	progID = interprocessInstalled;

	if isempty(progID)
		error('Interprocess is not installed');
	end

	fig3 = figure('name', 'InterProcess', 'numbertitle', 'off', 'visible', 'off', 'closeRequestFcn', 'rmappdata(0, ''interProcess''), delete(gcf)');
	handle = actxcontrol(progID, [10 10 10 10], fig3);
	handle.set('CaseSensitiveSearch', 0);
	handle.set('TargetSearchMethod', 'mbPartialCaption');
	handle.set('StringData', '');
	handle.set('Target', 'Raster');
	set(fig3, 'userData', handle);
	setappdata(0, 'interProcess', handle);
    
    [status result] = system('tasklist');
    if ~numel(strfind(result, 'Raster.exe'))
        switch(questdlg('Raster appears to not be running.  Would you like to start it?', 'Uh oh', 'Yes', 'No', 'Yes'))
            case 'Yes'
                system('"Y:\Larimer\Software\Raster\Raster 5.15.07\Raster.exe"')
        end
    end
end
	
if nargin > 0
	interProcess = getappdata(0, 'interProcess');
    
    % add a buffer of 150us to the end so that all data is returned
    numPoints = size(scanPoints, 1) + round(150 / pixelUs);
    
    if nargin > 1
        fid = fopen('R:\MLDAO.dat', 'w');
            fwrite(fid, scanPoints([1:end 1:round(150 / pixelUs)], :)', 'float32');
        fclose(fid);
        focusText = findobj(getappdata(0, 'rasterScan'), 'tag', 'cmdFocus');
        if returnScanPosition || isempty(focusText)
            interProcess.StringData = sprintf('mTakeImage %g %g 0 %g %g', [numPoints pixelUs], returnScanPosition, triggeredAcquisition);
            interProcess.Send;
        else
            switch get(focusText, 'string')
                case 'Focus'
                    interProcess.StringData = sprintf('mTakeImage %g %g 0 %g %g', [numPoints pixelUs], returnScanPosition, triggeredAcquisition);
                    interProcess.Send;
                case 'Preparing'
                    set(focusText, 'string', 'Stop');
                    interProcess.StringData = sprintf('mTakeImage %g %g 1 %g %g', [numPoints pixelUs], returnScanPosition, triggeredAcquisition);
                    interProcess.Send;
                    zImage = [];
                    return
                case 'Stopping'
                    set(focusText, 'string', 'Focus');
                    interProcess.StringData = sprintf('mTakeImage %g %g -1 %g %g', [numPoints pixelUs], returnScanPosition, triggeredAcquisition);
                    interProcess.Send;    
                    zImage = [];
                    return
            end
        end
    else
        interProcess.StringData = ['ACQUIRE ' fileName];
        interProcess.Send;
    end
	
    if triggeredAcquisition
        return
    end
    
	% wait until it is done
    imageDone = false;
    while ~imageDone
		pause(0.01)
    end	
	
    if ~returnScanPosition
        if exist(fileName, 'file')
            zImage = read2PRaster([fileName '.img']);
        else
            zImage = read2PRaster('R:\imageHeader.img', 1);
        end

        % write location information into the header
        if ispref('mitutoyo', 'xComm')
            % read the coordinates from there
            currentPosition = readMitutoyo;
        elseif ispref('ASI', 'commPort')
            currentPosition = readASI;
        else
            currentPosition = [0 0 0];
        end
        objectiveOrigins = getpref('objectives', 'origins');
        objectiveNames = getpref('objectives', 'nominalMagnification');
        objectiveIndex = find(strcmp(objectiveNames, zImage.info.Objective));
        objectiveDeltas = getpref('objectives', 'deltas');
        zImage.info.origin = [objectiveOrigins(objectiveIndex, :) + currentPosition(1:2) .* getpref('objectives', 'micronPerMit') + sscanf(zImage.info.Comment, 'Center = %g x %g mV')' .* (objectiveDeltas(objectiveIndex) * [1 1]) currentPosition(3)];
%         zImage.info.MiscInfo = [zImage.info.MiscInfo sprintf(', X = %g, Y = %g, Z = %g', [zImage.info.origin currentPosition(3)])];
        
        if numel(currentPosition) > 2
            zImage.info.origin(3) = currentPosition(3);
        end
        
        if exist(fileName, 'file')
            write2PRaster(zImage, [fileName '.img']);  
        else
            fid = fopen('R:\rasterOut.dat');
                fseek(fid, 20, 'bof'); % 20 for the header
                zImage.photometry = fread(fid, [2, numPoints], '*int16')';
                zImage.photometry(1:round(150 / pixelUs), :) = [];
            fclose(fid);
        end        
    else
        zImage = read2PRaster('R:\imageHeader.img', 1);
        fid = fopen('R:\rasterOut.dat'); % positions saturate at +/- 3.423
            fseek(fid, 20, 'bof'); % 20 for the header
            zImage.photometry = fread(fid, [2, size(scanPoints, 1)], 'int16')'  .* 4 .* repmat([0.0016749 0.0016734], size(scanPoints, 1), 1) + repmat([0.0072195 0.0035648], size(scanPoints, 1), 1);
            zImage.photometry(1:round(150 / pixelUs), :) = [];
        fclose(fid);
    end
end