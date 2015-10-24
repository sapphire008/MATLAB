%startup events, executed when MATLAB starts
addpath(matlabroot);%add matlab root path to current search directory
addpath('/usr/local/pkg64/matlabpackages/');%make some MATLAB packages available to be added later
userpath(matlabroot);%set userpath to matlab root path
cd(matlabroot);%keep the start up at root directory