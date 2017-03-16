function pdfdoc
%PDFDOC Opens the lfpBattery package's PDF documentation.
%
%Syntax: lfpBattery.pdfdoc
[p, ~] = fileparts(fileparts(which('lfpBatteryTests')));
open(fullfile(p, 'Documentation', 'lfpBattery_Documentation.pdf'))
end

