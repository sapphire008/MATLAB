% Coupling
% MATLAB Version 7.3 (R2006b) 20-Mar-2007 
%
% Command line functions.
%   alpha               - Generates alpha functions.
%   batchClassification - Looks through a directory for episodes to classify the cells therein.
%   batchCoupling       - Runs coupling analyses on all cells in a folder.
%   batchSTA            - Generates a spike-triggered average plot for all cells in a folder.
%   checkCoupling       - Look for synaptic coupling between simultaneously-recorded cells.
%   checkSTA            - Generates a spike-triggered average plot.
%   detectPSPs          - Finds postsynaptic events.
%   excelCoupling       - Transfers the PSPs data structure to a Microsoft Excel file.
%   pspGui              - A graphical interface for postsynaptic event detection.
%   setupCoupling       - Generates a coupling window.
%   setupSTA            - Generates a spike-triggered average window.
%
% GUI callbacks.
%   averageCoupling     - Called when the user clicks on a coupling window to show average traces .
%   averageOnly         - Called to transform a averageCoupling window into just an average EPSP or IPSP. 
%   characterizePSPs    - Called to show PSP amplitude, latency, rise, and decay taus.
%   cleanUpCoupling     - Removes action potentials and current traces from a coupling window.
%   featureVsPotential  - Called by coupling menu to plot a PSP feature vs the membrane potential.
%   generateEpisodes    - Called to create a amplitude-ranked text list of episodes for finding good examples.
%   generateStats       - Called to produce statistical significance data for a coupling.
%   generateTraces      - Called to pull data from episodes with known PSPs.
%   overlayPSPs         - Called to to overlay PSPs from one data file in a newScope.
%   showFit             - Called to display an overlay of the coupling fit and its raw data.
%   stimStats           - Called to generate statistics for a given connection.
%   zoomCoupling        - Called when mouse is over a coupling axis to increase size.
%   zoomSTA             - Called by clicks on STA axes to show a larger version.
%
% Other
%   userData of coupling figures is {channels_used, number_of_traces_processed, stim_times, PSPdata, stimulus_length, numControlWindows}.