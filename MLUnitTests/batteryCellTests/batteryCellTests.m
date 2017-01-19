function batteryCellTests
%BATTERYCELLTESTS Summary of this function goes here
%   Detailed explanation goes here

import lfpBattery.*
load(fullfile(pwd, 'MLUnitTests', 'batteryCellTests', 'dcCurves.mat'))

%% Initialization
b = batteryCell(3.5, 3.2, 'socIni', 0.2, 'socMax', 1, 'socMin', 0.2);
b.addcurves(d)
dt = 60;

%% Charge and discharge with current and SoC limiting tests
b.powerRequest(-10, dt);
assert(abs(b.SoC - 0.2) < 1e-10, 'Unexpected lower SoC limitation.')
P = b.powerRequest(500, dt);
assert(P < 100, 'Unexpected current limitation.')
for i = 1:100
    b.powerRequest(60, dt);
end
assert(isequal(b.SoC, 1), 'Unexpected upper SoC limitation')

%% Init batteryCell with ageModel
batteryCell(3.5, 3.2, 'ageModel', 'EO');
batteryCell(3.5, 3.2, 'cycleCounter', dummyCycleCounter);
batteryCell(3.5, 3.2, 'ageModel', dummyAgeModel);
%%
disp('batteryCell tests passed')

