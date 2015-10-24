% Auth: Meric Ozturk
% Contact: mrc.ozturk@gmail.com

% Editor: Edward Cui
% Advisor: Dennis Thompson
% MoveMeasure can be displacement or velocity
% -->runs(i)."MoveMeasure"...
% input_time -->runs(i).time

function MoveMeasure=postproc_char_signal(input_time, input_measure)
    %Total 24 parameters
    %1.1.x measurement
    MoveMeasure.RAW.x = mean(input_measure.x);
    %1.2.y measurement
    MoveMeasure.RAW.y = mean(input_measure.y);
    %1.3.positive x measurement
    MoveMeasure.RAW.xpos=mean(input_measure.x(input_measure.x>0));
    %1.4.negative x measurement
    MoveMeasure.RAW.xneg=mean(input_measure.x(input_measure.x<0));
    %1.5.positive y measurement
    MoveMeasure.RAW.ypos=mean(input_measure.y(input_measure.y>0));
    %1.6.negative y measurement
    MoveMeasure.RAW.yneg=mean(input_measure.y(input_measure.y>0));
    %1.7.average magnitude of measurement
    MoveMeasure.RAW.magnitude =norm([input_measure.x input_measure.y]);
    %1.8.worse measurement between x and y
    MoveMeasure.RAW.worse=MAXABS([MoveMeasure.RAW.x,MoveMeasure.RAW.y]);
    
    %2.1.Calculating RMS and Jaggedness of x measurement
    [MoveMeasure.RMS.x, MoveMeasure.JAG.x] = signal_character(...
        input_time,input_measure.x);
    %2.2.Calculating RMS and Jaggedness of y measurement
    [MoveMeasure.RMS.y, MoveMeasure.JAG.y] = signal_character(...
        input_time,input_measure.x);
    %2.3.Calculating RMS and Jaggedness of positive x measurement
    [MoveMeasure.RMS.xpos, MoveMeasure.JAG.xpos] = signal_character(...
        input_time(input_measure.x>0), input_measure.x(input_measure.x>0));
    %2.4.Calculating RMS and Jaggedness of negative x measurement
    [MoveMeasure.RMS.xneg, MoveMeasure.JAG.xneg] = signal_character(...
        input_time(input_measure.x<0), input_measure.x(input_measure.x<0));
    %2.5.Calculating RMS and Jaggedness of positive y measurement
    [MoveMeasure.RMS.ypos, MoveMeasure.JAG.ypos] = signal_character(...
        input_time(input_measure.y>0), input_measure.y(input_measure.y>0));
    %2.6.Calculating RMS and Jaggedness of negative y measurement
    [MoveMeasure.RMS.yneg, MoveMeasure.JAG.yneg] = signal_character(...
        input_time(input_measure.y<0), input_measure.y(input_measure.y<0));
    %2.7.Calculating RMS and Jaggedness of magnitude of measurement
    [MoveMeasure.RMS.magnitude, MoveMeasure.JAG.magnitude] = ...
        signal_character(input_time,...
        abs(complex(input_measure.x,input_measure.y)));
    %2.8.Calculating worse RMS and Jaggedness between x and y
    MoveMeasure.RMS.worse=max(MoveMeasure.RMS.x,MoveMeasure.RMS.y);
    MoveMeasure.JAG.worse=max(MoveMeasure.JAG.x,MoveMeasure.JAG.y);
end

function [RMS, jaggedness] = signal_character(t, input_signal)
% The window vaiable sets the step size of the windowed linear
% interpoilation -  used to remove high frequency noise by downsampling and
% interpolating between the remaining samples. If you're unsure you need
% this, setting the window to 1 will turn it off.
% window = 1;
% ln  = length(input_signal);
% % Reg_t stores the vector indices  which we are interpolating
% generic_t = 1:ln; reg_t = generic_t;
% %% Windowed linear interpolation
% regressed_signal = input_signal;
% % Indices stores the elements of the signal we are keeping
% indices = downsample(generic_t, window);
% reg_t(indices) = [];
% % The linear interpolation of the signal elements we threw away
% regressed_signal(reg_t) = interp1(indices, input_signal(indices), reg_t);
% %plot(t, regressed_signal);

%% Characterize signal size using Root-Mean-Square (RMS)
% size = norm(regressed_signal)
RMS = sqrt(mean(input_signal.^2));%EDC 081712: rms
%% Chracterize signal jaggedness using norm of first derivative
jaggedness = mean(abs(diff(input_signal))./diff(t));
%% Display the results
% disp(['Window used in windowed linear interpolation:'...
%     num2str(window)]);
disp(['Signal Root-Mean-Square: ' num2str(RMS)]);
disp(['Signal Jaggedness: ' num2str(jaggedness)]);
end

function max_num=MAXABS(input_vect)
%returns the number that has the largest absolute value in a vector
[~,max_ind]=max(abs(input_vect));
max_num=input_vect(max_ind);
end