function outX = correctX(inX, sinFreq)
% correct x sin amplitude for sin frequency using the boltzman distribution
% parameters as fit by Origin

if ~ispref('galvos', 'xFactors')
    switch questdlg('Use x correction factors derived for:', 'Set X Factors', 'Two-Photon A', 'Two-Photon B', 'Two-Photon B')
        case 'Two-Photon A'
            setpref('galvos', 'xFactors', [1.07616 0.0196 3413.81971 1149.62827]);
        otherwise
            setpref('galvos', 'xFactors', [1.11878 0.01416 3598.50261 1395.67131]);
    end
end

xFactors = getpref('galvos', 'xFactors');

% TPA 4-24-07 with 2 us pixels and normalized 0.5 V deflection
% A1 = 1.07616;
% A2 = 0.0196;
% xo = 3413.81971;
% dx = 1149.62827;

% TPB 4-25-07 with 1 us pixels and 1 V deflection

% A1 = 1.11878;
% A2 = 0.01416;
% xo = 3598.50261;
% dx = 1395.67131;

outX = inX ./ (xFactors(2) + (xFactors(1)-xFactors(2))./(1 + exp((sinFreq-xFactors(3))./xFactors(4))));
% only allow dilation, since contraction wasn't calibrated (or observed)
if abs(outX(1)) < abs(inX(1))
    outX = inX;
end