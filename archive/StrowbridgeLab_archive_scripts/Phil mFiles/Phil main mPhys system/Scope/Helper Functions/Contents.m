% newScope
% MATLAB Version 7.3 (R2006b) 20-Feb-2007 
%
% Command line functions.
%   analysisAxis          - Adds an analysis axis to the specified axis.
%   channelControl        - Adds a channel control to a data newScope.
%   *channelControlLocal  - Adds a local channel control.
%   exportSettings        - Generates a GUI to edit file exporting preferences.
%   exportWithAxes        - Exports the current newScope to the clipboard as a window enhanced metafile.
%   exportWithScaleBars   - Exports the current newScope as an HPGL file.
%   (this can be changed to export as an EMF or whatever, but the HPGL vectors seem to preserve the full data resolution)
%   updateTrace
%   *updateTraceLocal
%
% Other
%   Corel Importer.txt   - Macros for importing data into Corel Draw.
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