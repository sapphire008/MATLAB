% experiment
% MATLAB Version 7.2 (R2006a) 20-Oct-2006 
%
% Command line functions.
%   axoPatchAlpha        - Transforms data from a AxoPatch gain telegraph line into a scaling factor.
%   bridgeBalance        - Provide a step in current clamp and view voltage trace.
%   experiment           - Generates the experiment GUI.
%   generateStim         - Creates a stimulus from a protocol.
%   newSequence          - Increments by one the sequence.
%   reducedNeurons       - Izhikevich model neurons for use in simulated episodes.
%   saveExperiment       - Save the data from the experimment GUI to app data.
%   sealTest             - Provide a step in voltage clamp and view current trace.
%   setDataFolder        - Sets the folder to which data files will be saved.
%   startRunningScope    - Starts a scope to monitor data input.
%
% GUI callbacks.
%   changeRunningChannel - Called when channel data is changed in the protocol or the channel selector is changed on a runningScope to update what channels are available for monitoring.
%   doRepeat             - Execute a number of episodes at a rate.
%   doSingle             - Execute a single episode.
%   doStream             - Start or stop a streaming file.
%   experimentTimer      - Called every 0.1 seconds to update everything.
%   updateExperiment     - Called when a amp is added to a protocol to generate enable check boxes
%
% Other
%   itc18                - A prototype file used as a header to load the library 'C:\WINNT\system32\itc18vb.dll'.
% Hidden data
%   all submenus of the File menu contain as their userData the last
%   directory accessed using them
%
%   when any value is changed on the figure, app data in the base
%   workspace named 'currentExperiment' is saved
%
%   the figure handle of the experiment, runningScope, sealTest,
%   bridgeBalance are saved in the base app data to avoid having\
%   multiple viewers open at once
%
%   the timers have as their userData the date/time they were last reset
%
%   the timer event that updates the clocks also handles all itc18
%   acquisition

