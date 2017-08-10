function setupFiles

	% determine what directory this file is in
        thisDir = mfilename('fullpath');
		thisDir = thisDir(1:find(thisDir == filesep, 1, 'last'));
		
	% add this directory and its children to the path
		addpath(genpath(thisDir));
		savepath;
        
    % add amplifiers to the preferences
        currentAmps;
		
	% overwrite the preferences handling file with a faster one
		copyfile([thisDir 'Utility\prefutilsReplacer.m'], fullfile(matlabroot,'toolbox','matlab','uitools','private','prefutils.m'), 'f');
		copyfile([thisDir 'Utility\imlineCopy.txt'], fullfile(matlabroot,'toolbox','images','imuitools','imline.m'), 'f'); % the original must be gone or else the private functions that this references will not be found
        
        try
            copyfile([thisDir 'itc18vb.dll'], fullfile(getenv('systemroot'), 'system32', 'itc18vb.dll'));
        catch me
            if strcmp(me.identifier, 'MATLAB:COPYFILE:OSError') && ~exist(fullfile(getenv('systemroot'), 'system32', 'itc18vb.dll'), 'file')
                warning(['Could not copy file ' thisDir 'itc18vb.dll' ' to ' fullfile(getenv('systemroot'), 'system32', 'itc18vb.dll') '. Please copy manually or rerun setupFiles while running Matlab as an administrator.'])
            end
        end
        
	% determine what hardware is present
		switch questdlg('What location indicators are present on this setup?', '', 'Mitutoyo', 'ASI', 'None', 'Mitutoyo')
			case 'Mitutoyo'
				setupMitutoyo;
			case 'ASI'
				setupASI;
		end
		
        if strcmp(questdlg('Does this setup have a video capture device on the DIC?', '', 'Yes', 'No', 'Yes'), 'Yes')
			system(['regsvr32 "' thisDir 'Hardware\ezVidC60.ocx"']);
        end
		
		msgbox({'Please take a moment now to determine the horizontal offsets and magnifications of your microscope''s objective using a calibration slide.  This data must be stored as per the following preferences: '...
			''...
			'    setpref(''objectives'', ''nominalMagnification'', {''Any Name''});'...
			'    setpref(''objectives'', ''deltas'', [microns_per_pixel]);'...
			'    setpref(''objectives'', ''origins'', [offset_of_center_in_microns]);'...
			'    setpref(''objectives'', ''colorBands'', [r g b; ...]);'...
			'    setpref(''objectives'', ''micronPerMit'', [x y]);'});
		
		% in case they forget, use best guesses (but don't overwrite existing information)
			if ~ispref('objectives', 'deltas')
				setpref('objectives', 'nominalMagnification', {'5x,.12 Zeiss', '40x,.80W Olympus',  'Olympus 60x/0.9'});
				setpref('objectives', 'deltas', [1.8797 .2568 .1515]);
				setpref('objectives', 'origins', [0 0; 0 0; 0 0]);
				setpref('objectives', 'colorBands', [1 0 0; 0 0 1; 0 1 0]);
				setpref('objectives', 'micronPerMit', [1.05 1.05]);
			end