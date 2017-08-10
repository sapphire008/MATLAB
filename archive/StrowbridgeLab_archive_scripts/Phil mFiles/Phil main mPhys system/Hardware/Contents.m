% captureGUI
% MATLAB Version 7.3 (R2006b) 20-Mar-2007 
%
% Command line functions.
%   audioScope         - Creates a GUI for listening to activity on a channel.
%   asiGUI             - Creates a GUI for controlling and recording the location of the stage.
%   captureGUI         - Creates a GUI for controlling a video capture device.
%   mitutoyoGUI        - Creates a GUI for recording the location of the stage.
%   quantixGUI         - Creates a GUI for capturing images with a Photometrics camera.
%   readASI            - Reads the current stage location.
%   readMitutoyo       - Reads the current stage location.
%   setupASI           - Sets the comm port for ASI communication.
%   setupMitutoyo      - Sets the comm ports and precision for Mitutoyo communication.
%   takeTwoPhotonImage - Calls a VB program that controls the two-photon hardware.
%   twoPhotonGUI       - Generates an invisible figure necessary for communication with the two-photon's VB program.
%
% Other
%   asiGUI.fig         - Figure for Applied Systems Incorporated stage controller.
%   captureGUI.fig     - Figure for Windows capture device (receiving input from a DIC camera).
%   changeAudioChannel - Change the available channels on any audioScopes.
%   ezvidC60.ocx       - Interaction activeX for Windows capture device written by Ray Mercer.
%   mitutoyo.fig       - Figure for Mitutoyo stage location indicators.
%   quantix.ocx        - An activeX compiled in VB to control a Photometrics camera.
%   SIDXVB.dll         - Drivers for a Photometrics camera. 
%
% Hidden data
%   each GUI exists in only one copy, so sets appdata in the base workspace
%   with its name