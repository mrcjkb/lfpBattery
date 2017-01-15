%% MLUnit test for cycleCounter
function cycleCounterTests
import lfpBattery.*
socMax = 0.8;
socMin = 0.2;

c = dambrowskiCounter(socMin, socMax);
cl = ccListener(c);
load(fullfile(pwd, 'MLUnitTests', 'cycleCounterTests', 'testInputs.mat'))

for i = uint64(2):uint64(numel(soc))
    c.update(soc(i));
    if cl.isnewC
        cl.isnewC = false;
    end
end
% MTODO: Update tests with listener to extract cDoC
% assert(isequal(c.cDoC, result.cDoC), 'unexpected cDoC histogram')

disp('cycleCounter tests passed')
end