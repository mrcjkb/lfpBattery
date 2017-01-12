%% MLUnit test for cycleCounter
function cycleCounterTests
import lfpBattery.*
socMax = 0.8;
socMin = 0.2;

c = dambrowskiCounter(socMin, socMax);
cl = ccListener(c);
a = eoAgeModel(c);
load(fullfile(pwd,'cycleCounterTests', 'testInputs.mat'))

cDoC = [];
cDoC0 = 0;
for i = uint64(2):uint64(numel(soc))
    c.update(soc(i));
    if cl.isnewC
        if isequal(c.cDoC, cDoC0)
            error('double counting')
        else
            cDoC = [cDoC; c.cDoC]; %#ok<AGROW>
        end
        cDoC0 = c.cDoC;
        cl.isnewC = false;
    end
end

assert(isequal(c.cDoC, result.cDoC), 'unexpected cDoC histogram')

disp('cycleCounter tests passed')
end