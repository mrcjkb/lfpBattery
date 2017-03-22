%% MLUnit test for cycleCounter
function ageModelTests
import lfpBattery.*

load(fullfile(pwd, 'MLUnitTests', 'ageModelTests', 'testInputs.mat'))

socMax = 0.8;
socMin = 0.2;

c = dambrowskiCounter(socMin, socMax);
cl = ccListener(c);
warning('off', 'all')
a = eoAgeModel(c);
warning('on', 'all')
modelfun = @(beta,xx)(beta(1).*xx.^(-beta(2)));
beta = [10.^7, 1.691];
N1 = nlinfit(DoDN,N,modelfun,beta);
cfit = @(x)(N1(1).*x.^(-N1(2)));
a2 = eoAgeModel(c, cfit);
w = woehlerFit(DoDN, N);
w.plotResults
close gcf
a3 = eoAgeModel(c, w);

cDoC = [];
for i = uint64(2):uint64(numel(soc))
    c.update(soc(i));
    if cl.isnewC
        cDoC = [cDoC; c.cDoC]; %#ok<AGROW>
        cl.isnewC = false;
    end
end
tol = 1e-04;
assert(isequal(a.SoH, 1), 'ageModel should not be applied in eoAgeModel without fit function.')
assert(abs(a2.SoH - 0.9049) <= tol, 'unexpected aging behaviour for eoAgeModel with nlinfit.')
assert(abs(a3.SoH - 0.9057) <= tol, 'unexpected aging behaviour for eoAgeModel with woehlerFit.')

%%
disp('age model tests passed')