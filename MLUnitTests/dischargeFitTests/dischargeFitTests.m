function dischargeFitTests(fig)
if nargin == 0
    fig = false;
end

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
Temp = const.T_room;
CRate = 1;

%% Initialize with params
d = dischargeFit(V, C_d, CRate, Temp, E0, Ea, Eb, Aex, Bex, Cex, x0, v0, delta);
if fig
    d.plotResults
end
%% Initialize without params
d2 = dischargeFit(V, C_d, CRate, Temp);
if fig
    d2.plotResults
end

% TODO: Create assertion tests

end