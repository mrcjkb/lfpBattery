function batteryCellTests
%BATTERYCELLTESTS Summary of this function goes here
%   Detailed explanation goes here

import lfpBattery.*
load(fullfile(pwd, 'MLUnitTests', 'batteryCellTests', 'dcCurves.mat'))

%% Initialization
b = batteryCell;
b.adddcurves(d)


% Charge and discharge

%%
disp('batteryCell tests passed')

