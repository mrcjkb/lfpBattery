%% MLUnit test for cycleCounter
function ageModelTests
import lfpBattery.*
socMax = 0.8;
socMin = 0.2;

c = dambrowskiCounter(socMin, socMax);
cl = ccListener(c);
warning('off', 'all')
a = eoAgeModel(c);
warning('on', 'all')
% MTODO: replace this with woehlerFit object when class is completed
modelfun = @(beta,xx)(beta(1).*xx.^(-beta(2)));
beta = [10.^7, 1.691];
N1 = nlinfit(DoDN,N,modelfun,beta);
fit = @(x)(N1(1).*x.^(-N1(2)));

a2 = eoAgeModel(c, fit);

load(fullfile(pwd,'ageModelTests', 'testInputs.mat'))

cDoC = [];
cDoC0 = 0;
for i = uint64(2):uint64(numel(soc))
    c.update(soc(i));
    if cl.isnewC
        if isequal(c.cDoC, cDoC0)
            error('double counting in dambrowskiCounter.')
        else
            cDoC = [cDoC; c.cDoC]; %#ok<AGROW>
        end
        cDoC0 = c.cDoC;
        cl.isnewC = false;
    end
end
assert(isequal(c.cDoC, result.cDoC), 'unexpected cDoC histogram in dambrowskiCounter.')
assert(isequal(a.SoH, 1), 'ageModel should not be applied in eoAgeModel.')
assert(isequal(a2.SoH, soh), 'unexpected aging behaviour for eoAgeModel.')
end