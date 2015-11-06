function [RMS_Mag_disp, RMS_Mag_speed] = Calculate_RMS(ts_file)
% Given the time series .csv file, calcualte the RMS summary measure
%
% [RMS_Mag_disp, RMS_Mag_speed] = Calculate_RMS(ts_file)
%
% Inputs:
%   ts_file: the full directory to the time series file, with 5 columns
%           Time, Horizontal Displacement (mm), Vertical Displacement (mm),
%                   Horizontal Velocity (mm/s), Vertical Velocity (mm/s)
%
% Outputs:
%   RMS_Mag_disp: RMS of magnitude of displacement
%   RMS_Mag_speed: RMS of magnitude of speed
%

% Define custom functions
RMS = @(x) sqrt(mean(x.^2));
Magnitude = @(x, y) sqrt(x.^2 + y.^2);

% Read in the time series file
M = csvread(ts_file); % Should be a numerical matrix

% Calcualte RMS_Mag_disp
RMS_Mag_disp = RMS( Magnitude(M(:, 2), M(:,3)) );

% Calculate RMS_Mag_speed
RMS_Mag_speed = RMS( Magnitude(M(:,4),  M(:, 5)) );

end
