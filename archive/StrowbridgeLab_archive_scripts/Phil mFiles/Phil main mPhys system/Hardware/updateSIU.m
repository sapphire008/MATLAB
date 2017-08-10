function updateSIU(protocol)
persistent interprocessAbsent
if isempty(interprocessAbsent)
    interprocessAbsent = 0;
end

if ~isappdata(0, 'SIUinterProc') && ~interprocessAbsent
	progID = interprocessInstalled;

	if isempty(progID)
		warning('Interprocess is not installed. SIU polling not enabled');
        interprocessAbsent = 1;
        return
	end

	fig3 = figure('name', 'InterProcess', 'numbertitle', 'off', 'visible', 'off', 'closeRequestFcn', 'rmappdata(0, ''interProcess''), delete(gcf)');
	handle = actxcontrol(progID, [10 10 10 10], fig3);
	handle.set('CaseSensitiveSearch', 0);
	handle.set('TargetSearchMethod', 'mbPartialCaption');
	handle.set('StringData', '');
	handle.set('Target', 'SIU4A');
	set(fig3, 'userData', handle);
	setappdata(0, 'SIUinterProc', handle);
    
%     [status result] = system('tasklist');
%     if ~numel(strfind(result, 'Raster.exe'))
%         switch(questdlg('Raster appears to not be running.  Would you like to start it?', 'Uh oh', 'Yes', 'No', 'Yes'))
%             case 'Yes'
%                 system('"Y:\Larimer\Software\Raster\Raster 5.15.07\Raster.exe"')
%         end
%     end
end
	
if ~interprocessAbsent
    interProcess = getappdata(0, 'SIUinterProc');
    try
        interProcess.StringData = sprintf('neg %g %g %g %g', cellfun(@(x) str2double(x), protocol.ttlIntensity));
        interProcess.Send;
    catch
    end
end