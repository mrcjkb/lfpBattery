function pdfdoc
%PDFDOC Opens the lfpBattery package's PDF documentation.
%
%Syntax: lfpBattery.pdfdoc
p = lfpBattery.commons.getRoot;
open(fullfile(p, 'Documentation', 'lfpBattery_Documentation.pdf'))
end

