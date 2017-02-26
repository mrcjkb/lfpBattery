% NOTE: Not all functions required for running this script are included in
% the lfpBattery package.
import lfpBattery.*
[p, ~] = fileparts(fileparts(which('lfpBatteryTests')));
cd(p)
fs = 14;
%% dischargeFit lsq vs fmin
load(fullfile(pwd, 'MLUnitTests', 'dischargeFitTests','testCurve.mat'))
C_d = C_d.*1e-3; % convert to Ah
Temp = const.T_room;
I = 1;
d1 = dischargeFit(V, C_d, I, Temp, 'mode', 'lsq');
d2 = dischargeFit(V, C_d, I, Temp, 'mode', 'fmin');
f = figure;
setRatio(f, [2, 1])
AX(1) = subplot(1, 2, 1);
d1.plotResults
title('lsqcurvefit')
AX(2) = subplot(1, 2, 2);
d2.plotResults
title('fminsearch')
AX(2).YLim = AX(1).YLim;
leg = legend('raw data', 'fit', 'Orientation', 'horizontal');
leg.Location = 'northoutside';
fontsizeset(f, fs)
expandaxes(f, 0.01)
pos = AX(1).Position;
for i = 1:2
    AX(i).Position(4) = pos(4) - 0.1;
end
lpos = leg.Position;
leg.Position(1) = lpos(1) - 0.27;
leg.Box = 'off';
tldeccheck
printfig(f, fullfile(p, 'Documentation', 'dischargeFit01'), 'eps')
%% dischargeFit fmin
d1 = dischargeFit(V, C_d, I, Temp);
x0 = [3; 0.01; 0.22; 0.1; -0.9; -3; 1400; 260];
d2 = dischargeFit(V, C_d, I, Temp, 'x0', x0);
f = figure;
setRatio(f, [2, 1])
AX(1) = subplot(1, 2, 1);
d1.plotResults
AX(2) = subplot(1, 2, 2);
d2.plotResults
AX(1).YLim = AX(2).YLim;
leg = legend('raw data', 'fit', 'Orientation', 'horizontal');
leg.Location = 'northoutside';
fontsizeset(f, fs)
expandaxes(f, 0.01)
pos = AX(1).Position;
for i = 1:2
    AX(i).Position(4) = pos(4) - 0.1;
end
lpos = leg.Position;
leg.Position(1) = lpos(1) - 0.27;
leg.Box = 'off';
tldeccheck
printfig(f, fullfile(p, 'Documentation', 'dischargeFit02'), 'eps')
