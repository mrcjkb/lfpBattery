function dischargeFitTests


import lfpBattery.*

%% Input data
load(fullfile(pwd, 'MLUnitTests', 'dischargeFitTests','testCurve.mat'))
C_d = C_d.*1e-3; %#ok<NODEF> % convert to Ah
%% Params
E0 = 3;
Ea = 0.01;
Eb = 0.22;
Aex = 0.1;
Bex = -0.9;
Cex = 0.1;
x0 = -3;
v0 = 1400;
delta = 260;
x0 = [E0; Ea; Eb; Aex; Bex; Cex; x0; v0; delta];

%% Args
Temp = const.T_room;
I = 1;

%% Initialize with params
d = dischargeFit(V, C_d, I, Temp, 'x0', x0, 'mode', 'lsq');
d.plotResults
close gcf
%% Initialize without params
d2 = dischargeFit(V, C_d, I, Temp, 'mode', 'lsq');
d2.plotResults
close gcf
%% fminsearch options
d3 = dischargeFit(V, C_d, I, Temp, 'x0', x0, 'mode', 'fmin');
d3.plotResults
d4 = dischargeFit(V, C_d, I, Temp, 'mode', 'fmin');
d4.plotResults
close gcf
%% test subsref overload
da = [d; d2; d3; d4];
assert(isequal(size(da{100}), size(da)), 'unexpected subsref behaviour.');
assert(isequal(size(da(1)), [1 1]), 'unexpexted subsref behaviour.');

%% switch modes
d2.mode = 'fmin';
d2.plotResults
close gcf
%% both
dischargeFit(V, C_d, I, Temp, 'mode', 'both'); % validate syntax
d = dischargeFit(V, C_d, I, Temp); % 'both' should be default
d.plotResults
close gcf
% TODO: Create assertion tests
assert(isequal(d.rmse, d2.rmse), 'mode switch or ''both'' mode not functioning as expected')

disp('dischargeFit tests passed')

end