function setupMitutoyo

	xComm = inputdlg('Enter serial port to which mitutoyo X is connected', 'Comm ', 1, {'1'});
	if isempty(xComm)
		error('Must set a value for mitutoyo x indicator serial port')
	end
	if any(xComm{1} > 57 | xComm{1} < 48)
		error('Value must be a number')
	end
	xResolution = questdlg('What is the gage''s resolution?', 'X Resolution', '1 micron', '10 microns', '10 microns');
	if isempty(xResolution)
		error('Must set X resolution')
	end
	yComm = inputdlg('Enter serial port to which mitutoyo Y is connected', 'Comm ', 1, {'2'});
	if isempty(yComm)
		error('Must set a value for mitutoyo y indicator serial port')
	end		
	if any(yComm{1} > 57 | yComm{1} < 48)
		error('Value must be a number')
	end
	yResolution = questdlg('What is the gage''s resolution?', 'Y Resolution', '1 micron', '10 microns', '10 microns');
	if isempty(yResolution)
		error('Must set Y resolution')
	end		

	if strcmp(xResolution, '1 micron')
		setpref('mitutoyo', 'xNumDigits', 6);
	else
		setpref('mitutoyo', 'xNumDigits', 5);
	end
	if strcmp(yResolution, '1 micron')
		setpref('mitutoyo', 'yNumDigits', 6);
	else
		setpref('mitutoyo', 'yNumDigits', 5);
	end		
	setpref('mitutoyo', 'xComm', str2double(xComm));
	setpref('mitutoyo', 'yComm', str2double(yComm));