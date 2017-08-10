function twoPhotonGUI

rasterScan;
if ~isappdata(0, 'interProcess')
	takeTwoPhotonImage;
	if system('"Y:\Larimer\Software\Raster\Raster 5.15.07\Raster.exe"')
		msgbox('Error starting raster program')
		close(findobj('type', 'figure', 'name', 'InterProcess'));
	end
end