function startInterprocess
	progID = interprocessInstalled;

	if isempty(progID)
        error('MB Interprocess is not currently installed on this system.  Please install it and restart Matlab');
	end

	fig3 = figure('name', 'InterProcess', 'numbertitle', 'off', 'visible', 'off', 'closeRequestFcn', 'rmappdata(0, ''interProcess''), delete(gcf)');
	handle = actxcontrol(progID, [10 10 10 10], fig3);
	handle.set('CaseSensitiveSearch', 0);
	handle.set('TargetSearchMethod', 'mbPartialCaption');
	handle.set('StringData', '');
	handle.set('Target', 'Raster');
	set(fig3, 'userData', handle);
	setappdata(0, 'interProcess', handle);