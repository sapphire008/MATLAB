% imageBrowser
% MATLAB Version 7.2 (R2006b) 20-Feb-2007 
%
% Command line functions.
%   calcROI 		    - Calculates the mean value per frame per region of interest (ROI).
%   combineImageStacks 	- Compresses each Z-stack in a directory and combines the results into one image.
%   compressImageStack 	- Generates one large zImage data stack from a directory.
%   displayImage     	- Creates a single frame to send to processImage.
%   drawROI 		    - Draws the ROI on the image.
%   exportFrame 	    - Copies the current frame to the clipboard.
%   highlightROI	    - Emphasise the current region of interest on the display.
%   imageBrowser	    - Called to display an image browser set of forms.
%   loadROI		        - Load a set of regions of interest from a file.
%   locateCells		    - Generate regions of interest from an image using ellipticality criteria.
%   makeRaster		    - Make a spiking raster plot for a given set of ROI and an image stack.
%   printFrame		    - Print the currently displayed image.
%   processImage	    - Filter and project the current image. 
%   readRaster		    - Read data about a spiking raster for a set of ROI.
%   saveImageAs		    - Save the current image as an image file.
%   saveMovie		    - Generate an avi file of the current image stack.
%   saveROI		        - Save the current regions of interest to a file.
%   scaleBar	    	- Add a scale bar to the current image.
%   setCrossHairs    	- Called by a timer to show where the microscope is on the reference image.
%   setReference	    - Set the current image as the location reference image.
%   shapeRaster 	    - Determines what points of an image are inside a ROI.
%   showHighPower	    - Draw the boundaries of the current image on the reference image.
%   transferCellOutline - Draw the current cell on the reference image.
%   transferPoints      - Transform location from one objective to another.
%   transferROI         - Transfer regions of interest onto the reference image.
%   updateAverage       - Updates gui to show what frames are available for a given set of averaging parameters.
%
% Filtering functions (all from Peter Kovesi)
%   ANISODIFF   - Anisotropic diffusion.
%   HOMOMORPHIC - Homomorphic filtering.
%   MATSCII     - Generates ASCII images.
%   NOISECOMP   - Denoising.
%   NORMALISE   - Normalises image values to 0-1, or to desired mean and variance.
%   
% GUI callbacks.
%   resizeImage		- Called when the image display panel is resized to insure correct aspect ratio.
%   setCursor		- Set the cursor to display the number of pixels being averaged for it.
%   showHelp		- Called from the help menu to display helpful info.
%
% Other
%   blue          - A color palette of blues that is added to matlab's palettes.
%   bnw           - A color palette from black to white that is added to matlab's palettes.
%   cyan2red      - A color palette from cyan to red that is added to matlab's palettes.
%   cyan          - A color palette of cyans that is added to matlab's palettes.
%   green         - A color palette of greens that is added to matlab's palettes.
%   purple2green  - A color palette from purple to green that is added to matlab's palettes.
%   purple        - A color palette of purples that is added to matlabs palette's.
%   red           - A color palette of reds that is added to matlab's palettes.
%   redSat        - A color palette from black to white with the top five percent red that is added to matlab's palettes.
%   yellow2blue   - A color palette from yellow to blue that is added to matlab's palettes.
%   yellow        - A color palette from of yellows that is added to matlab's palettes.
%
%  imageBrowser.fig is the main control panel.
%  roi, fiducials,  and temproi are appdata of the imageDisplay
%  info is appdata of the imageBrowser
%
% Hidden data
%   any panel that contains tabs has an info stucture as its userData for
%   tab changing
%
%   when anything value is changed on the figure, app data in the base
%   workspace named 'currentProtocol' is saved
%
%   the figure handle of the protocolViewer is saved in the base app data
%   as 'protocolViewer' to avoid having multiple viewers open at once
%
%   any time the protocol is changed global appdata is generated called
%   'adScaleFactors' and 'daScaleFactors' that hold the analog to digital
%   conversion factors for all channels and the digital to analog
%   conversion factors for any activated channels
%
%   the userData for each channelType selector of the channels panel
%   contains the possible scale factors for those selections