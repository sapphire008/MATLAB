% -----------------------------------------------------------
% Digital Bit In/Out Example
% This file sets a single digital output channel  based on user
% input and reads a single digital input channel. Jumper a wire 
% from FIO0 to FIO1 and the program will return the value you set
% FIO0 to as FIO1.
% -----------------------------------------------------------

clc %clear the MATLAB command window
clear global %Clears MATLAB global variables

ljud_LoadDriver; % Loads LabJack UD Function Library
ljud_Constants; % Loads LabJack UD constant file
[Error ljHandle] = ljud_OpenLabJack(LJ_dtU3,LJ_ctUSB,'1',1); % Returns ljHandle for open LabJack
Error_Message(Error) % Check for and display any Errros


%Start by using the pin_configuration_reset IOType so that all
%pin assignments are in the factory default condition.
Error = ljud_ePut (ljHandle, LJ_ioPIN_CONFIGURATION_RESET, 0, 0, 0);
Error_Message(Error)

% Prompt user for FIO0 output value
FIO0 = input('Enter 1 for High and 0 for Low FIO0 Output FIO0 = ')
Error = ljud_ePut(ljHandle,LJ_ioPUT_DIGITAL_BIT,0,FIO0,0);
Error_Message(Error)

% Gets FIO1's State
[Error FIO1] = ljud_eGet(ljHandle,LJ_ioGET_DIGITAL_BIT,1,0,0);
Error_Message(Error)

% Display FIO1
FIO1
