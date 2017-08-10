function setupASI

	commPort = inputdlg('Enter serial port to which ASI is connected', 'Comm ', 1, {'1'});
	if isempty(commPort)
		error('Must set a value for ASI serial port')
	end
	if any(commPort{1} > 57 | commPort{1} < 48)
		error('Value must be a number')
	end
	setpref('ASI', 'commPort', str2double(commPort));