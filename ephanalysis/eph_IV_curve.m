function eph_IV_curve(Vs, Is, xcenter, ycenter)
% zData = eph_load('Neocortex J.03Mar16.S1.E17');
% ts = zData.protocol.msPerPoint;
% Vs = eph_window(zData.VoltA, ts, [4000, 16000]);
% Is = eph_window(zData.CurA, ts, [4000, 16000]) - mean(eph_window(zData.CurA, ts, [0, 500]));
if nargin<2, xcenter = -65; end
if nargin<3, ycenter = 0; end

plot(Vs, Is, '.');
draw_cartesian_axes(gca, xcenter, ycenter);
xlabel('Voltage (mV)', 'color', 'k');
ylabel('Current (pA)', 'color', 'k');
end
