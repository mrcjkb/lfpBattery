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
%% dischargeCurves
load(fullfile(pwd, 'MLUnitTests',  'curvefitCollectionTests', 'rawCurves.mat'))
for i = 1:6
    raw(i).Cd = raw(i).Cd .* 1e-3; %#ok<SAGROW> % convert from mAh to Ah
end
d = dischargeCurves;
for i = 1:6
    d.dischargeFit(raw(i).V, raw(i).Cd, raw(i).I, const.T_room);
end
% NOTE: Temporarily disable figure creation in curvefitCollection's
% plotResults() method
f = figure;
setRatio(f, [2, 1])
d.interpMethod = 'linear';
AX(1) = subplot(1, 2, 1);
idx = 4;
I_test = raw(idx).I;
d.remove(I_test)
Cd = linspace(min(raw(idx).Cd), max(raw(idx).Cd), 1000)';
V = zeros(size(Cd));
for i = 1:numel(Cd)
    V(i) = d.interp(I_test, Cd(i));
end
df = dischargeFit(raw(idx).V, raw(idx).Cd, I_test, const.T_room);
LW = {'LineWidth', 2};
d.plotResults('noRawData', true);
hold on
l = findobj(gcf, 'type', 'line');
for i = 1:numel(l)
    l(i).Color = const.grey;
    l(i).LineWidth = 1;
    l(i).LineStyle = '--';
end
plot(Cd, df(Cd), 'Color', const.blue, LW{:})
plot(Cd, V, 'Color', const.red, LW{:})
d.add(df);
title('linear')
d.interpMethod = 'spline';
AX(2) = subplot(1, 2, 2);
I_test = raw(idx).I;
d.remove(I_test)
Cd = linspace(min(raw(idx).Cd), max(raw(idx).Cd), 1000)';
V = zeros(size(Cd));
for i = 1:numel(Cd)
    V(i) = d.interp(I_test, Cd(i));
end
df = dischargeFit(raw(idx).V, raw(idx).Cd, I_test, const.T_room);
LW = {'LineWidth', 2};
d.plotResults('noRawData', true);
hold on
l = findobj(AX(2), 'type', 'line');
for i = 1:numel(l)
    l(i).Color = const.grey;
    l(i).LineWidth = 1;
    l(i).LineStyle = '--';
end
pl_df = plot(Cd, df(Cd), 'Color', const.blue, LW{:});
pl_int = plot(Cd, V, 'Color', const.red, LW{:});
d.add(df);
title('spline')
leg = legend([pl_df, pl_int, l(1)], ...
    {['fit at ', num2str(I_test),' A'],...
    ['interpolation at ', num2str(I_test), ' A'],...
    'curves used for interpolation'}, ...
    'Orientation', 'horizontal');
leg.Location = 'northoutside';
fontsizeset(gcf, fs)
expandaxes(gcf, 0.01)
h = AX(1).Position(4);
for i = 1:2
    AX(i).Position(4) = h - 0.1;
    AX(i).XLim = [0 3.25];
    AX(i).YLim = [2 3.5];
end
l = leg.Position(1);
leg.Position(1) = l - 0.1;
leg.Box = 'off';
tldeccheck
printfig(f, fullfile(p, 'Documentation', 'interpMethod'), 'eps')
%% limitation of I in dischargeCurves
load(fullfile(pwd, 'MLUnitTests', 'batteryCellTests', 'dcCurves.mat'))
f = figure;
setRatio(f, [2, 1])
AX(1) = subplot(1, 2, 1);
% NOTE: temporarily disable I limitation in dischargeCurves.interp and figure creation in curvefitCollection.plotResults here
I_test = 0.01;
Cd = linspace(min(raw(1).Cd), max(raw(1).Cd), 1000)';
V = zeros(size(Cd));
for i = 1:numel(Cd)
    V(i) = d.interp(I_test, Cd(i));
end
d.plotResults('noRawData', true)
l = findobj(gcf, 'type', 'line');
pl_int = plot(Cd, V, 'Color', const.red, LW{:});
% NIOTE: Enable I limiation again
AX(2) = subplot(1, 2, 2);
V = zeros(size(Cd));
for i = 1:numel(Cd)
    V(i) = d.interp(I_test, Cd(i));
end
d.plotResults('noRawData', true)
l = findobj(gcf, 'type', 'line');
pl_int = plot(Cd, V, 'Color', const.red, LW{:});
leg = legend([pl_int, l(1)], ...
    {['interpolation at ', num2str(I_test), ' A'], ...
    'curve fits'}, ...
    'Orientation', 'Horizontal');
leg.Location = 'northoutside';
fontsizeset(gcf, fs)
expandaxes(gcf, 0.01)
h = AX(1).Position(4);
for i = 1:2
    AX(i).Position(4) = h - 0.1;
    AX(i).XLim = [0 3.25];
    AX(i).YLim = [2 3.5];
end
l = leg.Position(1);
leg.Position(1) = l - 0.25;
leg.Box = 'off';
tldeccheck
printfig(f, fullfile(p, 'Documentation', 'dischargeCurvesIlim'), 'eps')
%% woehlerFit
load(fullfile(p, 'Resources', 'wfit.mat'), 'fit')
fit.plotResults
title([])
f = gcf;
setRatio(f, [2, 1])
fontsizeset(f, fs)
expandaxes(f)
printfig(f, fullfile(p, 'Documentation', 'woehlerFit'), 'eps')