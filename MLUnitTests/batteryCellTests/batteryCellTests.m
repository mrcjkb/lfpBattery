function batteryCellTests
%BATTERYCELLTESTS Summary of this function goes here
%   Detailed explanation goes here

import lfpBattery.*
load(fullfile(pwd, 'MLUnitTests', 'batteryCellTests', 'dcCurves.mat'))

%% Initialization
b = batteryCell('socIni', 0.2, 'socMax', 1, 'socMin', 0.2);
b.adddcurves(d)
dt = 60;

%% Charge and discharge with current and SoC limiting tests
b.powerRequest(-10, dt);
assert(isequal(b.SoC, 0.2), 'Unexpected lower SoC limitation.')
P = b.powerRequest(500, dt);
assert(P < 100, 'Unexpected current limitation.')
for i = 1:100
    b.powerRequest(60, dt);
end
assert(isequal(b.SoC, 1), 'Unexpected upper SoC limitation')

%% Init batteryCell with ageModel
batteryCell('ageModel', 'EO');
batteryCell('cycleCounter', dummyCycleCounter);
batteryCell('ageModel', dummyAgeModel);
%%
disp('batteryCell tests passed')

