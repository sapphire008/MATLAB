% protocolViewer
% MATLAB Version 7.2 (R2006b) 20-Feb-2007 
%
% Command line functions.
%   addAmp         - Adds an amplifier to the current protocol.
%   currentAmps    - Contains scale factors for all hardware.
%   isProtocol     - Verifies that a structure is a valid protocol.
%   loadProtocol   - Loads a protocol as the current protocol.
%   makeProtocol   - Removes any fields from a structure that aren't in a protocol structure.
%   protocolViewer - Generates a GUI for protocol viewing.
%   removeAmp      - Removes the amp that is currently being viewed.
%   saveProtocol   - Saves a protocol to a file or app data.
%
% GUI callbacks.
%   changeAcquisitionRate - Called when the acquisition rate is changed to set the time per point.
%   changeAdBoard         - Called when the hardware type is changed. 
%   changeAmp             - Called when the amplifier type is changed to update what types of channels are available.
%   changeCell            - Called when the cell type/location is changed to reset the software cell.
%   changeCurrent         - Called when the current channel is changed to check for conflicts.
%   changeTelegraph       - Called when the telegraph channel is changed to check for conflicts.
%   changeTtlType         - Called when a ttl type is changed to handle new types.
%   changeVoltage         - Called when the voltage channel is changed to check for conflicts.
%   checkAcquiisitionRate - Called to verify that the rate chosen is a multiple of the hardware's base rate.
%   tabChange             - Called to change tabs of protocolViewer.
%
% Other
%   defaultProtocol.mat   - The default protocol that is loaded when experiment starts.
%
% Template Folder contains the .fig files that generate prtocolViewer
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