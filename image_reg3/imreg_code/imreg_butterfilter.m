function output_signal=imreg_butterfilter(input_signal)
% By Dennis Thompson & Edward DongBo Cui
% output_signal=imreg_butterfilter(input_signal)
% create a Butterworth low pass filter to filter out noise in the signal
% input_signal must be a vector
Omega_N=0.1; %filter level
filt_order=3;%filter order
%create a butterworth filter
[B_numer,A_denom]=butter(filt_order,Omega_N,'low');
input_mean=mean(input_signal);%mean of input signal
input_len=length(input_signal);%length of input_signal

%Filtering
output_signal=input_signal-input_mean;%shift input to zero line
%append some zeros to prevent filter overflow
output_signal=[output_signal zeros(1,100)];
%double filtering using Butterworth-->prevent phase shift
output_signal=filtfilt(B_numer,A_denom,output_signal);
%recover position and length
output_signal=output_signal(1:input_len)+input_mean;

end