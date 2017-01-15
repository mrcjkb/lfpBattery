function batteryCellTests
%BATTERYCELLTESTS Summary of this function goes here
%   Detailed explanation goes here

import lfpBattery.*
load(fullfile(pwd, 'batteryCellTests', 'dcCurves.mat'))
b = batteryCell;
b.adddcurves(d)

disp('batteryCell tests passed')

