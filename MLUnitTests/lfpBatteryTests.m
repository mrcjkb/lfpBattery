import lfpBattery.*
[p, ~] = fileparts(which('lfpBatteryTests'));
cd(p)
clearvars p

%% Script for calling lfpBattery MLUnit tests
disp(' ')
disp('Beginning MLUnit tests...')
cycleCounterTests

dischargeFitTests;