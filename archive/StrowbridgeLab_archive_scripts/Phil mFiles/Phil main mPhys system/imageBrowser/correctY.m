function outY = correctY(inY, sinFreq)
% correct y sin amplitude for sin frequency using the boltzman distribution
% parameters as fit by Origin

if ~ispref('galvos', 'yFactors')
    switch questdlg('Use y correction factors derived for:', 'Set Y Factors', 'Two-Photon A', 'Two-Photon B', 'Two-Photon B')
        case 'Two-Photon A'
            setpref('galvos', 'yFactors', [1.09181 0.00676 3298.43656 1234.79291]);
        otherwise
            setpref('galvos', 'yFactors', [1.07002 0.00694 3874.87864 1340.79455]);
    end
end

yFactors = getpref('galvos', 'yFactors');
% TPA 4-24-07 with 2 us pixels and normalized 0.5 V deflection
% A1 = 1.09181;
% A2 = 0.00676;
% xo = 3298.43656;
% dx = 1234.79291;

% TPB 4-25-07 with 1 us pixels and 1 V deflection
% A1 = 1.07002;
% A2 = 0.00694;
% xo = 3874.87864;
% dx = 1340.79455;

outY = inY ./ (yFactors(2) + (yFactors(1)-yFactors(2))./(1 + exp((sinFreq-yFactors(3))./yFactors(4))));
% only allow dilation, since contraction wasn't calibrated (or observed)
if abs(outY(1)) < abs(inY(1))
    outY = inY;
end