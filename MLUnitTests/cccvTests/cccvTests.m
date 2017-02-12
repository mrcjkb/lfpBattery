function cccvTests
%CCCVTESTS: Function for testing the CCCV charging

%% Cell level

import lfpBattery.*
load(fullfile(pwd, 'MLUnitTests', 'batteryCellTests', 'dcCurves.mat'))
load(fullfile(pwd, 'Resources', 'cccvfit.mat'))
% Initialization
b = batteryCell(3.5, 3.2, 'socIni', 0.2, 'socMax', 1, 'socMin', 0.2);
b.addcurves(d)
b.addcurves(c, 'charge')
% Simulation
dt = 60;
P = inf;
ct = 1;
t(63, 1) = 0;
v(63, 1) = 0;
i(63, 1) = 0;
while P > 0
    ct = ct + 1;
    t(ct) = t(ct-1) + dt;
    [P, V, I] = b.powerRequest(1e3, dt);
    v(ct) = V;
    i(ct) = I;
end
t = t(1:end-1);
v = v(2:end);
i = i(2:end);
% Figure
setTUcolors
f = figure;
f.Position(3) = 1.8*f.Position(3);
time = t / 60; % in minutes
% h = plotyy(time, i, time, v);
% ylabel(h(1), 'Charge current / A')
% ylabel(h(2), 'Charge voltage / V')
hold on
plot(time, i, 'LineWidth', 2);
plot(time, v, 'LineWidth', 2);
legend('charge current / A', 'charge voltage / V', 'Location', 'SouthWest');
xlabel('time / min')
close all

%% Pack level
clearvars -except d c
B = initBatteries(d, c);
p = parallelElement('socIni', 0.2, 'socMax', 1, 'socMin', 0.2);
p.addElements(B(1:3))
p2 = parallelElement('socIni', 0.2, 'socMax', 1, 'socMin', 0.2);
p2.addElements(B(4:6))
p3 = parallelElement('socIni', 0.2, 'socMax', 1, 'socMin', 0.2);
p3.addElements(B(7:9))
b = seriesElementPE('socIni', 0.2, 'socMax', 1, 'socMin', 0.2);
b.addElements(p, p2, p3)

% Simulation
dt = 60;
P = inf;
ct = 1;
t(52, 1) = 0;
v(52, 1) = 0;
i(52, 1) = 0;
while P > 0
    ct = ct + 1;
    t(ct) = t(ct-1) + dt;
    [P, V, I] = b.powerRequest(1e3, dt);
    v(ct) = V;
    i(ct) = I;
end
t = t(1:ct-1);
v = v(2:ct);
i = i(2:ct);
% Figure
setTUcolors
f = figure;
f.Position(3) = 1.8*f.Position(3);
time = t / 60; % in minutes
% h = plotyy(time, i, time, v);
% ylabel(h(1), 'Charge current / A')
% ylabel(h(2), 'Charge voltage / V')
hold on
plot(time, i, 'LineWidth', 2);
plot(time, v, 'LineWidth', 2);
legend('charge current / A', 'charge voltage / V', 'Location', 'SouthWest');
xlabel('time / min')
close all

%%
disp('CCCV tests passed')
end

