function dischargeFitTests
import lfpBattery.*

%% Input data
load(fullfile(pwd,'dischargeFitTests','testCurve.mat'))

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

%% Args
en = 340;
st = 13;
Temp = const.T_room;
CRate = 1;

%% Initialize with params
d = dischargeFit(V, C_d, CRate, Temp, st, en, E0, Ea, Eb, Aex, Bex, Cex, x0, v0, delta);
% d.plotResults
assert(isequal(d.rmse, 0.3587), 'unexpected rmse')

%% Initialize without params
d2 = dischargeFit(V, C_d, CRate, Temp, st, en);
% d2.plotResults
assert(isequal(d2.rmse, 0.3587), 'unexpected rmse')

% TODO: Create additional assetion tests

end